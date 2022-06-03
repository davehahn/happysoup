/**
 * Created by Legend on 16/5/22.
 */

@IsTest
private class EcwidSalesOrder_T {

    @testSetup
    static void dataSetup() {
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
    }

    @IsTest
    static void afterInsert() {
        Account customer = Factory_Account.insertCustomerAccounts(1)[0];
        Test.startTest();
        AcctSeedERP__Sales_Order__c so = Factory_SalesOrder.createSalesOrder(customer,null);
        Ecwid_Sales_Order__e evt = new Ecwid_Sales_Order__e(Status__c = true, Sales_Order_Id__c = so.Id);
        Database.SaveResult sr = EventBus.publish(evt);
        Test.stopTest();
        for(Database.Error err : sr.getErrors()) { 
            System.debug('Error returned: ' +
                    err.getStatusCode() +
                    ' - ' +
                    err.getMessage());
        }
        Boolean crCreated = false;
        for(AcctSeed__Cash_Receipt__c cr : [SELECT Id FROM AcctSeed__Cash_Receipt__c WHERE Sales_Order__c =:so.Id])
        {
            crCreated = true;
        }
        System.assertEquals(true, sr.isSuccess());
        System.assertEquals(true, crCreated);
    }
}