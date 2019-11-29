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

}