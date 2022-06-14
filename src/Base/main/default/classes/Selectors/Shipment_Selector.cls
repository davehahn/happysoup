/**
 * Created by Legend on 14/6/22.
 */

public inherited sharing class Shipment_Selector extends Application_Selector {
    private final List<String> defaultFields = new List<String>{
            'Id',
            'AcctSeedERP__Status__c',
            'AcctSeedERP__Sales_Order__r.AcctSeedERP__Customer__c',
            'AcctSeedERP__Sales_Order__r.GL_Account_Variable_3__c',
            'AcctSeedERP__Sales_Order__r.Tax_is_Harmonized__c',
            'AcctSeedERP__Sales_Order__r.Tax_Rate_Federal__c',
            'AcctSeedERP__Sales_Order__r.Tax_Rate_Provincial__c',
            'AcctSeedERP__Sales_Order__r.Tax_Rate_Retail__c',
            'AcctSeedERP__Sales_Order__r.Tax_Override__c'
    };

    public Shipment_Selector(){
        this.sObjectName = 'AcctSeedERP__Shipment__c';
        this.fields = defaultFields;
    }

    public static List<AcctSeedERP__Shipment__c> allShipmentByShipped(set<Id> setIdShipment)
    {
        return new Shipment_Selector()
                .addWhereIdIn( setIdShipment )
                .addWhere('AcctSeedERP__Status__c = \'Shipped\'')
                .query();
    }

    public static List<AcctSeedERP__Shipment__c> byIdsIncludingSOL( Set<Id> recordIds )
    {
        ShipmentLine_Selector shipmentLineSelector = new ShipmentLine_Selector();
        return new Shipment_Selector()
                .addWhereIdIn( recordIds )
                .addWhere('AcctSeedERP__Status__c = \'Shipped\'')
                .addChildQuery(shipmentLineSelector)
                .query();
    }

}