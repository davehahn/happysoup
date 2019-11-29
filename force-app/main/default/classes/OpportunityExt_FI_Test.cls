@isTest
private class OpportunityExt_FI_Test {

   static Id rTId;
   static Account acct;
   static Opportunity opp;
   static {
        AcctSeed_Settings_Factory.getWarehouse('Whitefish');
        Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Account;
        Map<String,Schema.RecordTypeInfo> AccountRecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
        rTId = AccountRecordTypeInfo.get('Person Account').getRecordTypeId();
        acct = new Account(FirstName= 'Test', LastName='User', RecordTypeId=rTId);
        insert acct;
        OpportunityTriggerHandler.disableAutoPricebookSet = true;
        opp = new Opportunity(
          Name = 'Test Opportunity',
          CloseDate= Date.today(),
          StageName='Quoting',
          AccountId=acct.Id
        );
        insert opp;
        //CommissionRecord.recreateCommissionRecords(opp);
    }

  @isTest(seeAllData=true) static void test_method_one() {
        Id pbId = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :opp.Id].Pricebook2Id;
        List<InsurancePlan__c> insurancePlans = InsuranceFactory.insertInsurancePlansWithItems(2);
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        OpportunityExt_FI ext = new OpportunityExt_FI(sc);


        //System.assert( items.isEmpty() );
        System.assert( !ext.hasInvoice );

        Map<Id,InsurancePlan__c> plans = ext.getPlans();
        System.assert(  plans.size() >= insurancePlans.size() );

        Map<String, Map<String,String>> planOptions = ext.getPlanOptions();
        System.assert( planOptions == null );
        System.assert( !ext.getRenderTable() );

        Map<String, Map<String,String>> planOptions2 = OpportunityExt_FI.planSelectOptions('fail', 'fail');
        System.assert(planOptions2.isEmpty() );
        //OpportunityExt_FI.planSelectOptions(insurancePlans[0].Id);

        planOptions2 = OpportunityExt_FI.planSelectOptions(insurancePlans[0].Id, pbId);
        System.assert(planOptions2.size() > 0 );

        ext.planID = insurancePlans[0].Id;
        planOptions = ext.getPlanOptions();
        System.assert( !planOptions.isEmpty() );
        System.assert( ext.getRenderTable() );

        Map<String, String> data = new Map<String, String>();
        String key = new List<String>( planOptions.keySet() )[0];
        //data.put('Name',  new List<String>( planOptions.get(key) )[0] );
        //data.put('Plan_Name__c', new List<String>( plans.keySet() )[0] );
        data.put('PricebookEntryId', new List<String>( planOptions.get(key).keySet() )[0] );
        data.put('InsuranceCoverage__c', 'Single');
        data.put('Quantity', '1');
        data.put('UnitPrice', '500');
        data.put('OpportunityId', opp.Id);
        OpportunityExt_FI.saveItem( JSON.Serialize(data) );

        OpportunityLineItem[] items = [SELECT Id, UnitPrice, OpportunityId, InsuranceCoverage__c FROM OpportunityLineItem WHERE OpportunityId = :opp.Id AND isInsurance__c = true];
        System.assertEquals(1, items.size() );

        //change the plan, which should delete all insurance items
        PageReference pageRef = Page.Opportunity_FinanceForm;
        pageRef.getParameters().put( 'planId', insurancePlans[1].Id );
        Test.setCurrentPageReference(pageRef);

        ext.planChanged();
        System.assertEquals(ext.planId, insurancePlans[1].Id);
        items = [SELECT Id, UnitPrice, OpportunityId, InsuranceCoverage__c FROM OpportunityLineItem WHERE OpportunityId = :opp.Id AND isInsurance__c = true];
        System.assert( ext.fiItems.isEmpty() );
        System.assertEquals( 0, items.size() );

        //add another item in
        data.clear();
        key = new List<String>( planOptions.keySet() )[0];
        //data.put('Name',  new List<String>( planOptions.get(key) )[0] );
        //data.put('Plan_Name__c', new List<String>( plans.keySet() )[1] );
        data.put('PricebookEntryId', new List<String>( planOptions.get(key).keySet() )[1] );
        data.put('InsuranceCoverage__c', 'Single');
        data.put('Quantity', '1');
        data.put('UnitPrice', '500');
        data.put('OpportunityId', opp.Id);
        OpportunityExt_FI.saveItem( JSON.Serialize(data) );

        items = [SELECT Id, UnitPrice, OpportunityId, InsuranceCoverage__c FROM OpportunityLineItem WHERE OpportunityId = :opp.Id AND isInsurance__c = true];
        System.assertEquals(1, items.size() );

        PageReference savePdfResult = ext.updateInvoiceAndReturn();
        Opportunity o = [SELECT Id, Invoice_Document_Id__c FROM Opportunity WHERE Id =:opp.Id];
        System.assert( savePdfResult != null);
        System.assert( o.Invoice_Document_Id__c != null);

        sc = new ApexPages.StandardController(o);
        ext = new OpportunityExt_FI(sc);
        System.assertEquals(ext.planId, insurancePlans[0].Id );
        items = ext.fiItems;
        System.assert( items.size() == 1);

         //now lets delete the item
        OpportunityExt_FI.deleteItem(items[0].Id);
        items = [SELECT Id, UnitPrice, OpportunityId, InsuranceCoverage__c FROM OpportunityLineItem WHERE OpportunityId = :opp.Id AND isInsurance__c = true];
        System.assert( items.isEmpty() );

        Opportunity emptyOpp = new Opportunity();
        sc = new ApexPages.StandardController(emptyOpp);
        ext = new OpportunityExt_FI(sc);

        savePdfResult = ext.updateInvoiceAndReturn();
        System.assert( savePdfResult == null );

  }

    @isTest(seeAllData=true) static void warrantyAndService_Test()
    {
        Opportunity fullOpp = OpportunityFactory.insertRetailBoatSale();
        ApexPages.StandardController sc = new ApexPages.StandardController(fullOpp);
        OpportunityExt_FI ext = new OpportunityExt_FI(sc);
        Integer origLICount = [SELECT COUNT()
                               FROM OpportunityLineItem
                               WHERE OpportunityId = :fullOpp.Id];

        OpportunityExt_FI.WarrantyAndServiceItem[] wsItems = ext.warAndServItems;
        OpportunityLineItem newLI = OpportunityExt_FI.selectWarrantyOrServiceItem(wsItems[0].PricebookEntryId, wsItems[0].OpportunityId);
        Integer liCount = [SELECT COUNT()
                          FROM OpportunityLineItem
                          WHERE OpportunityId = :fullOpp.Id];

        System.assertEquals(1, wsItems.size() );
        System.assertEquals( (origLICount+1), liCount );

        OpportunityExt_FI.removeWarrantyOrServiceItem(newLI.Id);

        liCount = [SELECT COUNT()
                FROM OpportunityLineItem
                WHERE OpportunityId = :fullOpp.Id];

        System.assertEquals( origLICount, liCount );
    }

    @isTest(seeAllData=true) static void ppsa_Test()
    {
      Opportunity fullOpp = OpportunityFactory.insertRetailBoatSale();
      Integer origLICount = [SELECT COUNT()
                               FROM OpportunityLineItem
                               WHERE OpportunityId = :fullOpp.Id];
      try {
        PricebookEntry pe = [SELECT Id
              FROM PricebookEntry
              WHERE Pricebook2Id = :fullOpp.Pricebook2Id
              AND Product2.Family = 'Bank Registration PPSA Fee'
              AND Product2.RecordType.Name = 'Fees' ];
      }
      catch(Exception e)
      {
        InventoryTestFactory factory = new InventoryTestFactory();
        factory.insertTestProducts(1, 'Fees', 'Bank Registration PPSA Fee');
      }

      ApexPages.StandardController sc = new ApexPages.StandardController(fullOpp);
      OpportunityExt_FI ext = new OpportunityExt_FI(sc);

      System.assertEquals('Standard Price Book', ext.pbName);
      System.assert( ext.ppsaFee.Id == null );
      System.assert( ext.ppsaFeePricebookEntryId != null );

      Map<String,String> data = new Map<String,String>();
      data.put('UnitPrice', '100');
      data.put('OpportunityId', fullOpp.Id);
      data.put('PricebookEntryId', ext.ppsaFee.PricebookEntryId); 

      OpportunityLineItem ppsaFee = OpportunityExt_FI.savePPSA( JSON.serialize(data) );

      Integer afterLICount = [SELECT COUNT()
                               FROM OpportunityLineItem
                               WHERE OpportunityId = :fullOpp.Id];

      System.assertEquals( afterLICount, origLICount + 1 );

      data.put('UnitPrice', '0');
      data.put('Id', ppsaFee.Id);

       OpportunityExt_FI.savePPSA( JSON.serialize(data) );

      afterLICount = [SELECT COUNT()
                      FROM OpportunityLineItem
                      WHERE OpportunityId = :fullOpp.Id];

      System.assertEquals( afterLICount, origLICount );

    }

}