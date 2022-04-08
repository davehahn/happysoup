/**
 * Created by dave on 2022-04-01.
 */

trigger RetailBoatSaleFundedEvent on Retail_Boat_Sale_Funded_Event__e (after insert)
{
  Set<Id> projectIds = new Set<Id>();
  for( Retail_Boat_Sale_Funded_Event__e e : Trigger.new ){
    projectIds.add( e.ProjectId__c );
  }

  Task_Service.createRetailSaleFundedTasks( projectIds );
  Project_Service.createFlexibleAccessoryCreditProjects( projectIds );

}