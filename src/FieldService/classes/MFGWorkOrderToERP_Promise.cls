/**
 * Created by Legend on 16/6/21.
 */

public with sharing class MFGWorkOrderToERP_Promise {

    public void execute( Set<Id> woIds )
    {
        new Promise( new createMFGERP_Promise() )
                .then( new createErpTask_Promise() )
                .then( new createMaterial_Promise() )
                .error( new WorkOrderAndERP_Error () )
                .done( new WorkOrderAndERP_Done() )
                .execute( woIds );
    }

    public void executeStepOne( Set<Id> woIds )
    {
        new Promise( new createMFGERP_Promise() )
                .done( new WorkOrderAndERP_Done() )
                .execute( woIds );
    }

    public void executeStepTwo( Set<Id> woIds )
    {
        new Promise( new createErpTask_Promise() )
                .done( new WorkOrderAndERP_Done() )
                .execute( woIds );
    }

    public void executeStepThree( Set<Id> woliIds )
    {
        new Promise( new createMaterial_Promise() )
                .done( new WorkOrderAndERP_Done() )
                .execute( woliIds );
    }

    public static Set<Id> stepOne( Set<Id> woIds )
    {
        System.debug('Step One for MFG');
        Map<Id, AcctSeed__Project__c> woId_ERP_Map = new Map<Id, AcctSeed__Project__c>();
        List<WorkOrder> workOrders = WorkOrder_Selector.selectAllWithOutERPOrders_ByIds( woIds );
        Map<Id, WorkOrder> WO_Map = new Map<Id, WorkOrder>();
        for( WorkOrder wo : workOrders ) {
            WO_Map.put(wo.Id, wo);
        }
        for( WorkOrder wo : workOrders ) {
            woId_ERP_Map.put(wo.Id, Project_Service.constructMFGFromWorkOrder(wo));
        }
            insert woId_ERP_Map.values();
        workOrders = new List<WorkOrder>();
        for( Id woId : woId_ERP_Map.keySet() )
        {
            workOrders.add( new WorkOrder(
                    Id = woId,
                    ERP_Order__c = woId_ERP_Map.get( woId ).Id
            ));
        }
        TriggerBase.bypass('WorkOrder');
        update workOrders;
        TriggerBase.clearBypass('WorkOrder');
        return woIds;
    }

    public static Set<Id> stepTwo( Set<Id> woIds )
    {
        System.debug('Step Two for MFG');
        Set<Id> setWOLIIds = new Set<Id>();
        for(WorkOrderLineItem woli : WorkOrderLineItem_Selector.selectAllWithoutERPTask_ByWorkOrderIds(woIds)){
            setWOLIIds.add(woli.Id);
        }
        ProjectTask_Service.newFromWorkOrderLineItemIds( setWOLIIds);
        return setWOLIIds;
    }

    public static void stepThree( Set<Id> woLIIds )
    {
        System.debug('Step Three for MFG');
        Set<Id> setPRIds = new Set<Id>();
        for(ProductRequired pr : ProductRequired_Selector.selectAllByWorkOrderLineIds(woLIIds)){
            setPRIds.add(pr.Id);
        }
        Material_Service.createFromProductRequiredIds(setPRIds);
    }

    /* DEFERRED CLASSES */
    public class createMFGERP_Promise implements Promise.Deferred {
        private Set<Id> woIds;
        public Object resolve( Object woIDs )
        {
            woIds = stepOne( (Set<Id>)woIDs );
            System.debug('woIds');
            System.debug(woIds);
            return woIds;
        }
    }

    public class createErpTask_Promise implements Promise.Deferred
    {
        private Set<Id> woliIds;
        public Object resolve( Object woIds )
        {
            woliIds = stepTwo( (Set<Id>)woIds );
            return woliIds;
        }
    }

    public class createMaterial_Promise implements Promise.Deferred
    {

        public Object resolve( Object woliId )
        {
            stepThree( (Set<Id>)woliId );
            return null;
        }
    }

    /* HANDLER CLASSES */

    public class WorkOrderAndERP_Done implements Promise.Done
    {
        public WorkOrderAndERP_Done(){}
        public void done( Object error )
        {
            if( error != null )
            {
                WorkOrderAndERP_Error e = (WorkOrderAndERP_Error)error;
                new Queueable_Exception_Logger()
                        .setModule('DealerOrder To WorkOrder')
                        .setInitialInputType('Set<Id>')
                        .setInitialInput( e.initialInputs )
                        .log( e.theException );
            }
        }
    }

    public class WorkOrderAndERP_Error implements Promise.Error
    {
        public Exception theException;
        public Object initialInputs;
        public Object error( Exception e )
        {
            this.theException = e;
            this.initialInputs = initialInputs;
            return this;
        }
    }/*

    public class WorkOrderAndERP_Done implements Promise.Done
    {
        public WorkOrderAndERP_Done(){}
        public void done( Object error )
        {
            if( error != null )
            {
                WorkOrderAndERP_Error e = (WorkOrderAndERP_Error)error;
                new Queueable_Exception_Logger()
                        .setModule('WorkOrder to ERP')
                        .setInitialInputType('Set<Id>')
                        .setInitialInput( e.initialInputs )
                        .log( e.theException );
            }
        }
    }

    public class WorkOrderAndERP_Error implements Promise.Error
    {
        public Exception theException;
        public Object initialInputs;
        public Object error( Exception e, Object initialInputs )
        {
            this.theException = e;
            this.initialInputs = initialInputs;
            return this;
        }
    }*/

}