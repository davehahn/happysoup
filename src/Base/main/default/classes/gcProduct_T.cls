@isTest(SeeAllData=false)
public class gcProduct_T {

    final static String RECORDTYPE = 'Insurance';
    final static String FAMILY = 'Insurance';
    
    @TestSetup
    static void testData(){
        new Factory_TestData();
            Factory_CustomSettings.setupInventorySettings();
            Factory_AccountPayable.insertAccountPayable(5);
            new Factory_AccountingVariables();
            List<Product2> serializedProducts = Factory_Product.createSerializedProducts(RECORDTYPE, FAMILY, 10);
    }

    @isTest
    static void testInsertAndUpdateProduct(){
        Product2[] parts = Factory_Product.buildNonSerializedProducts('Part', 'Hardware', 5);
        insert parts; 
        
        List<Product2> productList = [select id,Allocated__c,Availability_Percentage__c,Sizes__c from Product2]; 
        List<Product2> productListForUpdate = new List<Product2>();
        if(!productList.isEmpty()){
            for(Product2 prod :productList){
                prod.Allocated__c = 1;
                prod.Sizes__c ='20';
                prod.Parts_Count__c = 10;
                prod.Landed_Unit_Cost__c = 2000;
                prod.Partner_Price__c = 1000;
                prod.AcctSeed__Inventory_GL_Account__c = null;
                productListForUpdate.add(prod);

            }
        }
        Test.startTest();
        update productListForUpdate;
        productList = [select id,Allocated__c,Availability_Percentage__c,Sizes__c,Parts_Count__c from Product2 limit 1];
		System.assertEquals(1,productList[0].Allocated__c);
        System.assertEquals('20',productList[0].Sizes__c);
        Test.stopTest();


    }
     @isTest
    static void testInsertAndUpdateProductForBoatRecordType(){
       	Product2[] products = Factory_Product.createSerializedProducts('Boat','Pontoon',12);
      //  insert products; 

        List<Product2> productList = [select id,Allocated__c,Availability_Percentage__c,Sizes__c from Product2]; 
        List<Product2> productListForUpdate = new List<Product2>();
        if(!productList.isEmpty()){
            for(Product2 prod :productList){
                prod.Allocated__c = 1;
                prod.Sizes__c ='20';
                prod.Parts_Count__c = 10;
                prod.Landed_Unit_Cost__c = 2000;
                prod.Partner_Price__c = 1000;
                productListForUpdate.add(prod);

            }
        }
        Test.startTest();
        update productListForUpdate;
        productList = [select id,Allocated__c,Availability_Percentage__c,Sizes__c,Parts_Count__c from Product2 limit 1]; 
		System.assertEquals(1,productList[0].Allocated__c);
        System.assertEquals('20',productList[0].Sizes__c);
        Test.stopTest();



    }

      @isTest
    static void testInsertAndUpdateProductForGLAccountNull(){
       	Product2[] products = Factory_Product.createSerializedProducts('Boat','Pontoon',12);
      //  insert products; 
        
        List<Product2> productList = [select id,Allocated__c,Availability_Percentage__c,Sizes__c from Product2]; 
        List<Product2> productListForUpdate = new List<Product2>();
        if(!productList.isEmpty()){
            for(Product2 prod :productList){
                prod.Allocated__c = 1;
                prod.Sizes__c ='20';
                prod.Parts_Count__c = 10;
                prod.Landed_Unit_Cost__c = 2000;
                prod.Partner_Price__c = 1000;
				prod.AcctSeed__Inventory_GL_Account__c =null;
                prod.AcctSeed__Expense_GL_Account__c = null;
                prod.AcctSeed__Revenue_GL_Account__c = null;
                prod.AcctSeed__Inventory_Type__c = null;
                productListForUpdate.add(prod);

            }
        }
        Test.startTest();
        update productListForUpdate;
		productList = [select id,Allocated__c,Availability_Percentage__c,Sizes__c,Parts_Count__c,AcctSeed__Inventory_GL_Account__c,AcctSeed__Expense_GL_Account__c,AcctSeed__Revenue_GL_Account__c,AcctSeed__Inventory_Type__c from Product2 limit 1]; 
		System.assertEquals(null,productList[0].AcctSeed__Inventory_GL_Account__c);
        System.assertEquals(null,productList[0].AcctSeed__Inventory_Type__c);
        Test.stopTest();


    }
     @isTest
    static void testInsertAndUpdateProductForInventoryTypeNotPurchased(){
        Product2[] parts = Factory_Product.buildNonSerializedProducts('Motor', 'Hardware', 5);
        insert parts; 
        
        List<Product2> productList = [select id,Allocated__c,Availability_Percentage__c,Sizes__c,AcctSeed__Inventory_Type__c from Product2]; 
        List<Product2> productListForUpdate = new List<Product2>();
        if(!productList.isEmpty()){
            for(Product2 prod :productList){
                prod.Allocated__c = 1;
                prod.Sizes__c ='20';
                prod.Parts_Count__c = 10;
                prod.Landed_Unit_Cost__c = 2000;
                prod.Partner_Price__c = 1000;
                prod.AcctSeed__Inventory_GL_Account__c = null;
               // prod.AcctSeed__Inventory_Type__c = 'Purchased';
                productListForUpdate.add(prod);

            }
        }
        Test.startTest();
        update productListForUpdate;
		productList = [select id,Allocated__c,Availability_Percentage__c,Sizes__c,AcctSeed__Inventory_GL_Account__c,AcctSeed__Inventory_Type__c from Product2]; 
		System.assertEquals(null,productList[0].AcctSeed__Inventory_GL_Account__c);
        System.assertNotEquals('Purchased',productList[0].AcctSeed__Inventory_Type__c);
        Test.stopTest();
    }

     @isTest
    static void testDeleteProductWithLot(){
        Product2[] parts = Factory_Product.buildNonSerializedProducts('Part', 'Hardware', 5);
        insert parts; 
        
        List<Product2> productList = [select id,Allocated__c,Availability_Percentage__c,Sizes__c from Product2 limit 1]; 
         List<Product2> productListForUpdate = new List<Product2>();
        if(!productList.isEmpty()){
            for(Product2 prod :productList){
                prod.Allocated__c = 1;
                prod.Sizes__c ='20';
                prod.Parts_Count__c = 10;
                prod.Landed_Unit_Cost__c = 2000;
                prod.Partner_Price__c = 1000;
                prod.AcctSeed__Inventory_GL_Account__c = null;
                prod.GMBLASERP__Lot_Tracked__c =true;
                productListForUpdate.add(prod);

            }
        }
        Test.startTest();
        update productListForUpdate;
        productList = [select id,Allocated__c,Availability_Percentage__c,Sizes__c,GMBLASERP__Lot_Tracked__c from Product2 limit 1]; 
        Date today = Date.today();
    	GMBLASERP__Lot__c lot = new GMBLASERP__Lot__c(
      								GMBLASERP__Product__c = productList[0].Id,
      								Name = String.valueOf( today.year() ),
      								GMBLASERP__Uniquefier__c = productList[0].Id + '-' + String.valueOf(today.year())
    								);
        insert lot;
        if(!productList.isEmpty()){
            try{
            	delete productList[0];
            }catch(Exception e){
                System.debug('Exception: '+e.getMessage());  
                System.assert(e != null);
            }
        }

         Test.stopTest();


    }

    
     @isTest
    static void testDeleteProductWithoutLot(){
        Product2[] parts = Factory_Product.buildNonSerializedProducts('Part', 'Hardware', 5);
        insert parts;
         Test.startTest();
        List<Product2> productList = [select id,Allocated__c,Availability_Percentage__c,Sizes__c from Product2 limit 1]; 
         List<Product2> productListForUpdate = new List<Product2>();
        if(!productList.isEmpty()){
            for(Product2 prod :productList){
                prod.Allocated__c = 1;
                prod.Sizes__c ='20';
                prod.Parts_Count__c = 10;
                prod.Landed_Unit_Cost__c = 2000;
                prod.Partner_Price__c = 1000;
                prod.AcctSeed__Inventory_GL_Account__c = null;
                prod.GMBLASERP__Lot_Tracked__c =true;
                productListForUpdate.add(prod);

            }
        }
        update productListForUpdate;
         productList = [select id,Allocated__c,Availability_Percentage__c,Sizes__c,GMBLASERP__Lot_Tracked__c from Product2 limit 1]; 
        
    	Id productId = productList[0].id; 
        if(!productList.isEmpty()){
            try{
            	delete productList[0];
            }catch(Exception e){
                System.debug('Exception: '+e.getMessage());  
            }
        }
        
        productList = [select id,Allocated__c,Availability_Percentage__c,Sizes__c,GMBLASERP__Lot_Tracked__c from Product2 where id =:productId]; 
        System.assert(productList.isEmpty());
        Test.stopTest();



    }
}