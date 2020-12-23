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
    }

    @IsTest
    static void testStepOnePromise()
    {
        TriggerHandler.bypass('CommissionPayment2_TriggerHandler');
        TriggerHandler.bypass('CommissionRecord2_TriggerHandler');
        gcProjectTask.ignoreCommissions = true;
        project = ProjectTestFactory.insertCounterSale();
        System.debug('projectm');
        System.debug(project);
        AcctSeed__Project__c pr = [SELECT Id, AcctSeed__Account__c, GMBLASERP__Warehouse__c FROM AcctSeed__Project__c LIMIT 1][0];
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
        WHERE AcctSeedERP__Project__c =:pr.Id
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
    @IsTest
    static void testStepTwoPromise()
    {
        TriggerHandler.bypass('CommissionPayment2_TriggerHandler');
        TriggerHandler.bypass('CommissionRecord2_TriggerHandler');
        gcProjectTask.ignoreCommissions = true;
        project = ProjectTestFactory.insertCounterSale();
        System.debug('projectm');
        System.debug(project);
        AcctSeed__Project__c pr = [SELECT Id, AcctSeed__Account__c, GMBLASERP__Warehouse__c FROM AcctSeed__Project__c LIMIT 1][0];
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
        WHERE AcctSeedERP__Project__c =:pr.Id
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

        /// Now Create all that happened in first step
        pd = saveReturnMaterials_Original(pd);
        Test.startTest();
        new POSReturn_Promise().Test_Payment(pd);
        Test.stopTest();
    }
    /////
    public static POSReturn_Promise.promiseData saveReturnMaterials_Original(POSReturn_Promise.promiseData pd)
    {
        gcProject.disableTrigger = true;
        gcProjectTask.disableTrigger = true;
        gcMaterial.disableTrigger = true;
        arMaterial_PACKAGE.disableTrigger = true;
        gcBilling.disableTrigger = true;
        GMBLASERP.gcProject.disableTrigger = true;
        GMBLASERP.gcProjectTask.disableTrigger = true;
        Id idAccount = pd.idAccount;
        String paymentMethod = pd.paymentMethod;
        String pIdWarehouse = pd.pIdWarehouse;
        List<POSReturn_Promise.materialData> listMapMaterials = pd.allMaterials;
        //return 'OK';

        Map<Id,List<AcctSeedERP__Material__c>> mapMaterialsInsert = new Map<Id,List<AcctSeedERP__Material__c>>();
        List<AcctSeedERP__Material__c> listMaterialsInsert = new List<AcctSeedERP__Material__c>();
        Set<Id> setIdProjects = new Set<Id>();
        Set<Id> setIdMaterials = new Set<Id>();
        Map<Id,Decimal> mapIdQuantity = new Map<Id,Decimal>();
        Map<Id,AcctSeedERP__Material__c> mapIdMaterial = new Map<Id,AcctSeedERP__Material__c>();
        //List<materialData> listMapMaterials = (List<materialData>)JSON.deserialize(allMaterials, List<materialData>.class);
        Id idLocation = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c = :pIdWarehouse ORDER BY CreatedDate LIMIT 1][0].Id;
        map<Id,map<Id,map<Id,Id>>> mapPWLB = new map<Id,map<Id,map<Id,Id>>>();
        for(POSReturn_Promise.materialData m : listMapMaterials)
        {
            setIdMaterials.add(m.matId);
            mapIdQuantity.put(m.matId, m.returnQuantity);
        }
        setIdMaterials.remove(null);
        if(!setIdMaterials.isEmpty())
            for(AcctSeedERP__Material__c matl :
            [SELECT Id,
                AcctSeedERP__GL_Account_Variable_1__c,
                AcctSeedERP__GL_Account_Variable_2__c,
                AcctSeedERP__GL_Account_Variable_3__c,
                AcctSeedERP__GL_Account_Variable_4__c,
                AcctSeedERP__Product__r.Name,
                AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
                AcctSeedERP__Product__r.GMBLASERP__Lot_Tracked__c,
                AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c,
                GMBLASERP__Lot__c,
                AcctSeedERP__Project__c,
                AcctSeedERP__Project_Task__c,
                AcctSeedERP__Product__c,
                GMBLASERP__Serial_Number__c,
                Taxable_Provincial__c,
                Taxable_Federal__c,
                Taxable_Retail__c,
                AcctSeedERP__Quantity_Per_Unit__c,
                GMBLASERP__Unit_Price__c,
                GMBLASERP__Total_Price__c,
                Return_Parent__c
            FROM AcctSeedERP__Material__c
            WHERE Id IN:setIdMaterials])
            {
                /// It is safe to get the Project Ids from here
                setIdProjects.add(matl.AcctSeedERP__Project__c);
                mapIdMaterial.put(matl.Id,matl);
                AcctSeedERP__Material__c newMatl = matl.clone(false,true);
                newMatl.Return_Parent__c = matl.Id;
                newMatl.AcctSeedERP__Quantity_Per_Unit__c = mapIdQuantity.get(matl.Id) * -1;
                newMatl.GMBLASERP__Price_Override__c = true;
                if(!mapMaterialsInsert.containsKey(matl.AcctSeedERP__Project__c))
                    mapMaterialsInsert.put(matl.AcctSeedERP__Project__c, new List<AcctSeedERP__Material__c>());

                mapMaterialsInsert.get(matl.AcctSeedERP__Project__c).add(newMatl);
                listMaterialsInsert.add(newMatl);

                if(matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c)
                {
                    if(!mapPWLB.containsKey(matl.AcctSeedERP__Product__c)){
                        mapPWLB.put(matl.AcctSeedERP__Product__c, new map<Id,map<Id,Id>>{pIdWarehouse => new map<Id,Id>{idLocation => null}});
                    }
                }
            }
        GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);
        // Now let us update the project status to active to allow new materials
        List<AcctSeed__Project__c> listProjects = new List<AcctSeed__Project__c>();
        Map<Id,AcctSeed__Billing__c> mapIdBillings = new Map<Id,AcctSeed__Billing__c>();
        Map<Id,AcctSeed__Cash_Disbursement__c> mapIdDisbursement = new Map<Id,AcctSeed__Cash_Disbursement__c>();
        Map<Id,AcctSeed__Project_Task__c> mapIdReturnTask = new Map<Id,AcctSeed__Project_Task__c>();
        List<AcctSeed__Project_Task__c> listNewTasks = new List<AcctSeed__Project_Task__c>();
        for(AcctSeed__Project__c pr :
        [SELECT Id,
            AcctSeed__Account__c,
            AcctSeed__Opportunity__c,
            GL_Account_Variable_3__c,
            Tax_Rate_Provincial__c,
            Tax_Rate_Federal__c,
            Tax_Rate_Retail__c,
            Tax_is_Harmonized__c,
            Tax_Override__c,
            AcctSeed__Status__c,
        (SELECT Id FROM AcctSeed__Project_Tasks__r WHERE Is_Return_Task__c = true LIMIT 1)
        FROM AcctSeed__Project__c
        WHERE Id IN:setIdProjects])
        {
            //pr.AcctSeed__Status__c = 'Active';
            listProjects.add(pr);
            AcctSeed__Project_Task__c pt = new AcctSeed__Project_Task__c(AcctSeed__Project__c = pr.Id, Name = 'Customer Return', Is_Return_Task__c = true, DisplayOnCustomerInvoice__c = true);
            mapIdReturnTask.put(pr.Id, pt);
            listNewTasks.add(pt);

            /// This should never happen but still validating
            if(!mapIdBillings.containsKey(pr.Id)){
                AcctSeed__Billing__c b = new AcctSeed__Billing__c(
                    AcctSeed__Date__c = date.Today(),
                    AcctSeed__Customer__c = pr.AcctSeed__Account__c,
                    GMBLASERP__Project__c = pr.Id,
                    AcctSeed__Status__c = 'Approved',
                    AcctSeed__Opportunity__c = pr.AcctSeed__Opportunity__c,
                    GL_Account_Variable_3__c = pr.GL_Account_Variable_3__c,
                    Tax_is_Harmonized__c = pr.Tax_is_Harmonized__c,
                    Tax_Override__c = pr.Tax_Override__c,
                    Tax_Rate_Federal__c = pr.Tax_Rate_Federal__c,
                    Tax_Rate_Provincial__c = pr.Tax_Rate_Provincial__c,
                    Tax_Rate_Retail__c = pr.Tax_Rate_Retail__c,
                    AcctSeed__Ledger__c = gcConstants.idActualLedger
                );
                /// The bills
                mapIdBillings.put(pr.Id, b);
            }
        }
        System.debug(loggingLevel.Error,'mapIdBillings: '+mapIdBillings);

        //Savepoint sp = Database.setSavepoint();
        //try{
        Boolean oldVal = gcProject.disableLockedCheck;
        gcProject.disableLockedCheck = true;
        //update listProjects;
        // Insert New Tasks
        if(!listNewTasks.isEmpty())
            insert listNewTasks;
        pd.idTask = listNewTasks[0].Id;
        // Now insert all the materials
        /// This Loop is a bit redundant but more safe
        for(AcctSeedERP__Material__c matl : listMaterialsInsert)
        {
            matl.AcctSeedERP__Project_Task__c = mapIdReturnTask.get(matl.AcctSeedERP__Project__c).Id;
        }
        insert listMaterialsInsert;
        // Insert new Billings
        insert mapIdBillings.values();
        /// Create all the billing lines
        list<AcctSeed__Billing_Line__c> listLine = new list<AcctSeed__Billing_Line__c>();
        /// Create all the Payable lines
        list<AcctSeed__Account_Payable_Line__c> listAPLine = new list<AcctSeed__Account_Payable_Line__c>();
        Set<Id> setIdNewBills = new Set<Id>();
        Set<Id> setIdNewPayables = new Set<Id>();
        list<AcctSeedERP__Manufacturing_Inventory_Movement__c> listMove = new list<AcctSeedERP__Manufacturing_Inventory_Movement__c>();
        for(AcctSeedERP__Material__c matl : listMaterialsInsert)
        {
            /// Billing lines per product
            AcctSeed__Billing_Line__c bl = new AcctSeed__Billing_Line__c(
                AcctSeed__Billing__c = mapIdBillings.get(matl.AcctSeedERP__Project__c).Id,
                AcctSeed__Project__c = matl.AcctSeedERP__Project__c,
                AcctSeed__Project_Task__c = matl.AcctSeedERP__Project_Task__c,
                AcctSeed__Product__c = matl.AcctSeedERP__Product__c,
                AcctSeed__Hours_Units__c = matl.AcctSeedERP__Quantity_Per_Unit__c,
                AcctSeed__Rate__c = matl.GMBLASERP__Unit_Price__c,
                GMBLASERP__Material__c = matl.Id,
                Taxable_Federal__c = matl.Taxable_Federal__c,
                Taxable_Provincial__c = matl.Taxable_Provincial__c,
                Taxable_Retail__c = matl.Taxable_Retail__c
            );
            listLine.add(bl);
            setIdNewBills.add(bl.AcctSeed__Billing__c);
            /// Reverse Manufacturing Movements if the product is inventory product
            /// This bring in the inventory
            if(matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c)
            {
                Id idBalance = mapPWLB.get(matl.AcctSeedERP__Product__c).get(pIdWarehouse).get(idLocation);
                listMove.add(new AcctSeedERP__Manufacturing_Inventory_Movement__c(
                    AcctSeedERP__GL_Account_Variable_1__c = matl.AcctSeedERP__GL_Account_Variable_1__c,
                    AcctSeedERP__GL_Account_Variable_2__c = matl.AcctSeedERP__GL_Account_Variable_2__c,
                    AcctSeedERP__GL_Account_Variable_3__c = matl.AcctSeedERP__GL_Account_Variable_3__c,
                    AcctSeedERP__GL_Account_Variable_4__c = matl.AcctSeedERP__GL_Account_Variable_4__c,
                    AcctSeedERP__Inventory_Balance__c = idBalance,
                    AcctSeedERP__Material__c = matl.Id,
                    AcctSeedERP__Quantity__c = matl.AcctSeedERP__Quantity_Per_Unit__c,
                    AcctSeedERP__Movement_Date__c = Date.today(),
                    GMBLASERP__Lot__c = matl.GMBLASERP__Lot__c,
                    GMBLASERP__Serial_Number__c = matl.GMBLASERP__Serial_Number__c/*,
						GMBLASERP__Cost_Override__c = true,
						AcctSeedERP__Unit_Cost__c = matl.GMBLASERP__Unit_Price__c*/
                ));
            }
        }
        /// Insert Manufacturing Moves
        insert listMove;
        /// Inserting all B lines
        insert listLine;

        /// Now Create one positive billing and insert all the negative ones as BCR
        AcctSeed__Billing__c posBill = new AcctSeed__Billing__c(
            AcctSeed__Date__c = date.Today(),
            AcctSeed__Customer__c = idAccount,
            AcctSeed__Status__c = 'Approved',
            GL_Account_Variable_3__c = gcConstants.idGlv3Others,
            Tax_is_Harmonized__c = false,
            Tax_Override__c = true,
            Tax_Rate_Federal__c = 0,
            Tax_Rate_Provincial__c = 0,
            Tax_Rate_Retail__c = 0
        );
        insert posBill;
        Id idAccountingPeriod = [SELECT AcctSeed__Accounting_Period__c FROM AcctSeed__Billing__c WHERE Id =:posBill.Id][0].AcctSeed__Accounting_Period__c;
        List<AcctSeed__Billing_Credit_Memo__c> listBCM = new List<AcctSeed__Billing_Credit_Memo__c>();
        list<AcctSeed__Billing_Line__c> listLinePOS = new list<AcctSeed__Billing_Line__c>();
        Decimal totalAmount = 0;
        for(AcctSeed__Billing__c negBill :
        [SELECT Id,
            GMBLASERP__Project__c,
            AcctSeed__Balance__c
        FROM AcctSeed__Billing__c
        WHERE AcctSeed__Type__c = 'Credit Memo'
        AND Id IN:setIdNewBills
        ORDER BY AcctSeed__Balance__c ASC])
        {
            // There is only one always. Although this code covers multiple
            pd.idNegBill = negBill.Id;
            AcctSeed__Billing_Credit_Memo__c bcm = new AcctSeed__Billing_Credit_Memo__c(
                AcctSeed__Accounting_Period__c = idAccountingPeriod,
                AcctSeed__Amount__c = negBill.AcctSeed__Balance__c,
                AcctSeed__Billing_Credit_Memo__c = negBill.Id,
                AcctSeed__Billing_Invoice__c = posBill.Id
            );
            listBCM.add(bcm);

            AcctSeed__Billing_Line__c bl = new AcctSeed__Billing_Line__c(
                AcctSeed__Billing__c = posBill.Id,
                AcctSeed__Hours_Units__c = 1,
                AcctSeed__Rate__c = negBill.AcctSeed__Balance__c * -1,
                AcctSeed__Revenue_GL_Account__c = gcConstants.idGlCustomerRefund,
                AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
                AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales,
                Taxable_Federal__c = false,
                Taxable_Provincial__c = false,
                Taxable_Retail__c = false
            );
            listLinePOS.add(bl);
        }
        insert listLinePOS;
        List<AcctSeed__Billing__c> listAllBills = new List<AcctSeed__Billing__c>();
        listAllBills.addAll(mapIdBillings.values());
        listAllBills.add(posBill);
        AcctSeed.BillingPostService.postBillings(listAllBills);

        if(!listBCM.isEmpty())
            insert listBCM;

        gcProject.disableLockedCheck = oldVal;
        AcctSeed__Project__c pr = listProjects.get(0);
        pd.idFilter = pr.Id;
        pd.idBill = mapIdBillings.get(pr.Id).Id;
        return pd;
    }
    /////
    @IsTest
    static void testStepThreePromise()
    {
        TriggerHandler.bypass('CommissionPayment2_TriggerHandler');
        TriggerHandler.bypass('CommissionRecord2_TriggerHandler');
        gcProjectTask.ignoreCommissions = true;
        project = ProjectTestFactory.insertCounterSale();
        System.debug('projectm');
        System.debug(project);
        AcctSeed__Project__c pr = [SELECT Id, AcctSeed__Account__c, GMBLASERP__Warehouse__c FROM AcctSeed__Project__c LIMIT 1][0];
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
        WHERE AcctSeedERP__Project__c =:pr.Id
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
    @IsTest
    static void testStepFourPromise()
    {
        TriggerHandler.bypass('CommissionPayment2_TriggerHandler');
        TriggerHandler.bypass('CommissionRecord2_TriggerHandler');
        gcProjectTask.ignoreCommissions = true;
        project = ProjectTestFactory.insertCounterSale();
        System.debug('projectm');
        System.debug(project);
        AcctSeed__Project__c pr = [SELECT Id, AcctSeed__Account__c, GMBLASERP__Warehouse__c FROM AcctSeed__Project__c LIMIT 1][0];
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
        WHERE AcctSeedERP__Project__c =:pr.Id
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