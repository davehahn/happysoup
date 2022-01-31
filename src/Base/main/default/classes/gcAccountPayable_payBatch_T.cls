@IsTest
private class gcAccountPayable_payBatch_T {
    final static String RECORDTYPE = 'Motor';
    final static String FAMILY = 'Remote';

    @TestSetup
    static void testData(){     
        Test.startTest();
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
        Factory_AccountPayable.insertAccountPayable(5);
        new Factory_AccountingVariables();
        Test.stopTest();
        
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
        List<AcctSeed__Account_Payable__c> lstAccountPayable = [SELECT id, AcctSeed__Type__c, 
                                                                (select id, AcctSeed__Amount__c from AcctSeed__Project_Account_Payable_Lines__r) 
                                                                FROM AcctSeed__Account_Payable__c ];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstAccountPayable);
        List<AcctSeed__Account_Payable__c> lstSelected = new List<AcctSeed__Account_Payable__c>();

        List<AcctSeed__Account_Payable_Line__c > lstPayableLines = new List<AcctSeed__Account_Payable_Line__c >();
        for(AcctSeed__Account_Payable__c ap: lstAccountPayable){
            if(!ap.AcctSeed__Project_Account_Payable_Lines__r.isEmpty()){
                for(AcctSeed__Account_Payable_Line__c  lines: ap.AcctSeed__Project_Account_Payable_Lines__r){
                    lines.AcctSeed__Amount__c = 100;
                    lstPayableLines.add(lines);
                }
            }
            lstSelected.add(ap);
            setId.add(ap.Id);
        }
        update lstSelected;
        update lstPayableLines;
        AcctSeed.AccountPayablePostService.postAccountPayables(lstAccountPayable);
        
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
       // gcAccountPayable_payBatch.retrieveApDataAll();
        accountPayableBatch.payBatch();
        System.debug('@@ setId[0] in test class= '+setId[0]);
        List<Map<String,String>> listResult  = gcAccountPayable_payBatch.retrieveApData(setId);
        System.debug('listResult1= '+listResult);
        gcAccountPayable_payBatch.retrieveApDataAll();
      System.debug('about to call payWS ');
        try{
        	String id = gcAccountPayable_payBatch.payWS(setId[0]);
            System.assertNotEquals(NULL,id);
        }catch(Exception ex){
            System.assertEquals('The AP cannot be paid; check that it is posted, and that it has a positive balance.',ex.getMessage());
       }
        Test.stopTest();
    }
  	
    @IsTest
    static void testScenario2() {
        Test.startTest();
        List<String> setId = new List<String>();
        List<AcctSeed__Account_Payable__c> lstAccountPayable = [SELECT id, AcctSeed__Type__c, 
                                                                (select id, AcctSeed__Amount__c from AcctSeed__Project_Account_Payable_Lines__r) 
                                                                FROM AcctSeed__Account_Payable__c ];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstAccountPayable);
        List<AcctSeed__Account_Payable__c> lstSelected = new List<AcctSeed__Account_Payable__c>();
        //
        List<AcctSeed__Account_Payable_Line__c > lstPayableLines = new List<AcctSeed__Account_Payable_Line__c >();
        for(AcctSeed__Account_Payable__c ap: lstAccountPayable){
            if(!ap.AcctSeed__Project_Account_Payable_Lines__r.isEmpty()){
                for(AcctSeed__Account_Payable_Line__c  lines: ap.AcctSeed__Project_Account_Payable_Lines__r){
                    lines.AcctSeed__Amount__c = 100;
                    lstPayableLines.add(lines);
                }
            }
            lstSelected.add(ap);
            setId.add(ap.Id);
        }
        update lstSelected;
        update lstPayableLines;
        AcctSeed.AccountPayablePostService.postAccountPayables(lstAccountPayable);
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

     	List<Map<String,String>> listResult = gcAccountPayable_payBatch.retrieveApDataAll();
        System.debug('listResult= '+listResult);
        Test.stopTest();
    
    }
  	
     @IsTest
    static void testScenario3() {
        List<AcctSeed__Account_Payable__c> lstAccountPayable = [ 
         					SELECT 
                                 Id
                    		FROM 
                        		 AcctSeed__Account_Payable__c
            			
 			];
        List<Id> setId = new List<Id>();
        for(AcctSeed__Account_Payable__c ap: lstAccountPayable){
            setId.add(ap.Id);
        }
        Test.StartTest();
        AcctSeed.AccountPayablePostService.postAccountPayables(lstAccountPayable);
        Test.StopTest();
        List<Map<String,String>> mapApData = gcAccountPayable_payBatch.retrieveApData(setId);
    }
    
     @IsTest
    static void testScenario4() {
        List<AcctSeed__Account_Payable__c> lstAccountPayable = [ 
         					SELECT 
                                 Id, AcctSeed__Date__c
                    		FROM 
                        		 AcctSeed__Account_Payable__c
            			
 			];
        for(AcctSeed__Account_Payable__c ap: lstAccountPayable){
            ap.AcctSeed__Date__c = Date.Today().addMonths(-1);
        }
        update lstAccountPayable;
        Test.StartTest();
        AcctSeed.AccountPayablePostService.postAccountPayables(lstAccountPayable);
        Test.StopTest();

        List<Map<String,String>> mapAllData = gcAccountPayable_payBatch.retrieveApDataAll();
    }

}