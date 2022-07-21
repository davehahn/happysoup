/**
 * Created by Legend on 28/4/22.
 */

public without sharing class Shipment_Service {
  public static void createBilling(Set<Id> setIdShipment) {
    Map<Id, AcctSeed__Billing__c> billingToBeSaved = new Map<Id, AcctSeed__Billing__c>();
    Map<Id, List<AcctSeed__Billing_Line__c>> mapShipmentListLine = new Map<Id, List<AcctSeed__Billing_Line__c>>();
    Map<Id, List<AcctSeed__Billing_Line__c>> mapSOListLine = new Map<Id, List<AcctSeed__Billing_Line__c>>();
    List<AcctSeed__Billing_Line__c> listBillingLines = new List<AcctSeed__Billing_Line__c>();
    Date billDate = Date.today();
    Map<Id, AcctSeedERP__Shipment__c> mapShipments = new Map<Id, AcctSeedERP__Shipment__c>();
    Set<Id> setIdSO = new Set<Id>();
    Id idPeriod;
    List<AcctSeedERP__Shipment__c> listShipments = Shipment_Selector.allShipmentByShipped(setIdShipment);
    for (AcctSeedERP__Shipment__c shipment : listShipments) {
      setIdSO.add(shipment.AcctSeedERP__Sales_Order__c);
      mapShipments.put(shipment.Id, shipment);
      mapShipmentListLine.put(shipment.Id, new List<AcctSeed__Billing_Line__c>());
      mapSOListLine.put(shipment.AcctSeedERP__Sales_Order__c, new List<AcctSeed__Billing_Line__c>());
    }

    if (!mapShipments.isEmpty()) {
      /// Find The Period
      for (AcctSeed__Accounting_Period__c p : [
        SELECT Id
        FROM AcctSeed__Accounting_Period__c
        WHERE AcctSeed__End_Date__c >= :billDate AND AcctSeed__Status__c = 'Open'
        ORDER BY AcctSeed__End_Date__c
        LIMIT 1
      ]) {
        idPeriod = p.Id;
      }
      List<AcctSeedERP__Shipment_Line__c> listShipmentLine = ShipmentLine_Selector.byShipment(mapShipments.keySet());
      for (AcctSeedERP__Shipment_Line__c shipmentLine : listShipmentLine) {
        Decimal priorBillAmt = 0;
        Decimal priorBillQty = 0;
        Boolean hasPriorBill = false;
        for (AcctSeed__Billing_Line__c line : shipmentLine.Billing_Lines__r) {
          priorBillAmt += (line.AcctSeed__Total__c == null ? 0 : line.AcctSeed__Total__c);
          priorBillQty += (line.AcctSeed__Hours_Units__c == null ? 0 : line.AcctSeed__Hours_Units__c);
          hasPriorBill = true;
        }

        priorBillAmt = priorBillAmt.setScale(6);
        Decimal matlAmt = shipmentLine.AcctSeedERP__Sales_Order_Line__r.AcctSeedERP__Total__c;
        Decimal matlQty = (shipmentLine.AcctSeedERP__Quantity_Shipped__c == null
          ? 0
          : shipmentLine.AcctSeedERP__Quantity_Shipped__c);
        Decimal matlRate = shipmentLine.AcctSeedERP__Sales_Order_Line__r.AcctSeedERP__Unit_Price__c;
        Decimal thisBillQty = matlQty - priorBillQty;
        if (matlQty != 0) {
          if (
            priorBillAmt != matlAmt ||
            (hasPriorBill == false &&
            matlAmt == 0) ||
            (hasPriorBill == true &&
            matlAmt == 0 &&
            thisBillQty <> 0)
          ) {
            Decimal thisBillAmt = matlAmt - priorBillAmt;
            Decimal thisBillRate = (thisBillQty == 0 ? 0 : thisBillAmt / thisBillQty);
            if (thisBillQty != 0) {
              List<AcctSeed__Billing_Line__c> listLine = mapShipmentListLine.get(shipmentLine.AcctSeedERP__Shipment__c);
              listLine.add(
                new AcctSeed__Billing_Line__c(
                  AcctSeedERP__Sales_Order_Line__c = shipmentLine.AcctSeedERP__Sales_Order_Line__c,
                  AcctSeed__Product__c = shipmentLine.AcctSeedERP__Sales_Order_Line__r.AcctSeedERP__Product__c,
                  AcctSeed__Hours_Units__c = thisBillQty,
                  AcctSeed__Rate__c = thisBillRate,
                  Shipment_Line__c = shipmentLine.Id,
                  AcctSeed__GL_Account_Variable_1__c = shipmentLine.AcctSeedERP__Sales_Order_Line__r.AcctSeedERP__GL_Account_Variable_1__c,
                  AcctSeed__GL_Account_Variable_2__c = shipmentLine.AcctSeedERP__Sales_Order_Line__r.AcctSeedERP__GL_Account_Variable_2__c,
                  AcctSeed__GL_Account_Variable_3__c = shipmentLine.AcctSeedERP__Sales_Order_Line__r.AcctSeedERP__GL_Account_Variable_3__c,
                  AcctSeed__GL_Account_Variable_4__c = shipmentLine.AcctSeedERP__Sales_Order_Line__r.AcctSeedERP__GL_Account_Variable_4__c,
                  Taxable_Federal__c = shipmentLine.AcctSeedERP__Sales_Order_Line__r.Taxable_Federal__c,
                  Taxable_Provincial__c = shipmentLine.AcctSeedERP__Sales_Order_Line__r.Taxable_Provincial__c,
                  Taxable_Retail__c = shipmentLine.AcctSeedERP__Sales_Order_Line__r.Taxable_Retail__c
                )
              );
            }
          }
        }
      }
      if (!mapShipmentListLine.isEmpty()) {
        for (Id shipId : mapShipments.keySet()) {
          AcctSeedERP__Shipment__c shipment = mapShipments.get(shipId);
          if (shipment.AcctSeedERP__Sales_Order__r.AcctSeedERP__Customer__c == null) {
            throw new gcException('The Sales Order must have a Customer, in order to create a Billing.');
          }

          AcctSeed__Billing__c b = new AcctSeed__Billing__c(
            AcctSeed__Date__c = billDate,
            AcctSeed__Customer__c = shipment.AcctSeedERP__Sales_Order__r.AcctSeedERP__Customer__c,
            AcctSeedERP__Sales_Order__c = shipment.AcctSeedERP__Sales_Order__c,
            AcctSeed__Status__c = 'Approved',
            GL_Account_Variable_3__c = shipment.AcctSeedERP__Sales_Order__r.GL_Account_Variable_3__c,
            Tax_is_Harmonized__c = shipment.AcctSeedERP__Sales_Order__r.Tax_is_Harmonized__c,
            Tax_Override__c = shipment.AcctSeedERP__Sales_Order__r.Tax_Override__c,
            Tax_Rate_Federal__c = shipment.AcctSeedERP__Sales_Order__r.Tax_Rate_Federal__c,
            Tax_Rate_Provincial__c = shipment.AcctSeedERP__Sales_Order__r.Tax_Rate_Provincial__c,
            Tax_Rate_Retail__c = shipment.AcctSeedERP__Sales_Order__r.Tax_Rate_Retail__c,
            AcctSeed__Accounting_Period__c = idPeriod
          );

          billingToBeSaved.put(shipment.Id, b);
        }
        if (!billingToBeSaved.isEmpty()) {
          insert billingToBeSaved.values();
          for (Id idShip : mapShipments.keySet()) {
            Id idBilling = billingToBeSaved.get(idShip).Id;
            List<AcctSeed__Billing_Line__c> listLines = mapShipmentListLine.get(idShip);
            for (AcctSeed__Billing_Line__c line : listLines) {
              line.AcctSeed__Billing__c = idBilling;
              listBillingLines.add(line);
            }
          }
          Boolean boolOld = gcBillingLine.disableAutosetTaxable;
          gcBillingLine.disableAutosetTaxable = true;
          insert listBillingLines;
          gcBillingLine.disableAutosetTaxable = boolOld;
          AcctSeed.BillingPostService.postBillings(billingToBeSaved.values());
        }
      }
    }
  }
}
