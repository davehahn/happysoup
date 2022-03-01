/**
 * Created by dave on 2019-08-21.
 */

public with sharing class OpportunityToWorkOrderAndERP_Promise {

  /* JustForTesting */
  public void execute( String oppId )
  {
    new Promise( new createWorkOrderAndERP_Promise() )
            .then( new createWorkOrderLineItemAndErpTask_Promise() )
            .then( new createProductRequiredsAndMaterial_Promise() )
            .error( new OpportunityToWorkOrderAndERP_Error () )
            .done( new OpportunityToWorkOrderAndERP_Done() )
            .execute( oppId );
  }

  public void executeStepOne( String oppId )
  {
    new Promise( new createWorkOrderAndERP_Promise() )
      .done( new OpportunityToWorkOrderAndERP_Done() )
      .execute( oppId );
  }

  public void executeStepTwo( String workOrderId )
  {
    new Promise( new createWorkOrderLineItemAndErpTask_Promise() )
      .done( new OpportunityToWorkOrderAndERP_Done() )
      .execute( workOrderId );
  }

  public void executeStepThree( String workOrderLineItemId )
  {
    new Promise( new createProductRequiredsAndMaterial_Promise() )
      .done( new OpportunityToWorkOrderAndERP_Done() )
      .execute( workOrderLineItemId );
  }
  /* /just4Testing */


  /* Static methods to make testing easier */
  public static Id stepOne( Id oppId )
  {
    TriggerBase.bypass('WorkOrder');
    Opportunity opp = Opportunity_Selector.allByIds( new Set<Id>{ (Id)oppId } )[0];
    WorkOrder wo = WorkOrder_Service.createFromOppy( opp );
    System.debug('Created WO');
    insert wo;
    System.debug('InsertedWorkOrder');
    System.debug(wo);
    Project_Service.createFromOpportunityAndWorkOrder( opp, wo );
    TriggerBase.clearBypass('WorkOrder');
    return wo.Id;
  }

  public static Id stepTwo( Id workOrderId)
  {
    TriggerBase.bypass('WorkOrderLineItem');
    WorkOrderLineItem woli = WorkOrderLineItem_Service.createForRetailBoatSale( (Id)workOrderId );
    AcctSeed__Project_Task__c task = ProjectTask_Service.newFromWorkOrderLineItemIds( new Set<Id>{ woli.Id })[0];
    woli.ERP_Order_Task__c = task.Id;
    update woli;
    TriggerBase.clearBypass('WorkOrderLineItem');
    return woli.Id;
  }

  public static void stepThree( Id workOrderLineItemId )
  {
    WorkOrderLineItem woli = WorkOrderLineItem_Selector.selectById( workOrderLineItemId );
    Map<String, List<OpportunityLineItem>> olis_map = step3_fetchAndGroupOpportunityLineItems( woli.WorkOrder.Opportunity__c );
    //handle standard items - create PR's and Materials
    if( olis_map.get('standardItems').size() > 0 )
    {
      step3_handleStandardItems( olis_map.get('standardItems'), woli );
    }
    List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
    //Handle Insurance Items - Create a new ERP Order task and add materials
    if( olis_map.get('insuranceItems').size() > 0 )
    {
      materials.addAll( step3_handleNonStandardItems( olis_map.get('insuranceItems'),
                                                      woli.WorkOrder.ERP_Order__c,
                                                      'Insurance Items',
                                                      true ) );

    }
    //Handle Protection and Services Items - Create a new ERP Order task and add materials
    if( olis_map.get('protectionAndServiceItems').size() > 0 )
    {
      materials.addAll( step3_handleNonStandardItems( olis_map.get('protectionAndServiceItems'),
                                                      woli.WorkOrder.ERP_Order__c,
                                                      'Protection and Services',
                                                      false ) );
    }
    if( materials.size() > 0 )
      insert materials;
  }

  private static Map<String, List<OpportunityLineItem>> step3_fetchAndGroupOpportunityLineItems( Id oppId )
  {
    Id insuranceRT = LGND_Utilities.recordTypeIdFromName('Product2', 'Insurance');
    Id p_and_s_RT = LGND_Utilities.recordTypeIdFromName('Product2', 'Protection and Services');
    Map<String, List<OpportunityLineItem>> result = new Map<String, List<OpportunityLineItem>>{
      'insuranceItems' => new List<OpportunityLineItem>(),
      'protectionAndServiceItems' => new List<OpportunityLineItem>(),
      'standardItems' => new List<OpportunityLineItem>()
    };
    for( OpportunityLineItem oli : OpportunityLineItem_Selector.selectAllByOpportunityId( oppId ) )
    {
      if( oli.Product2.RecordTypeId == insuranceRT )
        result.get('insuranceItems').add( oli );
      else if( oli.Product2.RecordTypeId == p_and_s_RT &&
        oli.Product2.Family == 'Extended Warranty' )
        result.get('protectionAndServiceItems').add( oli );
      else
        result.get('standardItems').add( oli );
    }
    return result;
  }

  private static void step3_handleStandardItems( List<OpportunityLineItem> olis, WorkOrderLineItem woli )
  {
    TriggerBase.bypass('ProductRequired');
    Map<Integer, ProductRequired> prMap = new Map<Integer, ProductRequired>();
    Map<Integer, AcctSeedERP__Material__c> matMap = new Map<Integer, AcctSeedERP__Material__c>();
    for( Integer i=0; i<olis.size(); i++ )
    {
      prMap.put( i, ProductRequired_Service.buildFromWorkOrderLineItemId_and_OpportunityLineItem( woli.Id,
                                                                                                  olis[i]
                                                                                                ));
      matMap.put( i, Material_Service.buildFromOpportunityLineItem( olis[i],
                                                                    woli.WorkOrder.ERP_Order__c,
                                                                    woli.ERP_Order_Task__c ) );
    }
    insert matMap.values();
    for( Integer i : prMap.keySet() )
    {
      prMap.get(i).Material__c = matMap.get(i).Id;
    }
    insert prMap.values();
    TriggerBase.clearBypass('ProductRequired');
  }

  private static List<AcctSeedERP__Material__c> step3_handleNonStandardItems( List<OpportunityLineItem> olis,
                                                                            Id erpId,
                                                                            String taskName,
                                                                            Boolean isInsurance )
  {
    List<AcctSeedERP__Material__c> mats = new List<AcctSeedERP__Material__c>();
    AcctSeed__Project_Task__c insuranceTask = new AcctSeed__Project_Task__c(
      Name = taskName,
      DisplayOnCustomerInvoice__c = true,
      IsInsurance__c = isInsurance,
      AcctSeed__Project__c = erpId
    );
    insert insuranceTask;
    for( OpportunityLineItem oli : olis )
    {
      mats.add( Material_Service.buildFromOpportunityLineItem( oli,
                                                               erpId,
                                                               insuranceTask.Id ) );
    }
    return mats;
  }

  /* DEFERRED CLASSES */

  public class createWorkOrderAndERP_Promise implements Promise.Deferred {
    private String workOrderId;
    public Object resolve( Object oppId )
    {
      workOrderId = OpportunityToWorkOrderAndERP_Promise.stepOne( (Id)oppId );
      return workOrderId;
    }
  }

  public class createWorkOrderLineItemAndErpTask_Promise implements Promise.Deferred
  {
    private String workOrderLineItemId;
    public Object resolve( Object woId )
    {
      workOrderLineItemId = OpportunityToWorkOrderAndERP_Promise.stepTwo( (Id)woId );
      return workOrderLineItemId;
    }
  }

  public class createProductRequiredsAndMaterial_Promise implements Promise.Deferred
  {

    public Object resolve( Object woliId )
    {
      OpportunityToWorkOrderAndERP_Promise.stepThree( (Id)woliId );
      return null;
    }
  }

  /* HANDLER CLASSES */

  public class OpportunityToWorkOrderAndERP_Done implements Promise.Done
  {
    private String completed;

    public OpportunityToWorkOrderAndERP_Done(){}

    public void done( Object incomingObject )
    {
      completed = 'completed';
    }
  }

  public class OpportunityToWorkOrderAndERP_Error implements Promise.Error
  {
    private String errorMessage;
    public Object error( Exception e )
    {
      System.debug( 'OpportunityToWorkOrderAndERP received the following exception ' + e.getMessage() + '\n\n' + e.getStackTraceString() );
      this.errorMessage = e.getMessage();
      return e;
    }
  }

}