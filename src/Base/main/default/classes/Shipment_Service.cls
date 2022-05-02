/**
 * Created by Legend on 28/4/22.
 */

public without sharing class Shipment_Service {
    public static List<AcctSeed__Billing__c> Billing(List<AcctSeedERP__Sales_Order__c>lstSalesOrder){
        System.debug('@@ lstSalesOrder= '+lstSalesOrder);
        List<AcctSeed__Billing__c> lstBilingToBeSaved = new List<AcctSeed__Billing__c>();
        List<AcctSeed__Billing_Line__c> lstBilingLineToBeSaved = new List<AcctSeed__Billing_Line__c>();
        List<BillingWrapper> lstBillingWrapper = new List<BillingWrapper>();
        List<AcctSeedERP__Sales_Order_Line__c> SalesOrderLineList = new List<AcctSeedERP__Sales_Order_Line__c>();
        BillingWrapper billingWrapper = new BillingWrapper();
        Map<id,List<AcctSeedERP__Sales_Order_Line__c>> SalesOrderToSOLineMap = getSalesOrder(lstSalesOrder);
        for(AcctSeedERP__Sales_Order__c so :lstSalesOrder){
            //AcctSeed__Billing__c billing = new AcctSeed__Billing__c();
            // billingWrapper.billing.AcctSeed__Billing_City__c =so.AcctSeedERP__Billing_City__c !=null?so.AcctSeedERP__Billing_City__c:null;
            //billingWrapper.billing.AcctSeed__Billing_Country__c = so.AcctSeedERP__Billing_Country__c!=null?so.AcctSeedERP__Billing_Country__c:null;
            billingWrapper.billing.AcctSeed__Customer__c = so.AcctSeedERP__Customer__c!=null ?so.AcctSeedERP__Customer__c:null;
            billingWrapper.billing.Lgnd_Due_Date__c = Date.today().addMonths(1);
            //billing.GL_Account_Variable_3__c = ;
            billingWrapper.billing.AcctSeed__Date__c = Date.today();
            billingWrapper.billing.AcctSeed__Billing_Format__c = 'a0e7h0000023LwkAAE';
            billingWrapper.billing.Tax_Override__c = true;
            billingWrapper.billing.AcctSeedERP__Sales_Order__c = so.Id;
            billingWrapper.billing.AcctSeed__Ledger__c = so.AcctSeedERP__Ledger__c;
            billingWrapper.billing.AcctSeed__Status__c = 'Posted';
            // List<AcctSeedERP__Sales_Order_Line__c> listSalesOrderLine = so.AcctSeedERP__Sales_Order_Line__r;
            System.debug('@@ SalesOrderLineList= '+SalesOrderToSOLineMap.get(so.Id));
            for(AcctSeedERP__Sales_Order_Line__c sol :SalesOrderToSOLineMap.get(so.Id)){
                AcctSeed__Billing_Line__c billingLine = new AcctSeed__Billing_Line__c();
                billingLine.AcctSeed__Comment__c=sol.AcctSeedERP__Comment__c;
                billingLine.AcctSeed__Date__c = Date.today();
                billingLine.AcctSeed__GL_Account_Variable_2__c=sol.AcctSeedERP__GL_Account_Variable_2__c;
                billingLine.AcctSeed__GL_Account_Variable_1__c=sol.AcctSeedERP__GL_Account_Variable_1__c;
                billingLine.AcctSeed__Product__c=sol.AcctSeedERP__Product__c;
                billingLine.AcctSeed__Product_Unit_Cost__c=sol.AcctSeedERP__Unit_Price__c;
                billingLine.AcctSeed__Hours_Units__c=sol.AcctSeedERP__Quantity_Ordered__c;
                billingLine.AcctSeedERP__Sales_Order_Line__c =sol.Id;
                billingLine.AcctSeed__GL_Account_Variable_3__c=sol.AcctSeedERP__GL_Account_Variable_3__c;
                billingLine.AcctSeed__Rate__c=sol.AcctSeedERP__Unit_Price__c;
                billingWrapper.lstBillingLine.add(billingLine);
                // billingLine.AcctSeed__Rate__c = ;
            }
            // lstBillingWrapper.add(new BillingWrapper(billing,lstBilingLineToBeSaved));
            lstBillingWrapper.add(billingWrapper);
        }



        System.debug('@@ lstBillingWrapper= '+lstBillingWrapper);
        for(BillingWrapper wrapper :lstBillingWrapper){
            lstBilingToBeSaved.add(wrapper.billing);
        }
        if(!lstBilingToBeSaved.isEmpty()){
            System.debug('@@# lstBilingToBeSaved= '+lstBilingToBeSaved);
            insert lstBilingToBeSaved;

            System.debug('@@# after insert');
        }

        for(BillingWrapper wrapper :lstBillingWrapper){
            for(AcctSeed__Billing_Line__c billingLine :wrapper.lstBillingLine){
                billingLine.AcctSeed__Billing__c =  wrapper.billing.Id;
                lstBilingLineToBeSaved.add(billingLine);
            }
        }
        System.debug('lstBilingLineToBeSaved= '+lstBilingLineToBeSaved);
        if(!lstBilingLineToBeSaved.isEmpty()){
            insert lstBilingLineToBeSaved;
        }
        if(!lstBilingToBeSaved.isEmpty()){
            AcctSeed.PostResult[] postResultsAP = AcctSeed.BillingPostService.postBillings(lstBilingToBeSaved);
            for (AcctSeed.PostResult theResult : postResultsAP) {
                if (!theResult.isSuccess) {
                    for (AcctSeed.PostResult.PostErrorResult errorResult: theResult.errors) {
                        throw new gcException('Billing was not posted. Please try again. REASON: ' + errorResult.message);
                    }
                }
            }
        }
        return lstBilingToBeSaved;
    }
}