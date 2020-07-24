/**
 * Created by aminrubel on 7/5/20.
 */

public with sharing class JournalEntry_Service {
    /// Create JE for Task from ERP
    @future
    public static void takeExpenseFuture(Set<Id> setIdFilter) {
        takeExpense(setIdFilter);
    }
    public static void takeExpense(Set<Id> setIdFilter) {
        System.debug(LoggingLevel.ERROR,'setIdFilter:'+setIdFilter);
        Date cogsDate = Date.today();
        list<AcctSeed__Journal_Entry_Line__c> listJEL = new list<AcctSeed__Journal_Entry_Line__c>();
        List<CommissionRecord2__c> listCR = new List<CommissionRecord2__c>();
        Map<Id, Id> mapUserGLV4 = new Map<Id, Id>();
        Map<Id, AcctSeed__Journal_Entry__c> mapProjectJE = new Map<Id, AcctSeed__Journal_Entry__c>();
        Date earliestOpenDate = GMBLASERP.gcAccountingPeriod.dateEarliestOpen();
        System.debug('earliestOpenDate');
        System.debug(earliestOpenDate);
        for (CommissionRecord2__c cr : [
            SELECT Id,
                Journal_Entry__c,
                Project__c,
                Project__r.RecordTypeId,
                Project__r.Delivery_Date__c,
                Project__r.AcctSeedERP__Work_Order_Number__c,
                Project__r.GL_Account_Variable_1__c,
                Project__r.GL_Account_Variable_2__c,
                Project__r.GL_Account_Variable_3__c,
                Project_Task__c,
                Project_Task__r.Name,
                Project_Task__r.AcctSeed__GL_Account_Variable_1__c,
                Project_Task__r.AcctSeed__GL_Account_Variable_2__c,
                Project_Task__r.AcctSeed__GL_Account_Variable_3__c,
                (SELECT Id, Owner__c, Amount__c FROM Commission_Payments__r)
            FROM CommissionRecord2__c
            WHERE Id IN :setIdFilter
        ]) {
            System.debug(LoggingLevel.ERROR,'cr:'+cr);
            for (CommissionPayment2__c cp : cr.Commission_Payments__r) {
                mapUserGLV4.put(cp.Owner__c, null);
            }
            Datetime dt = cr.Project__r.Delivery_Date__c;
            if(earliestOpenDate != null && dt != null){
                if(earliestOpenDate > dt.date()){
                    dt = Date.today();
                    //throw new gcException(earliestOpenDate.format() + ' ' + dt.format());
                }
            }
            if(dt == null) dt = Date.today();
            mapProjectJE.put(cr.Project__c, new AcctSeed__Journal_Entry__c(
                Name = 'Commission Payment - ' + cr.Project_Task__r.Name,
                AcctSeed__Journal_Date__c = dt.date(),
                AcctSeed__Status__c = 'Approved',
                Commission_Record__c = cr.Id,
                Project__c = cr.Project__c));
            listCR.add(cr);
        }
        for (AcctSeed__Accounting_Variable__c avr : [SELECT Id, User__c FROM AcctSeed__Accounting_Variable__c WHERE User__c IN:mapUserGLV4.keySet()]) {
            mapUserGLV4.put(avr.User__c, avr.Id);
        }
        System.debug(LoggingLevel.ERROR,'mapUserGLV4:'+mapUserGLV4);

        insert mapProjectJE.values();
        for (CommissionRecord2__c cr : listCR) {
            Datetime dt = cr.Project__r.Delivery_Date__c;
            if(dt == null) dt = Date.today();
            for (CommissionPayment2__c cp : cr.Commission_Payments__r) {
                Decimal amt = cp.Amount__c.setScale(6);
                Id idDebitGL = gcConstants.idGlCommissionExpense;
                Id idCreditGL = gcConstants.idGlCommissionsPayable;
                Id idGLV1 = cr.Project_Task__r.AcctSeed__GL_Account_Variable_1__c;
                Id idGLV2 = cr.Project_Task__r.AcctSeed__GL_Account_Variable_2__c;
                Id idGLV3 = cr.Project_Task__r.AcctSeed__GL_Account_Variable_3__c;
                Id idGLV4 = mapUserGLV4.get(cp.Owner__c);
                Id idProject = cr.Project__c;
                Id idProjectTask = cr.Project_Task__c;
                AcctSeed__Journal_Entry__c je = mapProjectJE.get(idProject);
                Id idJE = je.Id;
                Date jeDate = je.AcctSeed__Journal_Date__c;
                AcctSeed__Journal_Entry_Line__c debitJE = new AcctSeed__Journal_Entry_Line__c(
                    AcctSeed__Debit__c = amt,
                    AcctSeed__GL_Account__c = idDebitGL,
                    AcctSeed__Project__c = idProject,
                    AcctSeed__Project_Task__c = idProjectTask,
                    AcctSeed__Date__c = jeDate,
                    AcctSeed__Units__c = 1,
                    Commission_Payment__c = cp.Id,
                    AcctSeed__GL_Account_Variable_1__c = idGlv1,
                    AcctSeed__GL_Account_Variable_2__c = idGlv2,
                    AcctSeed__GL_Account_Variable_4__c = idGLV4,
                    AcctSeed__Journal_Entry__c = idJE
                );
                listJEL.add(debitJE);
                AcctSeed__Journal_Entry_Line__c creditJE = new AcctSeed__Journal_Entry_Line__c(
                    AcctSeed__Credit__c = amt,
                    AcctSeed__GL_Account__c = idCreditGL,
                    AcctSeed__Project__c = idProject,
                    AcctSeed__Project_Task__c = idProjectTask,
                    AcctSeed__Date__c = jeDate,
                    AcctSeed__Units__c = 1,
                    Commission_Payment__c = cp.Id,
                    AcctSeed__GL_Account_Variable_1__c = idGlv1,
                    AcctSeed__GL_Account_Variable_2__c = idGlv2,
                    AcctSeed__GL_Account_Variable_4__c = idGLV4,
                    AcctSeed__Journal_Entry__c = idJE
                );
                listJEL.add(creditJE);
                cr.Journal_Entry__c = idJE;
            }
        }
        if (!listJEL.isEmpty()) {
            insert listJEL;
            update listCR;
            AcctSeed.PostResult[] postResults = AcctSeed.JournalEntryPostService.postJournalEntries(mapProjectJE.values());
            System.debug(LoggingLevel.ERROR,'listCR:'+listCR);
        }
    }

    @future
    public static void unTakeExpenseFuture(Set<Id> setIdFilter) {
        unTakeExpense(setIdFilter);
    }
    public static void unTakeExpense(Set<Id> setIdFilter) {
        System.debug(LoggingLevel.ERROR,'setIdFilter:'+setIdFilter);
        Date earliestOpenDate = GMBLASERP.gcAccountingPeriod.dateEarliestOpen();
        Set<Id> setJEToReverse = new Set<Id>();
        List<CommissionRecord2__c> listCR = new List<CommissionRecord2__c>();
        for (CommissionRecord2__c cr : [SELECT Id, Journal_Entry__c FROM CommissionRecord2__c WHERE Id IN :setIdFilter]){
            setJEToReverse.add(cr.Journal_Entry__c);
            cr.Journal_Entry__c = null;
            listCR.add(cr);
        }
        System.debug(LoggingLevel.ERROR,'setJEToReverse:'+setJEToReverse);
        Map<Id,AcctSeed__Journal_Entry__c> mapNewJE = new Map<Id,AcctSeed__Journal_Entry__c>();
        List<AcctSeed__Journal_Entry_Line__c> listJEL = new List<AcctSeed__Journal_Entry_Line__c>();
        for(AcctSeed__Journal_Entry__c je :
            [SELECT
                Id,
                Name,
                AcctSeed__Accounting_Year__c,
                AcctSeed__Out_of_Balance__c,
                AcctSeed__Total_Credits__c,
                AcctSeed__Total_Debits__c,
                Commission_Record__c,
                Project__c,
                AcctSeed__Journal_Date__c,
                (SELECT
                    Id,
                    AcctSeed__Account__c,
                    AcctSeed__Bank_Reconciliation__c,
                    Material__c,
                    AcctSeed__GL_Account_Variable_1__c,
                    AcctSeed__GL_Account_Variable_2__c,
                    AcctSeed__GL_Account_Variable_3__c,
                    AcctSeed__GL_Account_Variable_4__c,
                    AcctSeed__Cleared_Date__c,
                    AcctSeed__Credit__c,
                    AcctSeed__Debit__c,
                    AcctSeed__Employee__c,
                    AcctSeed__GL_Account__c,
                    AcctSeed__Journal_Entry__c,
                    AcctSeed__Product__c,
                    AcctSeed__Project__c,
                    AcctSeed__Project_Task__c,
                    AcctSeed__Units__c,
                    AcctSeed__Reference__c,
                    AcctSeed__Time_Card_Variable_1__c,
                    AcctSeed__Time_Card_Variable_2__c
                FROM AcctSeed__Journal_Entry_Lines__r)
            FROM AcctSeed__Journal_Entry__c
            WHERE Id IN:setJEToReverse])
            {
                AcctSeed__Journal_Entry__c newJE = je.clone(false,true);
                newJE.Name = je.Name + '-Reversal';
                if(earliestOpenDate != null && earliestOpenDate > je.AcctSeed__Journal_Date__c){
                     newJE.AcctSeed__Journal_Date__c = Date.today();
                }
                mapNewJE.put(je.Id,newJE);
                for(AcctSeed__Journal_Entry_Line__c jel : je.AcctSeed__Journal_Entry_Lines__r)
                {
                    AcctSeed__Journal_Entry_Line__c newJEL = jel.clone(false,true);
                    newJEL.AcctSeed__Journal_Entry__c = je.Id;
                    newJEL.AcctSeed__Credit__c = jel.AcctSeed__Debit__c;
                    newJEL.AcctSeed__Debit__c = jel.AcctSeed__Credit__c;
                    listJEL.add(newJEL);
                }
            }
        System.debug(LoggingLevel.ERROR,'listJEL:'+listJEL);
        System.debug(LoggingLevel.ERROR,'listCR:'+listCR);
        System.debug(LoggingLevel.ERROR,'mapNewJE:'+mapNewJE);
        if(!listJEL.isEmpty()){
            insert mapNewJE.values();
            for(AcctSeed__Journal_Entry_Line__c jel : listJEL){
                jel.AcctSeed__Journal_Entry__c = mapNewJE.get(jel.AcctSeed__Journal_Entry__c).Id;
            }
            insert listJEL;
            AcctSeed.JournalEntryPostService.postJournalEntries(mapNewJE.values());
        }
        if(!listCR.isEmpty())
            update listCR;
    }
}
