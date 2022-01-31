/**
 * Created by dave on 2022-01-11.
 */

@IsTest
public class TA_CommRec2_TestHelper {
  public AcctSeed__Project__c project {
    get {
      if (project == null) {
        project = [
          SELECT
            Id,
            Salesperson__c,
            Business_Manager__c,
            (
              SELECT
                Id,
                AcctSeed__Project__c,
                Name,
                DisplayOnCustomerInvoice__c,
                AcctSeed__GL_Account_Variable_2__c,
                Commission_Calculation_Method__c,
                Is_Retail_Boat_Sale__c
              FROM AcctSeed__Project_Tasks__r
            )
          FROM AcctSeed__Project__c
          LIMIT 1
        ];
      }
      return project;
    }
    set {
    }
  }

  public List<AcctSeed__Project_Task__c> tasks {
    get {
      if (tasks == null) {
        tasks = project.AcctSeed__Project_Tasks__r;
      }
      return tasks;
    }
    set {
    }
  }

  public CommissionRecord2__c commRec {
    get {
      if (commRec == null) {
        commRec = new CommissionRecord2__c(Project_Task__c = tasks[0].Id);
      }
      return commRec;
    }
    set {
    }
  }

  public List<CommissionRecord2__c> getNewList() {
    return new List<CommissionRecord2__c>{ commRec };
  }

  public List<CommissionRecord2__c> getOldList() {
    CommissionRecord2__c c = this.commRec.clone(true, true, true, true);
    return new List<CommissionRecord2__c>{ c };
  }

  public void insertCommRec() {
    insert this.commRec;
  }

  public static void testDataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', 'test12345');
    Map<String, User> users = new Map<String, User>{
      'sales' => Factory_User.newUser('Sales', 'Person', 'System Administrator', null),
      'businessOffice' => Factory_User.newUser('Business', 'Office', 'System Administrator', null)
    };
    insert users.values();
    AcctSeed__Project__c project = Factory_ERPOrder.buildERP(customer, serial.Id, gcConstants.idRtProjectBoatSale);
    project.GMBLASERP__Pricebook__c = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;

    project.Salesperson__c = users.get('sales').Id;
    project.Business_Manager__c = users.get('businessOffice').Id;
    insert project;
    Factory_ERPOrderTask.insertDefaultRetailBoatSaleTasks(project.Id);
  }
}
