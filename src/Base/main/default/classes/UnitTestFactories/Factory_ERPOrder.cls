@isTest
public class Factory_ERPOrder {

  public static AcctSeed__Project__c createWarrantyERP( Account acct, Id serialId, Integer numOfParts )
  {
    AcctSeed__Project__c erp = buildERP( acct, serialId, gcConstants.idRtProjectWarranty );
    Boolean origTrig = gcProject.disableTrigger;
    //gcProject.disableTrigger = true;
    insert erp;
    //gcProject.disableTrigger = origTrig;
    AcctSeed__Project_Task__c task = buildProjectTask( erp.Id, 'Warranty Recoverable' );
    insert task;
    InventoryTestFactory itf = new InventoryTestFactory();
    Product2[] prods = itf.buildTestProducts( numOfParts, 'Part' );
    origTrig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert prods;
    gcProduct.disableTrigger = origTrig;
    AcctSeedERP__Material__c[] mats = new List<AcctSeedERP__Material__c>();
    for( Product2 p : prods )
    {
      mats.add( buildMaterial( erp.Id, task.Id, p.Id) );
    }
    insert mats;
    return erp;
  }

  public static AcctSeed__Project__c[] createPartnerBoatSales( Account acct, Product2[] prods, String[] stages )
  {
    AcctSeed__Project__c[] erps = new List<AcctSeed__Project__c>();
    for( String stage : stages )
    {
      AcctSeed__Project__c erp = buildERP( acct, null, gcConstants.idRtProjectPartnerBoatSale );
      erp.Stage__c = stage;
      erps.add( erp );
    }
    Boolean origTrig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    insert erps;
    gcProject.disableTrigger = origTrig;
    Map<Id, AcctSeed__Project_Task__c> erpId_task_map = new  Map<Id, AcctSeed__Project_Task__c>();
    for( AcctSeed__Project__c erp :erps )
    {
      erpId_task_map.put( erp.Id, buildProjectTask( erp.Id, 'Dealer Order' ) );
    }
    insert erpId_task_map.values();
    AcctSeedERP__Material__c[] mats = new List<AcctSeedERP__Material__c>();
    for( AcctSeed__Project__c erp :erps )
    {
      for(Product2 p : prods )
      {
        mats.add( buildMaterial( erp.Id, erpId_task_map.get( erp.Id ).Id, p.Id) );
      }
    }
    insert mats;
    return erps;
  }

  public static List<AcctSeed__Project__c> createPartnerBoatSales(
    Account acct,
    List<GMBLASERP__Serial_Number__c> serials
  )
  {
    Map<Id,AcctSeed__Project__c> serialId_erp_map = new Map<Id, AcctSeed__Project__c>();
    for( GMBLASERP__Serial_Number__c serial : serials )
    {
      serialId_erp_map.put( serial.Id,  buildERP( acct, serial.Id, gcConstants.idRtProjectPartnerBoatSale ) );
    }
    Boolean origTrig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    insert serialId_erp_map.values();
    gcProject.disableTrigger = origTrig;
    Map<Id, AcctSeed__Project_Task__c> erpId_task_map = new Map<Id, AcctSeed__Project_Task__c>();
    for( AcctSeed__Project__c erp : serialId_erp_map.values() )
    {
      erpId_task_map.put( erp.Id, buildProjectTask( erp.Id, 'Dealer Order' ) );
    }
    insert erpId_task_map.values();
    List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
    for( GMBLASERP__Serial_Number__c serial : serials )
    {
      Id erpId = serialId_erp_map.get(serial.Id).Id;
      AcctSeedERP__Material__c mat = buildMaterial( erpId, erpId_task_map.get( erpId ).Id, serial.GMBLASERP__Product__c);
      mat.GMBLASERP__Serial_Number__c = serial.Id;
      materials.add( mat );
    }
    origTrig = gcMaterial.disableTrigger;
    gcMaterial.disableTrigger = true;
    insert materials;
    gcMaterial.disableTrigger = origTrig;
    return serialId_erp_map.values();
  }

  public static AcctSeed__Project__c[] createPartnerBoatSales(
    Account acct,
    Product2[] prods,
    List<AcctSeed__Project__c> linkedRetailERPs )
  {
    AcctSeed__Project__c[] erps = new List<AcctSeed__Project__c>();
    for( AcctSeed__Project__c retailERP : linkedRetailERPs )
    {
      AcctSeed__Project__c erp = buildERP( acct, null, gcConstants.idRtProjectPartnerBoatSale );
      erp.Stage__c = 'Draft';
      erp.Retail_ERP__c = retailERP.Id;
      erps.add( erp );
    }
    Boolean origTrig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    insert erps;
    gcProject.disableTrigger = origTrig;
    Map<Id, AcctSeed__Project_Task__c> erpId_task_map = new  Map<Id, AcctSeed__Project_Task__c>();
    for( AcctSeed__Project__c erp :erps )
    {
      erpId_task_map.put( erp.Id, buildProjectTask( erp.Id, 'Dealer Order' ) );
    }
    insert erpId_task_map.values();
    AcctSeedERP__Material__c[] mats = new List<AcctSeedERP__Material__c>();
    for( AcctSeed__Project__c erp :erps )
    {
      for(Product2 p : prods )
      {
        mats.add( buildMaterial( erp.Id, erpId_task_map.get( erp.Id ).Id, p.Id) );
      }
    }
    origTrig = gcMaterial.disableTrigger;
    gcMaterial.disableTrigger = true;
    insert mats;
    gcMaterial.disableTrigger = origTrig;
    return erps;
  }

  public static AcctSeed__Project__c[] createPartnerBoatSales( Account acct, Product2[] prods, Integer count, Decimal boatPrice )
  {
    AcctSeed__Project__c[] erps = new List<AcctSeed__Project__c>();
    for( Integer i=0; i<count; i++ )
    {
      AcctSeed__Project__c erp = buildERP( acct, null, gcConstants.idRtProjectPartnerBoatSale );
      erp.Stage__c = 'Draft';
      erps.add( erp );
    }
    Boolean origTrig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    insert erps;
    gcProject.disableTrigger = origTrig;
    Map<Id, AcctSeed__Project_Task__c> erpId_task_map = new  Map<Id, AcctSeed__Project_Task__c>();
    for( AcctSeed__Project__c erp :erps )
    {
      erpId_task_map.put( erp.Id, buildProjectTask( erp.Id, 'Dealer Order' ) );
    }
    insert erpId_task_map.values();
    AcctSeedERP__Material__c[] mats = new List<AcctSeedERP__Material__c>();
    for( AcctSeed__Project__c erp :erps )
    {
      for(Product2 p : prods )
      {
        mats.add( buildMaterial( erp.Id, erpId_task_map.get( erp.Id ).Id, p.Id, boatPrice) );
      }
    }
    origTrig = gcMaterial.disableTrigger;
    gcMaterial.disableTrigger = true;
    insert mats;
    gcMaterial.disableTrigger = origTrig;
    return erps;
  }

  public static AcctSeed__Project__c[] createPartnerBoatSales( Account acct, Product2[] prods, Integer count )
  {
    AcctSeed__Project__c[] erps = new List<AcctSeed__Project__c>();
    for( Integer i=0; i<count; i++ )
    {
      AcctSeed__Project__c erp = buildERP( acct, null, gcConstants.idRtProjectPartnerBoatSale );
      erp.Stage__c = 'Draft';
      erps.add( erp );
    }
    Boolean origTrig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    insert erps;
    gcProject.disableTrigger = origTrig;
    Map<Id, AcctSeed__Project_Task__c> erpId_task_map = new  Map<Id, AcctSeed__Project_Task__c>();
    for( AcctSeed__Project__c erp :erps )
    {
      erpId_task_map.put( erp.Id, buildProjectTask( erp.Id, 'Dealer Order' ) );
    }
    insert erpId_task_map.values();
    AcctSeedERP__Material__c[] mats = new List<AcctSeedERP__Material__c>();
    for( AcctSeed__Project__c erp :erps )
    {
      for(Product2 p : prods )
      {
        mats.add( buildMaterial( erp.Id, erpId_task_map.get( erp.Id ).Id, p.Id) );
      }
    }
    origTrig = gcMaterial.disableTrigger;
    gcMaterial.disableTrigger = true;
    insert mats;
    gcMaterial.disableTrigger = origTrig;
    return erps;
  }

  public static AcctSeed__Project__c[] createPartnerBoatSales(
    Account acct,
    PricebookEntry[] pbes,
    Integer count )
  {
    AcctSeed__Project__c[] erps = new List<AcctSeed__Project__c>();
    for( Integer i=0; i<count; i++ )
    {
      AcctSeed__Project__c erp = buildERP( acct, null, gcConstants.idRtProjectPartnerBoatSale );
      erp.Stage__c = 'Draft';
      erps.add( erp );
    }
    Boolean origTrig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    insert erps;
    gcProject.disableTrigger = origTrig;
    Map<Id, AcctSeed__Project_Task__c> erpId_task_map = new  Map<Id, AcctSeed__Project_Task__c>();
    for( AcctSeed__Project__c erp :erps )
    {
      erpId_task_map.put( erp.Id, buildProjectTask( erp.Id, 'Dealer Order' ) );
    }
    insert erpId_task_map.values();
    AcctSeedERP__Material__c[] mats = new List<AcctSeedERP__Material__c>();
    for( AcctSeed__Project__c erp :erps )
    {
      for(PricebookEntry pbe : pbes )
      {
        mats.add( buildMaterial( erp.Id, erpId_task_map.get( erp.Id ).Id, pbe) );
      }
    }
    origTrig = gcMaterial.disableTrigger;
    gcMaterial.disableTrigger = true;
    insert mats;
    gcMaterial.disableTrigger = origTrig;
    return erps;
  }

  public static AcctSeed__Project__c createPartnerBoatSale( Account acct, GMBLASERP__Serial_Number__c serial )
  {
    AcctSeed__Project__c erp = buildERP( acct, serial.Id, gcConstants.idRtProjectPartnerBoatSale );
    Boolean origTrig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    insert erp;
    gcProject.disableTrigger = origTrig;
    AcctSeed__Project_Task__c task = buildProjectTask( erp.Id, 'Dealer Order' );
    insert task;
    AcctSeedERP__Material__c mat = buildMaterial( erp.Id, task.Id, serial.GMBLASERP__Product__c);
    mat.GMBLASERP__Serial_Number__c = serial.Id;
    insert mat;
    return erp;
  }

  public static AcctSeed__Project__c insertRetailBoatSale( Account acct,
                                                           AcctSeedERP__Warehouse__c warehouse,
                                                           DateTime deliveryDate,
                                                           GMBLASERP__Serial_Number__c boatSerial )
  {
    AcctSeed__Project__c erp = buildERP( acct,
                                         boatSerial.Id,
                                         gcConstants.idRtProjectBoatSale );
    erp.GMBLASERP__Warehouse__c = warehouse.Id;
    erp.Boat_Product__c = boatSerial.GMBLASERP__Product__c;
    erp.Delivery_Date__c = deliveryDate;
    erp.Pickup_Location__c = findPickupLocationFromWarehouse( warehouse.Name );
    insert erp;
    AcctSeed__Project_Task__c task = Factory_ERPOrderTask.buildRetailSaleTask( erp.Id );
    insert task;
    AcctSeedERP__Material__c mat = buildMaterial( erp.Id, task.Id, boatSerial.GMBLASERP__Product__c);
    mat.GMBLASERP__Serial_Number__c = boatSerial.Id;
    mat.GMBLASERP__Total_Price__c = mat.AcctSeedERP__Quantity_Per_Unit__c * mat.GMBLASERP__Unit_Price__c;
    insert mat;
    return erp;
  }

  public static AcctSeed__Project__c insertRetailBoatSale( Account acct,
                                                           AcctSeedERP__Warehouse__c warehouse,
                                                           DateTime deliveryDate,
                                                           GMBLASERP__Serial_Number__c boatSerial,
                                                           GMBLASERP__Serial_Number__c motorSerial)
  {
    System.debug(warehouse);
    AcctSeed__Project__c erp = buildERP( acct,
                                         boatSerial.Id,
                                         gcConstants.idRtProjectBoatSale );
    erp.GMBLASERP__Warehouse__c = warehouse.Id;
    erp.Boat_Product__c = boatSerial.GMBLASERP__Product__c;
    erp.Delivery_Date__c = deliveryDate;
    erp.Pickup_Location__c = findPickupLocationFromWarehouse( warehouse.Name );
    insert erp;
    AcctSeed__Project_Task__c task = buildProjectTask( erp.Id, 'Boat Sale' );
    insert task;
    List<AcctSeedERP__Material__c> mats = new List<AcctSeedERP__Material__c>();
    for( GMBLASERP__Serial_Number__c serial : new List<GMBLASERP__Serial_Number__c>{ boatSerial, motorSerial } )
    {
      AcctSeedERP__Material__c mat = buildMaterial( erp.Id, task.Id, serial.GMBLASERP__Product__c);
      mat.GMBLASERP__Serial_Number__c = serial.Id;
      mats.add( mat );
    }
    insert mats;
    return erp;
  }

  public static AcctSeed__Project__c insertPartnerPartsOrder(
    Account dealer,
    Id warehouseId )
  {
    AcctSeed__Project__c erp = buildERP(
      dealer,
      null,
      new Application_RecordType().getERPOrderRecordTypes().getPartnerPartsOrderId()
    );
    erp.GMBLASERP__Warehouse__c = warehouseId;
    insert erp;
    return erp;
  }

  public static AcctSeed__Project__c[] insertRetailBoatSales( Account acct,
                                                              AcctSeedERP__Warehouse__c warehouse,
                                                              DateTime deliveryDate,
                                                              GMBLASERP__Serial_Number__c[] boatSerials)
  {
    Map<Id, AcctSeed__Project__c> serial_erp_map = new Map<Id, AcctSeed__Project__c>();
    for( GMBLASERP__Serial_Number__c sn : boatSerials )
    {
      AcctSeed__Project__c erp = buildERP( acct,
                                         sn.Id,
                                         gcConstants.idRtProjectBoatSale );
      erp.GMBLASERP__Warehouse__c = warehouse.Id;
      erp.Boat_Product__c = sn.GMBLASERP__Product__c;
      erp.Delivery_Date__c = deliveryDate;
      erp.Pickup_Location__c = findPickupLocationFromWarehouse( warehouse.Name );
      serial_erp_map.put( sn.Id, erp );
    }
    //Boolean origTrig = gcProject.disableTrigger;
    //gcProject.disableTrigger = true;
    insert serial_erp_map.values();
    //gcProject.disableTrigger = origTrig;

    Map<Id, AcctSeed__Project_Task__c> serial_task_map = new Map<Id, AcctSeed__Project_Task__c>();
    for( GMBLASERP__Serial_Number__c sn : boatSerials )
    {
      serial_task_map.put( sn.Id, buildProjectTask( serial_erp_map.get(sn.Id).Id, 'Boat Sale' ) );
    }
    insert serial_task_map.values();

    AcctSeedERP__Material__c[] mats = new List<AcctSeedERP__Material__c>();
    for( GMBLASERP__Serial_Number__c sn : boatSerials )
    {
      AcctSeedERP__Material__c mat = buildMaterial( serial_erp_map.get(sn.Id).Id,
                                                    serial_task_map.get(sn.Id).Id,
                                                    sn.GMBLASERP__Product__c);
      mat.GMBLASERP__Serial_Number__c = sn.Id;
      mats.add( mat );
    }
    insert mats;
    return serial_erp_map.values();
  }

  public static AcctSeed__Project__c[] insertServiceOrders( Account acct,
                                                            AcctSeedERP__Warehouse__c warehouse,
                                                            DateTime serviceDate,
                                                            GMBLASERP__Serial_Number__c[] boatSerials )
  {
    AcctSeed__Project__c[] erps = new List<AcctSeed__Project__c>();
    for( GMBLASERP__Serial_Number__c sn : boatSerials)
    {
      AcctSeed__Project__c erp = buildERP( acct,
                                           sn.Id,
                                           gcConstants.idRtProjectService );
      erp.GMBLASERP__Warehouse__c = warehouse.Id;
      erp.Service_Date__c = serviceDate;
      //erp.Pickup_Location__c = findPickupLocationFromWarehouse( warehouse.Name );
      erps.add( erp );
    }
    insert erps;
    return erps;
  }

  private static String[] pickupLocations;
  private static String findPickupLocationFromWarehouse( String whName )
  {
    String result = '';
    if( pickupLocations == null )
      pickupLocations = LGND_Utilities.getPicklistValues( 'AcctSeed__Project__c', 'Pickup_Location__c');
    for( String pl : pickupLocations )
    {
      if( pl.toLowerCase().contains( whName.toLowerCase() ) )
      {
        result =  pl;
        break;
      }
    }
    return result;
  }

  public static AcctSeed__Project__c buildERP( Account acct, Id serialId, Id recordTypeId )
  {
    String projectName;
    try {
      projectName = acct.Name.trim();
    }
    catch(Exception e){
      projectName = ( acct.FirstName + '_' + acct.LastName ).trim();
    }
    return new AcctSeed__Project__c (
      AcctSeed__Status__c = 'Active',
      Name = projectName,
      RecordTypeId = recordTypeId,
      AcctSeed__Account__c = acct.Id,
      Serial_Number__c = serialId,
      Customer_Notes__c = 'Test notes'
    );
  }

  public static AcctSeed__Project_Task__c buildProjectTask( Id erpId, String taskName )
  {
    return Factory_ERPOrderTask.buildProjectTask( erpId, taskName );
  }

  public static AcctSeedERP__Material__c[] buildMaterials(
    Id erpId,
    Id taskId,
    Product2[] products )
  {
    return Factory_Material.buildMaterials(
      erpId,
      taskId,
      products
    );
  }

  public static AcctSeedERP__Material__c buildMaterial(
    Id erpId,
    Id taskId,
    Id prodId )
  {
    return Factory_Material.buildMaterial(
      erpId,
      taskId,
      prodId
    );
  }
  public static AcctSeedERP__Material__c buildMaterial(
    Id erpId,
    Id taskId,
    Id prodId,
    Decimal boatPrice)
  {
    return Factory_Material.buildMaterial(
      erpId,
      taskId,
      prodId,
      boatPrice
    );
  }


  public static AcctSeedERP__Material__c buildMaterial(
    Id erpId,
    Id taskId,
    PricebookEntry pbe )
  {
    return Factory_Material.buildMaterial(
      erpId,
      taskId,
      pbe
    );
  }


}