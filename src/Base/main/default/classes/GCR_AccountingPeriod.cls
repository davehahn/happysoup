/**
 * Created by Legend on 28/7/21.
 */

public without sharing class GCR_AccountingPeriod {

    public GCR_AccountingPeriod(ApexPages.StandardController ctrl){}
    public GCR_AccountingPeriod(){}

    @RemoteAction @ReadOnly
    public static AcctSeed__Accounting_Period__c periodPrev(String idPeriod)
    {
        AcctSeed__Accounting_Period__c period = [SELECT Id, Name, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, AcctSeed__Status__c
        FROM AcctSeed__Accounting_Period__c
        WHERE Id = :idPeriod][0];

        for(AcctSeed__Accounting_Period__c p :
        [SELECT Id, Name, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, AcctSeed__Status__c
        FROM AcctSeed__Accounting_Period__c
        WHERE AcctSeed__End_Date__c < :period.AcctSeed__End_Date__c ORDER BY AcctSeed__End_Date__c DESC LIMIT 1])
        {
            period = p;
        }

        return period;
    }

    @RemoteAction @ReadOnly
    public static AcctSeed__Accounting_Period__c periodNext(String idPeriod)
    {
        AcctSeed__Accounting_Period__c period = [SELECT Id, Name, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, AcctSeed__Status__c
        FROM AcctSeed__Accounting_Period__c
        WHERE Id = :idPeriod][0];

        for(AcctSeed__Accounting_Period__c p :
        [SELECT Id, Name, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, AcctSeed__Status__c
        FROM AcctSeed__Accounting_Period__c
        WHERE AcctSeed__End_Date__c > :period.AcctSeed__End_Date__c ORDER BY AcctSeed__End_Date__c LIMIT 1])
        {
            period = p;
        }

        return period;
    }

    @RemoteAction @ReadOnly
    public static AcctSeed__Accounting_Period__c periodCurr()
    {
        return [SELECT Id, Name, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, AcctSeed__Status__c
        FROM AcctSeed__Accounting_Period__c
        WHERE AcctSeed__Start_Date__c <= TODAY AND AcctSeed__End_Date__c >= TODAY][0];
    }

    @RemoteAction @ReadOnly
    public static AcctSeed__Accounting_Period__c periodThis(String idPeriod)
    {
        AcctSeed__Accounting_Period__c period = new AcctSeed__Accounting_Period__c();
        for(AcctSeed__Accounting_Period__c p :
        [SELECT Id, Name, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, AcctSeed__Status__c
        FROM AcctSeed__Accounting_Period__c
        WHERE Id = :idPeriod])
        {
            period = p;
        }

        if(period.Id == NULL)
            return periodCurr();
        else
                return period;
    }

    @RemoteAction @ReadOnly
    public static list<AcctSeed__Accounting_Period__c> periodAll()
    {
        return [SELECT Id, Name, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, AcctSeed__Status__c
        FROM AcctSeed__Accounting_Period__c
        ORDER BY AcctSeed__Start_Date__c DESC];
    }

    @RemoteAction @ReadOnly
    public static AcctSeed__Accounting_Period__c periodYearStart(String idPeriod)
    {
        AcctSeed__Accounting_Period__c periodThis = periodThis(idPeriod);
        AcctSeed__Accounting_Period__c periodYearStart = new AcctSeed__Accounting_Period__c();

        String strYear = periodThis.Name.LEFT(4)+'%';

        for(AcctSeed__Accounting_Period__c p :
        [SELECT Id, Name, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, AcctSeed__Status__c
        FROM AcctSeed__Accounting_Period__c
        WHERE Name LIKE :strYear
        ORDER BY AcctSeed__Start_Date__c
        LIMIT 1])
        {
            periodYearStart = p;
        }
        if(periodYearStart.Id == null) periodYearStart = periodThis;

        return periodYearStart;
    }

    @RemoteAction @ReadOnly
    public static set<Id> periodPriorAllId(String idPeriod)
    {
        AcctSeed__Accounting_Period__c period = [SELECT Id, AcctSeed__Start_Date__c, AcctSeed__End_Date__c FROM AcctSeed__Accounting_Period__c WHERE Id = :idPeriod][0];

        //collect all periods prior to and including the selected period
        set<Id> setIdPeriods = new set<Id>();
        for(AcctSeed__Accounting_Period__c p : [SELECT Id FROM AcctSeed__Accounting_Period__c WHERE AcctSeed__Start_Date__c <= :period.AcctSeed__Start_Date__c])
        {
            setIdPeriods.add(p.Id);
        }

        return setIdPeriods;
    }

    @RemoteAction @ReadOnly
    public static date dateEarliestOpen()
    {
        Date dateEarliestOpen = date.Today();
        for(AcctSeed__Accounting_Period__c period :
        [SELECT AcctSeed__Start_Date__c
        FROM AcctSeed__Accounting_Period__c
        WHERE AcctSeed__Status__c = 'Open'
        ORDER BY AcctSeed__Start_Date__c
        LIMIT 1])
        {
            if(period.AcctSeed__Start_Date__c < dateEarliestOpen)
                dateEarliestOpen = period.AcctSeed__Start_Date__c;
        }
        return dateEarliestOpen;
    }
}