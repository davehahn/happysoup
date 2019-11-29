@isTest
public with sharing class AccountFactory {

  public static Account insertPersonAccount()
  {
    Account a =  buildAccount( recordTypeIdFromString('Person Account') );
    insert a;
    return a;
  }

  public static Account buildSupplierAccount(String accountName)
  {
    return new Account(
      Name = accountName,
      RecordTypeId = recordTypeIdFromString('Supplier')
    );
  }

  public static Account insertSupplierAccount(String accountName)
  {
    Id supplierPbId = LGND_Utilities.recordTypeIdFromName('Pricebook2', 'Supplier');
    Pricebook2 pb = new Pricebook2(
      isActive = true,
      RecordTypeId = supplierPbId,
      Name = accountName + ' - Supplier'
    );
    insert pb;
    Account acct = new Account(
      Name = accountName,
      RecordTypeId = recordTypeIdFromString('Supplier'),
      GMBLASERP__Pricebook__c = pb.Id
    );
    insert acct;
    return acct;
  }

  public static Account insertSupplierAccountWithContacts(String accountName, Integer numOfContacts )
  {
    Account a = insertSupplierAccount( accountName );
    Contact[] contacts = new List<Contact>();
    for( Integer i=0; i< numOfContacts; i++ )
    {
      contacts.add( new Contact(
        AccountId = a.Id,
        Email = accountName.replace(' ','_') + '_' + String.valueOf(i) + '@test.net',
        FirstName = 'Tester' + String.valueOf(i),
        LastName = 'McTestface'
      ));
    }
    insert contacts;
    return a;
  }

  public static Account buildPersonAccount(String firstName, String lastName)
  {
    return new Account( FirstName = firstName,
                        LastName = lastName,
                        RecordTypeId = recordTypeIdFromString('Person Account')
                      );
  }

  public static Account buildDealerAccount( String name )
  {
    return new Account( Name = name,
                        RecordTypeId = LGND_Utilities.recordTypeIdFromName('Account', 'Dealer')
                      );
  }

  public static Account buildDealerAccountWithEmail( String name, String email )
  {
    return new Account( Name = name,
                        AccountEmail__c = email,
                        RecordTypeId = LGND_Utilities.recordTypeIdFromName('Account', 'Dealer')
                      );
  }

  private static Account buildAccount(Id rtId)
  {
    return new Account(FirstName='Test_First_Name', LastName='Test_Last_Name', RecordTypeId= rtId);
  }

  private static Id recordTypeIdFromString(String rtName)
  {
    Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Account;
    Map<String,Schema.RecordTypeInfo> AccountRecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
    return AccountRecordTypeInfo.get(rtName).getRecordTypeId();
  }
}