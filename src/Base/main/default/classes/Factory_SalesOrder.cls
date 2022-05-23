/**
 * Created by Legend on 16/5/22.
 */
@isTest
public class Factory_SalesOrder {

    public static AcctSeedERP__Sales_Order__c createSalesOrder( Account acct, Id idWarehouse)
    {
        AcctSeedERP__Sales_Order__c so = buildSO( acct );
        if(idWarehouse != null)
            so.Warehouse__c = idWarehouse;
        insert so;
        InventoryTestFactory itf = new InventoryTestFactory();
        Product2[] prods = itf.buildTestProducts( 1, 'Part' );
        gcProduct.disableTrigger = true;
        insert prods;
        gcProduct.disableTrigger = false;
        AcctSeedERP__Sales_Order_Line__c[] sols = new List<AcctSeedERP__Sales_Order_Line__c>();
        for( Product2 p : prods ) {
            sols.add( buildSOL( so, p.Id) );
        }
        insert sols;
        return so;
    }

    public static AcctSeedERP__Sales_Order__c createSalesOrder( Account acct, Id idWarehouse, Id idProduct)
    {
        AcctSeedERP__Sales_Order__c so = buildSO( acct );
        if(idWarehouse != null)
            so.Warehouse__c = idWarehouse;
        insert so;
        AcctSeedERP__Sales_Order_Line__c[] sols = new List<AcctSeedERP__Sales_Order_Line__c>();
        sols.add( buildSOL( so, idProduct) );
        insert sols;
        return so;
    }

    public static AcctSeedERP__Sales_Order__c buildSO( Account acct )
    {
        Id idWarehouseWholesale = gcConstants.idWarehouseWholesale;
        Id idGLV1 = gcConstants.idGlv1Wholesale;
        Id idGLV2 = gcConstants.idGlv2Sales;
        Id idGLV3 = gcConstants.idGlv3Others;
        return new AcctSeedERP__Sales_Order__c (
                AcctSeedERP__Status__c = 'New',
                AcctSeedERP__Customer__c = acct.Id,
                Warehouse__c = idWarehouseWholesale,
                GL_Account_Variable_1__c = idGLV1,
                GL_Account_Variable_2__c = idGLV2,
                GL_Account_Variable_3__c = idGLV3
        );
    }

    public static AcctSeedERP__Sales_Order_Line__c buildSOL(
            Id soId,
            Id prodId )
    {
        return Factory_SalesOrderLine.buildSOL(
                soId,
                prodId
        );
    }

    public static AcctSeedERP__Sales_Order_Line__c buildSOL(AcctSeedERP__Sales_Order__c so, Id prodId )
    {
        AcctSeedERP__Sales_Order_Line__c sol = Factory_SalesOrderLine.buildSOL(so.Id, prodId);
        sol.AcctSeedERP__GL_Account_Variable_1__c = so.GL_Account_Variable_1__c;
        sol.AcctSeedERP__GL_Account_Variable_2__c = so.GL_Account_Variable_2__c;
        sol.AcctSeedERP__GL_Account_Variable_3__c = so.GL_Account_Variable_3__c;
        return sol;
    }
}