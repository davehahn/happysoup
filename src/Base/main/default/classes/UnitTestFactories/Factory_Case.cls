@isTest
public class Factory_Case {

  public static Case buildWarrantyCase( Account acct )
  {
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat',
      'Pontoon',
      '1234TEST6789');
    return buildWarrantyCase( acct, serial.Id );
  }

  public static Case buildWarrantyCase( Account acct, Id serialNumberId )
  {
    return new Case(
      Serial_Number__c = serialNumberId,
      AccountId = acct.Id,
      RecordTypeId = LGND_Utilities.recordTypeIdFromName('Case', 'Warranty')
    );
  }

  public static Case buildSalesforceCase()
  {
    return new Case(
      RecordTypeId = LGND_Utilities.recordTypeIdFromName('Case', 'Salesforce'),
      Type = 'Service',
      Priority = 'High',
      Reason = 'Bug',
      Subject = 'Salesforce bug',
      Description = 'Salesforce bug in unit test'
    );
  }

  public static Case createWarrantyCase(Account acct)
  {

    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat',
                                                                               'Pontoon',
                                                                               '1234TEST6789');

    Case c = buildWarrantyCase( acct, serial.Id );
    insert c;
    return c;
  }

  public static Case createWarrantyCaseWithErp(Account acct)
  {

    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat',
                                                                               'Pontoon',
                                                                               '1234TEST6789');

    AcctSeed__Project__c erp = Factory_ERPOrder.createWarrantyERP(acct, serial.Id, 0);

    Case c = buildWarrantyCaseWithErp( acct, serial.Id, erp.Id );
    insert c;
    return c;
  }

  public static Case buildWarrantyCaseWithErp( Account acct, Id serialNumberId, Id erpId )
  {
    return new Case(
      Serial_Number__c = serialNumberId,
      AccountId = acct.Id,
      RecordTypeId = LGND_Utilities.recordTypeIdFromName('Case', 'Warranty'),
      Warranty_ERP__c = erpId
    );
  }

  public static Case createPartsRequestCase(
    Id erpId,
    Id acctId,
    List<AcctSeedERP__Material__c> materials
  )
  {
    Case result = new Case(
      ERP_Order__c = erpId,
      AccountId = acctId,
      RecordTypeId = new Application_RecordType().getCaseRecordTypes().getPartOrderRequestId()
    );
    insert result;
    Factory_CasePart.create( result.Id, materials);
    return result;
  }

  public static Case insertCustomerCommunityCase(){
    Case c = new Case(
      SuppliedEmail = 'test@unittesting.net',
      Status = 'New',
      Subject = 'Unit Test',
      Description = 'Created in a Unit Test',
      RecordTypeId = new Application_RecordType().getCaseRecordTypes().getCustomerCommunityId()
    );
    insert c;
    return c;
  }

}