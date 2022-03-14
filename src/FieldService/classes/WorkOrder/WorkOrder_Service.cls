/**
 * Created by dave on 2019-08-06.
 */

public with sharing class WorkOrder_Service {

  private Id recordId;

  private WorkOrder record {
    get {
      if( record == null )
      {
        record = WorkOrder_Selector.getEverythingById( this.recordId );
        populateLineItems();
        populateServiceAppointments();
      }
      return record;
    }
    private set;
  }

  private Map<Id, WorkOrderLineItem> lineItems {
    get {
      if( lineItems == null )
      {
        lineItems = WorkOrderLineItem_Selector.selectAllByWorkOrderId_AsMap( this.recordId );
      }
      return lineItems;
    }
    private set;
  }

  private List<ProductRequired> requiredProducts {
    get {
      if( requiredProducts == null )
      {
        requiredProducts = ProductRequired_Selector.selectAllByWorkOrderLineIds( this.lineItems.keySet() );
      }
      return requiredProducts;
    }
    private set;
  }

  private Map<Id, ServiceAppointment> serviceAppointments {
    get {
      if( serviceAppointments == null )
      {
        serviceAppointments = ServiceAppointment_Selector.allByWorkOrderId_asMAp( this.recordId );
      }
      return serviceAppointments;
    }
    private set;
  }

  private List<AssignedResource> assignedResources {
    get {
      if( assignedResources == null )
      {
        if( this.serviceAppointments.size() == 0 )
        {
          assignedResources = new List<AssignedResource>();
        }
        else
        {
          assignedResources =
            AssignedResource_Selector.allByServiceAppointmentIds(
              this.serviceAppointments.keySet()
            );
        }
      }
      return assignedResources;
    }
    private set;
  }

  private Schema.Location pickAndPackLocation {
    get {
      if( pickAndPackLocation == null )
      {
        List<Schema.Location> ppLocs = Location_Selector.getSitePickAndPack( this.record.Location.ParentLocationId );
        pickAndPackLocation = Location_Service.getWorkOrderPickAndPackLocation( this.recordId, ppLocs[0].Id );
      }
      return pickAndPackLocation;
    }
    private set;
  }

  private static Id retailSaleRecordType {
    get {
      if( retailSaleRecordType == null ) {
        retailSaleRecordType = findWoRecordType('Retail Sale');
      }
      return retailSaleRecordType;
    }
    set{}
  }

  private static Id partnerSaleRecordType {
    get {
      if( partnerSaleRecordType == null ) {
        partnerSaleRecordType = findWoRecordType('Partner Sale');
      }
      return partnerSaleRecordType;
    }
    set{}
  }

  public WorkOrder_Service( Id recordId )
  {
    this.recordId = recordId;
  }

  public WorkOrder getRecord()
  {
    return this.record;
  }

  public List<WorkOrderLineItem> getLineItems()
  {
    return this.lineItems.values();
  }

  public List<ProductRequired> getRequiredProducts()
  {
    return this.requiredProducts;
  }

  public List<ProductRequired> getRequiredProductsForPickAndPack()
  {
    List<ProductRequired> result = new List<ProductRequired>();
    for( ProductRequired pr : this.requiredProducts )
    {
      if( !pr.IsPickAndPackComplete__c  || !pr.IsHandOutComplete__c )
        result.add( pr );
    }
    return result;
  }

  public List<ServiceAppointment> getServiceAppointments()
  {
    return this.serviceAppointments.values();
  }

  public List<AssignedResource> getAssignedResources()
  {
    return this.assignedResources;
  }

  public Schema.Location getLocation()
  {
    return this.record.Location;
  }

  public Schema.Location getPickAndPackLocation()
  {
    return this.pickAndPackLocation;
  }

  public static WorkOrder createFromOppy( Opportunity opp )
  {
    return new WorkOrder(
      Opportunity__c = opp.Id,
      Pricebook2Id = opp.Pricebook2Id,
      AccountId = opp.AccountId,
      RecordTypeId = retailSaleRecordType,
      Status = 'New',
      Subject = 'Retail Sale - ' + opp.Name,
      LocationId = findLocation( opp.Warehouse__c )
    );
  }

  public static WorkOrder newFromPartnerBoatSaleERP( AcctSeed__Project__c erp )
  {
    return new WorkOrder(
      Pricebook2Id = erp.GMBLASERP__Pricebook__c,
      AccountId = erp.AcctSeed__Account__c,
      ERP_Order__c = erp.Id,
      Status = 'New',
      Subject = 'Partner Sale - ' + erp.Name,
      RecordTypeId = partnerSaleRecordType,
      LocationId = findLocation( erp.GMBLASERP__Warehouse__c )
    );
  }

  /*
    this will only create Work Orders IF the ERP is
    a partner boat sale.  This should only be called
    from DealerOrder_Ext.createERPs()
  */
  public static void createFromPartnerBoatSaleErpIds( Set<Id> erpIds )
  {
    new ERPOrder_PartnerBoatSaleToWO_Promise().execute( erpIds );
  }

  private static Id findWoRecordType(String rtName)
  {
    return Schema.getGlobalDescribe()
      .get( 'WorkOrder' )
      .getDescribe()
      .getRecordTypeInfosByName()
      .get( rtName )
      .getRecordTypeId();
  }

  private static Id findLocation( Id warehouseId )
  {
    if( warehouseId != null )
    {
      try {
        return [ SELECT Id FROM Location WHERE Warehouse__c = : warehouseId ].Id;
      }
      catch( Exception e )
      {
        return null;
      }
    }
    return null;
  }

  private void populateLineItems()
  {
    this.lineItems = new Map<Id, WorkOrderLineItem>();
    for( WorkOrderLineItem woli : this.record.WorkOrderLineItems )
    {
      this.lineItems.put( woli.Id, woli );
    }
  }

  private void populateServiceAppointments()
  {
    this.serviceAppointments = new Map<Id, ServiceAppointment>();
    for( ServiceAppointment sa : this.record.ServiceAppointments )
    {
      this.serviceAppointments.put( sa.Id, sa );
    }
  }






}