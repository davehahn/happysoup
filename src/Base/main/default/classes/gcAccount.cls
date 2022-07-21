public without sharing class gcAccount {
  public static Boolean disableTrigger {
    get {
      if (disableTrigger == null)
        return false;
      else
        return disableTrigger;
    }
    set {
      if (value == null)
        disableTrigger = false;
      else
        disableTrigger = value;
    }
  }

  public static void triggerHandler(
    map<Id, Account> oldMap,
    map<Id, Account> newMap,
    list<Account> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (oldMap == null)
      oldMap = new Map<Id, Account>();
    if (newMap == null)
      newMap = new Map<Id, Account>();
    if (listNew == null)
      listNew = new List<Account>();

    updateAndValidate(oldMap, newMap, listNew, boolIsBefore, boolIsInsert, boolIsUpdate, boolIsDelete);

    if (boolIsBefore) {
      if (boolIsInsert) {
      }
      if (boolIsUpdate) {
      }
      if (boolIsDelete) {
      }
    } else //i.e. trigger.isAfter
    {
      if (boolIsInsert) {
        createGeoAccountsForPersonAccounts(listNew);
      }
      if (boolIsUpdate) {
        updateOpportunityContactEmail(listNew, oldMap);
        populateGeoCodes(listNew);
      }
      if (boolIsDelete) {
      }
    }
  }

  private static void createGeoAccountsForPersonAccounts(List<Account> listNew) {
    List<Account> geoAccts = new List<Account>();
    Id geoHackRtId = LGND_Utilities.recordTypeIdFromName('Account', 'Geo Hack');
    for (Account a : listNew) {
      if (a.IsPersonAccount) {
        geoAccts.add(
          new Account(
            Name = a.FirstName + '_' + a.LastName + '-geo',
            BillingStreet = a.BillingStreet,
            BillingCity = a.BillingCity,
            BillingState = a.BillingState,
            BillingCountry = a.BillingCountry,
            BillingPostalCode = a.BillingPostalCode,
            RecordTypeId = geoHackRtId,
            Geo_Account__c = a.Id
          )
        );
      }
    }
    if (geoAccts.size() > 0)
      insert geoAccts;
  }

  private static void populateGeoCodes(List<Account> listNew) {
    Id geoHackRtId = LGND_Utilities.recordTypeIdFromName('Account', 'Geo Hack');
    Map<Id, Account> pAcctId_geoAcct = new Map<Id, Account>();
    List<Account> toDelete = new List<Account>();
    for (Account a : listNew) {
      if (a.RecordTypeId == geoHackRtId && a.BillingLongitude != null && a.BillingLatitude != null)
        pAcctId_geoAcct.put(a.Geo_Account__c, a);
    }
    List<Account> personAccts = [SELECT Id, PersonContactId FROM Account WHERE Id IN :pAcctId_geoAcct.keySet()];
    List<Contact> personContacts = new List<Contact>();
    for (Account pa : personAccts) {
      personContacts.add(
        new Contact(
          Id = pa.PersonContactId,
          MailingStreet = pAcctId_geoAcct.get(pa.Id).BillingStreet,
          MailingCity = pAcctId_geoAcct.get(pa.Id).BillingCity,
          MailingState = pAcctId_geoAcct.get(pa.Id).BillingState,
          MailingCountry = pAcctId_geoAcct.get(pa.Id).BillingCountry,
          MailingLatitude = pAcctId_geoAcct.get(pa.Id).BillingLatitude,
          MailingLongitude = pAcctId_geoAcct.get(pa.Id).BillingLongitude,
          MailingPostalCode = pAcctId_geoAcct.get(pa.Id).BillingPostalCode
        )
      );
      toDelete.add(new Account(Id = pAcctId_geoAcct.get(pa.Id).Id));
    }
    update personContacts;
    delete toDelete;
  }

  private static void updateOpportunityContactEmail(Account[] accounts, Map<Id, Account> oldMap) {
    Map<Id, Account> accountsMap = new Map<Id, Account>();
    Set<String> processStatuses = new Set<String>{ 'Pending', 'Approved' };
    for (Account a : accounts) {
      Account oldAcct = oldMap.get(a.Id);
      if (a.isPersonAccount) {
        if (a.PersonEmail != oldAcct.PersonEmail)
          accountsMap.put(a.Id, a);
      } else {
        if (a.AccountEmail__c != oldAcct.AccountEmail__c)
          accountsMap.put(a.Id, a);
      }
    }
    List<Opportunity> opps = [
      SELECT
        Id,
        AccountId,
        ContactEmail__c,
        StageName,
        (SELECT Id, Status FROM ProcessInstances WHERE Status IN :processStatuses)
      FROM Opportunity
      WHERE AccountId IN :accountsMap.keySet()
    ];
    List<Opportunity> updateOpps = new List<Opportunity>();

    if (opps.size() > 0) {
      for (Opportunity o : opps) {
        if (o.ProcessInstances.size() == 0) {
          String email = accountsMap.get(o.AccountId).isPersonAccount
            ? accountsMap.get(o.AccountId).PersonEmail
            : accountsMap.get(o.AccountId).AccountEmail__c;
          if (o.ContactEmail__c != email) {
            o.ContactEmail__c = email;
            updateOpps.add(o);
          }
        }
      }
    }
    if (updateOpps.size() > 0) {
      update updateOpps;
    }
  }

  private static void updateAndValidate(
    map<Id, Account> oldMap,
    map<Id, Account> newMap,
    list<Account> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (boolIsBefore && (boolIsInsert || boolIsUpdate)) {
      for (Account a : listNew) {
        a.AcctSeed__Accounting_Active__c = true;
        if (a.AcctSeed__Accounting_Type__c == null)
          a.AcctSeed__Accounting_Type__c = 'Customer and Vendor';
        if (a.AcctSeed__Account_Payable_Terms__c == null) {
          a.AcctSeed__Account_Payable_Terms__c = 30;
        }
        if (a.AcctSeed__Billing_Days_Due__c == null) {
          a.AcctSeed__Billing_Days_Due__c = 30;
        }

        if (a.AcctSeed__Billing_Days_Due__c > 0)
          a.AcctSeed__Billing_Terms_Name__c = 'net ' + String.valueOf(a.AcctSeed__Billing_Days_Due__c.setScale(0));
      }
    }
  }
}
