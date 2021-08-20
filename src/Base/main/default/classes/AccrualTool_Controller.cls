public class AccrualTool_Controller {
    
    public static Map<String,AccuralWrapper> groupingWrapper = new Map<String,AccuralWrapper>();
    public static ProductPriceWrapper prodPrice;
    public static Map<String,List<ProductPriceWrapper>> prodPriceMapExpense = new Map<String,List<ProductPriceWrapper>>();
    public static Map<String,List<ProductPriceWrapper>> prodPriceMapRevenue = new Map<String,List<ProductPriceWrapper>>();
    public static Map<String,List<ProductPriceWrapper>> prodPriceMapInsurance = new Map<String,List<ProductPriceWrapper>>();
    
    public static Map<String,Map<String,List<ProductPriceWrapper>>> departmentMapExpense = new Map<String,Map<String,List<ProductPriceWrapper>>>();
    public static Map<String,Map<String,List<ProductPriceWrapper>>> departmentMapRevenue = new Map<String,Map<String,List<ProductPriceWrapper>>>();
    public static Map<String,Map<String,List<ProductPriceWrapper>>> departmentMapInsurance = new Map<String,Map<String,List<ProductPriceWrapper>>>();
    
    public static Map<Id,JournalEntryLineWrapper> jounralEntryLineWrapperExpense = new Map<Id,JournalEntryLineWrapper>();
    public static Map<Id,JournalEntryLineWrapper> jounralEntryLineWrapperRevenue = new Map<Id,JournalEntryLineWrapper>();
    public static Map<Id,JournalEntryLineWrapper> jounralEntryLineWrapperInsurance = new Map<Id,JournalEntryLineWrapper>();
    public static List<JournalEntryLineWrapper> journalEntryLineWrapperList = new List<JournalEntryLineWrapper>();
    
    public static Map<String,Accrual_Tool_GLAccount_Setting__mdt> accrualSettingMap = new Map<String,Accrual_Tool_GLAccount_Setting__mdt>();
    public static List<Accrual_Tool_GLAccount_Setting__mdt> accrualSettings = [Select Id,Accrual_Type__c,GLAccount__c,GLV1__c,GLV2__c FROM Accrual_Tool_GLAccount_Setting__mdt];
    
    public static Map<String,Id> glAccMap = new Map<String,Id>();
    public static Map<String,Id> glVMap = new Map<String,Id>();
    public static List<String> glAccounts = new List<String>();
    public static List<String> glVs = new List<String>();
    
    //Fetch Factory PriceBook
    public static Id factoryPriceBook = gcConstants.idPricebookFactory;
    public static Map<Id,Decimal> factoryPrice = new Map<Id,Decimal>();
    
    @AuraEnabled(Cacheable=true)
    public static AcctSeed__Project__c fetchERPData( String erpId )
    {
        system.debug('erpId >> '+erpId);
        AcctSeed__Project__c erpRec ;
        for(AcctSeed__Project__c erp : [SELECT Id,Name,Stage__c,AcctSeed__Status__c,(Select Id From Journal_Entries__r) FROM AcctSeed__Project__c WHERE Id=:erpId LIMIT 1]) {
            erpRec = erp;
        }
        return erpRec;
    }
    
    @AuraEnabled
    public static CommissionWrapper fetchCommissionRecords( String erpId )
    {
        system.debug('erpId >> '+erpId);
        
        List<CommissionRecordWrapper> commissionRecordsList = new List<CommissionRecordWrapper>();
        List<CommissionPaymentWrapper> commPaymentWrapperList = new List<CommissionPaymentWrapper>();
        Map<String,List<CommissionPaymentRecordsWrapper>> commPaymentMap = new Map<String,List<CommissionPaymentRecordsWrapper>>();
        
        Boolean allReviewed = true;
        for(CommissionRecord2__c commissionRecord : [SELECT Id,Name,Status__c,Project_Task__r.Name,
                                                     Project_Task__r.AcctSeed__Labor_GL_Account__c,Project_Task__r.AcctSeed__Labor_GL_Account__r.name,
                                                     Project_Task__r.AcctSeed__GL_Account_Variable_1__c,Project_Task__r.AcctSeed__GL_Account_Variable_1__r.name,
                                                     Project_Task__r.AcctSeed__GL_Account_Variable_2__c,Project_Task__r.AcctSeed__GL_Account_Variable_2__r.name,
                                                     (Select id,Status__c,Amount__c,Commission_Record2__r.Name
                                                      from Commission_Payments__r) 
                                                     FROM CommissionRecord2__c WHERE Project__c=:erpId])
        {
            if(allReviewed && commissionRecord.Status__c != 'Reviewed') {
                allReviewed = false;
            }
            commissionRecordsList.add(new CommissionRecordWrapper(commissionRecord));
            
            if(!commPaymentMap.containsKey(commissionRecord.Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name)) {
                commPaymentMap.put(commissionRecord.Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name, new List<CommissionPaymentRecordsWrapper>());
            }
            for(CommissionPayment2__c commPmnt : commissionRecord.Commission_Payments__r) {
                commPaymentMap.get(commissionRecord.Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name).add(
                    new CommissionPaymentRecordsWrapper(
                        commissionRecord.Project_Task__r.Name,commissionRecord.Status__c,commPmnt.Amount__c,commissionRecord.Project_Task__r.AcctSeed__Labor_GL_Account__c,
                        commissionRecord.Project_Task__r.AcctSeed__Labor_GL_Account__r.name,
                        commissionRecord.Project_Task__r.AcctSeed__GL_Account_Variable_1__c,commissionRecord.Project_Task__r.AcctSeed__GL_Account_Variable_1__r.name,
                        commissionRecord.Project_Task__r.AcctSeed__GL_Account_Variable_2__c,commissionRecord.Project_Task__r.AcctSeed__GL_Account_Variable_2__r.name
                    ));
            }
        }
        for(String dept: commPaymentMap.keyset()) {
            commPaymentWrapperList.add(new CommissionPaymentWrapper(dept,commPaymentMap.get(dept)));
        }
        system.debug('commissionRecords >> '+commissionRecordsList);
        system.debug('commPaymentWrapperList >> '+commPaymentWrapperList);
        
        CommissionWrapper commWrapper = new CommissionWrapper(allReviewed,commissionRecordsList,commPaymentWrapperList);
        
        return commWrapper;
    }
    
    @AuraEnabled
    public static List<ProductWrapper> fetchSerializedProducts( String erpId )
    {
        system.debug('erpId >> '+erpId);
        List<ProductWrapper> prodList = new List<ProductWrapper>();
        List<Id> prodIdList = new List<Id>();
        for(AcctSeedERP__Material__c material : [select id,Serial_Number__c,AcctSeedERP__Product__c,AcctSeedERP__Product__r.Name,
                                                 AcctSeedERP__Product__r.AcctSeedERP__Serialized__c ,AcctSeedERP__Product__r.Status__c,AcctSeedERP__Product__r.Physical_Location__c
                                                 from AcctSeedERP__Material__c 
                                                 where AcctSeedERP__Product__r.AcctSeedERP__Serialized__c = true 
                                                 AND AcctSeedERP__Project__c =:erpId]) 
        {
            prodIdList.add(material.AcctSeedERP__Product__c);
            //prodList.add(new ProductWrapper(material.Serial_Number__c,material.AcctSeedERP__Product__r.Name,material.AcctSeedERP__Product__r.Status__c,material.AcctSeedERP__Product__r.Physical_Location__c ));
        }
        
        for(Product2 prod : [Select Id,Name,Status__c,(Select Id,Name,Status__c,Location__c From GMBLASERP__Serial_Numbers__r) From Product2 Where Id IN: prodIdList])
        {
            for(GMBLASERP__Serial_Number__c sn : prod.GMBLASERP__Serial_Numbers__r) {
                prodList.add(new ProductWrapper(sn.Name,prod.Name,sn.Status__c,sn.Location__c ));
                break;
            }
        }
        system.debug('prodList >> '+prodList);
        return prodList;
    }
    
    public static void fetchCustomSetting(){
        //Process Accrual Tool Custom Metadata
        List<Accrual_Tool_GLAccount_Setting__mdt> accrualSettings = [Select Id,Accrual_Type__c,GLAccount__c,GLV1__c,GLV2__c FROM Accrual_Tool_GLAccount_Setting__mdt];
        
        for(Accrual_Tool_GLAccount_Setting__mdt accrualSetting : accrualSettings) {
            accrualSettingMap.put(accrualSetting.Accrual_Type__c,accrualSetting);
            glAccounts.add(accrualSetting.GLAccount__c);
            glVs.add(accrualSetting.GLV1__c);
            glVs.add(accrualSetting.GLV2__c);
        }
    }
    public static void fetchGLAccounts(){
        for(AcctSeed__GL_Account__c glAcc : [Select Id,Name from AcctSeed__GL_Account__c Where Name IN:glAccounts]) {
            glAccMap.put(glAcc.Name,glAcc.Id);
        }
        for(AcctSeed__Accounting_Variable__c glv : [Select Id,Name from AcctSeed__Accounting_Variable__c Where Name IN:glVs]) {
            glVMap.put(glv.Name,glv.Id);
        }
    }
    public static void fetchFactoryPrice( String erpId ){
        for(Product2 prod : [SELECT Id, Landed_Unit_Cost__c, Partner_Price__c, 
                             (SELECT Id, UnitPrice FROM PricebookEntries 
                              WHERE Pricebook2Id =:factoryPriceBook 
                              and Product2Id IN (select AcctSeedERP__Product__c from AcctSeedERP__Material__c Where AcctSeedERP__Project__c =:erpId) 
                              ORDER BY CreatedDate DESC LIMIT 1)  FROM Product2])
        {
            for(PricebookEntry pbe : prod.PricebookEntries) {
                factoryPrice.put(prod.Id,pbe.UnitPrice);
            }
        }
    }
    public static void processERPLine(AcctSeedERP__Material__c material){
        prodPrice = new ProductPriceWrapper(material.AcctSeedERP__Product__r.Name,material.GMBLASERP__Total_Price__c);
        if(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c != null 
           && material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.AcctSeed__Type__c == 'Expense') // Expense GL Account 
        {
            system.debug('Expense Type >> ');
            //process for both Expense and Insurance
            if(material.AcctSeedERP__Product__r.RecordType.Name == 'Insurance') {
                
                if(!departmentMapInsurance.containsKey(material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name)) {
                    departmentMapInsurance.put(material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,new Map<String,List<ProductPriceWrapper>>());
                }
                prodPriceMapInsurance = departmentMapInsurance.get(material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name);
                
                if(!prodPriceMapInsurance.containsKey(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name)) {
                    prodPriceMapInsurance.put(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name, new List<ProductPriceWrapper>());
                }
                prodPriceMapInsurance.get(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name).add(prodPrice);
                
                departmentMapInsurance.put(material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,prodPriceMapInsurance);
                system.debug('prodPriceMapInsurance >> '+prodPriceMapInsurance);
                
                if(!jounralEntryLineWrapperInsurance.containsKey(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c)) {
                    jounralEntryLineWrapperInsurance.put(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c,
                                                         new JournalEntryLineWrapper(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c,
                                                                                     material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name,
                                                                                     material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__c,
                                                                                     material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__r.Name,
                                                                                     material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__c,
                                                                                     material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,
                                                                                     material.GMBLASERP__Total_Price__c,0.0));
                } else {
                    JournalEntryLineWrapper Insurance = jounralEntryLineWrapperInsurance.get(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c);
                    Insurance.Debit = Insurance.Debit + material.GMBLASERP__Total_Price__c;
                    jounralEntryLineWrapperInsurance.put(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c,Insurance);
                }
            }
            else {
                
                //Use factory price here
                ProductPriceWrapper newProdPrice = prodPrice; 
                if(factoryPrice.containsKey(material.AcctSeedERP__Product__c)) {
                    newProdPrice = new ProductPriceWrapper(material.AcctSeedERP__Product__r.Name,factoryPrice.get(material.AcctSeedERP__Product__c));
                } else {
                    return;
                }
                if(!departmentMapExpense.containsKey(material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name)) {
                    departmentMapExpense.put(material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,new Map<String,List<ProductPriceWrapper>>());
                }
                prodPriceMapExpense = departmentMapExpense.get(material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name);
                
                if(!prodPriceMapExpense.containsKey(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name)) {
                    prodPriceMapExpense.put(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name, new List<ProductPriceWrapper>());
                }
                prodPriceMapExpense.get(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name).add(newProdPrice);
                
                departmentMapExpense.put(material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,prodPriceMapExpense);
                system.debug('prodPriceMapExpense >> '+prodPriceMapExpense);
                
                if(!jounralEntryLineWrapperExpense.containsKey(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c)) {
                    jounralEntryLineWrapperExpense.put(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c,
                                                       new JournalEntryLineWrapper(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c,
                                                                                   material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name,
                                                                                   material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__c,
                                                                                   material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__r.Name,
                                                                                   material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__c,
                                                                                   material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,
                                                                                   material.GMBLASERP__Total_Price__c,0.0));
                } else {
                    JournalEntryLineWrapper Expense = jounralEntryLineWrapperExpense.get(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c);
                    Expense.Debit = Expense.Debit + material.GMBLASERP__Total_Price__c;
                    jounralEntryLineWrapperExpense.put(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c,Expense);
                }
            }
        } 
        if(material.AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__c != null 
           && material.AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.AcctSeed__Type__c == 'Revenue')
        {
            system.debug('revenue GL >> ');
            //process for Revenue 
            
            if(!departmentMapRevenue.containsKey(material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name)) {
                departmentMapRevenue.put(material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,new Map<String,List<ProductPriceWrapper>>());
            }
            prodPriceMapRevenue = departmentMapRevenue.get(material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name);
            
            if(!prodPriceMapRevenue.containsKey(material.AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.Name)) {
                prodPriceMapRevenue.put(material.AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.Name, new List<ProductPriceWrapper>());
            }
            prodPriceMapRevenue.get(material.AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.Name).add(prodPrice);
            
            departmentMapRevenue.put(material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,prodPriceMapRevenue);
            system.debug('prodPriceMapRevenue >> '+prodPriceMapRevenue);
            
            if(!jounralEntryLineWrapperRevenue.containsKey(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c)) {
                jounralEntryLineWrapperRevenue.put(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c,
                                                   new JournalEntryLineWrapper(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c,
                                                                               material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name,
                                                                               material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__c,
                                                                               material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__r.Name,
                                                                               material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__c,
                                                                               material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,
                                                                               0.0,material.GMBLASERP__Total_Price__c));
            } else {
                JournalEntryLineWrapper Revenue = jounralEntryLineWrapperRevenue.get(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c);
                Revenue.Credit = Revenue.Credit + material.GMBLASERP__Total_Price__c;
                jounralEntryLineWrapperRevenue.put(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c,Revenue);
            }
        }
    }
    
    public static void pricessJournalLines(String erpId){
        Decimal journalDebitTotal = 0.0;
        Decimal journalCreditTotal = 0.0;
        Decimal revenueGLTotal = 0.0;
        for(JournalEntryLineWrapper lineWrapper: jounralEntryLineWrapperRevenue.values()) {
            revenueGLTotal += lineWrapper.Credit;
            journalCreditTotal += lineWrapper.Credit;
        }
        JournalEntryLineWrapper revenueGL = new JournalEntryLineWrapper(
            glAccMap.get(accrualSettingMap.get('Revenue').GLAccount__c),accrualSettingMap.get('Revenue').GLAccount__c,
            glVMap.get(accrualSettingMap.get('Revenue').GLV1__c),accrualSettingMap.get('Revenue').GLV1__c,
            glVMap.get(accrualSettingMap.get('Revenue').GLV2__c),accrualSettingMap.get('Revenue').GLV2__c,
            revenueGLTotal,0.0
        );
        journalDebitTotal+=revenueGLTotal;
        
        Decimal expenseGLTotal = 0.0;
        for(JournalEntryLineWrapper lineWrapper: jounralEntryLineWrapperExpense.values()) {
            expenseGLTotal += lineWrapper.Debit;
            journalDebitTotal += lineWrapper.Debit;
        }
        JournalEntryLineWrapper expenseGL = new JournalEntryLineWrapper(
            glAccMap.get(accrualSettingMap.get('Expense').GLAccount__c),accrualSettingMap.get('Expense').GLAccount__c,
            glVMap.get(accrualSettingMap.get('Expense').GLV1__c),accrualSettingMap.get('Expense').GLV1__c,
            glVMap.get(accrualSettingMap.get('Expense').GLV2__c),accrualSettingMap.get('Expense').GLV2__c,
            0.0,expenseGLTotal
        );
        journalCreditTotal+=expenseGLTotal;
        
        Decimal insuranceGLTotal = 0.0;
        for(JournalEntryLineWrapper lineWrapper: jounralEntryLineWrapperInsurance.values()) {
            insuranceGLTotal += lineWrapper.Debit;
            journalDebitTotal += lineWrapper.Debit;
        }
        JournalEntryLineWrapper insuranceGL = new JournalEntryLineWrapper(
            glAccMap.get(accrualSettingMap.get('Insurance').GLAccount__c),accrualSettingMap.get('Insurance').GLAccount__c,
            glVMap.get(accrualSettingMap.get('Insurance').GLV1__c),accrualSettingMap.get('Insurance').GLV1__c,
            glVMap.get(accrualSettingMap.get('Insurance').GLV2__c),accrualSettingMap.get('Insurance').GLV2__c,
            0.0,insuranceGLTotal
        );
        journalCreditTotal+=insuranceGLTotal;
        
        Map<Id,JournalEntryLineWrapper> jounralEntryLineWrapperCommission = new Map<Id,JournalEntryLineWrapper>();
        CommissionWrapper commWrapper = fetchCommissionRecords( erpId );
            
        for(CommissionPaymentWrapper commPaymentWrapper : commWrapper.commPaymentWrapper) {
            for(CommissionPaymentRecordsWrapper commPayments : commPaymentWrapper.commPayments) {
                if(!jounralEntryLineWrapperCommission.containsKey(commPayments.GLAccountId)) {
                    jounralEntryLineWrapperCommission.put(commPayments.GLAccountId,
                                                          new JournalEntryLineWrapper(commPayments.GLAccountId,
                                                                                      commPayments.GLAccountName,
                                                                                      commPayments.GLV1Id,
                                                                                      commPayments.GLV1Name,
                                                                                      commPayments.GLV2Id,
                                                                                      commPayments.GLV2Name,
                                                                                      0.0,
                                                                                      commPayments.Amount));
                } else {
                    JournalEntryLineWrapper commission = jounralEntryLineWrapperCommission.get(commPayments.GLAccountId);
                    commission.Credit = commission.Credit + commPayments.Amount;
                    jounralEntryLineWrapperCommission.put(commPayments.GLAccountId,commission);
                }
            }
        }
        Decimal commissionGLTotal = 0.0;
        for(JournalEntryLineWrapper lineWrapper: jounralEntryLineWrapperCommission.values()) {
            commissionGLTotal += lineWrapper.Credit;
            journalCreditTotal += lineWrapper.Credit;
        }
        JournalEntryLineWrapper commissionGL = new JournalEntryLineWrapper(
            glAccMap.get(accrualSettingMap.get('Commission').GLAccount__c),accrualSettingMap.get('Commission').GLAccount__c,
            glVMap.get(accrualSettingMap.get('Commission').GLV1__c),accrualSettingMap.get('Commission').GLV1__c,
            glVMap.get(accrualSettingMap.get('Commission').GLV2__c),accrualSettingMap.get('Commission').GLV2__c,
            commissionGLTotal,0.0
        );
        journalDebitTotal+=commissionGLTotal;
        
        
        groupingWrapper.put('TotalDebit',new AccuralWrapper(journalDebitTotal,null,null));
        groupingWrapper.put('TotalCredit',new AccuralWrapper(journalCreditTotal,null,null));
        
        journalEntryLineWrapperList.addAll(jounralEntryLineWrapperRevenue.values());
        journalEntryLineWrapperList.add(revenueGL);
        journalEntryLineWrapperList.addAll(jounralEntryLineWrapperExpense.values());
        journalEntryLineWrapperList.add(expenseGL);
        journalEntryLineWrapperList.addAll(jounralEntryLineWrapperInsurance.values());
        journalEntryLineWrapperList.add(insuranceGL);
        journalEntryLineWrapperList.addAll(jounralEntryLineWrapperCommission.values());
        journalEntryLineWrapperList.add(commissionGL);
        
        system.debug('journalEntryLineWrapperList >> '+journalEntryLineWrapperList);
        groupingWrapper.put('JournalLines',new AccuralWrapper(null,null,journalEntryLineWrapperList));
    }
    
    public static void processRevenueWrapper(){        
        List<DepartmentWrapper> revenueWrapper = new List<DepartmentWrapper>();
        Decimal totalAmount = 0.0;
        for(String department: departmentMapRevenue.keyset()) {
            List<LineItemWrapper> lineItemWrapp = new List<LineItemWrapper>();
            Map<String,List<ProductPriceWrapper>> tmpMap = departmentMapRevenue.get(department);
            for(String glAccount : tmpMap.keyset()) {
                Decimal totalPrice = 0.0;
                for(ProductPriceWrapper prodPriceVar : tmpMap.get(glAccount)) {
                    totalPrice += prodPriceVar.price;
                    totalAmount += prodPriceVar.price;
                }
                
                lineItemWrapp.add(new LineItemWrapper(tmpMap.get(glAccount),glAccount,totalPrice));
            }
            revenueWrapper.add(new DepartmentWrapper(department,lineItemWrapp));
        }
        groupingWrapper.put('Revenue',new AccuralWrapper(totalAmount,revenueWrapper,null));
        
    }
    
    public static void processExpenseWrapper(){
        List<DepartmentWrapper> expenseWrapper = new List<DepartmentWrapper>();
        
        Decimal totalAmount = 0.0;
        for(String department: departmentMapExpense.keyset()) {
            List<LineItemWrapper> lineItemWrapp = new List<LineItemWrapper>();
            Map<String,List<ProductPriceWrapper>> tmpMap = departmentMapExpense.get(department);
            for(String glAccount : tmpMap.keyset()) {
                Decimal totalPrice = 0.0;
                for(ProductPriceWrapper prodPriceVar : tmpMap.get(glAccount)) {
                    totalPrice += prodPriceVar.price;
                    totalAmount += prodPriceVar.price;
                }
                
                lineItemWrapp.add(new LineItemWrapper(tmpMap.get(glAccount),glAccount,totalPrice));
            }
            expenseWrapper.add(new DepartmentWrapper(department,lineItemWrapp));
        }
        groupingWrapper.put('Expense',new AccuralWrapper(totalAmount,expenseWrapper,null));
    }
    
    public static void processInsuranceWrapper(){
        List<DepartmentWrapper> InsuranceWrapper = new List<DepartmentWrapper>();
        
        Decimal totalAmount = 0.0;
        for(String department: departmentMapInsurance.keyset()) {
            List<LineItemWrapper> lineItemWrapp = new List<LineItemWrapper>();
            Map<String,List<ProductPriceWrapper>> tmpMap = departmentMapInsurance.get(department);
            for(String glAccount : tmpMap.keyset()) {
                Decimal totalPrice = 0.0;
                for(ProductPriceWrapper prodPriceVar : tmpMap.get(glAccount)) {
                    totalPrice += prodPriceVar.price;
                    totalAmount += prodPriceVar.price;
                }
                
                lineItemWrapp.add(new LineItemWrapper(tmpMap.get(glAccount),glAccount,totalPrice));
            }
            insuranceWrapper.add(new DepartmentWrapper(department,lineItemWrapp));
        }
        groupingWrapper.put('Insurance',new AccuralWrapper(totalAmount,insuranceWrapper,null));
    }
    
    @AuraEnabled
    public static Map<String,AccuralWrapper> fetchOrderLines( String erpId )
    {
        system.debug('erpId >> '+erpId);
        
        fetchCustomSetting();
        fetchGLAccounts();
        fetchFactoryPrice(erpId);
        
        for(AcctSeedERP__Material__c material : [select id,Serial_Number__c,AcctSeedERP__Product__c,AcctSeedERP__Product__r.Name,GMBLASERP__Total_Price__c,
                                                 AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c,AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name,AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.AcctSeed__Type__c,
                                                 AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__c,AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.Name,AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.AcctSeed__Type__c,
                                                 AcctSeedERP__Product__r.RecordType.Name,
                                                 AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__c,AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__r.Name,
                                                 AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__c,AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name
                                                 from AcctSeedERP__Material__c 
                                                 where AcctSeedERP__Project__c =:erpId]) 
        {
            processERPLine(material);
        }
        
        pricessJournalLines(erpId);
        processRevenueWrapper();
        processExpenseWrapper();
        processInsuranceWrapper();
        
        system.debug('groupingWrapper >> '+groupingWrapper);
        return groupingWrapper;
    }
    
    @AuraEnabled
    public static String createJournalEntry(String erpId, String jounralEntryDate) {
        
        system.debug('erpId >> '+erpId);
        system.debug('jounralEntryDate >> '+jounralEntryDate);
        
        String message = 'Success';
        Map<String,AccuralWrapper> groupingWrapper = fetchOrderLines(erpId);
        AccuralWrapper wrapper = groupingWrapper.get('JournalLines');
        List<JournalEntryLineWrapper> journalEntryLineWrapper = wrapper.journalEntryLineWrapper;
        
        Date jeDate = Date.valueOf(jounralEntryDate);
        
        Savepoint sp = Database.setSavepoint();
        try{
            AcctSeed__Project__c project = [SELECT Id,Name,Stage__c,AcctSeed__Status__c,AcctSeedERP__Work_Order_Number__c
                                            FROM AcctSeed__Project__c WHERE Id=:erpId LIMIT 1];
            
            List<AcctSeed__Journal_Entry__c> existingEntry = [Select Id From AcctSeed__Journal_Entry__c Where Project__c =:project.Id];
            
            List<AcctSeed__Journal_Entry_Line__c> journalEntries = new List<AcctSeed__Journal_Entry_Line__c>();
            AcctSeed__Journal_Entry__c journalEntry = new AcctSeed__Journal_Entry__c(
                Name = 'Accrual Entry - '+project.Name,
                AcctSeed__Journal_Date__c = jeDate,
                AcctSeed__Status__c = 'Approved',
                Project__c = project.Id
            );
            
            if(existingEntry.size() > 0) {
                journalEntry.Id = existingEntry[0].Id;
            }
            
            upsert journalEntry;
            
            if(existingEntry.size() > 0) {
                // delete existing lines
                delete ([Select Id From AcctSeed__Journal_Entry_Line__c Where AcctSeed__Journal_Entry__c =:journalEntry.Id]);
            }
            for(JournalEntryLineWrapper wrap : journalEntryLineWrapper) {
                
                AcctSeed__Journal_Entry_Line__c je = new AcctSeed__Journal_Entry_Line__c();
                je.AcctSeed__GL_Account__c = wrap.GLAccountId;
                if(wrap.Credit != null && wrap.Credit > 0.0) {
                    je.AcctSeed__Credit__c = wrap.Credit;
                } else {
                    je.AcctSeed__Debit__c = wrap.Debit;
                }
                //je.AcctSeed__Project__c = project.Id;
                je.AcctSeed__GL_Account_Variable_1__c = wrap.GLV1Id;
                je.AcctSeed__GL_Account_Variable_2__c = wrap.GLV2Id;
                je.AcctSeed__Date__c = jeDate;
                je.AcctSeed__Units__c = 1;
                je.AcctSeed__Journal_Entry__c = journalEntry.Id;
                
                journalEntries.add(je);
            }
            
            insert journalEntries;
            AcctSeed.JournalEntryPostService.postJournalEntries(new List<AcctSeed__Journal_Entry__c>{journalEntry});
        }
        catch(Exception e) {
            Database.rollback(sp);
            system.debug('Exception - '+e);
            message = e.getMessage();
        }
        return message;
        
    }
    
    public class ProductWrapper {
        @AuraEnabled public string serialNumber;
        @AuraEnabled public string productName;
        @AuraEnabled public string Status;
        @AuraEnabled public string Location;
        
        public ProductWrapper(string serialNumber,string productName,string Status,string Location) {
            this.serialNumber = serialNumber;
            this.productName = productName;
            this.Status = Status;
            this.Location = Location;
        }
    }
    public class CommissionWrapper {
        @AuraEnabled public Boolean isReviewed;
        @AuraEnabled public List<CommissionRecordWrapper> commissionRecordsList;
        @AuraEnabled public List<CommissionPaymentWrapper> commPaymentWrapper;
        
        public CommissionWrapper(Boolean isReviewed, List<CommissionRecordWrapper> commissionRecordsList, List<CommissionPaymentWrapper> commPaymentWrapper) {
            this.isReviewed = isReviewed;
            this.commissionRecordsList = commissionRecordsList;
            this.commPaymentWrapper = commPaymentWrapper;
        }
    }
    public class CommissionRecordWrapper {
        @AuraEnabled public Boolean isReviewed;
        @AuraEnabled public CommissionRecord2__c commissionRecord;
        
        public CommissionRecordWrapper(CommissionRecord2__c commissionRecord) {
            this.commissionRecord = commissionRecord;
            this.isReviewed = commissionRecord.Status__c == 'Reviewed' ? true : false;
        }
    }
    public class CommissionPaymentWrapper {
        @AuraEnabled public String Department;
        @AuraEnabled public List<CommissionPaymentRecordsWrapper> commPayments;
        
        public CommissionPaymentWrapper(String Department, List<CommissionPaymentRecordsWrapper> commPayments) {
            this.Department = Department;
            this.commPayments = commPayments;
        }
    }
    public class CommissionPaymentRecordsWrapper {
        @AuraEnabled public String Name;
        @AuraEnabled public String Status;
        @AuraEnabled public Decimal Amount;
        @AuraEnabled public String GLAccountId;
        @AuraEnabled public String GLAccountName;
        @AuraEnabled public String GLV1Id;
        @AuraEnabled public String GLV1Name;
        @AuraEnabled public String GLV2Id;
        @AuraEnabled public String GLV2Name;
        
        public CommissionPaymentRecordsWrapper(String Name, String Status, Decimal Amount, String GLAccountId, String GLAccountName,String GLV1Id,String GLV1Name,String GLV2Id,String GLV2Name) {
            this.Name = Name;
            this.Status = Status;
            this.Amount = Amount;
            this.GLAccountId = GLAccountId;
            this.GLAccountName = GLAccountName;
            this.GLV1Id = GLV1Id;
            this.GLV1Name = GLV1Name;
            this.GLV2Id = GLV2Id;
            this.GLV2Name = GLV2Name;
        }
    }
    
    public class AccuralWrapper {
        @AuraEnabled public Decimal totalAmount;
        @AuraEnabled public List<DepartmentWrapper> departmentWrapper;
        @AuraEnabled public List<JournalEntryLineWrapper> journalEntryLineWrapper;
        
        public AccuralWrapper(Decimal totalAmount, List<DepartmentWrapper> departmentWrapper, List<JournalEntryLineWrapper> journalEntryLineWrapper) {
            this.departmentWrapper = departmentWrapper;
            this.journalEntryLineWrapper = journalEntryLineWrapper;
            this.totalAmount = totalAmount;
        }
    }  
    public class DepartmentWrapper {
        @AuraEnabled public String Department;
        @AuraEnabled public List<LineItemWrapper> lineItemWrapperList;
        
        public DepartmentWrapper(String Department, List<LineItemWrapper> lineItemWrapperList) {
            this.lineItemWrapperList = lineItemWrapperList;
            this.Department = Department;
        }
    }    
    public class LineItemWrapper {
        @AuraEnabled public List<ProductPriceWrapper> productPriceWrapperList;
        @AuraEnabled public String GLAccountName;
        @AuraEnabled public Decimal totalPrice;
        
        public LineItemWrapper(List<ProductPriceWrapper> productPriceWrapperList, String GLAccountName,Decimal totalPrice) {
            this.productPriceWrapperList = productPriceWrapperList;
            this.GLAccountName = GLAccountName;
            this.totalPrice = totalPrice;
        }
    }
    public class ProductPriceWrapper {
        @AuraEnabled public String productName;
        @AuraEnabled public String profit;
        @AuraEnabled public Decimal price;
        @AuraEnabled public Decimal cost;
        
        public ProductPriceWrapper(String productName,Decimal price) {
            this.productName = productName;
            this.price = price;
            this.profit = '50%';
            this.cost = price*(1-0.5);
        }
    }
    public class JournalEntryLineWrapper {
        @AuraEnabled public String GLAccountId;
        @AuraEnabled public String GLAccountName;
        @AuraEnabled public String GLV1Id;
        @AuraEnabled public String GLV1Name;
        @AuraEnabled public String GLV2Id;
        @AuraEnabled public String GLV2Name;
        @AuraEnabled public Decimal Debit;
        @AuraEnabled public Decimal Credit;
        
        public JournalEntryLineWrapper(String GLAccountId,String GLAccountName,String GLV1Id,String GLV1Name,String GLV2Id,String GLV2Name,Decimal Debit,Decimal Credit) {
            this.GLAccountId = GLAccountId;
            this.GLAccountName = GLAccountName;
            this.GLV1Id  = GLV1Id;
            this.GLV1Name = GLV1Name;
            this.GLV2Id = GLV2Id;
            this.GLV2Name = GLV2Name;
            this.Debit = Debit;
            this.Credit = Credit;
        }
    }
}