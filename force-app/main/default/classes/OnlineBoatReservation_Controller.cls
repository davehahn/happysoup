/**
 * Created by dave on 2020-04-23.
 */

public with sharing class OnlineBoatReservation_Controller
{

  public virtual class AccountSaveResult
  {
    @AuraEnabled public Account record;
    @AuraEnabled public String status;
    @AuraEnabled public String[] messages;
    @AuraEnabled public List<SObject> duplicateRecords;

    public AccountSaveResult(){}

    public Boolean isSuccess()
    {
      return this.status == 'success';
    }

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

    private Account acct;
    private Lead lead;

    public Customer(){}

    public AccountSaveResult upsertToAccount()
    {
      this.buildAccount();
      return handleAccountUpsert();
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
    }

    private AccountSaveResult handleAccountUpsert()
    {
      if( this.acct.Id != null || !hasLead() )
      {
        return doAccountSave();
      }
      return convertLead();
    }

    private Boolean hasLead()
    {
      List<Lead> leads =
        Lead_Selector.allNonConvertedByEmail( this.acct.PersonEmail );
      if( leads.size() == 0 )
        return false;
      else
      {
        if( leads.size() == 1 )
        {
          this.lead = leads[0];
          return true;
        }
        else
        {
          // figure out what to do here not this
          this.lead = leads[0];
          return true;
        }
      }
    }

    private AccountSaveResult convertLead()
    {
      this.lead.FirstName = this.firstName;
      this.lead.LastName = this.lastName;
      this.lead.Email = this.email;
      this.lead.Phone = this.phone;
      this.lead.Company = null;
      update this.lead;

      Database.LeadConvert lc = new Database.LeadConvert();
      lc.setLeadId( this.lead.Id );
      LeadStatus convertStatus = [ SELECT Id, ApiName FROM LeadStatus WHERE IsConverted = true LIMIT 1];
      lc.setConvertedStatus( convertStatus.ApiName );
      lc.setDoNotCreateOpportunity( true );
      try
      {
        Database.LeadConvertResult leadConvertResult =
          Database.convertLead( lc );
        if( leadConvertResult.isSuccess() )
        {
          AccountSaveResult result = new AccountSaveResult();
          result.status = 'success';
          result.record = [
            SELECT Id, FirstName, LastName, Phone, PersonEmail, RecordTypeId
            FROM Account
            WHERE Id = :leadConvertResult.getAccountId() ];
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
          Savepoint sp = Database.setSavepoint();
          AccountSaveResult result = doAccountSave();
          Database.rollback(sp);
          return result;
        }
        AccountSaveResult result = new AccountSaveResult();
        result.status = 'error';
        result.addMessage( e.getMessage() );
        return result;
      }


    }

    private AccountSaveResult doAccountSave()
    {
      Database.UpsertResult saveResult =
        Database.upsert(
          this.acct,
          Account.Fields.Id,
          false
        );

      if( saveResult.isSuccess() )
      {
        AccountSaveResult result = new AccountSaveResult();
        result.record = this.acct;
        result.status = 'success';
        return result;
      }
      else
      {
        return handleErrors( saveResult.getErrors() );
      }
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
      return result;
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


}
