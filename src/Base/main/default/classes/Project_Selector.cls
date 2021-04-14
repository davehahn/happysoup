/**
 * Created by dave on 2020-01-15.
 */

public without sharing class Project_Selector Extends Application_Selector
{
  public Project_Selector()
  {
    this.sObjectName = 'AcctSeed__Project__c';
    this.fields = new List<String>{
      'Id',
      'RecordTypeId',
      'RecordType.Name',
      'Name',
      'Job_Status__c',
      'Parking_Spot__c',
      'GMBLASERP__Warehouse__c',
      'WarehouseName__c',
      'Serial_Product__c',
      'AcctSeedERP__Work_Order_Number__c',
      'GL_Account_Variable_1__c',
      'GL_Account_Variable_1__r.Name',
      'GL_Account_Variable_2__c',
      'GL_Account_Variable_2__r.Name',
      'GL_Account_Variable_3__c',
      'GL_Account_Variable_3__r.Name',
      'Estimated_Service_Duration__c',
      'Stage__c',
      'Owner.Name',
      'Salesperson__r.Name',
      'AcctSeed__Account__r.Name',
      'AcctSeed__Account__c',
      'AcctSeed__Account__r.Boat_Specialist__c',
      'AcctSeed__Account__r.Boat_Specialist__r.Name',
      'Grand_Total__c',
      'Boat_Product__c',
      'Boat_Product__r.Name',
      'Serial_Number__c',
      'Pickup_Location__c',
      'Delivery_Date__c',
      'Service_Date__c',
      'On_Water_Orientation__c',
      'Payment_Method__c',
      'Payment_Status__c',
      'Original_ERP__c'
    };
  }

  public static List<AcctSeed__Project__c> allUnScheduledByLocation_Retail( String locationName )
  {
    String loc_string = '%' + locationName.capitalize() + '%';
    Project_Selector selector = new Project_Selector();
    selector
      .addWhere('Delivery_Date__c = null')
      .addWhere('(Pickup_Location__c LIKE \'' + loc_string + '\' OR Pickup_Location__c = null)')
      .addWhere('RecordTypeId = \'' + gcConstants.idRtProjectBoatSale + '\'' )
      .addWhere('AcctSeed__Status__c = \'Active\'')
      .addWhere('Stage__c != \'Closed Lost\'')
      .addOrderBy('Pickup_Location__c DESC');
    return selector.query();
  }

  public static List<AcctSeed__Project__c> allUnScheduledByLocation_Service_TradeIn_Manufacturing( String locationName )
  {
    String rtIds = '(\''+gcConstants.idRtProjectManufacturing +'\'';
    rtIds += ',\'' + gcConstants.idRtTradeIn + '\'';
    rtIds += ',\'' + gcConstants.idRtProjectService +'\')';
    String excludeStages = '(\'Closed Lost\',\'Repair Completed\',\'Delivered\')';
    Project_Selector selector = new Project_Selector();
    selector
      .addWhere('Service_Date__c = null')
      .addWhere('WarehouseName__c = \'' + locationName +'\'' )
      .addWhere('RecordTypeId IN ' + rtIds )
      .addWhere('AcctSeed__Status__c = \'Active\'')
      .addWhere('Stage__c NOT IN ' + excludeStages )
      .addOrderBy('WarehouseName__c DESC');
    return selector.query();
  }

  public static List<AcctSeed__Project__c> allRetailBoatSaleByLocationByPickupDateRange( String location,
                                                                                         Date startAt,
                                                                                         Date endAt,
                                                                                         Boolean excludeComplete )
  {
    String locString = '%' + location + '%';
    Project_Selector selector = new Project_Selector();
    selector
      .addWhere('RecordTypeId = \'' + gcConstants.idRtProjectBoatSale + '\'')
      .addWhere( 'Pickup_Location__c LIKE \'' + locString + '\'' )
      .addWhere('Stage__c != \'Closed Lost\'')
      .addWhere('Delivery_Date__c >= ' + toDateString( startAt ) )
      .addWhere('Delivery_Date__c <= ' + toDateString( endAt ) )
      .addChildQuery('(SELECT Id, Employee__c FROM Rigger_Jobs__r)');
    if( excludeComplete )
    {
      selector.addWhere('Job_Status__c != \'Completed\'' );
    }
    return selector.query();
  }

  public static List<AcctSeed__Project__c> allByWarehouseAndRecordTypeAndServiceDateRange( Id recordTypeId,
                                                                                           Id warehouseId,
                                                                                           Date startAt,
                                                                                           Date endAt,
                                                                                           Boolean excludeComplete )
  {
    Project_Selector selector = new Project_Selector();
    selector
      .addWhere('RecordTypeId = \'' + recordTypeId + '\'')
      .addWhere( 'GMBLASERP__Warehouse__c = \'' + warehouseId + '\'' )
      .addWhere('Stage__c != \'Closed Lost\'')
      .addWhere('Service_Date__c >= ' + toDateString( startAt ) )
      .addWhere('Service_Date__c <= ' + toDateString( endAt ) )
      .addChildQuery('(SELECT Id, Employee__c FROM Rigger_Jobs__r)');
    if( excludeComplete )
    {
      selector.addWhere('Job_Status__c != \'Completed\'' );
    }
    return selector.query();
  }

  public static List<AcctSeed__Project__c> allOpenRetailBoatSalesAvailableToReserveByGLV1AndBoatId( Id glv1Id, Id boatProductId )
  {
    Project_Selector selector = new Project_Selector();
    selector
      .addWhere( 'RecordTypeId = \'' + gcConstants.idRtProjectBoatSale + '\'')
      .addWhere( 'GL_Account_Variable_1__c = \'' + glv1Id + '\'')
      .addWhere( 'Boat_Product__c = \'' + boatProductId + '\'')
      .addWhere( 'Stage__c <> \'Delivered\'')
      .addWhere( 'Stage__c <> \'Closed Lost\'')
    .addChildQuery('(SELECT Id, AcctSeedERP__Product__r.Name, AcctSeedERP__Quantity_per_Unit__c FROM AcctSeedERP__Project_Materials__r WHERE AcctSeedERP__Product__r.AcctSeedERP__Serialized__c = true AND AcctSeedERP__Product__r.RecordType.Name <> \'Boat\')');
    return selector.query();
  }

  public static List<AcctSeed__Project__c> allByIds( Set<Id> ids )
  {
    Project_Selector selector = new Project_Selector();
    selector.addWhere( whereInClauseBuilder(
      'Id',
      (Set<String>)JSON.deserialize( JSON.serialize( ids ), Set<String>.class ) )
    );
    return selector.query();
  }

  public static List<AcctSeed__Project__c> allByIdsWithTasks( Set<Id> ids )
  {
    return new Project_Selector()
      .addChildQuery( new ProjectTask_Selector() )
      .addWhereIdIn( ids )
      .query();
  }

  public static Map<Id, AcctSeed__Project__c> mapAllById(Set<Id> ids)
  {
    return new Map<Id, AcctSeed__Project__c>([
      SELECT Id,
        AcctSeed__Status__c,
        Stage__c
      FROM AcctSeed__Project__c
      WHERE Id IN :ids
    ]);
  }
}
