@IsTest(SeeAllData=False)
private class gcAccountPayable_payBatch_T {
    final static String RECORDTYPE = 'Motor';
    final static String FAMILY = 'Motor Accessories';

    @TestSetup
    static void testData(){
        Factory_CustomSettings.setupInventorySettings();
        new Factory_TestData();
        //new Factory_AccountingSettings();
        new Factory_AccountingVariables();
        List<Product2> serializedProducts = Factory_Product.createSerializedProducts(RECORDTYPE, FAMILY, 10);
        AcctSeed__Account_Payable__c ap1 = Factory_AccountPayable.insertAccountPayable(5);
        AcctSeed__Account_Payable__c ap2 = Factory_AccountPayable.insertAccountPayable(5);
        AcctSeed__Account_Payable__c ap3 = Factory_AccountPayable.insertAccountPayable(5);
        AcctSeed__Account_Payable__c ap4 = Factory_AccountPayable.insertAccountPayable(5);
        AcctSeed__Account_Payable__c ap5 = Factory_AccountPayable.insertAccountPayable(5);
    }
    @IsTest
    static void testScenario1() {
        Test.startTest();
        List<String> setId = new List<String>();
        List<AcctSeed__Account_Payable__c> lstAccountPayable = [SELECT id FROM AcctSeed__Account_Payable__c ];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstAccountPayable);
        List<AcctSeed__Account_Payable__c> lstSelected = new List<AcctSeed__Account_Payable__c>();
        AcctSeed.AccountPayablePostService.postAccountPayables(lstAccountPayable);
        for(AcctSeed__Account_Payable__c ap: lstAccountPayable){

            lstSelected.add(ap);
            setId.add(ap.Id);
        }
        update lstSelected;
        if(!lstSelected.isEmpty() && lstSelected.size()>0){
            lstSelected.remove(0);
        }
        ssc.setSelected(lstSelected);
        gcAccountPayable_payBatch accountPayableBatch = new gcAccountPayable_payBatch(ssc);
        accountPayableBatch.cancel();
        accountPayableBatch.includedApId = JSON.serialize(setId);
        Map<String,Object> m = new Map<String, Object>();
        m.put(setId[0], 50);
        List<Map<String,Object>> listMap = new List<Map<String,Object>>();
        listMap.add(m);
        accountPayableBatch.discountedApId = JSON.serialize(listMap);
        accountPayableBatch.payBatch();
        gcAccountPayable_payBatch.payWS(setId[0]);
        gcAccountPayable_payBatch.retrieveApData(setId);
        gcAccountPayable_payBatch.retrieveApDataAll();
        Test.stopTest();
    }
}