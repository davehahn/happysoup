/**
 * Created by dave on 2020-01-30.
 */

@IsTest
private class CommissionLineItem2_Service_T
{
  static Integer partsCount = 4;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    List<Product2> parts = Factory_Product.createNonSerializedProducts('Part', 'Hardware', partsCount );
    Factory_PricebookEntry.createAllDefaultEntriesEntries( parts, 100 );
    List<AcctSeed__Project__c> projects = new List<AcctSeed__Project__c>();
    for( Account customer : Factory_Account.insertCustomerAccounts(4) )
    {
      AcctSeed__Project__c project = Factory_ERPOrder.buildERP( customer, null, gcConstants.idRtProjectBoatSale );
      project.GMBLASERP__Pricebook__c = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
      projects.add( project );
    }
    insert projects;
    List<AcctSeed__Project_Task__c> tasks = new List<AcctSeed__Project_Task__c>();
    for( AcctSeed__Project__c project : projects )
    {
      tasks.add( Factory_ERPOrderTask.buildRetailSaleTask( project.Id ) );
    }
    Boolean orig = gcProjectTask.ignoreCommissions;
    gcProjectTask.ignoreCommissions = true;
    insert tasks;
    gcProjectTask.ignoreCommissions = orig;
    List<CommissionRecord2__c> commissionRecords = new List<CommissionRecord2__c>();
    List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
    for( AcctSeed__Project_Task__c task : tasks )
    {
      commissionRecords.add( new CommissionRecord2__c(
        Project_Task__c = task.Id
      ));
      for( Product2 p : parts )
      {
        materials.add( new AcctSeedERP__Material__c(
          AcctSeedERP__Project_Task__c = task.Id,
          AcctSeedERP__Quantity_Per_Unit__c = 1,
          GMBLASERP__Unit_Price__c = 200,
          AcctSeedERP__Product__c = p.Id,
          AcctSeedERP__Project__c = task.AcctSeed__Project__c
        ));
      }
    }
    insert commissionRecords;
    insert materials;
  }


  @IsTest
  static void saveRecords_New_Test()
  {
    List<AcctSeedERP__Material__c> materials = [ SELECT Id,
                                                        AcctSeedERP__Project_Task__c,
                                                        AcctSeedERP__Product__c,
                                                        AcctSeedERP__Quantity_Per_Unit__c,
                                                        GMBLASERP__Unit_Price__c
                                                  FROM AcctSeedERP__Material__c ];
    System.debug( 'Material Size = ' + materials.size());
    Test.startTest();
    CommissionLineItem2_Service service = new CommissionLineItem2_Service();
    service.addMaterials( materials );
    service.saveRecords();
    Test.stopTest();

    List<CommissionRecord2__c> commissionRecords = [ SELECT Id,
                                                    ( SELECT Id FROM Commission_Line_Items__r )
                                                    FROM CommissionRecord2__c ];
    System.debug( commissionRecords.size() );
    for( CommissionRecord2__c cr : commissionRecords )
    {
      System.assertEquals( partsCount, cr.Commission_Line_Items__r.size() );
    }
  }

  @IsTest
  static void saveRecords_Update_Test()
  {
    AcctSeedERP__Material__c material =  [ SELECT Id,
                                                  AcctSeedERP__Project__c,
                                                  AcctSeedERP__Project_Task__c,
                                                  AcctSeedERP__Product__c,
                                                  AcctSeedERP__Quantity_Per_Unit__c,
                                                  GMBLASERP__Unit_Price__c
                                          FROM AcctSeedERP__Material__c
                                          LIMIT 1];
    //lets make sure our data is correct
    CommissionLineItem2__c[] clis = [SELECT Id, Sale_Price__c FROM CommissionLineItem2__c WHERE Material__c = :material.Id];
    System.assertEquals( 1, clis.size() );
    System.assertEquals( material.GMBLASERP__Unit_Price__c, clis[0].Sale_Price__c );

    material.GMBLASERP__Unit_Price__c = 1000;
    update material;

    Test.startTest();
    CommissionLineItem2_Service service = new CommissionLineItem2_Service();
    service.addMaterials( new List<AcctSeedERP__Material__c>{ material } );
    service.saveRecords();
    Test.stopTest();

    clis = [SELECT Id, Sale_Price__c FROM CommissionLineItem2__c WHERE Material__c = :material.Id];
    System.assertEquals( 1, clis.size() );
    System.assertEquals( 1000, clis[0].Sale_Price__c );
  }
}