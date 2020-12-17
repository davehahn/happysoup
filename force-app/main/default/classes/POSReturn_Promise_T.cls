/**
 * Created by aminrubel on 10/12/20.
 */
@IsTest
public class POSReturn_Promise_T
{
    static Partner_Program_Settings__c programSettings = Partner_Program_Settings__c.getOrgDefaults();
    static String customerAccountName = 'Dave R';
    static Account partner;
    static User partnerUser;
    static Product2 boat;
    static PricebookEntry pbe;
    static Dealer_Order__c order;
    static List<AcctSeed__Project__c> erps;
    static AcctSeed__Project__c project;

    @testSetup static void dataSetup()
    {
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
        TriggerHandler.bypass('CommissionPayment2_TriggerHandler');
        TriggerHandler.bypass('CommissionRecord2_TriggerHandler');
        project = ProjectTestFactory.insertCounterSale();
        System.debug('projectm');
        System.debug(project);
    }

    @IsTest
    static void testStepOnePromise()
    {
        AcctSeed__Project__c pr = [SELECT Id, AcctSeed__Account__c, GMBLASERP__Warehouse__c FROM AcctSeed__Project__c WHERE Id =:project.Id][0];
        Id idAccount = pr.AcctSeed__Account__c;
        List<POSReturn_Promise.materialData> listMaterials = new List<POSReturn_Promise.materialData>();
        for(AcctSeedERP__Material__c matl :
        [SELECT Id,
            AcctSeedERP__Project__c,
            AcctSeedERP__Project__r.Name,
            AcctSeedERP__Product__c,
            AcctSeedERP__Product__r.RecordType.Name,
            AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c,
            AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
            AcctSeedERP__Product__r.Name,
            GMBLASERP__Serial_Number__c,
            GMBLASERP__Serial_Number__r.Name,
            AcctSeedERP__Project_Task__r.Name,
            AcctSeedERP__Quantity_Per_Unit__c,
            AcctSeedERP__Quantity_Allocated__c,
            GMBLASERP__Unit_Price__c,
            GMBLASERP__Total_Price__c,
        (SELECT AcctSeedERP__Quantity_Per_Unit__c, AcctSeedERP__Quantity_Allocated__c FROM ReturndMaterials__r)
        FROM AcctSeedERP__Material__c
        WHERE AcctSeedERP__Project__c =:project.Id
        AND Return_Parent__c = null
        AND (AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c = false
        OR (AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c = true
        AND AcctSeedERP__Quantity_Allocated__c > 0))
        LIMIT 1])
        {
            POSReturn_Promise.materialData md = new POSReturn_Promise.materialData();
            md.matId = matl.Id;
            md.matQuantity = matl.AcctSeedERP__Quantity_Allocated__c;
            md.returnQuantity = 1;
            md.pricePerQuantity = matl.GMBLASERP__Unit_Price__c;
            md.serialized = matl.AcctSeedERP__Product__r.AcctSeedERP__Serialized__c;
            md.totalPrice = matl.GMBLASERP__Unit_Price__c;
            md.productName = matl.AcctSeedERP__Product__r.Name;
            md.projectName = matl.AcctSeedERP__Project__r.Name;
            listMaterials.add(md);
        }

        POSReturn_Promise.promiseData pd = new POSReturn_Promise.promiseData();
        pd.idAccount = idAccount;
        pd.idFilter = project.Id;
        pd.paymentMethod = 'Cash';
        pd.pIdWarehouse = pr.GMBLASERP__Warehouse__c;
        pd.allMaterials = listMaterials;
        Test.startTest();
        new POSReturn_Promise().Test_ERPTaskAndBilling(pd);
        Test.stopTest();
    }
}