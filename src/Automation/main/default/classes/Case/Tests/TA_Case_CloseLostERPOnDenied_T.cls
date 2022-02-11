
/**
 * Created by dave on 2022-01-07.
 */

@IsTest
private class TA_Case_CloseLostERPOnDenied_T
{

  private static List<Case> cases;
  private static List<Case> oldList;
  private static Account dealer;
  private static Map<String, AcctSeed__Project__c> erps;
  public static User partner;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    dealer = AccountFactory.buildDealerAccount('Testy McDealer');
    insert dealer;
    partner = Factory_User.createPartnerUser(dealer);
    cases = new List<Case>();
    oldList = new List<Case>();
    erps = new Map<String, AcctSeed__Project__c>();
    Application_RecordType.ERPOrderRTs rts = new Application_RecordType().getERPOrderRecordTypes();
    erps.put('warranty', buildERP(rts.getWarrantyId()));
    erps.put('recoverable', buildERP(rts.getWarrantyId()));
    erps.put('partsOrder', buildERP(rts.getPartnerPartsOrderId()));
    TriggerBase.bypass('AcctSeed__Project__c');
    insert erps.values();
    TriggerBase.clearBypass('AcctSeed__Project__c');
    initCase();
  }

  private static AcctSeed__Project__c buildERP(Id recordTypeId) {
    AcctSeed__Project__c erp = new AcctSeed__Project__c(
      RecordTypeId = recordTypeId,
      Name = dealer.Name.trim(),
      AcctSeed__Status__c = 'Active',
      AcctSeed__Account__c = dealer.Id
    );
    return erp;
  }

  private static void initCase() {
    Case c = Factory_Case.buildWarrantyCase(dealer);
    c.Warranty_ERP__c = erps.get('warranty').Id;
    c.Recoverable_ERP__c = erps.get('recoverable').Id;
    c.Parts_Order_ERP__c = erps.get('partsOrder').Id;
    cases.add(c);
  }

  @IsTest
  static void TA_AfterUpdate() {
    init();
    cases[0].Id = TestUtility.getFakeId(Case.SObjectType);
    Case oldC = cases[0].clone(true, true, true, true);
    oldList.add(oldC);
    String[] deniedReasons = LGND_Utilities.getPicklistValues('Case', 'Denied_Reasons__c');
    cases[0].Status = 'Denied';
    cases[0].Denied_Reasons__c = deniedReasons[0];

    Test.startTest();
    new TA_Case_CloseLostERPOnDenied().afterUpdate(cases, oldList);
    Test.stopTest();

    Set<Id> erpIds = new Set<Id>{ erps.get('warranty').Id, erps.get('recoverable').Id, erps.get('partsOrder').Id };
    for (AcctSeed__Project__c p : [SELECT Id, Stage__c FROM AcctSeed__Project__c WHERE Id IN :erpIds]) {
      System.assertEquals('Closed Lost', p.Stage__c);
    }
  }
}