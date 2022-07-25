/**
 * Created by dave on 2020-04-23.
 */

public without sharing class OnlineBoatReservation_Controller {
  public virtual class DuplicateWrapper implements Comparable {
    public Decimal confidence;
    public SObject record;

    public DuplicateWrapper(Datacloud.MatchRecord matchRecord) {
      this.confidence = matchRecord.getMatchConfidence();
      this.record = matchRecord.getRecord();
    }

    public Integer compareTo(Object compareTo) {
      DuplicateWrapper compareDup = (DuplicateWrapper) compareTo;
      if (compareDup.confidence > this.confidence)
        return 1;
      if (compareDup.confidence < this.confidence)
        return -1;
      return 0;
    }
  }

  public virtual class AccountSaveResult {
    @AuraEnabled
    public Account record;
    @AuraEnabled
    public String opportunityId;
    @AuraEnabled
    public String referenceNumber;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String[] messages;
    @AuraEnabled
    public List<DuplicateWrapper> duplicateRecords;

    public AccountSaveResult() {
    }

    public void addDuplicate(DuplicateWrapper dup) {
      if (this.duplicateRecords == null)
        this.duplicateRecords = new List<DuplicateWrapper>();
      this.duplicateRecords.add(dup);
    }

    public void addMessage(String msg) {
      if (this.messages == null)
        this.messages = new List<String>();
      this.messages.add(msg);
    }
  }

  public virtual class Customer {
    public String id;
    public String firstName;
    public String lastName;
    public String email;
    public String phone;
    public String state;

    private Account acct;
    private Lead lead;
    private String[] errors;

    public Customer() {
    }

    public AccountSaveResult upsertToAccount() {
      if (isValid()) {
        this.buildAccount();
        return handleAccountUpsert();
      } else {
        AccountSaveResult result = new AccountSaveResult();
        result.status = 'error';
        result.messages = this.errors;
        return result;
      }
    }

    private Boolean isValid() {
      String[] errs = new List<String>();
      if (this.firstName == null)
        errs.add('First Name is required');
      if (this.lastName == null)
        errs.add('Last Name is required');
      if (this.email == null)
        errs.add('Email is required');
      if (this.phone == null)
        errs.add('Phone number is required');
      if (this.state == null)
        errs.add('Province is required');
      if (errs.size() > 0) {
        this.errors = errs;
        return false;
      }
      return true;
    }

    private void buildAccount() {
      if (this.acct == null)
        this.acct = new Account(RecordTypeId = LGND_Utilities.recordTypeIdFromName('Account', 'Person Account'));
      this.acct.Id = this.id;
      this.acct.FirstName = this.firstName;
      this.acct.LastName = this.lastName;
      this.acct.PersonEmail = this.email;
      this.acct.Phone = this.phone;
      this.acct.BillingState = this.state;
    }

    private AccountSaveResult handleAccountUpsert() {
      if (this.acct.Id != null || !hasLead()) {
        return doAccountSave();
      }
      return convertLead();
    }

    private AccountSaveResult doAccountSave() {
      Database.UpsertResult saveResult = Database.upsert(this.acct, Account.Fields.Id, false);

      if (saveResult.isSuccess()) {
        return handleSaveSuccess();
      } else {
        return handleErrors(saveResult.getErrors());
      }
    }

    private Boolean hasLead() {
      if (this.lead != null)
        return true;
      List<Lead> leads = Lead_Selector.allNonConvertedByEmail(this.acct.PersonEmail);
      if (leads.size() == 0)
        return false;
      else {
        this.lead = leads[0];
        return true;
      }
    }

    private Boolean leadSynced() {
      if (this.firstName != this.lead.FirstName)
        return false;
      if (this.lastName != this.lead.LastName)
        return false;
      if (this.email != this.lead.Email)
        return false;
      if (this.phone != this.lead.Phone)
        return false;
      if (this.lead.Company != null)
        return false;
      return true;
    }

    private Account updateAccountDetails() {
      update this.acct;
      return this.acct;
    }

    private String buildOppName() {
      Datetime today = Datetime.now();
      String nameString = this.firstName + ' ' + this.lastName + ' - ';
      nameString += today.format('yyyy.MM.dd-HHmm');
      return nameString;
    }

    private AccountSaveResult convertLead() {
      if (!leadSynced()) {
        this.lead.FirstName = this.firstName;
        this.lead.LastName = this.lastName;
        this.lead.Email = this.email;
        this.lead.Phone = this.phone;
        this.lead.Company = null;
        update this.lead;
      }
      checkForDuplicateAccount();
      Database.LeadConvert lc = new Database.LeadConvert();
      lc.setLeadId(this.lead.Id);
      LeadStatus convertStatus = [SELECT Id, ApiName FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
      lc.setConvertedStatus(convertStatus.ApiName);
      lc.setOpportunityName(buildOppName());
      lc.setOwnerId(UserInfo.getUserId());
      //lc.setDoNotCreateOpportunity( true );
      if (this.acct != null && this.acct.Id != null) {
        lc.setAccountId(this.acct.Id);
      }
      try {
        Database.LeadConvertResult leadConvertResult = Database.convertLead(lc);
        if (leadConvertResult.isSuccess()) {
          this.acct.Id = leadConvertResult.getAccountId();
          Opportunity opp = upsertOpportunity(leadConvertResult.getOpportunityId());
          AccountSaveResult result = new AccountSaveResult();
          result.status = 'success';
          result.opportunityId = opp.Id;
          result.referenceNumber = opp.Reference_Number__c;
          result.record = updateAccountDetails();
          return result;
        } else {
          return handleErrors(leadConvertResult.getErrors());
        }
      } catch (Exception e) {
        if (e.getMessage().contains('DUPLICATES_DETECTED')) {
          AccountSaveResult result = doAccountSave();
          return result;
        }
        AccountSaveResult result = new AccountSaveResult();
        result.status = 'error';
        result.addMessage(e.getMessage());
        return result;
      }
    }

    private void checkForDuplicateAccount() {
      List<Datacloud.FindDuplicatesResult> results = Datacloud.FindDuplicates.findDuplicates(
        new List<Account>{ this.acct }
      );
      System.debug(results.size());
      if (results.size() > 0) {
        System.debug('We have duplicates');
        System.debug(results[0].getDuplicateResults());
        System.debug(results[0].getDuplicateResults()[0].getMatchResults());
        System.debug(results[0].getDuplicateResults()[0].getMatchResults()[0].getMatchRecords());
        List<DuplicateWrapper> dupWrappers = new List<DuplicateWrapper>();
        for (
          Datacloud.MatchRecord matchRecord : results[0].getDuplicateResults()[0].getMatchResults()[0].getMatchRecords()
        ) {
          dupWrappers.add(new DuplicateWrapper(matchRecord));
        }
        if (dupWrappers.size() > 0) {
          dupWrappers.sort();
          this.acct.Id = (Id) dupWrappers[0].record.get('Id');
        }
      }
    }

    private AccountSaveResult forceAccountSave() {
      Database.DMLOptions dml = new Database.DMLOptions();
      dml.DuplicateRuleHeader.allowSave = true;
      dml.DuplicateRuleHeader.runAsCurrentUser = true;
      Database.SaveResult saveResult = Database.insert(this.acct, dml);
      if (saveResult.isSuccess()) {
        if (this.lead != null)
          return convertLead();
        return handleSaveSuccess();
      } else {
        return handleErrors(saveResult.getErrors());
      }
    }

    private AccountSaveResult handleSaveSuccess() {
      Opportunity opp = upsertOpportunity(null);
      AccountSaveResult result = new AccountSaveResult();
      result.record = this.acct;
      result.status = 'success';
      result.opportunityId = opp.Id;
      result.referenceNumber = opp.Reference_Number__c;
      return result;
    }

    private AccountSaveResult handleErrors(List<Database.Error> errors) {
      AccountSaveResult result = new AccountSaveResult();
      result.status = 'error';
      for (Database.Error error : errors) {
        result.addMessage(error.getMessage());
        if (error instanceof Database.DuplicateError) {
          /* The Error */
          Database.DuplicateError duplicateError = (Database.DuplicateError) error;
          Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();

          /* Matched Records */
          Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
          Datacloud.MatchResult matchResult = matchResults[0];
          Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();

          for (Datacloud.MatchRecord matchRecord : matchRecords) {
            result.addDuplicate(new DuplicateWrapper(matchRecord));
          }
        }
      }
      if (result.duplicateRecords != null) {
        result.duplicateRecords.sort();
        this.acct.Id = (Id) result.duplicateRecords[0].record.get('Id');
        return this.acct.Id == null ? forceAccountSave() : this.hasLead() ? convertLead() : doAccountSave();
      }
      return result;
    }

    private Opportunity upsertOpportunity(Id oppId) {
      Opportunity opp = new Opportunity(
        Id = oppId,
        //recordTypeId = new Application_RecordType().getOpportunityRecordTypes().getOnlineId(),
        AccountId = this.acct.Id,
        Name = buildOppName(),
        StageName = 'Quoting',
        CloseDate = Date.today().addMonths(1)
      );
      upsert opp;
      //Boolean o = OpportunityTriggerHandler.disableTrigger;
      //OpportunityTriggerHandler.disableTrigger = true;
      opp.Pricebook2Id = LGND_Constants.retailPricebookId;
      MetadataTriggerHandler.bypass('Opportunity');
      update opp;
      // OpportunityTriggerHandler.disableTrigger = o;
      MetadataTriggerHandler.clearBypass('Opportunity');
      System.debug(opp);
      return Opportunity_Selector.allByIds(new Set<Id>{ opp.Id })[0];
    }
  }

  @AuraEnabled(Cacheable=true)
  public static List<Map<String, String>> fetchBoats() {
    List<Map<String, String>> boats = new List<Map<String, String>>();
    for (Product2 p : Product_Selector.allBoatsAvailableForOnlineSale()) {
      Map<String, String> b = new Map<String, String>();
      b.put('id', p.Id);
      b.put('name', p.Name);
      b.put('imageURL', p.Default_Gallery_Image_Original__c);
      boats.add(b);
    }
    return boats;
  }

  @AuraEnabled(Cacheable=true)
  public static OnlineBoat fetchBoat(String boatId) {
    OnlineBoat b = new OnlineBoat(Product_Selector.getOnlineBoat(boatId));
    return b;
  }

  @AuraEnabled(Cacheable=true)
  public static Map<String, Object> fetchSettings() {
    Map<String, Object> result = new Map<String, Object>();
    Boat_Reservation_Settings__mdt settings = [
      SELECT Default_Deposit_Amount__c, Default_Interest_Rate__c, Default_Term__c
      FROM Boat_Reservation_Settings__mdt
      LIMIT 1
    ];
    result.put('term', settings.Default_Term__c);
    result.put('deposit', settings.Default_Deposit_Amount__c);
    result.put('interestRate', settings.Default_Interest_Rate__c);
    return result;
  }

  @AuraEnabled(Cacheable=true)
  public static Map<String, Object> fetchOrderDetails(String opportunityId) {
    if (opportunityId == null) {
      return null;
    }
    Opportunity opp = Opportunity_Selector.selectAllByIdWithLineItems(new Set<Id>{ Id.valueOf(opportunityId) })[0];
    Account acct = Account_Selector.personAccountById(opp.AccountId);
    Map<String, Object> result = new Map<String, Object>{ 'account' => acct, 'opportunity' => opp };
    List<Map<String, String>> options = new List<Map<String, String>>();
    Application_RecordType.ProductRTs productRts = new Application_RecordType().getProductRecordTypes();

    Set<Id> boatMotorTrailerRtIds = new Set<Id>{
      productRts.getBoatId(),
      productRts.getMotorId(),
      productRts.getTrailerId()
    };
    for (OpportunityLineItem oli : opp.OpportunityLineItems) {
      System.debug(oli.Product2.Name + ' - ' + oli.Product2.RecordType.Name);
      if (oli.Product2.RecordTypeId == productRts.getBoatId()) {
        OnlineBoat boat = new OnlineBoat(Product_Selector.getOnlineBoat(oli.Product2Id));
        result.put('boat', boat);
      }
      if (oli.Product2.RecordTypeId == productRts.getMotorId()) {
        result.put('motor', buildItem(oli));
      }
      if (oli.Product2.RecordTypeId == productRts.getTrailerId()) {
        result.put('trailer', buildItem(oli));
      }
      if (
        (oli.Product2.RecordTypeId == productRts.getTrollingMotorId() ||
        oli.Product2.RecordTypeId == productRts.getPartId()) &&
        (oli.ParentProductId__c == null ||
        (oli.ParentProductId__c <> null && boatMotorTrailerRtIds.contains(oli.ParentProductId__r.RecordTypeId)))
      ) {
        options.add(buildItem(oli));
      }
    }
    if (options.size() > 0) {
      result.put('options', options);
    }
    getImagesForSummary(result);
    return result;
  }

  @AuraEnabled
  public static AccountSaveResult createAccount(String customerJSON) {
    OnlineBoatReservation_Controller.Customer cust = (OnlineBoatReservation_Controller.Customer) JSON.deserialize(
      customerJSON,
      OnlineBoatReservation_Controller.Customer.class
    );
    AccountSaveResult result = cust.upsertToAccount();
    if (result.status == 'success')
      return result;
    AuraHandledException err = new AuraHandledException(result.messages[0]);
    err.setMessage(result.messages[0]);
    throw err;
  }

  @AuraEnabled
  public static void saveLineItems(String acctJSON, String oppJSON, String olisJSON) {
    Account acct = (Account) JSON.deserialize(acctJSON, Account.class);
    update acct;
    Opportunity opp = (Opportunity) JSON.deserialize(oppJSON, Opportunity.class);
    opp.StageName = 'Sales Manager Approval Pending';
    update opp;

    List<OpportunityLineItem> olis = (List<OpportunityLineItem>) JSON.deserialize(
      olisJSON,
      List<OpportunityLineItem>.class
    );
    for (OpportunityLineItem oli : olis) {
      oli.OpportunityId = opp.Id;
      oli.BoatBuilderItem__c = true;
    }
    insert olis;
  }

  @AuraEnabled
  public static void setPickupDealership(String opportunityId, String dealerId) {
    System.debug('setPickupDealership');
    update new Opportunity(Id = opportunityId, PickupDealership__c = dealerId);
  }

  //PRIVATES

  private static Map<String, String> buildItem(OpportunityLineItem oli) {
    return new Map<String, String>{
      'id' => oli.Product2Id,
      'name' => oli.Product2.Name,
      'name_fr' => oli.Product2.Name_FR__c
    };
  }

  private static void getImagesForSummary(Map<String, Object> orderDetails) {
    Map<String, Object> images = new Map<String, Object>();
    String boatImage;
    String motorImage;
    List<String> optionImages = new List<String>();

    Set<String> selectedOptionIds = new Set<String>();
    //build set of Ids of selected Options
    if (orderDetails.containsKey('options')) {
      System.debug('^^^^^^^^^^ WE HAVE OPTIONS ^^^^^^^^^^^^^');
      List<Map<String, String>> selectedOptions = (List<Map<String, String>>) orderDetails.get('options');
      for (Map<String, String> opt : selectedOptions) {
        selectedOptionIds.add(opt.get('id'));
      }
    }

    OnlineBoat boat = (OnlineBoat) orderDetails.get('boat');
    boatImage = findCorrectImageFromAllMarketingContents(boat.marketingContent);
    if (selectedOptionIds.size() > 0) {
      System.debug('^^^^^^^^^^^ Get Option Images  ^^^^^^^^^^');
      optionImages.addAll(optionImages(boat.optionalProducts, selectedOptionIds));
    }

    //figure out motor image
    if (orderDetails.containsKey('motor')) {
      System.debug('*** Order Detail MOTOR ****');
      System.debug(orderDetails.get('motor'));
      Map<String, String> motor = (Map<String, String>) orderDetails.get('motor');
      if (motor.get('id') == boat.standardMotor.id) {
        motorImage = findCorrectImageFromAllMarketingContents(boat.standardMotor.marketingContent);
        if (selectedOptionIds.size() > 0) {
          optionImages.addAll(optionImages(boat.standardMotor.optionalProducts, selectedOptionIds));
        }
      } else {
        for (Online_Product.Upgrade motorUpgrade : boat.motorUpgrades) {
          if (motor.get('id') == motorUpgrade.id) {
            if (selectedOptionIds.size() > 0) {
              optionImages.addAll(optionImages(motorUpgrade.optionalProducts, selectedOptionIds));
            }
            String mImage = findCorrectImageFromAllMarketingContents(motorUpgrade.marketingContent);
            if (mImage != null) {
              motorImage = mImage;
            }
            break;
          }
        }
      }
    }

    //Check if trailer upgrade
    if (orderDetails.containsKey('trailer')) {
      Map<String, String> trailer = (Map<String, String>) orderDetails.get('trailer');
      if (trailer.get('id') != boat.standardTrailer.id) {
        for (Online_Product.Upgrade trailerUpgrade : boat.trailerUpgrades) {
          if (trailer.get('id') == trailerUpgrade.id) {
            if (selectedOptionIds.size() > 0) {
              optionImages.addAll(optionImages(trailerUpgrade.optionalProducts, selectedOptionIds));
            }
            String trailerImage = findCorrectImageFromAllMarketingContents(trailerUpgrade.marketingContent);
            if (trailerImage != null) {
              boatImage = trailerImage;
            }
            break;
          }
        }
      }
    }

    if (boatImage != null) {
      images.put('boat', boatImage);
    }
    if (motorImage != null) {
      images.put('motor', motorImage);
    }
    if (optionImages.size() > 0) {
      images.put('options', optionImages);
    }

    orderDetails.put('summaryImages', images);
  }

  private static List<String> optionImages(
    Map<String, List<Online_Product.Option>> optionsMap,
    Set<String> selectedOptionIds
  ) {
    List<String> result = new List<String>();
    for (String key : optionsMap.keySet()) {
      if (key != 'canvas') {
        for (Online_Product.Option option : optionsMap.get(key)) {
          if (selectedOptionIds.contains(option.id)) {
            String optionImage = findCorrectImageFromAllMarketingContents(option.marketingContent);
            if (optionImage != null) {
              result.add(optionImage);
            }
          }
        }
      }
    }
    return result;
  }

  private static String findCorrectImageFromAllMarketingContents(
    List<Online_Product.MarketingContent> marketingContents
  ) {
    String url;
    for (Online_Product.MarketingContent mc : marketingContents) {
      if (mc.label == 'images') {
        Map<String, String> images = imagesFromMarketingContent(mc.content);
        if (images.containsKey('backLeft')) {
          url = images.get('backLeft');
          break;
        }
      }
    }
    return url;
  }

  private static Map<String, String> imagesFromMarketingContent(String content) {
    Map<String, String> result = new Map<String, String>();
    for (String image : content.stripHtmlTags().split('\\|')) {
      System.debug(image);
      String[] keyValue = image.split(':');
      result.put(keyValue[0], keyValue[1]);
    }
    return result;
  }
}
