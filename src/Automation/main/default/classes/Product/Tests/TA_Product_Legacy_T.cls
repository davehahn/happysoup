@isTest
public class TA_Product_Legacy_T {

    final static String RECORDTYPE = 'Insurance';
    final static String FAMILY = 'Insurance';
    static List<Product2> products;
    private static List<Product2> getData(){
        return [Select
                id,
                Allocated__c,
                Availability_Percentage__c,
                Sizes__c,
                Parts_Count__c,
                Landed_Unit_Cost__c,
                Partner_Price__c,
                AcctSeed__Inventory_GL_Account__c,
                AcctSeed__Expense_GL_Account__c,
                AcctSeed__Revenue_GL_Account__c,
                AcctSeed__Inventory_Type__c,
                RecordTypeId,
                Family
        From Product2
        ];
    }
    @TestSetup
    static void testData(){
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
        Factory_AccountPayable.insertAccountPayable(5);
        new Factory_AccountingVariables();
        List<Product2> serializedProducts = Factory_Product.createSerializedProducts(RECORDTYPE, FAMILY, 10);
    }

    @IsTest
    static void beforeInsertTest() {
        Test.startTest();
        products = getData();
        new TA_Product_Legacy().beforeInsert(products);
        Test.stopTest();
    }
    @IsTest
    static void afterInsertTest() {
        Test.startTest();
        new TA_Product_Legacy().afterInsert(getData());
        Test.stopTest();
    }
    @IsTest
    static void afterUpdateTest() {
        Test.startTest();
        products = getData();
        Product2 productClone =products[0].clone(true, true, true, true);
        new TA_Product_Legacy().afterUpdate(new List<Product2>{products[0]},new List<Product2>{productClone});
        Test.stopTest();
    }
    @IsTest
    static void beforeUpdateTest() {
        Test.startTest();
        products = getData();
        Product2 productClone =products[0].clone(true, true, true, true);
        new TA_Product_Legacy().beforeUpdate(new List<Product2>{products[0]},new List<Product2>{productClone});
        Test.stopTest();
    }
    @IsTest
    static void beforeDeleteTest() {
        Test.startTest();
        new TA_Product_Legacy().beforeDelete(getData());
        Test.stopTest();
    }
    @IsTest
    static void afterDeleteTest() {
        Test.startTest();
        new TA_Product_Legacy().afterDelete(getData());
        Test.stopTest();
    }


}