@isTest
private class ERPInvoiceDocumentBuilder_TEST {

  static AcctSeed__Project__c erp;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init()
  {
    AcctSeedERP__Warehouse__c wh = [ SELECT Id, Name, GL_Account_Variable_3__c
                                     FROM AcctSeedERP__Warehouse__c
                                     LIMIT 1 ];
    Account cust = Factory_Account.insertFullPersonAccount('TestFname', 'TestLname');
    GMBLASERP__Serial_Number__c ser = Factory_SerialNumber.insertFullSerial('Boat','Pontoon','0987654321');
    Boolean orig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    erp = Factory_ERPOrder.insertRetailBoatSale( cust, wh, DateTime.now(), ser);
    gcProject.disableTrigger = orig;
  }

  @isTest static void tempTest()
  {
    ERPInvoiceDocumentBuilder.coverage();
    init();
    Test.startTest();
    ERP_Document__c doc = new ERP_Document__c(Document_Type__c = 'Retail',
                                              Project__c = erp.Id);
    insert doc;
    Test.stopTest();
  }

}