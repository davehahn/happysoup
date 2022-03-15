/**
 * Created by dave on 2019-10-08.
 */

public with sharing class Registration_Helper {

  public class RegistrationWrapper {
    public String id;
    public Boolean isCurrent;
    public DateTime deliveryDate;
    public DateTime registeredDate;
    public DateTime createDate;
    public Boolean registeredToCustomer;
    public String registeredMotorId;
    public Account toAccount;
    public String serialId;
    public String serialNumber;
    public Boolean serialRegisteredWithSupplier;
    public String productName;
    public String productRecordTypeId;
    public String serialDefaultVendorId;
    public String serialDefaultVendorName;
    public String erpOrderId;
    public String erpOrderRecordTypeId;
    public String supplierRegistrationClass;

    public RegistrationWrapper(){}

    public RegistrationWrapper( Registration__c r )
    {
      setAttrs(r);
    }

    public RegistrationWrapper( Id regId )
    {
      setAttrs( Registration_Selector.allById( new Set<Id>{ regId } )[0] );
    }

    private void setAttrs( Registration__c r )
    {
      this.id = r.Id;
      this.isCurrent = r.isCurrent__c;
      this.deliveryDate = r.Delivery_Date__c;
      this.registeredDate = r.Registered_Date__c;
      this.createDate = r.CreatedDate;
      this.registeredToCustomer = r.Registered_To_Customer__c;
      this.registeredMotorId = r.Registered_Motor__c;
      this.toAccount = r.Account__r;
      this.serialId = r.SerialNumber__c;
      this.serialNumber = r.SerialNumber__r.Name;
      this.serialRegisteredWithSupplier = r.SerialNumber__r.IsRegisteredWithSupplier__c;
      this.productName = r.SerialNumber__r.GMBLASERP__Product__r.Name;
      this.productRecordTypeId = r.SerialNumber__r.GMBLASERP__Product__r.RecordTypeId;
      this.serialDefaultVendorId = r.SerialNumber__r.GMBLASERP__Product__r.AcctSeedERP__Default_Vendor__c;
      if( r.SerialNumber__r.GMBLASERP__Product__r.AcctSeedERP__Default_Vendor__c != null )
        this.serialDefaultVendorName = r.SerialNumber__r.GMBLASERP__Product__r.AcctSeedERP__Default_Vendor__r.Name;
      this.erpOrderId = r.ErpOrder__c;
      this.erpOrderRecordTypeId = r.ErpOrder__r.RecordTypeId;
      this.supplierRegistrationClass = determineApexSupplierRegistrationClass();
    }

    private String determineApexSupplierRegistrationClass()
    {
      if( this.serialDefaultVendorId == Legend_Settings__c.getOrgDefaults().Smokercraft_Account_Id__c )
      {
        return 'SupplierRegistration_SmokerCraft';
      }
      return null;
    }

  }

  public static Id registeredByAccountId
  {
    get {
      if( registeredByAccountId == null )
      {
        if( UserInfo.getUserType() == 'Standard' )
        {
          User currentUser = [SELECT Id, Warehouse__c FROM User WHERE Id = :Userinfo.getUserId() ];
          Legend_Settings__c orgDefaults = Legend_Settings__c.getOrgDefaults();
          Map<String, Id> wareHouseMap = new Map<String, Id>{
            'Whitefish' => orgDefaults.LegendWhitefishAccountId__c,
            'Barrie' => orgDefaults.LegendBarrieAccountId__c,
            'Montreal' => orgDefaults.LegendMontrealAccountId__c,
            'Wholesale' => orgDefaults.LegendWholesaleAccountId__c
          };
          if( wareHouseMap.containsKey( currentUser.wareHouse__c ) ) {
            registeredByAccountId = wareHouseMap.get( currentUser.Warehouse__c );
          }
        }
        else
        {
          Id contactId = [SELECT ContactId FROM User WHERE Id = :Userinfo.getUserId()].ContactId;
          Contact ct = [SELECT AccountId, Account.BillingState FROM Contact WHERE Id = :contactId];
          registeredByAccountId = ct.AccountId;
        }
      }
      return registeredByAccountId;
    }
    set;
  }

  public static void executeAfterInsert( Map<Id, Registration__c> newMap,
                                         Map<Id, Registration__c> oldMap )
  {
    if( !Test.isRunningTest() )
    {
      System.debug('why is this running');
      setRegistrationDateOnSerial( newMap.values(), oldMap );
      createPartnerCustomers( newMap.values() );
      new Promise( new AfterInsert_recordChanges() )
        .then( new RegisterWithSupplier() )
        .then( new UpdateSupplierRegisteredSerials() )
        .then( new NotifyRegistrationFailure() )
        .error( new AfterInsert_Error() )
        .done( new AfterInsert_Done() )
        .execute( newMap.keySet() );
    }
  }

  public static void setRegistrationDateOnSerial( List<Registration__c> listNew,
                                                  Map<Id, Registration__c> oldMap )
  {
    GMBLASERP__Serial_Number__c[] serials = new List<GMBLASERP__Serial_Number__c>();
    for( Registration__c reg : listNew )
    {
      boolean include = false;
      Registration__c oldReg;
      if( oldMap != null && oldMap.size() > 0 )
      {
        oldReg = oldMap.get( reg.Id );
      }
      if( reg.Registered_To_Customer__c )
      {
        include = true;
        if( oldReg != null && reg.Delivery_Date__c == oldReg.Delivery_Date__c )
          include = false;
      }
      if( include )
      {
        serials.add( new GMBLASERP__Serial_Number__c(
          Id = reg.SerialNumber__c,
          Retail_Registration_Date__c = reg.Delivery_Date__c
        ));
      }
    }
    if( serials.size() > 0 )
    {
      Boolean orig = gcSerialNumber.disableTrigger;
      gcSerialNumber.disableTrigger = true;
      update serials;
      gcSerialNumber.disableTrigger = orig;
    }
  }

  /*************************************************************************************
   _____   _____   _____ __      __    _______  ______   _____
  |  __ \ |  __ \ |_   _|\ \    / //\ |__   __||  ____| / ____|
  | |__) || |__) |  | |   \ \  / //  \   | |   | |__   | (___
  |  ___/ |  _  /   | |    \ \/ // /\ \  | |   |  __|   \___ \
  | |     | | \ \  _| |_    \  // ____ \ | |   | |____  ____) |
  |_|     |_|  \_\|_____|    \//_/    \_\|_|   |______||_____/
  *************************************************************************************/

  @TestVisible
  private static void createPartnerCustomers( List<Registration__c> listNew )
  {
    Map<String, Registration__c> uniqueRegMap = new Map<String, Registration__c>();
    for ( Registration__c reg : listNew )
    {
      uniqueRegMap.put( reg.RegisteredByAccount__c + '-' + reg.Account__c, reg);
    }
    Set<String> existing = new Set<String>();
    for( Partner_Customer__c pc : [ SELECT Uniqueifier__c
                                    FROM Partner_Customer__c
                                    WHERE Uniqueifier__c IN :uniqueRegMap.keySet() ] )
    {
      existing.add(pc.Uniqueifier__c);
    }
    Partner_Customer__c[] pcs = new List<Partner_Customer__c>();
    for( String key : uniqueRegMap.keySet() )
    {
      if( !existing.contains(key) )
      {
        Registration__c reg = uniqueRegMap.get( key );
        pcs.add( new Partner_Customer__c (
          Customer__c = reg.Account__c,
          Partner__c = reg.RegisteredByAccount__c,
          Uniqueifier__c = key
        ));
      }
    }
    insert pcs;
  }


  /** METHODS JUST TO FACILITATE TESTING **/

  @TestVisible
  private static void execute_AfterInsert_recordChanges( Set<Id> regIds )
  {
    new Promise( new AfterInsert_recordChanges() )
      .error( new AfterInsert_Error() )
      .done( new AfterInsert_Done() )
      .execute( regIds );
  }

  @TestVisible
  private static void execute_RegisterWithSupplier( Set<Id> regIds )
  {
    new Promise( new RegisterWithSupplier() )
      .error( new AfterInsert_Error() )
      .done( new AfterInsert_Done() )
      .execute( regIds );
  }

  @TestVisible
  private static void execute_UpdateSupplierRegisteredSerials( List<SupplierRegistration.Result> results )
  {
    new Promise( new UpdateSupplierRegisteredSerials() )
      .error( new AfterInsert_Error() )
      .done( new AfterInsert_Done() )
      .execute( results );
  }

  @TestVisible
  private static void execute_NotifyRegistrationFailure( List<SupplierRegistration.Result> results )
  {
    new Promise( new NotifyRegistrationFailure() )
      .error( new AfterInsert_Error() )
      .done( new AfterInsert_Done() )
      .execute( results );
  }


  /*************************************************************************************
   *
   *   _____   ______  ______  ______  _____   ______  _____    _____
   *  |  __ \ |  ____||  ____||  ____||  __ \ |  ____||  __ \  / ____|
   *  | |  | || |__   | |__   | |__   | |__) || |__   | |  | || (___
   *  | |  | ||  __|  |  __|  |  __|  |  _  / |  __|  | |  | | \___ \
   *  | |__| || |____ | |     | |____ | | \ \ | |____ | |__| | ____) |
   *  |_____/ |______||_|     |______||_|  \_\|______||_____/ |_____/
   *
   *************************************************************************************/

  public class AfterInsert_recordChanges implements Promise.Deferred
  {
    private Set<Id> regIds;
    public Object resolve( Object registrationIds )
    {
      this.regIds = (Set<Id>)registrationIds;
      Id pjRt = gcConstants.idRtProjectBoatSale;
      Id boatRt = LGND_Constants.productRtId_Boat;
      Set<Id> serialIds = new Set<Id>();
      Map<Id, Registration__c> erpId_Reg_map = new Map<Id, Registration__c>();
      List<Registration__c> toUpdate = new List<Registration__c>();

      for( Registration__c reg : Registration_Selector.allById( regIds  ) )
      {
        serialIds.add( reg.SerialNumber__c );
        if( reg.ERPOrder__c != null &&
          reg.ErpOrder__r.RecordTypeId == pjRt &&
          reg.Registered_Motor__c == null &&
          reg.SerialNumber__r.GMBLASERP__Product__r.RecordTypeId == boatRt )
        {
          erpId_Reg_map.put( reg.ErpOrder__c, reg );
        }
      }
      toUpdate.addAll( setNonCurrent( serialIds, regIds ) );
      toUpdate.addAll( setMotor( erpId_Reg_map ) );
      System.debug( toUpdate );
      update toUpdate;
      return regIds;
    }

    private List<Registration__c> setNonCurrent( Set<Id> serialIds, Set<Id> excludeRegIds )
    {
      System.debug( 'running setNonCurrent' );
      List<Registration__c> nonCurrents = [ SELECT Id
                                            FROM Registration__c
                                            WHERE SerialNumber__c IN :serialIds
                                            AND Id NOT IN :excludeRegIds ];
      for( Registration__c r : nonCurrents )
      {
        if( !excludeRegIds.contains( r.Id ) )
          r.isCurrent__c = false;
      }
      return nonCurrents;
    }

    private List<Registration__c> setMotor( Map<Id, Registration__c> erpId_Reg_map )
    {
      System.debug('SETMOTOR');
      System.debug(erpId_Reg_map.keySet());
      Id motorRt = LGND_Constants.productRtId_Motor;
      for( AcctSeedERP__Material__c mat : [ SELECT Id,
        AcctSeedERP__Project__c,
        AcctSeedERP__Product__c,
        GMBLASERP__Serial_Number__r.Name
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__c IN :erpId_Reg_map.keySet()
      AND AcctSeedERP__Product__r.RecordTypeId = :motorRt
      AND AcctSeedERP__Product__r.Family <> 'Kicker Motor'] )
      {
        System.debug(mat);
        if( erpId_Reg_map.containsKey( mat.AcctSeedERP__Project__c ) )
        {
          erpId_Reg_map.get( mat.AcctSeedERP__Project__c ).Registered_Motor__c = mat.AcctSeedERP__Product__c;
          erpId_Reg_map.get( mat.AcctSeedERP__Project__c ).Registered_Motor_Serial__c = mat.GMBLASERP__Serial_Number__r.Name;
        }
      }
      return erpId_Reg_map.values();
    }
  }

  public class RegisterWithSupplier implements Promise.Deferred
  {
    private Set<Id> regIds;
    public Object resolve( Object registrationIds )
    {
      this.regIds = (Set<Id>)registrationIds;
      List<RegistrationWrapper> wrappers = new List<RegistrationWrapper>();
      for( Registration__c r : Registration_Selector.allById( regIds ) )
      {
        wrappers.add(new RegistrationWrapper(r));
      }
      SupplierRegistration sReg = new SupplierRegistration( wrappers );
      return sReg.execute();
    }
  }

  public class UpdateSupplierRegisteredSerials implements Promise.Deferred
  {
    public Object resolve( Object supplierRegistrationResult )
    {
      List<GMBLASERP__Serial_Number__c> successSerials = new List<GMBLASERP__Serial_Number__c>();
      for( SupplierRegistration.Result r : (List<SupplierRegistration.Result>)supplierRegistrationResult )
      {
        if( r.status == 'success' )
        {
          successSerials.add( new GMBLASERP__Serial_Number__c(
            Id = r.wrapper.serialId,
            RegisteredWithSupplierDate__c = DateTime.now(),
            IsRegisteredWithSupplier__c = true
          ));
        }
      }
      if( successSerials.size() > 0 )
        update successSerials;
      return supplierRegistrationResult;
    }
  }

  public class NotifyRegistrationFailure implements Promise.Deferred
  {
    public Object resolve( Object supplierRegistrationResult )
    {
      String body = '';
      for( SupplierRegistration.Result r : (List<SupplierRegistration.Result>)supplierRegistrationResult )
      {
        if( r.status =='error' )
        {
          body += '<div style="margin-bottom:10px; border-bottom:3px solid #000"><p>Serial number <b>';
          body += r.wrapper.serialNumber + '</b> failed to be registered with Supplier</p>';
          body += '<br /><p style="border-bottom:1px solid #000;padding:5px 0;">Error Message:</p>';
          body += '<p>' + r.errorMessage + '</p></div>';
        }
      }
      if( body.length() > 0 )
      {
        List<String> toAddrs = new List<String>();
        try
        {
          toAddrs.add([SELECT Address FROM OrgWideEmailAddress WHERE DisplayName = 'Dealer Care' LIMIT 1].Address);
        }
        catch( Exception e )
        {
          toAddrs.add( 'dealercare@legendboats.com' );
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setHtmlBody( body );
        mail.setSubject( 'Registering Serial Number(s) with Supplier failed');
        mail.setToAddresses( toAddrs );
        if( !Test.isRunningTest() )
          Messaging.sendEmail( new List<Messaging.SingleEmailMessage>{ mail });
      }
      return supplierRegistrationResult;
    }
  }

  public class AfterInsert_Done implements Promise.Done
  {
    public AfterInsert_Done(){}

    public void done( Object input )
    {
      System.debug('AfterInsert Complete');
    }
  }

  public class AfterInsert_Error implements Promise.Error
  {
    private String errorMessage;
    public Object error( Exception e )
    {
      System.debug('AfterInsert Promise Error');
      System.debug(e.getMessage());
      System.debug( e.getStackTraceString() );
      this.errorMessage = e.getMessage();
      return e;
    }
  }

}