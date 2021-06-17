@IsTest
private class gcProductPart_T {
    final static String RECORDTYPE = 'Insurance';
    final static String FAMILY = 'Insurance';
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
    static void testProperties() {
        //disableTrigger Property
        gcProductPart.disableTrigger = null;
        Boolean retFlag1 = gcProductPart.disableTrigger;
        System.assertEquals(False, retFlag1);
        gcProductPart.disableTrigger = true;
        Boolean retFlag2 = gcProductPart.disableTrigger;
        system.assertEquals(True, retFlag2);
    }

    @IsTest
    static void testSibling(){
        Product2 part = [SELECT Id, AcctSeed__Inventory_Product__c FROM Product2 WHERE recordType.Name='Part' LIMIT 1];
        part.AcctSeed__Inventory_Product__c = false;
        update part;
        List<AcctSeed__Product_Part__c> product_parts = [SELECT Id, AcctSeed__Product__c, AcctSeed__Product_Part__c FROM AcctSeed__Product_Part__c];
        Test.startTest();
        for(AcctSeed__Product_Part__c pp: product_parts){

            pp.AcctSeed__Product_Part__c = part.Id;
        }
        update product_parts;
        test.stopTest();

    }
}