/**
 * Created by dave on 2022-04-01.
 */

public without sharing class TA_Project_RetailBoatSaleFunded implements TriggerAction.AfterUpdate {
  public static final String FUNDED_STATUS = 'Funded';

  public void afterUpdate(List<AcctSeed__Project__c> newList, List<AcctSeed__Project__c> oldList) {
    List<Retail_Boat_Sale_Funded_Event__e> events = buildFundedEvents(newList, oldList);
    System.debug('EVENTS SIZE: ' + events.size());
    if (events.size() > 0) {
      publishEvents(events);
    }
  }

  private List<Retail_Boat_Sale_Funded_Event__e> buildFundedEvents(
    List<AcctSeed__Project__c> newList,
    List<AcctSeed__Project__c> oldList
  ) {
    Map<Id, AcctSeed__Project__c> oldMap = new Map<Id, AcctSeed__Project__c>(oldList);
    List<Retail_Boat_Sale_Funded_Event__e> events = new List<Retail_Boat_Sale_Funded_Event__e>();
    for (AcctSeed__Project__c project : newList) {
      AcctSeed__Project__c beforeProject = oldMap.get(project.Id);
      if (
        project.Business_Office_Status__c == FUNDED_STATUS &&
        beforeProject.Business_Office_Status__c != FUNDED_STATUS
      ) {
        events.add(new Retail_Boat_Sale_Funded_Event__e(ProjectId__c = project.Id));
      }
    }
    return events;
  }

  private void publishEvents(List<Retail_Boat_Sale_Funded_Event__e> events) {
    List<Database.SaveResult> results = EventBus.publish(events);
    for (Database.SaveResult sr : results) {
      if (sr.isSuccess()) {
        System.debug('Successfully published event.');
      } else {
        for (Database.Error err : sr.getErrors()) {
          System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
        }
      }
    }
  }
}
