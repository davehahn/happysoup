public with sharing class BusinessOffice_Controller {
  /* +++++ TOOL METHODS +++++ */

  @AuraEnabled
  public static String toolInitialize(String recordId) {
    String objType = objType(recordId);
    Id pbId;
    Opportunity opp;
    Quote qt;
    AcctSeed__Project__c erp;
    if (objType == 'Opportunity') {
      opp = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :recordId];
      pbId = opp.Pricebook2Id;
    }
    if (objType == 'Quote') {
      qt = [SELECT Id, Pricebook2Id FROM Quote WHERE Id = :recordId];
      pbId = qt.Pricebook2Id;
    }
    if (objType == 'AcctSeed__Project__c') {
      erp = [
        SELECT
          Id,
          GMBLASERP__Pricebook__c,
          (
            SELECT Id, AcctSeedERP__Product__r.InsurancePlan__r.Name
            FROM AcctSeedERP__Project_Materials__r
            WHERE
              AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__c = :LGND_Constants.GLV2Id_BusinessOffice
            LIMIT 1
          )
        FROM AcctSeed__Project__c
        WHERE Id = :recordId
      ];
      pbId = erp.GMBLASERP__Pricebook__c;
    }

    if (pbId != null) {
      Map<String, String> result = new Map<String, String>();
      Pricebook2 pb = [SELECT Id, Name FROM Pricebook2 WHERE ID = :pbId];
      Boolean canAccess =
        objType == 'AcctSeed__Project__c' &&
        LGND_Utilities.CustomPermissions.canAccessInsuranceDocuments &&
        erp != null &&
        erp.AcctSeedERP__Project_Materials__r.size() > 0;
      result.put('Id', pb.Id);
      result.put('Name', pb.Name);
      result.put('sObjectType', objType);
      result.put('documentsAccessible', String.valueOf(canAccess));
      //result.put('institutions', JSON.serialize(institutions) );
      return JSON.serialize(result);
    }
    return null;
  }

  /* ===== TOOL METHODS ===== */

  /* +++++++  BUSINESS OFFICE SPECIFIC FIELDS +++++++++ */

  @AuraEnabled(cacheable=true)
  public static List<Map<String, Object>> getBusinessOfficeFields(String sObjectType) {
    String fieldSetName = 'Retail_Business_Office_Fields';
    List<Map<String, Object>> result = new List<Map<String, Object>>();
    List<Schema.FieldSetMember> fieldSetMembers = Schema.getGlobalDescribe()
      .get(sObjectType)
      .getDescribe()
      .FieldSets.getMap()
      .get(fieldSetName)
      .getFields();
    if (fieldSetMembers != null) {
      for (FieldSetMember fsm : fieldSetMembers) {
        Map<String, Object> field = new Map<String, Object>{
          'name' => fsm.getFieldPath(),
          'editable' => fsm.getSObjectField().getDescribe().isUpdateable()
        };

        result.add(field);
      }
    }
    return result;
  }

  /* ======= /BUSINESS OFFICE SPECIFIC FIELDS ========= */

  /* +++++ FINANCIAL INSTITUTION +++++*/

  public class FinancingInstitutionDetails {
    public String value { get; set; }
    public List<Account> options { get; set; }

    public FinancingInstitutionDetails() {
      this.options = new List<Account>();
    }
  }

  @AuraEnabled
  public static String fetchFinancialInstitutionOptions(String recordId) {
    FinancingInstitutionDetails result = new FinancingInstitutionDetails();
    String objType = objType(recordId);
    //String query = 'SELECT Id, Financing_Account__r.Name FROM ';
    //query += objType;
    //query += ' WHERE Id = \'' + recordId +'\' LIMIT 1';
    //sObject record = Database.query( query );
    //result.value = String.valueOf( record.get('Financing_Account__r.Name') );
    if (objType == 'AcctSeed__Project__c') {
      result.value = [SELECT Financing_Account__c FROM AcctSeed__Project__c WHERE Id = :recordId LIMIT 1]
      .Financing_Account__c;
    } else if( objType == 'Quote')
    {
      result.value = [SELECT Financing_Account__c FROM Quote WHERE Id = :recordId LIMIT 1].Financing_Account__c;
    } else {
      result.value = [SELECT Financing_Account__c FROM Opportunity WHERE Id = :recordId LIMIT 1].Financing_Account__c;
    }
    result.options = [SELECT Id, Name, BillingStreet, BillingState FROM Account WHERE Financing_Vendor__c = TRUE];
    return JSON.serialize(result);
  }

  @AuraEnabled
  public static void updateFinancialInstitution(String recordId, String fi_value) {
    String ot = objType(recordId);
    sObject record;
    switch on ot {
      when 'AcctSeed__Project__c' {
        record = [SELECT Id FROM AcctSeed__Project__c WHERE Id = :recordId LIMIT 1];
      }
      when 'Quote' {
        record = [SELECT Id FROM Quote WHERE Id = :recordId LIMIT 1];
      }
      when 'Opportunity' {
        record = [SELECT Id FROM Opportunity WHERE Id = :recordId LIMIT 1];
      }
    }
    try {
      record.put('Financing_Account__c', fi_value);
    } catch (Exception e) {
    }
    update record;
  }

  /* +++++ PPSA METHODS +++++ */

  @AuraEnabled
  public static String ppsa_init(String recordId, String pricebookId) {
    Map<String, String> result = new Map<String, String>();
    Id pbeId = findPPSAPricebookEntry(pricebookId);
    result.put('pricebookEntryId', pbeId);
    findPPSALineItem(recordId, pbeId, result);
    return JSON.serialize(result);
  }

  @AuraEnabled
  public static String savePPSALine(String lineId, String value, String parentId, String pricebookEntryId) {
    String objType = objType(parentId);
    switch on objType {
      when 'Opportunity' {
        return handleOpportunityLineItem(lineId, value, parentId, pricebookEntryId);
      }
      when 'Quote' {
        return handleQuoteLineItem(lineId, value, parentId, pricebookEntryId);
      }
      when 'AcctSeed__Project__c'{
        return handleMaterialLineItem(lineId, value, parentId, pricebookEntryId);
      }
      when else {
        return null;
      }
    }
  }

  private static void findPPSALineItem(Id recordId, Id pricebookId, Map<String, String> result) {
    String objType = objType(recordId);
    if (result.get('pricebookEntryId') != null) {
      if (objType == 'Opportunity') {
        try {
          OpportunityLineItem oli = [
            SELECT Id, UnitPrice
            FROM OpportunityLineItem
            WHERE OpportunityId = :recordId AND PricebookEntryId = :pricebookId
          ];
          result.put('ppsa_id', oli.Id);
          result.put('ppsa_value', String.valueOf(oli.UnitPrice));
        } catch (Exception e) {
          result.put('ppsa_id', null);
          result.put('ppsa_value', null);
        }
      }
      if (objType == 'Quote') {
        try {
          QuoteLineItem qli = [
            SELECT Id, UnitPrice
            FROM QuoteLineItem
            WHERE QuoteId = :recordId AND PricebookEntryId = :pricebookId
          ];
          result.put('ppsa_id', qli.Id);
          result.put('ppsa_value', String.valueOf(qli.UnitPrice));
        } catch (Exception e) {
          result.put('ppsa_id', null);
          result.put('ppsa_value', null);
        }
      }


      if (objType == 'AcctSeed__Project__c') {
        try {
          PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Id = :pricebookId];
          AcctSeedERP__Material__c mat = [
            SELECT Id, GMBLASERP__Unit_Price__c
            FROM AcctSeedERP__Material__c
            WHERE AcctSeedERP__Product__c = :pbe.Product2Id AND AcctSeedERP__Project__c = :recordId
          ];
          result.put('ppsa_id', mat.Id);
          result.put('ppsa_value', String.valueOf(mat.GMBLASERP__Unit_Price__c));
        } catch (Exception e) {
          result.put('ppsa_id', null);
          result.put('ppsa_value', null);
        }
      }
    }
  }

  private static String findPPSAPricebookEntry(String pbId) {
    try {
      return [
        SELECT Id
        FROM PricebookEntry
        WHERE Pricebook2Id = :pbId AND Product2Id = :LGND_Constants.ppsaProductId
        LIMIT 1
      ]
      .Id;
    } catch (Exception e) {
      return null;
    }
  }

  private static String handleOpportunityLineItem(
    String lineId,
    String value,
    String parentId,
    String pricebookEntryId
  ) {
    Map<String, String> result = new Map<String, String>();
    if (lineId != null && (value == null || value == '' || Decimal.valueOf(value) == 0)) {
      OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem WHERE Id = :lineId];
      delete oli;
      result.put('ppsa_id', null);
      result.put('ppsa_value', null);
    } else {
      OpportunityLineItem oli = new OpportunityLineItem(
        Id = lineId,
        OpportunityId = parentId,
        PriceBookEntryId = pricebookEntryId,
        UnitPrice = Decimal.valueOf(value),
        Quantity = 1
      );
      upsert oli;
      result.put('ppsa_id', oli.Id);
      result.put('ppsa_value', String.valueOf(oli.UnitPrice));
    }
    return JSON.serialize(result);
  }

  private static String handleQuoteLineItem(
    String lineId,
    String value,
    String parentId,
    String pricebookEntryId
  ) {
    Map<String, String> result = new Map<String, String>();
    if (lineId != null && (value == null || value == '' || Decimal.valueOf(value) == 0)) {
      QuoteLineItem qli = [SELECT Id FROM QuoteLineItem WHERE Id = :lineId];
      delete qli;
      result.put('ppsa_id', null);
      result.put('ppsa_value', null);
    } else {
      QuoteLineItem qli = new QuoteLineItem(
        Id = lineId,
        QuoteId = parentId,
        PriceBookEntryId = pricebookEntryId,
        UnitPrice = Decimal.valueOf(value),
        Quantity = 1
      );
      upsert qli;
      result.put('ppsa_id', qli.Id);
      result.put('ppsa_value', String.valueOf(qli.UnitPrice));
    }
    return JSON.serialize(result);
  }

  private static String handleMaterialLineItem(String lineId, String value, String parentId, String pricebookEntryId) {
    System.debug('***LINE ID**** = ' + lineId);
    Map<String, String> result = new Map<String, String>();
    if (lineId != null && (value == null || value == '' || Decimal.valueOf(value) == 0)) {
      System.debug('HERE IS THE LINE ID = ' + lineId);
      AcctSeedERP__Material__c mat = new AcctSeedERP__Material__c(Id = lineId);
      delete mat;
      result.put('ppsa_id', null);
      result.put('ppsa_value', null);
    } else {
      PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Id = :pricebookEntryId];
      AcctSeed__Project_Task__c task;
      try {
        task = [
          SELECT Id
          FROM AcctSeed__Project_Task__c
          WHERE
            AcctSeed__Project__c = :parentId
            AND AcctSeed__GL_Account_Variable_2__c = :LGND_Constants.GLV2Id_BusinessOffice
          LIMIT 1
        ];
      } catch (Exception e) {
        task = ProjectTask_Service.buildBusinessOfficeTask(parentId);
        insert task;
      }
      AcctSeedERP__Material__c mat = new AcctSeedERP__Material__c(
        Id = lineId,
        AcctSeedERP__Project__c = parentId,
        AcctSeedERP__Project_Task__c = task.Id,
        AcctSeedERP__Product__c = pbe.Product2Id,
        GMBLASERP__Unit_Price__c = Decimal.valueOf(value),
        GMBLASERP__Price_Override__c = true,
        AcctSeedERP__Quantity_Per_Unit__c = 1
      );
      upsert mat;
      result.put('ppsa_id', mat.Id);
      result.put('ppsa_value', String.valueOf(Mat.GMBLASERP__Unit_Price__c));
    }
    return JSON.serialize(result);
  }

  /* ===== PPSA METHODS ===== */

  /* +++++ INSURANCE METHODS +++++ */

  public class InsuranceInitWrapper {
    public Integer term { get; set; }
    public Integer finTerm { get; set; }
    public Integer amort { get; set; }
    public Decimal intrestRate { get; set; }
    public Decimal preInsuranceAmount { get; set; }
    public String taxZoneId { get; set; }
    public Decimal insuranceTaxRate { get; set; }
    public Decimal deposit { get; set; }
    public List<InsurancePlan__c> plans { get; set; }
    public String planId { get; set; }
    public Map<String, BusinessOffice_Controller.SelectedInsuranceItem> selectedItems { get; set; }
    //temperary until we Quebec sorted out
    public Boolean isFromQuebec { get; set; }

    public InsuranceInitWrapper(String recordId) {
      this.plans = [SELECT Id, Name FROM InsurancePlan__c];
      this.selectedItems = new Map<String, BusinessOffice_Controller.SelectedInsuranceItem>();
      String objType = LGND_Utilities.sObjectNameFromId(recordId);
      if (objType == 'Opportunity')
        initForOpp(recordId);
      if (objType == 'Quote')
        initForQuote(recordId);
      if (objType == 'AcctSeed__Project__c')
        initForERP(recordId);
    }

    private void initForOpp(String recordId) {
      Opportunity opp = [
        SELECT
          Id,
          Pre_Insurance_Total__c,
          Deposit__c,
          Finance_Ammortization__c,
          Finance_Annual_Interest__c,
          Finance_Term__c,
          Insurance_Term__c,
          GL_Account_Variable_3__c,
          Tax_Rate_Retail__c,
          Account.BillingState,
          (
            SELECT
              Id,
              Insurance_Rate__c,
              InsuranceCoverage__c,
              PricebookEntryId,
              Product2Id,
              Product2.InsurancePlan__c,
              Product2.Is_Residual_Insurance__c,
              Product2.Family,
              UnitPrice,
              isPrepaid__c
            FROM OpportunityLineItems
            WHERE IsInsurance__c = TRUE
          )
        FROM Opportunity
        WHERE Id = :recordId
      ];
      this.isFromQuebec = opp.Account.BillingState == 'Quebec';
      this.term = Integer.valueOf(opp.Insurance_Term__c);
      this.finTerm = Integer.valueOf(opp.Finance_Term__c);
      this.amort = Integer.valueOf(opp.Finance_Ammortization__c);
      this.intrestRate = opp.Finance_Annual_Interest__c;
      this.preInsuranceAmount = opp.Pre_Insurance_Total__c;
      this.deposit = opp.Deposit__c;
      this.taxZoneId = opp.GL_Account_Variable_3__c;
      this.insuranceTaxRate = opp.Tax_Rate_Retail__c;
      if (opp.OpportunityLineItems.size() > 0) {
        this.planId = opp.OpportunityLineItems[0].Product2.InsurancePlan__c;
        for (OpportunityLineItem oli : opp.OpportunityLineItems) {
          this.selectedItems.put(oli.Product2Id, new BusinessOffice_Controller.SelectedInsuranceItem(oli));
        }
      }
    }

    private void initForQuote(String recordId) {
      Quote qt = [
        SELECT
          Id,
          Pre_Insurance_Total__c,
          Deposit__c,
          Finance_Ammortization__c,
          Finance_Annual_Interest__c,
          Finance_Term__c,
          Insurance_Term__c,
          GL_Account_Variable_3__c,
          Tax_Rate_Retail__c,
          Account.BillingState,
        (
          SELECT
            Id,
            Insurance_Rate__c,
            InsuranceCoverage__c,
            PricebookEntryId,
            Product2Id,
            Product2.InsurancePlan__c,
            Product2.Is_Residual_Insurance__c,
            Product2.Family,
            UnitPrice,
            isPrepaid__c
          FROM QuoteLineItems
          WHERE IsInsurance__c = TRUE
        )
        FROM Quote
        WHERE Id = :recordId
      ];
      this.isFromQuebec = qt.Account.BillingState == 'Quebec';
      this.term = Integer.valueOf(qt.Insurance_Term__c);
      this.finTerm = Integer.valueOf(qt.Finance_Term__c);
      this.amort = Integer.valueOf(qt.Finance_Ammortization__c);
      this.intrestRate =qt.Finance_Annual_Interest__c;
      this.preInsuranceAmount = qt.Pre_Insurance_Total__c;
      this.deposit = qt.Deposit__c;
      this.taxZoneId = qt.GL_Account_Variable_3__c;
      this.insuranceTaxRate = qt.Tax_Rate_Retail__c;
      if (qt.QuoteLineItems.size() > 0) {
        this.planId = qt.QuoteLineItems[0].Product2.InsurancePlan__c;
        for (QuoteLineItem qli : qt.QuoteLineItems) {
          this.selectedItems.put(qli.Product2Id, new BusinessOffice_Controller.SelectedInsuranceItem(qli));
        }
      }
    }

    private void initForErp(String recordId) {
      AcctSeed__Project__c erp = [
        SELECT
          Id,
          Deposit__c,
          Finance_Ammortization__c,
          Finance_Term__c,
          Finance_Annual_Interest__c,
          Insurance_Term__c,
          Pre_Insurance_Total__c,
          GL_Account_Variable_3__c,
          Tax_Rate_Retail__c,
          AcctSeed__Account__r.BillingState
        FROM AcctSeed__Project__c
        WHERE Id = :recordId
      ];
      this.isFromQuebec = erp.AcctSeed__Account__r.BillingState == 'Quebec';
      this.deposit = erp.Deposit__c == null ? 0 : erp.Deposit__c;
      this.intrestRate = erp.Finance_Annual_Interest__c == null ? 0 : erp.Finance_Annual_Interest__c;
      this.term = erp.Insurance_Term__c == null ? 0 : Integer.valueOf(erp.Insurance_Term__c);
      this.finTerm = erp.Finance_Term__c == null ? 0 : Integer.valueOf(erp.Finance_Term__c);
      this.amort = Integer.valueOf(erp.Finance_Ammortization__c);
      this.preInsuranceAmount = erp.Pre_Insurance_Total__c == null ? 0 : erp.Pre_Insurance_Total__c;
      this.taxZoneId = erp.GL_Account_Variable_3__c;
      this.insuranceTaxRate = erp.Tax_Rate_Retail__c;
      for (AcctSeed__Project_Task__c t : [
        SELECT
          Id,
          (
            SELECT
              Id,
              AcctSeedERP__Product__c,
              AcctSeedERP__Product__r.InsurancePlan__c,
              AcctSeedERP__Product__r.Is_Residual_Insurance__c,
              AcctSeedERP__Product__r.Family,
              GMBLASERP__Unit_Price__c,
              Insurance_Coverage__c,
              Insurance_Rate__c
            FROM AcctSeedERP__Materials__r
            WHERE
              AcctSeedERP__Product__r.RecordTypeId = :LGND_Constants.productRtId_Insurance
              AND AcctSeedERP__Product__r.InsurancePlan__c != NULL
          )
        FROM AcctSeed__Project_Task__c
        WHERE
          AcctSeed__Project__c = :recordId
          AND AcctSeed__GL_Account_Variable_2__c = :LGND_Constants.GLV2Id_BusinessOffice
      ]) {
        if (t.AcctSeedERP__Materials__r.size() > 0)
          this.planId = t.AcctSeedERP__Materials__r[0].AcctSeedERP__Product__r.InsurancePlan__c;
        for (AcctSeedERP__Material__c mat : t.AcctSeedERP__Materials__r) {
          this.selectedItems.put(mat.AcctSeedERP__Product__c, new BusinessOffice_Controller.SelectedInsuranceItem(mat));
        }
      }
    }
  }

  public class SelectedInsuranceItem {
    public String recordId { get; set; }
    public String pricebookEntryId { get; set; }
    public String productId { get; set; }
    public String coverage { get; set; }
    public String type { get; set; }
    public Decimal insuranceRate { get; set; }
    public Boolean isResidual { get; set; }
    public Decimal unitPrice { get; set; }

    public SelectedInsuranceItem() {
    }

    public SelectedInsuranceItem(OpportunityLineItem oli) {
      this.recordId = oli.Id;
      this.pricebookEntryId = oli.PricebookEntryId;
      this.productId = oli.Product2Id;
      this.coverage = oli.InsuranceCoverage__c;
      this.insuranceRate = oli.Insurance_Rate__c;
      this.unitPrice = oli.UnitPrice;
      this.isResidual = oli.Product2.Is_Residual_Insurance__c;
      this.type = oli.Product2.Family;
    }

    public SelectedInsuranceItem(QuoteLineItem qli) {
      this.recordId = qli.Id;
      this.pricebookEntryId = qli.PricebookEntryId;
      this.productId = qli.Product2Id;
      this.coverage = qli.InsuranceCoverage__c;
      this.insuranceRate = qli.Insurance_Rate__c;
      this.unitPrice = qli.UnitPrice;
      this.isResidual = qli.Product2.Is_Residual_Insurance__c;
      this.type = qli.Product2.Family;
    }

    public SelectedInsuranceItem(AcctSeedERP__Material__c mat) {
      this.recordId = mat.Id;
      this.pricebookEntryId = null;
      this.productId = mat.AcctSeedERP__Product__c;
      this.coverage = mat.Insurance_Coverage__c;
      this.insuranceRate = mat.Insurance_Rate__c;
      this.unitPrice = mat.GMBLASERP__Unit_Price__c;
      this.isResidual = mat.AcctSeedERP__Product__r.Is_Residual_Insurance__c;
      this.type = mat.AcctSeedERP__Product__r.Family;
    }
  }

  public class insurancePlanWrapper {
    public String groupName { get; set; }
    public String key { get; set; }
    public List<Map<String, String>> planItems { get; set; }

    public insurancePlanWrapper(String name, List<Map<String, String>> items) {
      this.key = LGND_Utilities.generateRandomString(8);
      this.groupName = name;
      this.planItems = items;
    }
  }

  @AuraEnabled
  public static String insurance_init(String recordId) {
    return JSON.serialize(new InsuranceInitWrapper(recordId));
  }

  @AuraEnabled
  public static String fetchInsurancePlanOptions(String planId, String pricebookId) {
    if (planId == null || planId == '')
      return null;
    Map<String, List<Map<String, String>>> items = groupedPlanOptions(planId, pricebookId);
    List<insurancePlanWrapper> result = new List<insurancePlanWrapper>();
    for (String groupName : items.keySet()) {
      result.add(new insurancePlanWrapper(groupName, items.get(groupName)));
    }
    return JSON.serialize(result);
  }

  @AuraEnabled
  public static void saveInsuranceItems(String parentRecordId, String items, List<String> deleteRecordIds) {
    System.debug('AHOY');
    System.debug(items);
    String objType = objType(parentRecordId);
    switch on objType {
      when 'Opportunity' {
        handleSaveInsuranceItem_OLI(parentRecordId, items, deleteRecordIds);
      }
      when 'Quote' {
        handleSaveInsuranceItem_QLI(parentRecordId, items, deleteRecordIds);
      }
      when 'AcctSeed__Project__c' {
        handleSaveInsuranceItem_Material(parentRecordId, items, deleteRecordIds);
      }
    }
  }

  private static void handleSaveInsuranceItem_OLI(String parentRecordId, String items, List<String> deleteRecordIds) {
    List<SelectedInsuranceItem> saveItems = (List<SelectedInsuranceItem>) JSON.deserialize(
      items,
      List<SelectedInsuranceItem>.class
    );
    List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
    for (SelectedInsuranceItem i : saveItems) {
      olis.add(
        new OpportunityLineItem(
          Id = i.recordId,
          OpportunityId = parentRecordId,
          Insurance_Rate__c = i.insuranceRate,
          InsuranceCoverage__c = i.coverage,
          PricebookEntryId = i.pricebookEntryId,
          UnitPrice = i.unitPrice,
          Quantity = 1
        )
      );
    }
    upsert olis;
    if (deleteRecordIds.size() > 0)
      delete [SELECT Id FROM OpportunityLineItem WHERE Id IN :deleteRecordIds];
  }

  private static void handleSaveInsuranceItem_QLI(String parentRecordId, String items, List<String> deleteRecordIds) {
    List<SelectedInsuranceItem> saveItems = (List<SelectedInsuranceItem>) JSON.deserialize(
      items,
      List<SelectedInsuranceItem>.class
    );
    List<QuoteLineItem> qlis = new List<QuoteLineItem>();
    for (SelectedInsuranceItem i : saveItems) {
      qlis.add(
        new QuoteLineItem(
          Id = i.recordId,
          QuoteId = parentRecordId,
          Insurance_Rate__c = i.insuranceRate,
          InsuranceCoverage__c = i.coverage,
          PricebookEntryId = i.pricebookEntryId,
          UnitPrice = i.unitPrice,
          Quantity = 1
        )
      );
    }
    upsert qlis;
    if (deleteRecordIds.size() > 0)
      delete [SELECT Id FROM OpportunityLineItem WHERE Id IN :deleteRecordIds];
  }

  private static void handleSaveInsuranceItem_Material(
    String parentRecordId,
    String items,
    List<String> deleteRecordIds
  ) {
    List<SelectedInsuranceItem> saveItems = (List<SelectedInsuranceItem>) JSON.deserialize(
      items,
      List<SelectedInsuranceItem>.class
    );
    AcctSeedERP__Material__c[] mats = new List<AcctSeedERP__Material__c>();
    AcctSeed__Project_Task__c task;
    try {
      task = [
        SELECT Id
        FROM AcctSeed__Project_Task__c
        WHERE AcctSeed__Project__c = :parentRecordId AND Name LIKE '%Business Office%'
        LIMIT 1
      ];
    } catch (Exception e) {
      task = new AcctSeed__Project_Task__c(
        Name = 'Business Office',
        DisplayOnCustomerInvoice__c = true,
        IsInsurance__c = true,
        AcctSeed__Project__c = parentRecordId
      );
      insert task;
    }
    for (SelectedInsuranceItem i : saveItems) {
      mats.add(
        new AcctSeedERP__Material__c(
          Id = i.recordId,
          AcctSeedERP__Project_Task__c = task.Id,
          AcctSeedERP__Product__c = i.productId,
          AcctSeedERP__Project__c = parentRecordId,
          Insurance_Rate__c = i.insuranceRate,
          Insurance_Coverage__c = i.coverage,
          GMBLASERP__Unit_Price__c = i.unitPrice,
          GMBLASERP__Price_Override__c = true,
          AcctSeedERP__Quantity_per_Unit__c = 1
        )
      );
    }
    upsert mats;
    if (deleteRecordIds.size() > 0)
      delete [SELECT Id FROM AcctSeedERP__Material__c WHERE Id IN :deleteRecordIds];
  }

  private static Map<String, List<Map<String, String>>> groupedPlanOptions(String planId, String pbId) {
    System.debug('Enter in group plan optionnn');
    Map<Id, PricebookEntry> planItems = fetchPlanItems(planId, pbId);
    Map<String, List<Map<String, String>>> planOptionsMap = new Map<String, List<Map<String, String>>>();
    for (PricebookEntry pItem : planItems.values()) {
      if (!planOptionsMap.containsKey(pItem.Product2.Family)) {
        planOptionsMap.put(pItem.Product2.Family, new List<Map<String, String>>());
      }
      Map<String, String> item = new Map<String, String>();
      item.put('Id', pItem.Product2Id);
      item.put('Name', pItem.Product2.Name);
      item.put('PricebookEntryId', pItem.Id);
      item.put('isResidual', String.valueOf(pItem.Product2.Is_Residual_Insurance__c));
      item.put('Family', pItem.Product2.Family);
      planOptionsMap.get(pItem.Product2.Family).add(item);
    }

    return planOptionsMap;
  }

  private static Map<Id, PricebookEntry> fetchPlanItems(String planId, String pbId) {
    System.debug(planId + ':' + pbId);
    return new Map<Id, PricebookEntry>(
      [
        SELECT Id, Product2.Name, Product2.Is_Residual_Insurance__c, Product2Id, Product2.Family
        FROM PricebookEntry
        WHERE Pricebook2Id = :pbId AND Product2.InsurancePlan__c = :planId
      ]
    );
  }

  /* ===== INSURANCE METHODS ===== */

  /* +++++ INSURANCE ITEMS METHODS +++++ */

  @AuraEnabled
  public static String fetchInsurancePlanItem(String productId, String taxZoneId) {
    //PricebookEntry pbe = [SELECT Id, Product2Id
    //                      FROM PricebookEntry
    //                      WHERE Id = :pricebookEntryId];

    System.debug('productId: ' + productId);
    System.debug('taxZoneId: ' + taxZoneId);

    Product2 item = [
      SELECT
        Id,
        Name,
        Family,
        (
          SELECT
            Id,
            Single__c,
            Joint__c,
            Joint_Factored_Result__c,
            Lower_Term__c,
            Upper_Term__c,
            Lower_Finance_Term__c,
            Upper_Finance_Term__c
          FROM Insurance_Rates__r
          WHERE Tax_Zone__c = :taxZoneId
        )
      FROM Product2
      WHERE Id = :productId
    ];

    System.debug(item);

    return JSON.serialize(item);
  }

  /* ===== INSURANCE ITEMS METHODS =====*/

  /* +++++ SERVICE AND WARRANTY +++++ */

  public class WarrantyAndServiceInitWrapper {
    public CPQ_Lib_dh.OptionWrapper[] warranty { get; set; }
    public CPQ_Lib_dh.OptionWrapper[] service { get; set; }
    public Set<Id> selectedLineIds { get; set; }

    public WarrantyAndServiceInitWrapper() {
      this.warranty = new List<CPQ_Lib_dh.OptionWrapper>();
      this.service = new List<CPQ_Lib_dh.OptionWrapper>();
      this.selectedLineIds = new Set<Id>();
    }
  }

  @AuraEnabled
  public static String initServiceAndWarranty(String recordId, String pbId) {
    String objType = objType(recordId);
    switch on objType {
      when 'Opportunity' {
        return initSW_Opp(recordId, pbId);
      }
      when 'Quote' {
        return initSW_Quote(recordId, pbId);
      }
      when 'AcctSeed__Project__c' {
        return initSW_Erp(recordId, pbId);
      }
      when else {
        return null;
      }
    }
  }

  @AuraEnabled
  public static void saveWarrantyAndServiceLines(String recordId, String items, List<String> lineIdsToDelete) {
    CPQ_Lib_dh.OptionWrapper[] itemsList = (List<CPQ_Lib_dh.OptionWrapper>) JSON.deserialize(
      items,
      List<CPQ_Lib_dh.OptionWrapper>.class
    );
    String objType = objType(recordId);
    switch on objType {
      when 'Opportunity' {
        handleWarrantyAndServiceSave_forOpp(itemsList, recordId, lineIdsToDelete);
      }
      when 'Quote' {
        handleWarrantyAndServiceSave_forQuote(itemsList, recordId, lineIdsToDelete);
      }
      when 'AcctSeed__Project__c' {
        handleWarrantyAndServiceSave_forERP(itemsList, recordId, lineIdsToDelete);
      }
    }
  }

  private static void handleWarrantyAndServiceSave_forOpp(
    CPQ_Lib_dh.OptionWrapper[] itemsList,
    String recordId,
    List<String> lineIdsToDelete
  ) {
    OpportunityLineItem[] olis = new List<OpportunityLineItem>();
    for (CPQ_Lib_dh.OptionWrapper item : itemsList) {
      System.debug(item);
      OpportunityLineItem oli = new OpportunityLineItem(
        Id = item.lineId,
        PricebookEntryId = item.pricebookEntryId,
        ParentProductId__c = item.parentProductId,
        UnitPrice = item.unitCost,
        Quantity = item.quantitySelected,
        OpportunityId = recordId,
        Description = item.productName,
        BoatBuilderItem__c = true
      );
      if (item.isPrepaid != null)
        oli.isPrepaid__c = item.isPrepaid;
      olis.add(oli);
    }
    upsert olis;

    if (lineIdsToDelete.size() > 0) {
      OpportunityLineItem[] olis2Delete = [SELECT Id FROM OpportunityLineItem WHERE Id IN :lineIdsToDelete];
      delete olis2Delete;
    }
  }

  private static void handleWarrantyAndServiceSave_forQuote(
    CPQ_Lib_dh.OptionWrapper[] itemsList,
    String recordId,
    List<String> lineIdsToDelete
  ) {
    QuoteLineItem[] qlis = new List<QuoteLineItem>();
    for (CPQ_Lib_dh.OptionWrapper item : itemsList) {
      System.debug(item);
      QuoteLineItem qli = new QuoteLineItem(
        Id = item.lineId,
        PricebookEntryId = item.pricebookEntryId,
        ParentProductId__c = item.parentProductId,
        UnitPrice = item.unitCost,
        Quantity = item.quantitySelected,
        QuoteId = recordId,
        Description = item.productName,
        BoatBuilderItem__c = true
      );
      if (item.isPrepaid != null)
        qli.isPrepaid__c = item.isPrepaid;
      qlis.add(qli);
    }
    upsert qlis;

    if (lineIdsToDelete.size() > 0) {
      QuoteLineItem[] qlis2Delete = [SELECT Id FROM QuoteLineItem WHERE Id IN :lineIdsToDelete];
      delete qlis2Delete;
    }
  }

  private static void handleWarrantyAndServiceSave_forERP(
    CPQ_Lib_dh.OptionWrapper[] itemsList,
    String recordId,
    List<String> lineIdsToDelete
  ) {
    AcctSeedERP__Material__c[] mats = new List<AcctSeedERP__Material__c>();
    AcctSeed__Project_Task__c task;
    try {
      task = [
        SELECT Id
        FROM AcctSeed__Project_Task__c
        WHERE AcctSeed__Project__c = :recordId AND Name LIKE '%Business Office%'
        LIMIT 1
      ];
    } catch (Exception e) {
      task = new AcctSeed__Project_Task__c(
        Name = 'Business Office',
        DisplayOnCustomerInvoice__c = true,
        AcctSeed__Project__c = recordId
      );
      insert task;
    }
    System.debug('***** TASK ***** ' + task);
    for (CPQ_Lib_dh.OptionWrapper item : itemsList) {
      System.debug(item.isPrepaid);
      AcctSeedERP__Material__c mat = new AcctSeedERP__Material__c(
        Id = item.lineId,
        AcctSeedERP__Product__c = item.productId,
        GMBLASERP__Unit_Price__c = item.unitCost,
        AcctSeedERP__Quantity_per_Unit__c = item.quantitySelected,
        AcctSeedERP__Project__c = recordId,
        Parent_Product__c = item.parentProductId
      );
      if (item.isPrepaid != null)
        mat.isPrepaid__c = item.isPrepaid;
      if (item.lineId == null)
        mat.AcctSeedERP__Project_Task__c = task.Id;
      mats.add(mat);
    }
    upsert mats;

    if (lineIdsToDelete.size() > 0) {
      AcctSeedERP__Material__c[] mats2Delete = [SELECT Id FROM AcctSeedERP__Material__c WHERE Id IN :lineIdsToDelete];
      delete mats2Delete;
    }
  }

  private static String initSW_Opp(String recordId, String pbId) {
    WarrantyAndServiceInitWrapper result = new WarrantyAndServiceInitWrapper();
    OpportunityLineItem[] oppLineItems = [
      SELECT
        Id,
        PricebookEntryId,
        PricebookEntry.Pricebook2Id,
        PricebookEntry.Product2Id,
        ParentProductId__c,
        Quantity,
        OpportunityId,
        isPrepaid__c
      FROM OpportunityLineItem
      WHERE OpportunityId = :recordId
    ];
    if (!oppLineItems.isEmpty()) {
      Map<Id, Id> productId_lineId_map = new Map<Id, Id>();
      Map<Id, Decimal> productId_quantity_map = new Map<Id, Decimal>();
      Map<Id, Boolean> productId_prepaid_map = new Map<Id, Boolean>();
      for (OpportunityLineItem oli : oppLineItems) {
        productId_lineId_map.put(oli.PricebookEntry.Product2Id, oli.Id);
        productId_quantity_map.put(oli.PricebookEntry.Product2Id, oli.Quantity);
        productId_prepaid_map.put(oli.PricebookEntry.Product2Id, oli.isPrepaid__c);
      }
      result = buildAvailableWarrantyAndServiceItems(
        productId_lineId_map,
        productId_quantity_map,
        productId_prepaid_map,
        recordId,
        pbId
      );
    }
    return JSON.serialize(result);
  }

  private static String initSW_Quote(String recordId, String pbId) {
    WarrantyAndServiceInitWrapper result = new WarrantyAndServiceInitWrapper();
    QuoteLineItem[] quoteLineItems = [
      SELECT
        Id,
        PricebookEntryId,
        PricebookEntry.Pricebook2Id,
        PricebookEntry.Product2Id,
        ParentProductId__c,
        Quantity,
        QuoteId,
        isPrepaid__c
      FROM QuoteLineItem
      WHERE QuoteId = :recordId
    ];
    if (!quoteLineItems.isEmpty()) {
      Map<Id, Id> productId_lineId_map = new Map<Id, Id>();
      Map<Id, Decimal> productId_quantity_map = new Map<Id, Decimal>();
      Map<Id, Boolean> productId_prepaid_map = new Map<Id, Boolean>();
      for (QuoteLineItem qli : quoteLineItems) {
        productId_lineId_map.put(qli.PricebookEntry.Product2Id, qli.Id);
        productId_quantity_map.put(qli.PricebookEntry.Product2Id, qli.Quantity);
        productId_prepaid_map.put(qli.PricebookEntry.Product2Id, qli.isPrepaid__c);
      }
      result = buildAvailableWarrantyAndServiceItems(
        productId_lineId_map,
        productId_quantity_map,
        productId_prepaid_map,
        recordId,
        pbId
      );
    }
    return JSON.serialize(result);
  }

  private static String initSW_Erp(String recordId, String pbId) {
    WarrantyAndServiceInitWrapper result = new WarrantyAndServiceInitWrapper();
    AcctSeedERP__Material__c[] matItems = [
      SELECT Id, AcctSeedERP__Product__c, AcctSeedERP__Quantity_Per_Unit__c, isPrepaid__c
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__c = :recordId
    ];
    if (!matItems.isEmpty()) {
      Map<Id, Id> productId_lineId_map = new Map<Id, Id>();
      Map<Id, Decimal> productId_quantity_map = new Map<Id, Decimal>();
      Map<Id, Boolean> productId_prepaid_map = new Map<Id, Boolean>();
      for (AcctSeedERP__Material__c mat : matItems) {
        productId_lineId_map.put(mat.AcctSeedERP__Product__c, mat.Id);
        productId_quantity_map.put(mat.AcctSeedERP__Product__c, mat.AcctSeedERP__Quantity_Per_Unit__c);
        productId_prepaid_map.put(mat.AcctSeedERP__Product__c, mat.isPrepaid__c);
      }
      result = buildAvailableWarrantyAndServiceItems(
        productId_lineId_map,
        productId_quantity_map,
        productId_prepaid_map,
        recordId,
        pbId
      );
    }
    return JSON.serialize(result);
  }

  private static WarrantyAndServiceInitWrapper buildAvailableWarrantyAndServiceItems(
    Map<Id, Id> productId_lineId_map,
    Map<Id, Decimal> productId_quantity_map,
    Map<Id, Boolean> productId_prepaid_map,
    String recordId,
    String pbId
  ) {
    WarrantyAndServiceInitWrapper result = new WarrantyAndServiceInitWrapper();
    Product_Option__c[] options = [
      SELECT Id, From_Product__c, Standard__c, Maximum__c
      FROM Product_Option__c
      WHERE
        To_Product__c IN :productId_lineId_map.keySet()
        AND (From_Product__r.Family = 'Extended Warranty'
        OR From_Product__r.RecordType.Name = 'Protection and Services'
        OR From_Product__r.RecordType.Name = 'Package Bundle')
    ];
    System.debug(options);
    if (!options.isEmpty()) {
      Map<Id, Product_Option__c> availOptionsMap = new Map<Id, Product_Option__c>();
      for (Product_Option__c po : options) {
        availOptionsMap.put(po.From_Product__c, po);
      }

      Set<Id> allSubOptionProductIds = new Set<Id>();
      Map<Id, Product_Option__c> allSubOptions = new Map<Id, Product_Option__c>();
      Map<Id, Set<Id>> parentProductId_childProductIds_Map = new Map<Id, Set<Id>>();

      for (Product_Option__c subOption : [
        SELECT Id, From_Product__c, To_Product__c, Standard__c, Maximum__c
        FROM Product_Option__c
        WHERE To_Product__c IN :availOptionsMap.keySet()
      ]) {
        allSubOptionProductIds.add(subOption.From_Product__c);
        allSubOptions.put(subOption.From_Product__c, subOption);
        if (!parentProductId_childProductIds_Map.containsKey(subOption.To_Product__c))
          parentProductId_childProductIds_Map.put(subOption.To_Product__c, new Set<Id>());
        parentProductId_childProductIds_Map.get(subOption.To_Product__c).add(subOption.From_Product__c);
      }

      Map<Id, PricebookEntry> subOption_pbe_map = new Map<Id, PricebookEntry>();
      for (PricebookEntry pbe : [
        SELECT
          Id,
          Product2Id,
          Product2.Name,
          UnitPrice,
          Product2.Family,
          Product2.RecordType.Name,
          Product2.isPrepayable__c
        FROM PricebookEntry
        WHERE Pricebook2Id = :pbId AND Product2Id IN :allSubOptions.keySet()
      ]) {
        subOption_pbe_map.put(pbe.Product2Id, pbe);
      }

      PricebookEntry[] pbItems = [
        SELECT
          Id,
          Product2Id,
          Product2.Name,
          UnitPrice,
          Product2.Family,
          Product2.RecordType.Name,
          Product2.isPrepayable__c
        FROM PricebookEntry
        WHERE Pricebook2Id = :pbId AND Product2Id IN :availOptionsMap.keySet()
      ];

      for (PricebookEntry pbe : pbItems) {
        Product_Option__c opt = availOptionsMap.get(pbe.Product2Id);
        CPQ_Lib_dh.OptionWrapper wsItem = new CPQ_Lib_dh.OptionWrapper(pbe, opt.Standard__c, opt.Maximum__c);
        System.debug('WSITEM = ' + wsItem);
        if (productId_lineId_map.containsKey(pbe.Product2Id)) {
          wsItem.lineId = productId_lineId_map.get(pbe.Product2Id);
          wsItem.quantitySelected = productId_quantity_map.get(pbe.Product2Id);
          wsItem.isSelected = true;
          if (productId_prepaid_map != null) {
            wsItem.isPrepaid = productId_prepaid_map.get(pbe.Product2Id);
          }
          result.selectedLineIds.add(wsItem.lineId);
          if (parentProductId_childProductIds_Map.containsKey(pbe.Product2Id)) {
            for (Id subOptionProductId : parentProductId_childProductIds_Map.get(pbe.Product2Id)) {
              if (subOption_pbe_map.containsKey(subOptionProductId)) {
                CPQ_Lib_dh.OptionWrapper subItem = new CPQ_Lib_dh.OptionWrapper(
                  subOption_pbe_map.get(subOptionProductId),
                  allSubOptions.get(subOptionProductId).Standard__c,
                  allSubOptions.get(subOptionProductId).Maximum__c
                );
                subItem.parentProductId = pbe.Product2Id;
                if (productId_lineId_map.containsKey(subItem.productId)) {
                  subItem.isSelected = true;
                  subItem.quantitySelected = productId_quantity_map.get(subItem.productId);
                  if (productId_prepaid_map != null) {
                    subItem.isPrepaid = productId_prepaid_map.get(pbe.Product2Id);
                  }
                  subItem.lineId = productId_lineId_map.get(subItem.productId);
                  result.selectedLineIds.add(subItem.lineId);
                }
                wsItem.subOptions.add(subItem);
              }
            }
          }
        }
        if (pbe.Product2.Family == 'Extended Warranty')
          result.warranty.add(wsItem);
        else if (
          pbe.Product2.RecordType.Name == 'Protection and Services' ||
          pbe.Product2.RecordType.Name == 'Package Bundle'
        )
          result.service.add(wsItem);
      }
    }
    return result;
  }

  private static WarrantyAndServiceInitWrapper buildAvailableWarrantyAndServiceItems(
    Map<Id, Id> productId_lineId_map,
    Map<Id, Decimal> productId_quantity_map,
    String recordId,
    String pbId
  ) {
    return buildAvailableWarrantyAndServiceItems(productId_lineId_map, productId_quantity_map, null, recordId, pbId);
  }

  /* ===== SERVICE AND WARRANTY ===== */

  /*
  @params
    items = Map<String, String> {
      'isResidual' = 'true/false',
      'insuranceRate' = 'insurance factor',
      'recordId' = 'id of lineItem either OpportunityLineItem or AcctSeedERP__Material__c'
    }
  returns
    Map<String, Decimal> {
      'idOfRecord': New Unit Cost fo line item
    }
  */
  public static Map<String, Decimal> calculateInsurancePremiums(
    List<Map<String, String>> items,
    Decimal amount,
    Decimal deposit,
    Decimal term,
    Decimal amort,
    Decimal intrestRate,
    Decimal insuranceTaxRate
  ) {
    return calculateInsurancePremiums(items, amount, deposit, term, amort, intrestRate, insuranceTaxRate, null);
  }

  public static Map<String, Decimal> calculateInsurancePremiums_withTaxZoneId(
    List<Map<String, String>> items,
    Decimal amount,
    Decimal deposit,
    Decimal term,
    Decimal amort,
    Decimal intrestRate,
    Decimal insuranceTaxRate,
    Id taxZone
  ) {
    String taxZoneName = [SELECT Name FROM AcctSeed__Accounting_Variable__c WHERE Id = :taxZone].Name;
    return calculateInsurancePremiums(items, amount, deposit, term, amort, intrestRate, insuranceTaxRate, taxZoneName);
  }

  public static Map<String, Decimal> calculateInsurancePremiums(
    List<Map<String, String>> items,
    Decimal amount,
    Decimal deposit,
    Decimal term,
    Decimal amort,
    Decimal intrestRate,
    Decimal insuranceTaxRate,
    String taxZone
  ) {
    if (taxZone == 'Quebec') {
      if (intrestRate == 0) {
        items = calculateUsingSimple_NoIntrest(items, amount, deposit, term, amort);
      } else {
        items = calculateUsingSimple(items, amount, deposit, amort, intrestRate);
      }
    } else {
      if (intrestRate == 0) {
        items = calculateUsingRecursive_NoIntrest(items, amount, deposit, term, amort, insuranceTaxRate);
      } else {
        items = calculateUsingRecursive(items, amount, deposit, term, amort, intrestRate, insuranceTaxRate);
      }
    }

    Map<String, Decimal> result = new Map<String, Decimal>();
    for (Map<String, String> i : items) {
      result.put(i.get('recordId'), Decimal.valueOf(i.get('unitCost')));
    }
    return result;
  }

  private static List<Map<String, String>> calculateUsingSimple_NoIntrest(
    List<Map<String, String>> items,
    Decimal amount,
    Decimal deposit,
    Decimal term,
    Decimal amort
  ) {
    Decimal paymt = ((amount - deposit) / amort).setScale(2, RoundingMode.HALF_UP);
    String feeApplicableType = determineFeeApplicableType(items);
    for (Map<String, String> item : items) {
      Decimal insRate = Decimal.valueOf(item.get('insuranceRate'));
      Decimal unitPrice = paymt * insRate;
      if (feeApplicableType != null && item.get('productFamily') == feeApplicableType)
        unitPrice += 50;
      else if (feeApplicableType == null && item.get('productFamily') == 'Life Insurance Coverage')
        unitPrice += 50;

      item.put('unitCost', String.valueOf(unitPrice.setScale(2, RoundingMode.HALF_UP)));
    }
    return items;
  }

  private static List<Map<String, String>> calculateUsingSimple(
    List<Map<String, String>> items,
    Decimal amount,
    Decimal deposit,
    Decimal amort,
    Decimal intrestRate
  ) {
    Decimal calcAmount = amount - deposit;
    Decimal ir = intrestRate / 100;
    Decimal v = 12 / (12 + ir);
    Decimal ann = (1 - Math.pow(Double.valueOf(v), Double.valueOf(amort))) / (ir / 12);
    Decimal paymt = (calcAmount / ann).setScale(2, RoundingMode.HALF_UP);
    String feeApplicableType = determineFeeApplicableType(items);
    for (Map<String, String> item : items) {
      Decimal insRate = Decimal.valueOf(item.get('insuranceRate'));
      Decimal unitPrice = paymt * insRate;
      if (feeApplicableType != null && item.get('productFamily') == feeApplicableType)
        unitPrice += 50;
      else if (feeApplicableType == null && item.get('productFamily') == 'Life Insurance Coverage')
        unitPrice += 50;

      item.put('unitCost', String.valueOf(unitPrice.setScale(2, RoundingMode.HALF_UP)));
    }
    return items;
  }

  private static List<Map<String, String>> calculateUsingRecursive_NoIntrest(
    List<Map<String, String>> items,
    Decimal amount,
    Decimal deposit,
    Decimal term,
    Decimal amort,
    Decimal insuranceTaxRate
  ) {
    Decimal calcAmount = amount - deposit;
    Decimal paymt = (calcAmount / amort).setScale(2, RoundingMode.HALF_UP);
    Decimal res;
    Decimal newAmount = calcAmount;
    Decimal origPaymnt;
    Boolean calcDone = false;

    while (!calcDone) {
      res = (newAmount - (paymt * term));
      newAmount = calcAmount;
      origPaymnt = paymt;
      for (Map<String, String> item : items) {
        Decimal cost;
        Decimal insuranceFactor = Decimal.valueOf(item.get('insuranceRate'));
        if (item.get('isResidual') == 'true') {
          cost = (res * insuranceFactor / 100);
          item.put('unitCost', String.valueOf(cost.setScale(2, RoundingMode.HALF_UP)));
        } else {
          cost = (paymt * term * insuranceFactor / 100);
          item.put('unitCost', String.valueOf(cost.setScale(2, RoundingMode.HALF_UP)));
        }
        newAmount += (cost * (1 + (insuranceTaxRate / 100)));
      }

      paymt = (newAmount / amort).setScale(2, RoundingMode.HALF_UP);
      if (paymt == origPaymnt)
        calcDone = true;
    }
    return items;
  }

  private static List<Map<String, String>> calculateUsingRecursive(
    List<Map<String, String>> items,
    Decimal amount,
    Decimal deposit,
    Decimal term,
    Decimal amort,
    Decimal intrestRate,
    Decimal insuranceTaxRate
  ) {
    Decimal calcAmount = amount - deposit;
    Decimal ir = intrestRate / 100;
    Decimal v = 12 / (12 + ir);
    Decimal ann = (1 - Math.pow(Double.valueOf(v), Double.valueOf(amort))) / (ir / 12);
    Decimal paymt = (calcAmount / ann).setScale(2, RoundingMode.HALF_UP);
    Decimal acc = (1 - Math.pow(Double.valueOf(v), Double.valueOf((amort - term)))) / (ir / 12);
    Decimal res;
    Decimal newAmount;
    Decimal origPaymnt;
    Boolean calcDone = false;

    while (!calcDone) {
      res = (paymt * acc).setScale(2, RoundingMode.HALF_UP);
      newAmount = calcAmount;
      origPaymnt = paymt;
      for (Map<String, String> item : items) {
        Decimal cost;
        Decimal insuranceFactor = Decimal.valueOf(item.get('insuranceRate'));
        if (item.get('isResidual') == 'true') {
          cost = (res * insuranceFactor / 100).setScale(2, RoundingMode.HALF_UP);
          item.put('unitCost', String.valueOf(cost));
        } else {
          cost = (paymt * term * insuranceFactor / 100).setScale(2, RoundingMode.HALF_UP);
          item.put('unitCost', String.valueOf(cost));
        }
        newAmount += (cost * (1 + (insuranceTaxRate / 100)));
      }

      paymt = (newAmount / ann).setScale(2, RoundingMode.HALF_UP);
      if (paymt == origPaymnt)
        calcDone = true;
    }
    return items;
  }

  private static String determineFeeApplicableType(List<Map<String, String>> items) {
    Boolean hasLife = false;
    Boolean hasIllness = false;
    Boolean hasDisability = false;

    for (Map<String, String> item : items) {
      if (item.get('productFamily') == 'Life Insurance Coverage')
        hasLife = true;
      if (item.get('productFamily') == 'Critical Illness Coverage')
        hasIllness = true;
      if (item.get('productFamily') == 'Disability Insurance Coverage')
        hasDisability = true;
    }
    if (hasDisability)
      return 'Disability Insurance Coverage';
    if (hasLife)
      return 'Life Insurance Coverage';
    if (hasIllness)
      return 'Critical Illness Coverage';
    return null;
  }

  private static Decimal calcJointFactor(Decimal unitPrice, String insuranceType) {
    if (insuranceType == 'Life Insurance Coverage')
      return unitPrice * 1.8;
    if (insuranceType == 'Critical Illness Coverage')
      return unitPrice * 1.8;
    if (insuranceType == 'Disability Insurance Coverage')
      return unitPrice * 2.0;
    return unitPrice;
  }

  private static String objType(Id recordId) {
    return LGND_Utilities.sObjectNameFromId(recordId);
  }
}
