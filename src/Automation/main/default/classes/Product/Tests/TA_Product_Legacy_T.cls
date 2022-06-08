@isTest
public class TA_Product_Legacy_T {

    final static String NONSERIALIZED_RECORDTYPE = 'Insurance';
    final static String NONSERIALIZED_FAMILY = 'Insurance';
    final static String SERIALIZED_RECORDTYPE = 'Boat';
    final static String SERIALIZED_FAMILY = 'Pontoon';
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
        Factory_Product.createSerializedProducts(SERIALIZED_RECORDTYPE, SERIALIZED_FAMILY, 10);
        Factory_Product.createNonSerializedProducts(NONSERIALIZED_RECORDTYPE, NONSERIALIZED_FAMILY, 10);
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

    @IsTest
    static void productCodeTest(){
        Product2 part = Factory_product.buildNonSerializedProduct('Part', 'Hardware');
        Test.startTest();
        insert part;
        Test.stopTest();
        part = [SELECT Id, ProductCode, Unique_Product_Code__c FROM Product2 WHERE Id = :part.Id];

        System.assertEquals( part.ProductCode, part.Unique_Product_Code__c, 'ProductCode and Unique Product Code should be the same');
    }

    @IsTest
    static void productCodeUniquenessTest(){
        List<Product2> parts = Factory_product.buildNonSerializedProducts('Part', 'Hardware', 2);
        String pCode = 'IamTheSame';
        String errorMsg;
        parts[0].ProductCode = pCode;
        parts[1].ProductCode = pCode;
        Test.startTest();
        try{
            insert parts;
        }
        catch( Exception e ){
            errorMsg = e.getMessage();
        }
        System.debug( errorMsg );
        System.assert( errorMsg != null );
    }


}