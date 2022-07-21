/**
 * Created by dave on 2022-04-04.
 */
@IsTest
public class RetailBoatSaleFunded_TestHelper {
  public static final Decimal ACCESSORY_CREDIT_AMOUNT = 2000;
  public static Id testDataCreate() {
    TriggerBase.bypass('AcctSeed__Project__c');
    TriggerBase.bypass('AcctSeed__Project_Task__c');
    TriggerBase.bypass('AcctSeedERP__Material__c');
    User boatSpecialist = Factory_User.createUser('Boat', 'Specialist', 'Minimum Access - Salesforce');
    AcctSeedERP__Warehouse__c wh = Test_Constants.warehouse;
    Product2 boat = Factory_Product.createSerializedProduct('Boat', 'Pontoon');
    GMBLASERP__Serial_Number__c boatSerial = Factory_SerialNumber.insertSerialNumber(boat, 'UNIT000001TEST');
    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    AcctSeed__Project__c boatSale = Factory_ERPOrder.insertRetailBoatSale(
      customer,
      wh,
      DateTime.now().addMonths(1),
      boatSerial
    );
    boatSale.Boat_Specialist__c = boatSpecialist.Id;
    update boatSale;
    AcctSeed__Project_Task__c retailTask = [
      SELECT Id
      FROM AcctSeed__Project_Task__c
      WHERE AcctSeed__Project__c = :boatSale.Id
    ];
    AcctSeedERP__Material__c fac = new AcctSeedERP__Material__c(
      AcctSeedERP__Project__c = boatSale.Id,
      AcctSeedERP__Project_Task__c = retailTask.Id,
      AcctSeedERP__Quantity_Per_Unit__c = 1,
      GMBLASERP__Price_Override__c = true,
      GMBLASERP__Unit_Price__c = ACCESSORY_CREDIT_AMOUNT,
      AcctSeedERP__Product__c = Application_Constants.getInstance().utilityProducts.getFlexibleAccessoriesCredit()
    );
    insert fac;
    TriggerBase.clearAllBypasses();
    return boatSale.Id;
  }
}
