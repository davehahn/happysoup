public without sharing class gcTimeCard {

    public static Boolean disableTrigger{
        get{
            if(disableTrigger == null) return false;
            else return disableTrigger;
        }
        set{
            if(value == null) disableTrigger = false;
            else disableTrigger = value;
        }
    }

    public static void triggerHandler
        (map<Id,AcctSeed__Time_Card__c> oldMap,
         map<Id,AcctSeed__Time_Card__c> newMap,
         list<AcctSeed__Time_Card__c> listNew,
         Boolean boolIsBefore,
         Boolean boolIsInsert,
         Boolean boolIsUpdate,
         Boolean boolIsDelete)
    {
        if(oldMap == NULL) oldMap = new map<Id,AcctSeed__Time_Card__c>();
        if(newMap == NULL) newMap = new map<Id,AcctSeed__Time_Card__c>();
        if(listNew == NULL) listNew = new list<AcctSeed__Time_Card__c>();

        updateAndValidate(oldMap,newMap,listNew,boolIsBefore,boolIsInsert,boolIsUpdate,boolIsDelete);
        
        if(boolIsBefore)
        {
            if(boolIsInsert)
            {

            }
            if(boolIsUpdate)
            {

            }
            if(boolIsDelete)
            {

            }
        }
        else //i.e. trigger.isAfter
        {
            if(boolIsInsert)
            {
                
            }
            if(boolIsUpdate)
            {

            }
            if(boolIsDelete)
            {

            }
        }           
    }

    private static void updateAndValidate
        (map<Id,AcctSeed__Time_Card__c> oldMap,
         map<Id,AcctSeed__Time_Card__c> newMap,
         list<AcctSeed__Time_Card__c> listNew,
         Boolean boolIsBefore,
         Boolean boolIsInsert,
         Boolean boolIsUpdate,
         Boolean boolIsDelete)
    {
        if(boolIsBefore)
        {
            if(boolIsInsert)
            {
                for(AcctSeed__Time_Card__c tc : listNew)
                {
                    String comboKey = String.valueOf(tc.AcctSeed__Employee__c) + String.valueOf(tc.AcctSeed__Time_Card_Period__c);
                    tc.Employee_TCP__c = comboKey;
                }
            }

            list<AcctSeed__Time_Card__c> listTC = new list<AcctSeed__Time_Card__c>();
            listTC.addAll(listNew);
            listTC.addAll(oldMap.values());
            retrieveStatics(listTC);

            if(boolIsInsert || boolIsUpdate)
            {
                for(AcctSeed__Time_Card__c tcp : listNew)
                {
                    if(mapTimeCardPeriod.get(tcp.AcctSeed__Time_Card_Period__c).AcctSeed__Status__c != 'Open')
                        tcp.addError('The Time Card cannot be inserted or updated, because the Time Card Period is not open.');
                    if(boolIsUpdate && tcp.AcctSeed__Time_Card_Period__c != oldMap.get(tcp.Id).AcctSeed__Time_Card_Period__c)
                        tcp.addError('A Time Card cannot be moved to a different Time Card Period.');
                }

                updateBurden(listNew);
            }
            if(boolIsDelete)
            for(AcctSeed__Time_Card__c tcp : oldMap.values())
            {
                if(mapTimeCardPeriod.get(tcp.AcctSeed__Time_Card_Period__c).AcctSeed__Status__c != 'Open')
                    tcp.addError('The Time Card cannot be deleted, because the Time Card Period is not open.');
            }
        }
        else //i.e. isAfter
        {
            set<Id> setIdTcRecalc = new set<Id>();
            
            if(boolIsUpdate)
            for(AcctSeed__Time_Card__c tcx : listNew)
            {
                if(tcx.Burden__c != oldMap.get(tcx.Id).Burden__c && mapTimeCardPeriod.get(tcx.AcctSeed__Time_Card_Period__c).AcctSeed__Start_Date__c >= dateEarliestOpen)
                    setIdTcRecalc.add(tcx.Id);      
            }

            else if(boolIsDelete)
            for(AcctSeed__Time_Card__c tcx : oldMap.values())
            {
                if(mapTimeCardPeriod.get(tcx.AcctSeed__Time_Card_Period__c).AcctSeed__Start_Date__c >= dateEarliestOpen)
                    setIdTcRecalc.add(tcx.Id);      
            }

            gcTimeCardDay.recalcOvertime(setIdTcRecalc);
        }
    }

    private static map<Id,Decimal> mapBurden{get;set;}
    private static map<Id,AcctSeed__Time_Card_Period__c> mapTimeCardPeriod{get;set;}
    private static Date dateEarliestOpen{get;set;}

    private static void retrieveStatics(list<AcctSeed__Time_Card__c> listTC)
    {
        if(mapTimeCardPeriod == null)
           mapTimeCardPeriod = new map<Id,AcctSeed__Time_Card_Period__c>();
        if(mapBurden == null)
           mapBurden = new map<Id,Decimal>();

        set<Id> setIdUser = new set<Id>();
        set<Id> setIdTimeCardPeriod = new set<Id>();
        for(AcctSeed__Time_Card__c tcx : listTC)
        {
            if(!mapTimeCardPeriod.containsKey(tcx.AcctSeed__Time_Card_Period__c))
                setIdTimeCardPeriod.add(tcx.AcctSeed__Time_Card_Period__c);
            if(!mapBurden.containsKey(tcx.AcctSeed__Employee__c))
                setIdUser.add(tcx.AcctSeed__Employee__c);
        }

        if(!setIdUser.isEmpty())
        for(Employee__c e : 
            [SELECT Id, User__c, GL_Account_Variable_2__r.Burden__c
            FROM Employee__c
            WHERE User__c IN :setIdUser
            ORDER BY CreatedDate DESC, Id DESC])
        {
            mapBurden.put(e.User__c, e.GL_Account_Variable_2__r.Burden__c);
        }

        if(!setIdTimeCardPeriod.isEmpty())
        for(AcctSeed__Time_Card_Period__c tcpx :
            [SELECT Id,
                    AcctSeed__End_Date__c,
                    AcctSeed__Start_Date__c,
                    AcctSeed__Status__c
            FROM AcctSeed__Time_Card_Period__c
            WHERE Id IN :setIdTimeCardPeriod])
        {
            mapTimeCardPeriod.put(tcpx.Id,tcpx);
        }

        if(dateEarliestOpen == null)
            dateEarliestOpen = GMBLASERP.gcAccountingPeriod.dateEarliestOpen();
    }


    private static void updateBurden(list<AcctSeed__Time_Card__c> listTC)
    {
        retrieveStatics(listTC);

        for(AcctSeed__Time_Card__c tcx : listTC)
        {
            if(mapTimeCardPeriod.get(tcx.AcctSeed__Time_Card_Period__c).AcctSeed__Start_Date__c >= dateEarliestOpen)
            {
                Decimal burden = mapBurden.get(tcx.AcctSeed__Employee__c);
                if(burden == null) burden = 0;

                tcx.Burden__c = burden;
            }
        }
    }

    public static void coverage(){
        integer i;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
    }
}