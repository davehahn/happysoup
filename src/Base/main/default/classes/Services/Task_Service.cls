/**
 * Created by dave on 2022-04-01.
 */

public inherited sharing class Task_Service {
  private static final String BOAT_SALE_FUNDED_ACCOUNTINGTEAM_DESCRIPTION = 'Add the Flexible Accessories Credit to the Customer Account';
  private static final String BOAT_SALE_FUNDED_BOATSPECIALIST_DESCRIPTION = 'Contact the Customer to use their Flexible Accessories Credit';
  public static final Integer DUEDATE_OFFSET = 2;

  public static void createRetailSaleFundedTasks(Set<Id> projectIds) {
    List<Task> tasks = new List<Task>();
    List<AcctSeedERP__Material__c> materials = Material_Selector.allFlexibleAccessoryCreditLinesByProjectIds(
      projectIds
    );
    Application_Constants constants = Application_Constants.getInstance();
    Date dueDate = Date.today().addDays(DUEDATE_OFFSET);
    for (AcctSeedERP__Material__c mat : materials) {
      Id boatSpecialist = mat.AcctSeedERP__Project__r.Boat_Specialist__c == null
        ? mat.AcctSeedERP__Project__r.Salesperson__c
        : mat.AcctSeedERP__Project__r.Boat_Specialist__c;
      tasks.add(
        new Task(
          OwnerId = constants.queues.getAccountTeamId(),
          WhatId = mat.AcctSeedERP__Project__c,
          Type = 'To Do',
          Subject = BOAT_SALE_FUNDED_ACCOUNTINGTEAM_DESCRIPTION,
          Description = BOAT_SALE_FUNDED_ACCOUNTINGTEAM_DESCRIPTION,
          ActivityDate = dueDate
        )
      );
      if (boatSpecialist != null) {
        tasks.add(
          new Task(
            OwnerId = boatSpecialist,
            WhatId = mat.AcctSeedERP__Project__c,
            Type = 'To Do',
            Subject = BOAT_SALE_FUNDED_BOATSPECIALIST_DESCRIPTION,
            Description = BOAT_SALE_FUNDED_BOATSPECIALIST_DESCRIPTION,
            ActivityDate = dueDate
          )
        );
      }
    }
    insert tasks;
  }
}
