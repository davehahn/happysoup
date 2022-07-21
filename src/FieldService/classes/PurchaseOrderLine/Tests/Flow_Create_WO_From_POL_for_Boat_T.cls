/**
 * Created by dave on 2022-03-02.
 */

@IsTest
private class Flow_Create_WO_From_POL_for_Boat_T {
  static AcctSeedERP__Purchase_Order__c po;
  static Product2 boat;
  static WorkType workType;
  static Contact shipperContact;
  static final Date ETA = Date.today().addDays(14);

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void buildData() {
    Account[] accounts = Factory_Account.insertSupplierAccounts(2);
    Account supplier = accounts[0];
    Account shipper = accounts[1];
    shipperContact = Factory_Contact.newContact(shipper.Id, 'UnitTest', 'Contact');
    insert shipperContact;
    po = Factory_PurchaseOrder.buildMinimalPO(supplier.Id, shipper.Id);
    po.Estimated_Time_of_Arrival_ETA__c = ETA;
    po.AcctSeedERP__Shipping_Contact__c = shipperContact.Id;
    insert po;
    workType = new WorkType(
      Name = 'Unit Test WorkType',
      Description = 'Work Type for Unit Tests',
      EstimatedDuration = 1
    );
    insert workType;
    boat = Factory_Product.buildSerializedProduct('Boat', 'Pontoon');
    boat.Pre_Rig_Work_Type__c = workType.Id;
    insert boat;
  }

  @IsTest
  static void createRecordsOnInsertTest() {
    buildData();
    AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(po.Id, boat.Id, 1);
    Test.startTest();
    insert pol;
    Test.stopTest();

    pol = [
      SELECT Id, Name, AcctSeedERP__Purchase_Order__r.Name, Work_Order__c, Work_Order_Line_Item__c
      FROM AcctSeedERP__Purchase_Order_Line__c
      WHERE Id = :pol.Id
    ];
    WorkOrder[] wos = [
      SELECT
        Id,
        Status,
        ContactId,
        Description,
        RecordTypeId,
        ServiceTerritoryId,
        Manufacturing_Product_Id__c,
        (SELECT Id, Status, Description, ServiceTerritoryId, WorkTypeId FROM WorkOrderLineItems)
      FROM WorkOrder
    ];
    WorkOrder wo = wos[0];
    WorkOrderLineItem woli = wos[0].WorkOrderLineItems[0];
    ServiceAppointment[] appointments = [SELECT Id, ParentRecordId, DueDate, EarliestStartTime FROM ServiceAppointment];

    System.assertEquals(1, wos.size(), 'Should be 1 WorkOrder');
    //System.assertEquals( shipperContact.Id, wos[0].ContactId );
    System.assertEquals(new Application_RecordType().getWorkOrderRecordTypes().getManufacturingId(), wo.RecordTypeId);
    System.assert(wo.Description.contains(pol.AcctSeedERP__Purchase_Order__r.Name));
    System.assert(wo.Description.contains(pol.Name));
    System.assertEquals(FSL_Constants.getServiceTerritoryWholeSale(), wo.ServiceTerritoryId);
    System.assertEquals('New', wo.Status);
    System.assertEquals(boat.Id, wo.Manufacturing_Product_Id__c);

    System.assertEquals(1, wos[0].WorkOrderLineItems.size(), 'Work Order should have 1 Line Item');
    System.assert(woli.Description.contains(pol.AcctSeedERP__Purchase_Order__r.Name));
    System.assert(woli.Description.contains(pol.Name));
    System.assertEquals(FSL_Constants.getServiceTerritoryWholeSale(), woli.ServiceTerritoryId);
    System.assertEquals('New', woli.Status);
    System.assertEquals(workType.Id, woli.WorkTypeId);

    ServiceAppointment sa = appointments[0];
    Date earliestStartDate = Date.newInstance(
      sa.EarliestStartTime.year(),
      sa.EarliestStartTime.month(),
      sa.EarliestStartTime.day()
    );
    Date dueDate = earliestStartDate.addDays(14);
    System.assertEquals(1, appointments.size(), 'Should be 1 Service Appointment');
    System.assertEquals(wos[0].Id, appointments[0].ParentRecordId);
    System.assertEquals(ETA, earliestStartDate);
    System.assertEquals(ETA.addDays(14), dueDate);

    System.assert(pol.Work_order__c != null, ' Work Order should be populated');
    System.assert(pol.Work_Order_line_Item__c != null, 'Work Order Line Item should be populated');
  }

  @IsTest
  static void createRecordsOnInsert_Bulk_Test() {
    buildData();
    List<AcctSeedERP__Purchase_Order_Line__c> pols = new List<AcctSeedERP__Purchase_Order_Line__c>();
    for (Integer i = 0; i < 200; i++) {
      pols.add(Factory_PurchaseOrder.buildLineItem(po.Id, boat.Id, 1));
    }
    Test.startTest();
    insert pols;
    Test.stopTest();

    WorkOrder[] wos = [SELECT Id FROM WorkOrder];
    WorkOrderLineItem[] wolis = [SELECT Id FROM WorkOrderLineItem];
    ServiceAppointment[] sas = [SELECT Id FROM ServiceAppointment];

    System.assertEquals(200, wos.size());
    System.assertEquals(200, wolis.size());
    System.assertEquals(200, sas.size());
  }

  @IsTest
  static void bypassed_TriggerBaseOnInsertTest() {
    buildData();
    AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(po.Id, boat.Id, 1);
    Test.startTest();
    TriggerBase.bypass('AcctSeedERP__Purchase_Order_Line__c');
    insert pol;
    Test.stopTest();

    pol = [
      SELECT Id, Work_Order__c, Work_Order_Line_Item__c
      FROM AcctSeedERP__Purchase_Order_Line__c
      WHERE Id = :pol.Id
    ];
    WorkOrder[] wos = [SELECT Id FROM WorkOrder];
    WorkOrderLineItem[] wolis = [SELECT Id FROM WorkOrderLineItem];
    ServiceAppointment[] sas = [SELECT Id FROM ServiceAppointment];

    System.assert(pol.Work_order__c == null, ' Work Order should be blank');
    System.assert(pol.Work_Order_line_Item__c == null, 'Work Order Line Item should be blank');
    System.assertEquals(0, wos.size());
    System.assertEquals(0, wolis.size());
    System.assertEquals(0, sas.size());
  }
}
