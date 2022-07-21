/**
 * Created by Legend on 26/8/21.
 */

public with sharing class GCR_SalesOrderLine {
  public static void rollup(set<Id> pSetIdSalesOrderLine) {
    map<Id, cube> mapCube = new Map<Id, cube>();
    /*pSetIdSalesOrderLine.remove(NULL);
        if(pSetIdSalesOrderLine.size() == 0) return;

        list<AcctSeedERP__Sales_Order_Line__c> listSOLupdate = new list<AcctSeedERP__Sales_Order_Line__c>();
        for(AcctSeed__Transaction__c txn :
        [SELECT Id,
                AcctSeed__GL_Account__c,
                AcctSeed__GL_Account__r.AcctSeed__Type__c,
                AcctSeed__Amount__c,
                AcctSeed__Billing_Line__r.AcctSeedERP__Sales_Order_Line__c,
                AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Sales_Order_Line__c
        FROM AcctSeed__Transaction__c
        WHERE AcctSeed__GL_Account__r.AcctSeed__Type__c IN ('Revenue','Expense')
        AND (AcctSeed__Billing_Line__r.AcctSeedERP__Sales_Order_Line__c IN :pSetIdSalesOrderLine OR
        AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Sales_Order_Line__c IN :pSetIdSalesOrderLine)
        AND (AcctSeed__Amount__c < 0 OR AcctSeed__Amount__c > 0)])
        {
            Id idSOL = txn.AcctSeed__Billing_Line__r.AcctSeedERP__Sales_Order_Line__c;
            if(idSOL == null)
                idSOL = txn.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Sales_Order_Line__c;

            cube cube = mapCube.get(idSOL);
            if(cube == null)
            {
                cube = new cube();
                mapCube.put(idSOL, cube);
            }

            if(txn.AcctSeed__GL_Account__r.AcctSeed__Type__c == 'Revenue')
                cube.revenue -= txn.AcctSeed__Amount__c;
            else
                    cube.expense += txn.AcctSeed__Amount__c;
        }

        for(AcctSeedERP__Sales_Order_Line__c sol :
        [SELECT Id, GMBLASERP__Expense__c, GMBLASERP__Quantity_Filled__c, GMBLASERP__Revenue__c,
        (SELECT AcctSeedERP__Quantity__c, GMBLASERP__Inventory_GL_Amount__c FROM GMBLASERP__Outbound_Inventory_Movements__r WHERE AcctSeedERP__Quantity__c <= 0 OR AcctSeedERP__Quantity__c > 0)
        FROM AcctSeedERP__Sales_Order_Line__c
        WHERE Id IN :pSetIdSalesOrderLine])
        {
            Decimal decQtyNew = 0;
            Decimal decExpNew = 0;
            Decimal decRevNew = 0;

            for(AcctSeedERP__Outbound_Inventory_Movement__c move : sol.GMBLASERP__Outbound_Inventory_Movements__r)
                decQtyNew += move.AcctSeedERP__Quantity__c;

            if(mapCube.containsKey(sol.Id))
            {
                cube cube = mapCube.get(sol.Id);
                decExpNew = cube.expense;
                decRevNew = cube.revenue;
            }

            if(sol.GMBLASERP__Quantity_Filled__c == NULL || sol.GMBLASERP__Quantity_Filled__c.setScale(6) != decQtyNew.setScale(6) ||
                    sol.GMBLASERP__Expense__c == null || sol.GMBLASERP__Expense__c.setScale(6) != decExpNew.setScale(6) ||
                    sol.GMBLASERP__Revenue__c == null || sol.GMBLASERP__Revenue__c.setScale(6) != decRevNew.setScale(6))
            {
                sol.GMBLASERP__Expense__c = decExpNew;
                sol.GMBLASERP__Quantity_Filled__c = decQtyNew;
                sol.GMBLASERP__Revenue__c = decRevNew;
                listSOLupdate.add(sol);
            }
        }

        if(listSOLupdate.size() > 0) {
            update listSOLupdate;
        }*/
  }

  private class cube {
    Decimal expense { get; set; }
    Decimal revenue { get; set; }

    cube() {
      expense = 0;
      revenue = 0;
    }
  }
}
