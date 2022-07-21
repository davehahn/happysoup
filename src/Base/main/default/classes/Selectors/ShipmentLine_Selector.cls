/**
 * Created by Legend on 14/6/22.
 */

public inherited sharing class ShipmentLine_Selector extends Application_Selector {
  private final List<String> defaultFields = new List<String>{
    'Id',
    'AcctSeedERP__Shipment__c',
    'AcctSeedERP__Product__c',
    'AcctSeedERP__Quantity_Shipped__c',
    'AcctSeedERP__Sales_Order__c',
    'AcctSeedERP__Sales_Order_Line__c',
    'AcctSeedERP__Sales_Order_Line__r.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c',
    'AcctSeedERP__Sales_Order_Line__r.AcctSeedERP__Product__r.Composite_Type__c',
    'AcctSeedERP__Sales_Order_Line__r.AcctSeedERP__Quantity_Allocated__c',
    'AcctSeedERP__Sales_Order_Line__r.AcctSeedERP__Quantity_Ordered__c',
    'AcctSeedERP__Sales_Order_Line__r.AcctSeedERP__Quantity_Needed__c',
    'AcctSeedERP__Sales_Order_Line__r.AcctSeedERP__Unit_Price__c',
    'AcctSeedERP__Sales_Order_Line__r.Taxable_Federal__c',
    'AcctSeedERP__Sales_Order_Line__r.Taxable_Provincial__c',
    'AcctSeedERP__Sales_Order_Line__r.Taxable_Retail__c',
    'AcctSeedERP__Sales_Order_Line__r.AcctSeedERP__GL_Account_Variable_1__c',
    'AcctSeedERP__Sales_Order_Line__r.AcctSeedERP__GL_Account_Variable_2__c',
    'AcctSeedERP__Sales_Order_Line__r.AcctSeedERP__GL_Account_Variable_3__c',
    'AcctSeedERP__Sales_Order_Line__r.AcctSeedERP__GL_Account_Variable_4__c',
    'AcctSeedERP__Sales_Order_Line__r.AcctSeedERP__Total__c'
  };

  public ShipmentLine_Selector() {
    this.sObjectName = 'AcctSeedERP__Shipment_Line__c';
    this.fields = defaultFields;
  }

  public static List<AcctSeedERP__Shipment_Line__c> byShipment(Set<Id> recordIds) {
    return new ShipmentLine_Selector()
      .addWhereIdInField(recordIds, 'AcctSeedERP__Shipment__c')
      .addChildQuery('(SELECT Id, AcctSeed__Hours_Units__c FROM Billing_Lines__r)')
      .query();
  }
}
