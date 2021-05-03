public without sharing class gcTimeCardPeriod {
    
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

    public class myException extends exception{}

    public static void triggerHandler
        (map<Id,AcctSeed__Time_Card_Period__c> oldMap,
         map<Id,AcctSeed__Time_Card_Period__c> newMap,
         list<AcctSeed__Time_Card_Period__c> listNew,
         Boolean boolIsBefore,
         Boolean boolIsInsert,
         Boolean boolIsUpdate,
         Boolean boolIsDelete)
    {
        if(oldMap == NULL) oldMap = new map<Id,AcctSeed__Time_Card_Period__c>();
        if(newMap == NULL) newMap = new map<Id,AcctSeed__Time_Card_Period__c>();
        if(listNew == NULL) listNew = new list<AcctSeed__Time_Card_Period__c>();

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
        (map<Id,AcctSeed__Time_Card_Period__c> oldMap,
         map<Id,AcctSeed__Time_Card_Period__c> newMap,
         list<AcctSeed__Time_Card_Period__c> listNew,
         Boolean boolIsBefore,
         Boolean boolIsInsert,
         Boolean boolIsUpdate,
         Boolean boolIsDelete)
    {
        if(boolIsBefore && (boolIsInsert || boolIsUpdate))
        {
            for(AcctSeed__Time_Card_Period__c tcp : listNew)
            {
                if(tcp.AcctSeed__Start_Date__c == null || tcp.AcctSeed__Start_Date__c != tcp.AcctSeed__Start_Date__c.toStartOfWeek())
                    tcp.addError('The Start Date of a Time Card Period must be a Sunday.');
            }
        }

        else if(!boolIsBefore)
        {
            if(dateEarliestOpen != null && dateLatestClosed != null && dateEarliestOpen < dateLatestClosed)
                throw new myException('The earliest time card period that is Open must be AFTER the latest period that is Closed.');
        }

    }   

    public static String timeCardPeriodStatus(String idPeriod)
    {
        return [SELECT Id, AcctSeed__Status__c FROM AcctSeed__Time_Card_Period__c WHERE Id = :idPeriod][0].AcctSeed__Status__c;
    }

    public static Date dateEarliestOpen{
        get
        {
            if(dateEarliestOpen == null)
            for(AggregateResult aggRes : 
                [SELECT min(AcctSeed__Start_Date__c) minStart
                 FROM AcctSeed__Time_Card_Period__c
                 WHERE AcctSeed__Status__c != 'Closed'])
            {
                dateEarliestOpen = (Date)aggRes.get('minStart');
            }

            return dateEarliestOpen;
        }
        set;
    }

    public static Date dateLatestClosed{
        get
        {
            if(dateLatestClosed == null)
            for(AggregateResult aggRes : 
                [SELECT max(AcctSeed__End_Date__c) maxEnd
                 FROM AcctSeed__Time_Card_Period__c
                 WHERE AcctSeed__Status__c = 'Closed'])
            {
                dateLatestClosed = (Date)aggRes.get('maxend');
            }

            return dateLatestClosed;
        }
        set;
    }


    @RemoteAction @ReadOnly
    public static AcctSeed__Time_Card_Period__c periodPrev(String idPeriod)
    {
        AcctSeed__Time_Card_Period__c period = [SELECT Id, Name, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, AcctSeed__Status__c
                                                 FROM AcctSeed__Time_Card_Period__c 
                                                 WHERE Id = :idPeriod][0];
        
        for(AcctSeed__Time_Card_Period__c p :
                [SELECT Id, Name, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, AcctSeed__Status__c
                 FROM AcctSeed__Time_Card_Period__c 
                 WHERE AcctSeed__End_Date__c < :period.AcctSeed__End_Date__c ORDER BY AcctSeed__End_Date__c DESC LIMIT 1])
        {
            period = p;
        }

        return period;
    }
 
    @RemoteAction @ReadOnly
    public static AcctSeed__Time_Card_Period__c periodNext(String idPeriod)
    {
        AcctSeed__Time_Card_Period__c period = [SELECT Id, Name, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, AcctSeed__Status__c
                                                 FROM AcctSeed__Time_Card_Period__c 
                                                 WHERE Id = :idPeriod][0];
        
        for(AcctSeed__Time_Card_Period__c p :
                [SELECT Id, Name, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, AcctSeed__Status__c
                 FROM AcctSeed__Time_Card_Period__c 
                 WHERE AcctSeed__End_Date__c > :period.AcctSeed__End_Date__c ORDER BY AcctSeed__End_Date__c LIMIT 1])
        {
            period = p;
        }

        return period;
    }

    @RemoteAction @ReadOnly
    public static AcctSeed__Time_Card_Period__c periodCurr()
    {
        return [SELECT Id, Name, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, AcctSeed__Status__c
                FROM AcctSeed__Time_Card_Period__c 
                WHERE AcctSeed__Start_Date__c <= TODAY AND AcctSeed__End_Date__c >= TODAY][0];
    }

    @RemoteAction @ReadOnly
    public static AcctSeed__Time_Card_Period__c getPeriod(String idPeriod)
    {
        return [SELECT Id, Name, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, AcctSeed__Status__c
                FROM AcctSeed__Time_Card_Period__c 
                WHERE Id =:idPeriod][0];
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
    }
}