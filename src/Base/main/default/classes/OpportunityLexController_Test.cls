@isTest
private class OpportunityLexController_Test {

  static Account acct;
  static Opportunity opp;
  static AcctSeed__Project__c erp;

  static {
    acct = AccountFactory.buildPersonAccount('Rando', 'Bobando');
    insert acct;
  }

  private static void doInit4Opp()
  {
    //OpportunityTriggerHandler.disableTrigger = true;
    MetadataTriggerHandler.bypass('Opportunity');
    Id retailRT = LGND_Utilities.recordTypeIdFromName('Opportunity', 'Retail');
    opp = new Opportunity(
      AccountId = acct.Id,
      RecordTypeId = retailRT,
      Name = 'Test Retail Opp',
      CloseDate = Date.today(),
      StageName = 'Quoting'
    );
    insert opp;
  }

  private static void doInit4erp()
  {
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial( 'Boat',
                                                                                'Pontoon',
                                                                                '1234567890');
    erp = Factory_ERPOrder.buildERP( acct,
                                     serial.Id,
                                     gcConstants.idRtProjectBoatSale );
    gcProject.disableTrigger = true;
    insert erp;
  }

  @isTest static void fetchRecor_opp_Test() {
    doInit4Opp();
    String jsonResult = OpportunityLexController.fetchRecord(String.valueOf( opp.Id ) );
    OpportunityLexController.RecordWrapper result =
      (OpportunityLexController.RecordWrapper)JSON.deserialize( jsonResult,
                                                                OpportunityLexController.RecordWrapper.class );
    System.assertEquals( 60, result.finTerm ); //60 is the default on the field
    System.assertEquals( 120, result.finAmort );//120 is the defasult on the field
  }

  @isTest
  static void fetchRecord_erp_Test()
  {
    doInit4erp();
    String jsonResult = OpportunityLexController.fetchRecord(String.valueOf( erp.Id ) );
    OpportunityLexController.RecordWrapper result =
      (OpportunityLexController.RecordWrapper)JSON.deserialize( jsonResult,
                                                                OpportunityLexController.RecordWrapper.class );
    System.assertEquals( 60, result.finTerm ); //60 is the default on the field
    System.assertEquals( 120, result.finAmort );//120 is the defasult on the field
  }

  @isTest static void update_record_opp_Test()
  {
    doInit4Opp();
    Map<String, String> data = new Map<String, String>();
    data.put('intrestRate', '6.99');
    data.put('finAmort', '180');
    data.put('finTerm', '48');
    data.put('deposit', '5000');
    OpportunityLexController.updateRecord(JSON.serialize(data), opp.Id);
    opp = [SELECT Id,
                  Deposit__c,
                  Finance_Annual_Interest__c,
                  Finance_Term__c,
                  Finance_Ammortization__c
           FROM Opportunity
           WHERE Id = :opp.Id ];
    System.assertEquals(6.99, opp.Finance_Annual_Interest__c );
    System.assertEquals(180, opp.Finance_Ammortization__c);
    System.assertEquals(48, opp.Finance_Term__c);
    System.assertEquals(5000, opp.Deposit__c);
  }

  @isTest static void update_record_erp_Test()
  {
    doInit4erp();
    Map<String, String> data = new Map<String, String>();
    data.put('intrestRate', '6.99');
    data.put('finAmort', '180');
    data.put('finTerm', '48');
    data.put('deposit', '5000');
    OpportunityLexController.updateRecord(JSON.serialize(data), erp.Id);
    erp = [SELECT Id,
                  Deposit__c,
                  Finance_Annual_Interest__c,
                  Finance_Term__c,
                  Finance_Ammortization__c
           FROM AcctSeed__Project__c
           WHERE Id = :erp.Id ];
    System.assertEquals(6.99, erp.Finance_Annual_Interest__c );
    System.assertEquals(180, erp.Finance_Ammortization__c);
    System.assertEquals(48, erp.Finance_Term__c);
    System.assertEquals(5000, erp.Deposit__c);
  }

}