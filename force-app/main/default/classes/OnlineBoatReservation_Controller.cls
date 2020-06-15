/**
 * Created by dave on 2020-04-23.
 */

public without sharing class OnlineBoatReservation_Controller
{

  public virtual class AccountSaveResult
  {
    @AuraEnabled public Account record;
    @AuraEnabled public String opportunityId;
    @AuraEnabled public String status;
    @AuraEnabled public String[] messages;
    @AuraEnabled public List<SObject> duplicateRecords;

    public AccountSaveResult(){}

    public void addDuplicate( SObject dup )
    {
      if( this.duplicateRecords == null )
        this.duplicateRecords = new List<SObject>();
      this.duplicateRecords.add( dup );
    }

    public void addMessage( String msg )
    {
      if( this.messages == null )
        this.messages = new List<String>();
      this.messages.add( msg );
    }

  }

  public virtual class Customer
  {
    public String id;
    public String firstName;
    public String lastName;
    public String email;
    public String phone;
    public String state;

    private Account acct;
    private Lead lead;
    private String[] errors;

    public Customer(){}

    public AccountSaveResult upsertToAccount()
    {
      if( isValid() )
      {
        this.buildAccount();
        return handleAccountUpsert();
      }
      else
      {
        AccountSaveResult result = new AccountSaveResult();
        result.status = 'error';
        result.messages = this.errors;
        return result;
      }
    }

    private Boolean isValid()
    {
      String[] errs = new List<String>();
      if( this.firstName == null )
        errs.add( 'First Name is required' );
      if( this.lastName == null )
        errs.add( 'Last Name is required' );
      if( this.email == null )
        errs.add( 'Email is required' );
      if( this.phone == null )
        errs.add( 'Phone number is required' );
      if( this.state == null )
        errs.add( 'Province is required' );
      if( errs.size() > 0 )
      {
        this.errors = errs;
        return false;
      }
      return true;
    }

    private void buildAccount()
    {

      if( this.acct == null )
        this.acct = new Account( RecordTypeId = LGND_Utilities.recordTypeIdFromName( 'Account', 'Person Account' ) );
      this.acct.Id = this.id;
      this.acct.FirstName = this.firstName;
      this.acct.LastName = this.lastName;
      this.acct.PersonEmail = this.email;
      this.acct.Phone = this.phone;
      this.acct.BillingState = this.state;
    }

    private AccountSaveResult handleAccountUpsert()
    {
      if( this.acct.Id != null || !hasLead() )
      {
        return doAccountSave();
      }
      return convertLead();
    }

    private AccountSaveResult doAccountSave()
    {
      Database.UpsertResult saveResult =
        Database.upsert(
          this.acct,
          Account.Fields.Id,
          false
        );

      if (saveResult.isSuccess())
      {
        return handleSaveSuccess();
      }
      else
      {
        return handleErrors(saveResult.getErrors());
      }
    }

    private Boolean hasLead()
    {
      if( this.lead != null ) return true;
      List<Lead> leads =
        Lead_Selector.allNonConvertedByEmail( this.acct.PersonEmail );
      if( leads.size() == 0 )
        return false;
      else
      {
        this.lead = leads[0];
        return true;
      }
    }

    private Boolean leadSynced()
    {
      if( this.firstName != this.lead.FirstName ) return false;
      if( this.lastName != this.lead.LastName ) return false;
      if( this.email != this.lead.Email ) return false;
      if( this.phone != this.lead.Phone ) return false;
      if( this.lead.Company != null ) return false;
      return true;
    }

    private Account updateAccountDetails()
    {
      update this.acct;
      return this.acct;
    }

    private String buildOppName()
    {
      Datetime today = Datetime.now();
      String nameString = this.firstName + ' ' + this.lastName + ' - ';
      nameString += today.format('yyyy.MM.dd-HHmm');
      return nameString;
    }

    private AccountSaveResult convertLead()
    {
      if( !leadSynced() )
      {
        this.lead.FirstName = this.firstName;
        this.lead.LastName = this.lastName;
        this.lead.Email = this.email;
        this.lead.Phone = this.phone;
        this.lead.Company = null;
        update this.lead;
      }

      Database.LeadConvert lc = new Database.LeadConvert();
      lc.setLeadId( this.lead.Id );
      LeadStatus convertStatus = [ SELECT Id, ApiName FROM LeadStatus WHERE IsConverted = true LIMIT 1];
      lc.setConvertedStatus( convertStatus.ApiName );
      lc.setOpportunityName( buildOppName() );
      lc.setOwnerId( UserInfo.getUserId() );
      //lc.setDoNotCreateOpportunity( true );
      if( this.acct != null && this.acct.Id != null )
      {
        lc.setAccountId( this.acct.Id );
      }
      try
      {
        Database.LeadConvertResult leadConvertResult =
          Database.convertLead( lc );
        if( leadConvertResult.isSuccess() )
        {
          this.acct.Id = leadConvertResult.getAccountId();
          AccountSaveResult result = new AccountSaveResult();
          result.status = 'success';
          result.opportunityId = upsertOpportunity( leadConvertResult.getOpportunityId() ).Id;
          result.record = updateAccountDetails();
          return result;
        }
        else
        {
          return handleErrors( leadConvertResult.getErrors() );
        }
      }
      catch( Exception e )
      {
        if( e.getMessage().contains('DUPLICATES_DETECTED') )
        {
          AccountSaveResult result = doAccountSave();
          return result;
        }
        AccountSaveResult result = new AccountSaveResult();
        result.status = 'error';
        result.addMessage( e.getMessage() );
        return result;
      }

    }

    private AccountSaveResult forceAccountSave()
    {
      Database.DMLOptions dml = new Database.DMLOptions();
      dml.DuplicateRuleHeader.allowSave = true;
      dml.DuplicateRuleHeader.runAsCurrentUser = true;
      Database.SaveResult saveResult = Database.insert( this.acct, dml );
      if( saveResult.isSuccess() )
      {
        if( this.lead != null )
          return convertLead();
        return handleSaveSuccess();
      }
      else
      {
        return handleErrors( saveResult.getErrors() );
      }
    }

    private AccountSaveResult handleSaveSuccess()
    {
      AccountSaveResult result = new AccountSaveResult();
      result.record = this.acct;
      result.status = 'success';
      result.opportunityId = upsertOpportunity(null).Id;
      return result;
    }

    private AccountSaveResult handleErrors( List<Database.Error> errors )
    {
      AccountSaveResult result = new AccountSaveResult();
      result.status = 'error';
      for( Database.Error error : errors )
      {
        result.addMessage( error.getMessage() );
        if( error instanceof Database.DuplicateError )
        {
          /* The Error */
          Database.DuplicateError duplicateError = (Database.DuplicateError) error;
          Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();

          /* Matched Records */
          Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
          Datacloud.MatchResult matchResult = matchResults[0];
          Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();

          for (Datacloud.MatchRecord matchRecord : matchRecords)
          {
            result.addDuplicate( matchRecord.getRecord() );
          }
        }
      }
      if( result.duplicateRecords != null )
      {
        if( result.duplicateRecords.size() == 1 )
          this.acct.Id = (Id)result.duplicateRecords[0].get('Id');

        if( result.duplicateRecords.size() > 1 )
        {
          for( SObject dup : result.duplicateRecords)
          {
            if( dup.get('Name') == this.firstName + ' ' + this.lastName )
            {
              this.acct.Id = (Id)dup.get('Id');
              break;
            }
          }
        }
        return this.acct.Id == null ?
          forceAccountSave() :
          this.hasLead() ? convertLead() : doAccountSave();
      }
      return result;
    }

    private Opportunity upsertOpportunity( Id oppId )
    {
      Opportunity opp = new Opportunity(
        Id = oppId,
        AccountId = this.acct.Id,
        Name = buildOppName(),
        StageName = 'Quoting',
        CloseDate = Date.today().addMonths( 1 )
      );
      upsert opp;
      return opp;
    }
  }

  @AuraEnabled(Cacheable=true)
  public static List<Map<String, String>> fetchBoats()
  {
    List<Map<String, String>> boats = new List<Map<String, String>>();
    for( Product2 p : Product_Selector.allBoatsAvailableForOnlineSale() )
    {
      Map<String, String> b = new Map<String, String>();
      b.put( 'id', p.Id );
      b.put( 'name', p.Name );
      b.put( 'imageURL', p.Default_Gallery_Image_Original__c );
      boats.add( b );
    }
    return boats;
  }

  @AuraEnabled(Cacheable=true)
  public static OnlineBoat fetchBoat( String boatId )
  {

    OnlineBoat b = new OnlineBoat(
      Product_Selector.getOnlineBoat( boatId )
    );
    return b;
  }

  @AuraEnabled
  public static AccountSaveResult createAccount( String customerJSON )
  {
    Customer cust = (Customer)JSON.deserialize( customerJSON, Customer.class );
    return cust.upsertToAccount();
  }

  @AuraEnabled
  public static void saveLineItems( String oppJSON, String olisJSON )
  {
    Opportunity opp =
      (Opportunity)JSON.deserialize( oppJSON, Opportunity.class );
    List<OpportunityLineItem> olis =
      (List<OpportunityLineItem>)JSON.deserialize( olisJSON, List<OpportunityLineItem>.class );
    System.debug( olis );
    update opp;
    for( OpportunityLineItem oli : olis )
    {
      oli.OpportunityId = opp.Id;
      oli.BoatBuilderItem__c = true;
    }
    insert olis;
  }


}
