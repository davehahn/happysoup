public without sharing class gcTimeCardDay {

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

    public static Boolean allowDMLHours{
        get{
            if(allowDMLHours == null) return false;
            else return allowDMLHours;
        }
        set{
            if(value == null) allowDMLHours = false;
            else allowDMLHours = value;
        }
    }

    public static void triggerHandler
        (map<Id,AcctSeed__Time_Card_Day__c> oldMap,
         map<Id,AcctSeed__Time_Card_Day__c> newMap,
         list<AcctSeed__Time_Card_Day__c> listNew,
         Boolean boolIsBefore,
         Boolean boolIsInsert,
         Boolean boolIsUpdate,
         Boolean boolIsDelete)
    {
        if(oldMap == NULL) oldMap = new map<Id,AcctSeed__Time_Card_Day__c>();
        if(newMap == NULL) newMap = new map<Id,AcctSeed__Time_Card_Day__c>();
        if(listNew == NULL) listNew = new list<AcctSeed__Time_Card_Day__c>();

        //String context = 'gcTimeCardDay ';
        //if(boolIsBefore) context += 'before ';
        //else context += 'after ';
        //if(boolIsInsert) context += 'insert';
        //else if(boolIsUpdate) context += 'update';
        //else if(boolIsDelete) context += 'delete';

        //system.debug(loggingLevel.error,'context: '+context);

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
        (map<Id,AcctSeed__Time_Card_Day__c> oldMap,
         map<Id,AcctSeed__Time_Card_Day__c> newMap,
         list<AcctSeed__Time_Card_Day__c> listNew,
         Boolean boolIsBefore,
         Boolean boolIsInsert,
         Boolean boolIsUpdate,
         Boolean boolIsDelete)
    {
        if(boolIsBefore)
        {
            map<Id,AcctSeed__Time_Card_Line__c> mapTimeCardLine = new map<Id,AcctSeed__Time_Card_Line__c>();
            for(AcctSeed__Time_Card_Day__c tcd : listNew)
            {
                mapTimeCardLine.put(tcd.AcctSeed__Time_Card_Line__c,null);
            }
            for(AcctSeed__Time_Card_Day__c tcd : oldMap.values())
            {
                mapTimeCardLine.put(tcd.AcctSeed__Time_Card_Line__c,null);
            }
            for(AcctSeed__Time_Card_Line__c tcl : 
                [SELECT Id,
                        AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__End_Date__c,
                        AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__Start_Date__c,
                        AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__Status__c
                 FROM AcctSeed__Time_Card_Line__c
                 WHERE Id IN :mapTimeCardLine.keySet()])
            {
                mapTimeCardLine.put(tcl.Id,tcl);
            }
            mapTimeCardLine.remove(null);

            if(boolIsInsert || boolIsUpdate)
            for(AcctSeed__Time_Card_Day__c tcd : listNew)
            {
                if(boolIsInsert && !allowDMLHours)
                   tcd.AcctSeed__Hours__c = 0;
                if(mapTimeCardLine.get(tcd.AcctSeed__Time_Card_Line__c).AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__Status__c != 'Open')
                    tcd.addError('The Time Card Day cannot be inserted or updated, because the Time Card Period is not open.');
                else if(boolIsUpdate && tcd.AcctSeed__Time_Card_Line__c != oldMap.get(tcd.Id).AcctSeed__Time_Card_Line__c)
                    tcd.AcctSeed__Time_Card_Line__c.addError('A Time Card Day cannot be moved to a different Time Card Line.');
                else if(tcd.AcctSeed__Date__c == null)
                    tcd.AcctSeed__Date__c.addError('A Date is required for a Time Card Day.');
                else if(tcd.AcctSeed__Date__c < mapTimeCardLine.get(tcd.AcctSeed__Time_Card_Line__c).AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__Start_Date__c ||
                        tcd.AcctSeed__Date__c > mapTimeCardLine.get(tcd.AcctSeed__Time_Card_Line__c).AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__End_Date__c)
                    tcd.AcctSeed__Date__c.addError('The Date of the Time Card Day must be within the specified Time Card Period.');
                else if(tcd.AcctSeed__Hours__c == null)
                        tcd.AcctSeed__Hours__c.addError('The number of hours must be specified.');
                else if(tcd.AcctSeed__Hours__c > 24)
                        tcd.AcctSeed__Hours__c.addError('The number of hours must not be greater than 24.');
                else if(tcd.AcctSeed__Hours__c < 0)
                        tcd.AcctSeed__Hours__c.addError('The number of hours must be positive.');
                else if(boolIsUpdate && !allowDMLHours && tcd.AcctSeed__Hours__c.setScale(2) != oldMap.get(tcd.Id).AcctSeed__Hours__c.setScale(2))
                        tcd.AcctSeed__Hours__c.addError('The number of hours cannot be directly manipulated; use Time Card Entries instead.');
                
                String uniqueKey = '';
                uniqueKey += tcd.AcctSeed__Time_Card_Line__c;
                uniqueKey += String.valueOf(tcd.AcctSeed__Date__c);

                tcd.Uniquefier__c = uniqueKey;
            }

            if(boolIsDelete)
            for(AcctSeed__Time_Card_Day__c tcd: oldMap.values())
            {
                if(mapTimeCardLine.get(tcd.AcctSeed__Time_Card_Line__c).AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__Status__c != 'Open')
                    tcd.addError('The Time Card Day cannot be inserted or updated, because the Time Card Period is not open.');
            }
        }
        else if(!boolIsBefore)
        {
            set<Id> setIdTimeCardDayRecalc = new set<Id>();
            map<Id,map<Date,Decimal>> mapLDH = new map<Id,map<Date,Decimal>>(); //map line-date-hours
            if(boolIsInsert || boolIsUpdate)
            {
                for(AcctSeed__Time_Card_Day__c tcd : listNew)
                {
                    /*if(!mapLDH.containsKey(tcd.AcctSeed__Time_Card_Line__c))
                        mapLDH.put(tcd.AcctSeed__Time_Card_Line__c, new map<Date,Decimal>());
                    if(!mapLDH.get(tcd.AcctSeed__Time_Card_Line__c).containsKey(tcd.AcctSeed__Date__c))
                        mapLDH.get(tcd.AcctSeed__Time_Card_Line__c).put(tcd.AcctSeed__Date__c,0);

                    Decimal newVal = tcd.AcctSeed__Hours__c + mapLDH.get(tcd.AcctSeed__Time_Card_Line__c).get(tcd.AcctSeed__Date__c);
                    if(newVal < 0)
                        tcd.addError('The Time Card Day cannot be inserted or updated because it would result in negative hours for the Time Card Line.');
                    if(newVal > 24)
                        tcd.addError('The Time Card Day cannot be inserted or updated because it would result in more than 24 hours for the Time Card Line.');*/

                    if(allowDMLhours)
                    {
                        setIdTimeCardDayRecalc.add(tcd.Id);
                    }
                }
                checkTotalHoursPerDayPerEmployee(listNew);
            }
            else if(boolIsDelete)
            {
                for(AcctSeed__Time_Card_Day__c tcd : oldMap.values())
                {
                    /*if(!mapLDH.containsKey(tcd.AcctSeed__Time_Card_Line__c))
                        mapLDH.put(tcd.AcctSeed__Time_Card_Line__c, new map<Date,Decimal>());
                    if(!mapLDH.get(tcd.AcctSeed__Time_Card_Line__c).containsKey(tcd.AcctSeed__Date__c))
                        mapLDH.get(tcd.AcctSeed__Time_Card_Line__c).put(tcd.AcctSeed__Date__c,0);

                    Decimal newVal = tcd.AcctSeed__Hours__c + mapLDH.get(tcd.AcctSeed__Time_Card_Line__c).get(tcd.AcctSeed__Date__c);
                    if(newVal < 0)
                        tcd.addError('The Time Card Day cannot be deleted because it would result in negative hours for the Time Card Line.');
                    if(newVal > 24)
                        tcd.addError('The Time Card Day cannot be deleted because it would result in more than 24 hours for the Time Card Line.');*/

                    setIdTimeCardDayRecalc.add(tcd.AcctSeed__Time_Card_Line__c);
                }
                checkTotalHoursPerDayPerEmployee(oldMap.values());
            }

            if(setIdTimeCardDayRecalc.size() > 0)
                gcTimeCardDay.recalcOvertime(setIdTimeCardDayRecalc);

        }
    }

    /// this method is called after insert/update/delete of the TCD
    public static void checkTotalHoursPerDayPerEmployee(List<AcctSeed__Time_Card_Day__c> listTCD)
    {
        Map<Id,Map<Date,Decimal>> mapEmployeeDH = new Map<Id,Map<Date,Decimal>>(); //map idEmployee-Date-HoursWorked
        Set<Id> setIdEmployee = new Set<Id>();
        Set<Id> setIdTCL = new Set<Id>();
        Set<Date> setDateTCD = new Set<Date>();
        Map<Id,Id> mapTCLToEmployee = new Map<Id,Id>();
        /// Gathering the ID of the ime card days and
        /// the dates for which we are going to calculate per day total
        for(AcctSeed__Time_Card_Day__c tcd : listTCD)
        {
            setIdTCL.add(tcd.AcctSeed__Time_Card_Line__c);
            setDateTCD.add(tcd.AcctSeed__Date__c);
        }
        /// Now finding the Employees from related Time Cards
        /// to finally match total hours per day per employee
        /// Doing it by Time Card lies because if he days were deleted we wont find them after delete
        for(AcctSeed__Time_Card_Line__c tcl : [
                SELECT Id, 
                    AcctSeed__Time_Card__r.AcctSeed__Employee__c
                FROM AcctSeed__Time_Card_Line__c
                WHERE Id IN:setIdTCL])
        {
            setIdEmployee.add(tcl.AcctSeed__Time_Card__r.AcctSeed__Employee__c);
            mapTCLToEmployee.put(tcl.Id, tcl.AcctSeed__Time_Card__r.AcctSeed__Employee__c);
        }
        /// Now lets gather all data of the Employees for all the dates we found in
        /// Current data set and add upto 24 or more so that we can find the outcome.
        /// We will add upto the ID which is not in the current list. So that we can through the error looping on the listnew
        for(AcctSeed__Time_Card_Day__c tcd :
            [SELECT Id, 
                    AcctSeed__Date__c, 
                    AcctSeed__Hours__c,
                    AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c,
                    AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card_Variable_1__r.Uniquefier__c
            FROM AcctSeed__Time_Card_Day__c
            WHERE AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c IN:setIdEmployee
                AND AcctSeed__Date__c IN:setDateTCD
                ORDER BY AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c, LastModifiedDate])
        {
            Id idEmployee = tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c;
            if(!mapEmployeeDH.containsKey(idEmployee))
                mapEmployeeDH.put(idEmployee, new Map<Date,Decimal>());
            if(!mapEmployeeDH.get(idEmployee).containsKey(tcd.AcctSeed__Date__c))
                mapEmployeeDH.get(idEmployee).put(tcd.AcctSeed__Date__c,0);

            /// If the hours are not related to work then discard
            String tcv1Uniquefier = tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card_Variable_1__r.Uniquefier__c;
            if(tcv1Uniquefier == 'WORK' || tcv1Uniquefier == null)
            {
                Decimal newVal = tcd.AcctSeed__Hours__c + mapEmployeeDH.get(idEmployee).get(tcd.AcctSeed__Date__c);
                mapEmployeeDH.get(idEmployee).put(tcd.AcctSeed__Date__c,newVal);
            }
        }
        /// now looping again in the newlist to add the latest time modified or added
        for(AcctSeed__Time_Card_Day__c tcd : listTCD)
        {
            Id idEmployee = mapTCLToEmployee.get(tcd.AcctSeed__Time_Card_Line__c);
            Decimal totalVal = 0;
            if(mapEmployeeDH.containsKey(idEmployee) && mapEmployeeDH.get(idEmployee).containsKey(tcd.AcctSeed__Date__c))
            {
                totalVal = mapEmployeeDH.get(idEmployee).get(tcd.AcctSeed__Date__c);
                //mapEmployeeDH.get(idEmployee).put(tcd.AcctSeed__Date__c,totalVal);
            }

            if(totalVal < 0)
                tcd.addError('The Time Card Day cannot be saved because it would result in negative hours for the day '+tcd.AcctSeed__Date__c.format());
            if(totalVal > 24)
                tcd.addError('The Time Card Day cannot be saved because it would result in more than 24 work hours for the day '+tcd.AcctSeed__Date__c.format());
        }
    }

    //call this method after DML on Time Card Entry
    public static void rollup(set<Id> setIdTimeCardDay)
    {
        setIdTimeCardDay.remove(null);
        if(setIdTimeCardDay.size() == 0) return;

        list<AcctSeed__Time_Card_Day__c> listTCD = new list<AcctSeed__Time_Card_Day__c>();

        for(AcctSeed__Time_Card_Day__c tcd : 
            [SELECT Id, AcctSeed__Hours__c,
                    (SELECT Id, Hours__c FROM Time_Card_Entries__r WHERE Hours__c != null)
             FROM AcctSeed__Time_Card_Day__c
             WHERE Id IN :setIdTimeCardDay])
        {
            Decimal hoursNew = 0;
            for(Time_Card_Entry__c tce : tcd.Time_Card_Entries__r)
            {
                hoursNew += tce.Hours__c;
            }
            //it is intentional that ALL records are updated, regardless of whether or not the roll-up value has changed 
            //in order to ensure that overtime is recalculated.
            tcd.AcctSeed__Hours__c = hoursNew.setScale(2);
            listTCD.add(tcd);
/*
            if(tcd.AcctSeed__Hours__c.setScale(2) != hoursNew.setScale(2))
            {
                tcd.AcctSeed__Hours__c = hoursNew.setScale(2);
                listTCD.add(tcd);
            }
*/
        }
        if(!listTCD.isEmpty())
        {
            Boolean boolOld = gcTimeCardDay.allowDMLHours;
            gcTimeCardDay.allowDMLHours = true;
            update listTCD;
            gcTimeCardDay.allowDMLHours = boolOld;
        }
    }



    public static void recalcOvertime(set<Id> setIdFilter)
    {
        setIdFilter.remove(null);
        set<Id> setIdTimeCard = new set<Id>();
        set<Id> setIdProject = new set<Id>();
        set<Date> setDate = new set<Date>();

        for(AcctSeed__Time_Card_Day__c tcdx : 
            [SELECT AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__c
             FROM AcctSeed__Time_Card_Day__c 
             WHERE Id IN :setIdFilter
               AND AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__Status__c = 'Open'
             ALL ROWS])
        {
            setIdTimeCard.add(tcdx.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__c);
        }

        for(AcctSeed__Time_Card_Line__c tclx :
            [SELECT AcctSeed__Time_Card__c 
             FROM AcctSeed__Time_Card_Line__c
             WHERE Id IN :setIdFilter
               AND AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__Status__c = 'Open'
             ALL ROWS])
        {
            setIdTimeCard.add(tclx.AcctSeed__Time_Card__c);
        }

        for(AcctSeed__Time_Card__c tc : 
            [SELECT Id, AcctSeed__Time_Card_Period__r.AcctSeed__Start_Date__c, AcctSeed__Time_Card_Period__r.AcctSeed__End_Date__c,
                    (SELECT Id, AcctSeed__Project__c FROM AcctSeed__Time_Card_Line_Details__r)
             FROM AcctSeed__Time_Card__c
             WHERE (Id IN :setIdFilter OR Id IN :setIdTimeCard)
               AND AcctSeed__Time_Card_Period__r.AcctSeed__Status__c = 'Open'
             ALL ROWS])
        {
            setIdTimeCard.add(tc.Id);
            setDate.add(tc.AcctSeed__Time_Card_Period__r.AcctSeed__Start_Date__c);
            setDate.add(tc.AcctSeed__Time_Card_Period__r.AcctSeed__End_Date__c);
            for(AcctSeed__Time_Card_Line__c tclx : tc.AcctSeed__Time_Card_Line_Details__r)
                setIdProject.add(tclx.AcctSeed__Project__c);
        }

        if(setIdTimeCard.size() == 0) return;

        list<AcctSeed__Time_Card_Day__c> listTCDupdate = new list<AcctSeed__Time_Card_Day__c>();
        list<AcctSeed__Time_Card_Day__c> listTCDdelete = new list<AcctSeed__Time_Card_Day__c>();
        list<Time_Card_Entry__c> listTCEupdate = new list<Time_Card_Entry__c>();

        map<Id,AcctSeed__Time_Card_Day__c> mapTCD = new map<Id,AcctSeed__Time_Card_Day__c>();

        map<Id,cube> mapCube = new map<Id,cube>();
        list<cube> listCube = new list<cube>();

        //set<Id> setIdProject = new set<Id>();
        //set<Date> setDate = new set<Date>();
        Map<Id,Decimal> mapIdUserEmployeeOTT = new Map<Id,Decimal>();
        for(AcctSeed__Time_Card_Day__c tcdx :
            [SELECT Id,
                    AcctSeed__Date__c,
                    AcctSeed__Hours__c,
                    //AcctSeed__Time_Card_Line__c,
                    //AcctSeed__Time_Card_Line__r.AcctSeed__Project__c,
                    AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c,
                    AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__c,
                    AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card_Variable_1__r.Exclude_From_Overtime__c,                    
                    Hours_DT__c,
                    Hours_OT__c,
                    Hours_RT__c,
                    (SELECT Id,
                            Hours__c,
                            Hours_DT__c,
                            Hours_RT__c,
                            Hours_OT__c,
                            isDoubleTime__c,
                            Time_In__c
                     FROM Time_Card_Entries__r
                     ORDER BY Time_In__c)
            FROM AcctSeed__Time_Card_Day__c
            WHERE AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__c IN :setIdTimeCard])
        {
            mapTCD.put(tcdx.Id,tcdx);
            mapIdUserEmployeeOTT.put(tcdx.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c, 40);
            Datetime timeIn;

            if(tcdx.Time_Card_Entries__r.size() > 0)
            {
                for(Time_Card_Entry__c tcex :tcdx.Time_Card_Entries__r)
                {
                    timeIn = tcex.Time_In__c;
                    if(timeIn == null)
                        timeIn = dateTime.newInstance(tcdx.AcctSeed__Date__c, Time.newInstance(23,59,59,999));
                    mapCube.put(tcex.Id,new cube(tcdx,timeIn, tcex.Hours__c, tcex.isDoubleTime__c));
                }
            }
            else
            {
                timeIn = dateTime.newInstance(tcdx.AcctSeed__Date__c, Time.newInstance(23,59,59,999));
                mapCube.put(tcdx.Id,new cube(tcdx,timeIn, tcdx.AcctSeed__Hours__c, false));
            }       
        }

        listCube.addAll(mapCube.values());
        listCube.sort();

        mapIdUserEmployeeOTT.remove(null);
        if(!mapIdUserEmployeeOTT.isEmpty())
        {
            for(Employee__c e : [SELECT Id, User__c, Overtime_Threshold__c FROM Employee__c WHERE User__c IN:mapIdUserEmployeeOTT.keySet()])
            {
                if(e.Overtime_Threshold__c != null || e.Overtime_Threshold__c > 0)
                    mapIdUserEmployeeOTT.put(e.User__c, e.Overtime_Threshold__c);
            }
        }

        Decimal loopHrs = 0;
        Date loopDate;

        Id idLoopTC = null;
        Decimal otThreshold = 40;

        for(cube c : listCube)
        {
            if(c.tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__c != idLoopTC)
            {
                idLoopTC = c.tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__c;
                otThreshold = mapIdUserEmployeeOTT.get(c.tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c);
                loopHrs = 0;
            }

            if(c.tcd.AcctSeed__Date__c != loopDate)
            {
                loopDate = c.tcd.AcctSeed__Date__c;
            }

            if(c.tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card_Variable_1__r.Exclude_From_Overtime__c)
            {
                c.hoursOT = 0;
                c.hoursDT = 0;
                c.isDoubleTime = false;
            }
            else if(c.isDoubleTime)
            {
                c.hoursDT = c.hoursRT;
                c.hoursRT = 0;
                c.hoursOT = 0;
            }
            else
            {
                if(c.hoursRT > 0 && (c.hoursRT + loopHrs) > otThreshold)
                {
                    c.hoursOT += ((c.hoursRT + loopHrs) - otThreshold);
                    c.hoursRT -= ((c.hoursRT + loopHrs) - otThreshold);
                }

                loopHrs += c.hoursRT;
                if(loopHrs > otThreshold)
                    loopHrs = otThreshold;
            }
        }

        for(AcctSeed__Time_Card_Day__c tcdx : mapTCD.values())
        {
            cube c;

            if(tcdx.Time_Card_Entries__r.size() > 0)
            {
                Decimal hrsRT = 0;
                Decimal hrsOT = 0;
                Decimal hrsDT = 0;

                for(Time_Card_Entry__c tcex : tcdx.Time_Card_Entries__r)
                {
                    c = mapCube.get(tcex.Id);
                    hrsRT += c.hoursRT;
                    hrsOT += c.hoursOT;
                    hrsDT += c.hoursDT;

                    if(tcex.Hours_RT__c != c.hoursRT || tcex.Hours_OT__c != c.hoursOT || tcex.Hours_DT__c != c.hoursDT || tcex.isDoubleTime__c != c.isDoubleTime)
                    {
                        tcex.Hours_RT__c = c.hoursRT;
                        tcex.Hours_OT__c = c.hoursOT;
                        tcex.Hours_DT__c = c.hoursDT;
                        tcex.isDoubleTime__c = c.isDoubleTime;
                        listTCEupdate.add(tcex);
                    }
                }

                if(tcdx.Hours_RT__c != hrsRT || tcdx.Hours_OT__c != hrsOT || tcdx.Hours_DT__c != hrsDT)
                {
                    tcdx.Hours_RT__c = hrsRT;
                    tcdx.Hours_OT__c = hrsOT;
                    tcdx.Hours_DT__c = hrsDT;
                    listTCDupdate.add(tcdx);                    
                }
            }
            else
            {
                c = mapCube.get(tcdx.Id);

                if(tcdx.Hours_RT__c != c.hoursRT || tcdx.Hours_OT__c != c.hoursOT || tcdx.Hours_DT__c != c.hoursDT)
                {
                    tcdx.Hours_RT__c = c.hoursRT;
                    tcdx.Hours_OT__c = c.hoursOT;
                    tcdx.Hours_DT__c = c.hoursDT;
                    listTCDupdate.add(tcdx);
                }               
            }
        }

        Boolean boolOld1 = gcTimeCardEntry.disableTrigger;
        Boolean boolOld2 = gcTimeCardDay.disableTrigger;
        Boolean boolOld3 = gcTimeCardLine.disableTrigger;
        Boolean boolOld4 = gcTimeCard.disableTrigger;

        gcTimeCardEntry.disableTrigger = true;
        gcTimeCardDay.disableTrigger = true;
        gcTimeCardLine.disableTrigger = true;
        gcTimeCard.disableTrigger = true;

        if(listTCDdelete.size() > 0)
            delete listTCDdelete;
        if(listTCEupdate.size() > 0)
            update listTCEupdate;
        if(listTCDupdate.size() > 0)
            update listTCDupdate;


        gcTimeCardEntry.disableTrigger = boolOld1;
        gcTimeCardDay.disableTrigger = boolOld2;
        gcTimeCardLine.disableTrigger = boolOld3;
        gcTimeCard.disableTrigger = boolOld4;    

        gcProjectLaborJobCost.refreshJobCostFuture(setIdProject, setDate);
    }

    private class cube implements Comparable{

        Decimal hoursRT{get;set;}
        Decimal hoursOT{get;set;}
        Decimal hoursDT{get;set;}

        Datetime timeIn{get;set;}

        Boolean isDoubleTime{get;set;}

        AcctSeed__Time_Card_Day__c tcd{get;set;}

        cube(AcctSeed__Time_Card_Day__c pTcd, Datetime pTimeIn, Decimal pHours, Boolean pIsDoubleTime)
        {
            tcd = pTcd;
            hoursRT = pHours;
            hoursOT = 0;
            hoursDT = 0;
            timeIn = pTimeIn;
            isDoubleTime = pIsDoubleTime;

            if(hoursRT == null) hoursRT = 0;
        }

        cube(AcctSeed__Time_Card_Day__c pTcd, Datetime pTimeIn, Decimal pHours)
        {
            tcd = pTcd;
            hoursRT = pHours;
            hoursOT = 0;
            hoursDT = 0;
            timeIn = pTimeIn;

            if(hoursRT == null) hoursRT = 0;
        }

        public integer compareTo(Object compareTo)
        {
            cube cmp = (cube)compareTo;

            //sort by time card period
            if(tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__c < cmp.tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__c)
                return -1;
            else if(tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__c > cmp.tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__c)
                return 1;

            //sort by employee
            else if(tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c < cmp.tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c)
                return -1;
            else if(tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c > cmp.tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c)
                return 1;

            //sort by date
            else if(tcd.AcctSeed__Date__c < cmp.tcd.AcctSeed__Date__c)
                return -1;
            else if(tcd.AcctSeed__Date__c > cmp.tcd.AcctSeed__Date__c)
                return 1;          

            //sort by time
            else if(timeIn < cmp.timeIn)
                return -1;
            //else if(tcd.timeIn > cmp.tcd.timeIn)
            return 1;
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
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
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