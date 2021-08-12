public with sharing class gcEmployeeWageRate {

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
        (map<Id,Employee_Wage_Rate__c> oldMap,
         map<Id,Employee_Wage_Rate__c> newMap,
         list<Employee_Wage_Rate__c> listNew,
         Boolean boolIsBefore,
         Boolean boolIsInsert,
         Boolean boolIsUpdate,
         Boolean boolIsDelete)
    {
        if(oldMap == NULL) oldMap = new map<Id,Employee_Wage_Rate__c>();
        if(newMap == NULL) newMap = new map<Id,Employee_Wage_Rate__c>();
        if(listNew == NULL) listNew = new list<Employee_Wage_Rate__c>();

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

    private static map<Id,AcctSeed__Time_Card_Period__c> mapTcp;
    private static map<Id,Employee__c> mapEmployee;

    private static void retrieveTimeCardPeriods(list<Employee_Wage_Rate__c> listEwr)
    {
        if(mapTcp == null)
           mapTcp = new map<Id,AcctSeed__Time_Card_Period__c>();

        set<Id> setIdTcp = new set<Id>();
        for(Employee_Wage_Rate__c ewr : listEwr)
        {
            if(!mapTcp.containsKey(ewr.Effective_Time_Card_Period__c))
                setIdTcp.add(ewr.Effective_Time_Card_Period__c);
        }

        if(setIdTcp.size() > 0)
        for(AcctSeed__Time_Card_Period__c tcp : 
            [SELECT Id,
                    AcctSeed__Start_Date__c,
                    AcctSeed__End_Date__c,
                    AcctSeed__Status__c
             FROM AcctSeed__Time_Card_Period__c
             WHERE Id IN :setIdTcp])
        {
            mapTcp.put(tcp.Id,tcp);
        }
    }

    private static void retrieveEmployees(list<Employee_Wage_Rate__c> listEwr)
    {
        if(mapEmployee == null)
        {
           mapEmployee = new map<Id,Employee__c>();
        }

        set<Id> setIdEmployee = new set<Id>();
        for(Employee_Wage_Rate__c ewr : listEwr)
        {
            if(!mapEmployee.containsKey(ewr.Employee__c))
                setIdEmployee.add(ewr.Employee__c);
        }

        if(setIdEmployee.size() > 0)
        for(Employee__c emp :
            [SELECT Id, User__c
             FROM Employee__c
             WHERE Id IN :setIdEmployee])
        {
            mapEmployee.put(emp.Id,emp);
        }
    }

    private static void updateAndValidate
        (map<Id,Employee_Wage_Rate__c> oldMap,
         map<Id,Employee_Wage_Rate__c> newMap,
         list<Employee_Wage_Rate__c> listNew,
         Boolean boolIsBefore,
         Boolean boolIsInsert,
         Boolean boolIsUpdate,
         Boolean boolIsDelete)
    {
        list<Employee_Wage_Rate__c> listEwr = new list<Employee_Wage_Rate__c>();
        listEwr.addAll(listNew);
        listEwr.addAll(oldMap.values());

        retrieveTimeCardPeriods(listEwr);

        if(boolIsBefore)
        {
            for(Employee_Wage_Rate__c ewr : listNew)
            {
                AcctSeed__Time_Card_Period__c tcp = mapTcp.get(ewr.Effective_Time_Card_Period__c);

                if(boolIsInsert || boolIsUpdate)
                {
                    if(ewr.Effective_Time_Card_Period__c == null)
                        ewr.addError('Effective Time Card Period is a required field.');
                    else if(ewr.Base__c == null || ewr.Base__c < 0)
                        ewr.addError('Base is required and must be greater or equal to zero.');
                    //else if(ewr.Benefits__c == null || ewr.Benefits__c < 0)
                    //    ewr.addError('Benefits is required and must be greater or equal to zero.');

                    ewr.Uniquefier__c = ewr.Employee__c + '-' + ewr.Effective_Time_Card_Period__c;

                    //Calculate the benefits
                    Decimal base = (ewr.Base__c != null) ? ewr.Base__c : 0;
                    Decimal ptoHours = (ewr.PTO_Hours__c != null) ? ewr.PTO_Hours__c : 0;
                    Decimal holidayHours = (ewr.Holiday_Hours__c != null) ? ewr.Holiday_Hours__c : 0;
                    Decimal medicalFringe = (ewr.Medical_Fringe__c != null) ? ewr.Medical_Fringe__c : 0;

                    Decimal benefits = (((ptoHours + holidayHours) * base) + (medicalFringe * 12)) / 2080;
                    ewr.Benefits__c = benefits.setScale(2);
                }

                if(boolIsInsert)
                {
                    if(tcp.AcctSeed__Status__c != 'Open')
                        tcp.addError('An Employee Wage Rate cannot be inserted for a Time Card Period that is Closed.');
                }

                if(boolIsUpdate)
                {
                    if(ewr.Employee__c != oldMap.get(ewr.Id).Employee__c)
                        ewr.addError('Employee cannot be changed.');
                    else if(ewr.Effective_Time_Card_Period__c != oldMap.get(ewr.Id).Effective_Time_Card_Period__c)
                        ewr.addError('The Effective Time Card Period cannot be changed.');

                    if(tcp.AcctSeed__Status__c != 'Open' &&
                       (ewr.Base__c != oldMap.get(ewr.Id).Base__c ||
                        ewr.PTO_Hours__c != oldMap.get(ewr.Id).PTO_Hours__c ||
                        ewr.Holiday_Hours__c != oldMap.get(ewr.Id).Holiday_Hours__c ||
                        ewr.Medical_Fringe__c != oldMap.get(ewr.Id).Medical_Fringe__c ||
                        ewr.Benefits__c != oldMap.get(ewr.Id).Benefits__c ||
                        ewr.Apprentice_Rate__c != oldMap.get(ewr.Id).Apprentice_Rate__c))
                    {
                        ewr.addError('An Employee\'s Base, PTO Hours, Holiday Hours, Medical Fringe, Benefit, and Apprentice Rates cannot be changed for a Time Card Period period that is Closed.');
                    }
                }
            }

            if(boolIsDelete)
            {
                for(Employee_Wage_Rate__c ewr : oldMap.values())
                {
                    AcctSeed__Time_Card_Period__c tcp = mapTcp.get(ewr.Effective_Time_Card_Period__c);

                    if(tcp.AcctSeed__Status__c != 'Open')
                    {
                        ewr.addError('An Employee Wage Rate cannot be deleted for a Time Card Period that is Closed.');
                    }
                }
            }
        }
        else //i.e. after context
        {
            if(boolIsUpdate || boolIsDelete)
            {
                retrieveTimeCardPeriods(oldMap.values());
                retrieveEmployees(oldMap.values());

                map<Id,Date> mapUserEarliestDate = new map<Id,Date>();
                Date dateEarliest;

                for(Employee_Wage_Rate__c ewr : oldMap.values())
                {
                    Date dateStart = mapTcp.get(ewr.Effective_Time_Card_Period__c).AcctSeed__Start_Date__c;
                    Id idUser = mapEmployee.get(ewr.Employee__c).User__c;

                    if(mapUserEarliestDate.get(idUser) == null || mapUserEarliestDate.get(idUser) > dateStart)
                        mapUserEarliestDate.put(idUser,dateStart);

                    if(dateEarliest == null || dateEarliest > dateStart)
                        dateEarliest = dateStart;
                }

                list<AcctSeed__Time_Card_Line__c> listTcl = new list<AcctSeed__Time_Card_Line__c>();
                for(AcctSeed__Time_Card_Line__c tcl :
                    [SELECT Id,
                            AcctSeed__Project__c, 
                            AcctSeed__Time_Card__c,
                            AcctSeed__Time_Card__r.AcctSeed__Employee__c,
                            AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__Start_Date__c,
                            AcctSeed__Time_Card_Variable_2__c 
                     FROM AcctSeed__Time_Card_Line__c 
                     WHERE AcctSeed__Time_Card__r.AcctSeed__Employee__c IN : mapUserEarliestDate.keySet()
                       AND AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__Start_Date__c >= :dateEarliest
                       AND AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__Status__c = 'Open'])
                {
                    Date dateEarliestUser = mapUserEarliestDate.get(tcl.AcctSeed__Time_Card__r.AcctSeed__Employee__c);
                    if(tcl.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__Start_Date__c >= dateEarliestUser)
                        listTcl.add(tcl);
                }

                gcTimeCardLine.updateWage(listTCL);

                Boolean boolOld = gcTimeCardLine.disableTrigger;
                gcTimeCardLine.disableTrigger = true;
                update listTCL;
                gcTimeCardLine.disableTrigger = boolOld;

            }
        }
    }


}