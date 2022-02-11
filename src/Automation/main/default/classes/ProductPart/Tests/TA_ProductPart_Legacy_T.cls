@isTest
public class TA_ProductPart_Legacy_T {

    final static String RECORDTYPE = 'Insurance';
    final static String FAMILY = 'Insurance';
    static List<AcctSeed__Product_Part__c> product_parts;
    private static List<AcctSeed__Product_Part__c> getData(){
        return  [SELECT Id, AcctSeed__Product__c, AcctSeed__Product_Part__c FROM AcctSeed__Product_Part__c];
    }
    @TestSetup
    static void testData(){
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
        Factory_AccountPayable.insertAccountPayable(5);
        new Factory_AccountingVariables();
        List<Product2> serializedProducts = Factory_Product.createSerializedProducts(RECORDTYPE, FAMILY, 10);
        List<Product2> Parts = Factory_Product.createSerializedProducts('Part', 'Safety', 10);

        List<AcctSeed__Product_Part__c> product_parts = new List<AcctSeed__Product_Part__c>();
        integer i=0;
        for(Product2 prod: serializedProducts){
            product_parts .add(new AcctSeed__Product_Part__c(
                    AcctSeed__Product__c=prod.Id,
                    AcctSeed__Quantity__c=2,
                    AcctSeed__Product_Part__c = parts[i].Id
            ));
            i++;
        }
        insert product_parts;
    }

    @IsTest
    static void beforeInsertTest() {
        Test.startTest();
        product_parts = getData();
        new TA_ProductPart_Legacy().beforeInsert(product_parts);
        Test.stopTest();
    }
    @IsTest
    static void afterInsertTest() {
        Test.startTest();
        new TA_ProductPart_Legacy().afterInsert(getData());
        Test.stopTest();
    }
    @IsTest
    static void afterUpdateTest() {
        Test.startTest();
        product_parts = getData();
        AcctSeed__Product_Part__c productPartClone =product_parts[0].clone(true, true, true, true);
        new TA_ProductPart_Legacy().afterUpdate(new List<AcctSeed__Product_Part__c>{product_parts[0]},new List<AcctSeed__Product_Part__c>{productPartClone});
        Test.stopTest();
    }
    @IsTest
    static void beforeUpdateTest() {
        Test.startTest();
        product_parts = getData();
        AcctSeed__Product_Part__c productPartClone =product_parts[0].clone(true, true, true, true);
        new TA_ProductPart_Legacy().beforeUpdate(new List<AcctSeed__Product_Part__c>{product_parts[0]},new List<AcctSeed__Product_Part__c>{productPartClone});
        Test.stopTest();
    }
    @IsTest
    static void beforeDeleteTest() {
        Test.startTest();
        new TA_ProductPart_Legacy().beforeDelete(getData());
        Test.stopTest();
    }
    @IsTest
    static void afterDeleteTest() {
        Test.startTest();
        new TA_ProductPart_Legacy().afterDelete(getData());
        Test.stopTest();
    }




}