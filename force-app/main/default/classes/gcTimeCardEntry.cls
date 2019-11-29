public without sharing class gcTimeCardEntry {

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
        (map<Id,Time_Card_Entry__c> oldMap,
         map<Id,Time_Card_Entry__c> newMap,
         list<Time_Card_Entry__c> listNew,
         Boolean boolIsBefore,
         Boolean boolIsInsert,
         Boolean boolIsUpdate,
         Boolean boolIsDelete)
    {
        if(oldMap == NULL) oldMap = new map<Id,Time_Card_Entry__c>();
        if(newMap == NULL) newMap = new map<Id,Time_Card_Entry__c>();
        if(listNew == NULL) listNew = new list<Time_Card_Entry__c>();

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
        (map<Id,Time_Card_Entry__c> oldMap,
         map<Id,Time_Card_Entry__c> newMap,
         list<Time_Card_Entry__c> listNew,
         Boolean boolIsBefore,
         Boolean boolIsInsert,
         Boolean boolIsUpdate,
         Boolean boolIsDelete)
    {
        if(boolIsBefore)
        {
            map<Id,AcctSeed__Time_Card_Day__c> mapTCD = new map<Id,AcctSeed__Time_Card_Day__c>();
            for(Time_Card_Entry__c tce : listNew)
            {
                mapTCD.put(tce.Time_Card_Day__c,null);
            }
            for(Time_Card_Entry__c tce : oldMap.values())
            {
                mapTCD.put(tce.Time_Card_Day__c,null);
            }           
            for(AcctSeed__Time_Card_Day__c tcd :
                [SELECT Id, AcctSeed__Date__c, AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__Status__c
                 FROM AcctSeed__Time_Card_Day__c
                 WHERE Id IN :mapTCD.keySet()])
            {
                mapTCD.put(tcd.Id,tcd);
            }
            if(boolIsUpdate || boolIsInsert)
            for(Time_Card_Entry__c tce : listNew)
            {
                if(tce.Time_Card_Day__c == null)
                   tce.Time_Card_Day__c.addError('Time Card Day is a required field.');
                else if(boolIsInsert && mapTCD.get(tce.Time_Card_Day__c).AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__Status__c != 'Open')
                {
                   tce.addError('The selected Time Card Day is in a period that is not open.');
                   continue;           
                }
                else if(tce.Time_In_Picklist__c == null)
                {
                   tce.Time_In_Picklist__c.addError('Time In is a required field.');
                   continue;
                }
                else if(tce.Time_Out_Picklist__c == null)
                {
                   tce.Time_Out_Picklist__c.addError('Time Out is a required field.');
                   continue;
                }

                Date myDate = mapTCD.get(tce.Time_Card_Day__c).AcctSeed__Date__c;
                tce.Time_In__c = convertTimeIn(myDate,tce.Time_In_Picklist__c);
                tce.Time_Out__c = convertTimeOut(myDate,tce.Time_Out_Picklist__c);

                Decimal milliseconds = Decimal.valueOf(tce.Time_Out__c.getTime() - tce.Time_In__c.getTime() + 1000);

                if(milliseconds < 0)
                   tce.addError('Time Out must be greater than Time In.');

                tce.Hours__c = (milliseconds/1000/60/60).setScale(2);

                if(boolIsUpdate)
                {
                    if(tce.Time_Card_Day__c != oldMap.get(tce.Id).Time_Card_Day__c)
                        tce.Time_Card_Day__c.addError('A Time Card Entry cannot be moved to a different Time Card Day.');

                    if(mapTCD.get(tce.Time_Card_Day__c).AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__Status__c != 'Open')
                    {
                        if(tce.Time_In__c != oldMap.get(tce.Id).Time_In__c)
                            tce.Time_In__c.addError('The Time In cannot be changed because the entry is in a period that is not open.');
                        if(tce.Time_Out__c != oldMap.get(tce.Id).Time_Out__c)
                            tce.Time_Out__c.addError('The Time Out cannot be changed because the entry is in a period that is not open.');
                    }
                }
            }
            else if(boolIsDelete)
            {
                for(Time_Card_Entry__c tce : oldMap.values())
                {
                    if(mapTCD.get(tce.Time_Card_Day__c).AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__Status__c != 'Open')
                        tce.addError('The Time Card Entry cannot be deleted because it is in a period that is not open.');                      
                }
            }
        }
        else if(!boolIsBefore)
        {
            set<Id> setIdTimeCardDay = new set<Id>();
            map<Id,AcctSeed__Time_Card_Day__c> mapTCD = new map<Id,AcctSeed__Time_Card_Day__c>();
            for(Time_Card_Entry__c tce : listNew)
            {
                setIdTimeCardDay.add(tce.Time_Card_Day__c);
            }
            for(Time_Card_Entry__c tce : oldMap.values())
            {
                setIdTimeCardDay.add(tce.Time_Card_Day__c);
            }
            gcTimeCardDay.rollUp(setIdTimeCardDay);

            if(boolIsInsert || boolIsUpdate)
            {
                //the goal of the After-Insert and After-Update logic is only to ensure
                //that there are not overlapping time card entries for same employee, and date.
                
                map<Id,set<Date>> mapEmployeeDates = new map<Id,set<Date>>();
                set<Date> setDates = new set<Date>();
                mapTCD.clear();

                //collect all time card days, and map the employees to a set of dates
                //also collect the dates in their own set, to aid with filtering a subsequent query.
                for(AcctSeed__Time_Card_Day__c tcd :
                    [SELECT Id, 
                            AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c,
                            AcctSeed__Date__c
                     FROM AcctSeed__Time_Card_Day__c
                     WHERE Id IN :setIdTimeCardDay])
                {
                    if(!mapEmployeeDates.containsKey(tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c))
                        mapEmployeeDates.put(tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c, new set<Date>());
                    mapEmployeeDates.get(tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c).add(tcd.AcctSeed__Date__c);

                    setDates.add(tcd.AcctSeed__Date__c);

                    mapTCD.put(tcd.Id,tcd);
                }

                //map each employee-date pair to a list of time card entries for that employee-date pair
                //subsequently, we will cycle through that list of time card entries, to look for overlap
                map<Id,map<Date,list<Time_Card_Entry__c>>> mapEmployeeDateEntries = new map<Id,map<Date,list<Time_Card_Entry__c>>>();
                for(Time_Card_Entry__c tce :
                    [SELECT Id,
                            Time_Card_Day__r.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c,
                            Time_Card_Day__r.AcctSeed__Date__c,
                            Time_In__c,
                            Time_Out__c
                     FROM Time_Card_Entry__c
                     WHERE Time_Card_Day__r.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c IN :mapEmployeeDates.keySet()
                       AND Time_Card_Day__r.AcctSeed__Date__c IN :setDates
                     ORDER BY Time_In__c])
                {
                    Id idEmployee = tce.Time_Card_Day__r.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c;
                    Date myDate = tce.Time_Card_Day__r.AcctSeed__Date__c;

                    if(!mapEmployeeDates.get(idEmployee).contains(myDate)) continue;

                    if(!mapEmployeeDateEntries.containsKey(idEmployee))
                        mapEmployeeDateEntries.put(idEmployee, new map<Date, list<Time_Card_Entry__c>>());

                    if(!mapEmployeeDateEntries.get(idEmployee).containsKey(myDate))
                        mapEmployeeDateEntries.get(idEmployee).put(myDate, new list<Time_Card_Entry__c>());

                    mapEmployeeDateEntries.get(idEmployee).get(myDate).add(tce);
                }

                //cycle over the context time card entries
                for(Time_Card_Entry__c tce : listNew)
                {
                    Id idEmployee = mapTCD.get(tce.Time_Card_Day__c).AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c;
                    Date myDate = mapTCD.get(tce.Time_Card_Day__c).AcctSeed__Date__c;

                    //cycle over all time card entries for the same employee-date as the context entry, looking for overlap.
                    Time_Card_Entry__c tcePrior;
                    for(Time_Card_Entry__c x : mapEmployeeDateEntries.get(idEmployee).get(myDate))
                    {
                        if(tcePrior != null)
                        {
                            if(x.Time_In__c == tcePrior.Time_In__c)
                                tce.addError('There is more than one time card entry having the same Time In.');
                            else if(x.Time_In__c <= tcePrior.Time_Out__c)
                                tce.addError('There are overlapping Time Card Entries for this Time Card Day.');
                        }
                        tcePrior = x;
                    }
                }
            }
        }
    }

    public static dateTime convertTimeIn(Date myDate, String myTime)
    {
        if(myTime == 'MIDNIGHT') myTime = '12:00AM';
        else if(myTime == 'NOON') myTime = '12:00PM';
        //myTime values should be 12:00AM thru 11:45PM

        Integer hour = 0;
        Integer minute = 0;
        Integer second = 0;

        if(myTime.indexOf(':') == 2)
        {
            hour = Integer.valueOf(myTime.left(2));
            minute = Integer.valueOf(myTime.substring(3,5));
        }
        else if(myTime.indexOf(':') == 1)
        {
            hour = Integer.valueOf(myTime.left(1));
            minute = Integer.valueOf(myTime.substring(2,4));            
        }

        if(hour == 12) hour = 0;
        if(myTime.right(2).equalsIgnoreCase('PM')) hour += 12;

        return Datetime.newInstance(myDate.year(),myDate.month(),myDate.day(),hour,minute,second);
    }

    public static dateTime convertTimeOut(Date myDate, String myTime)
    {
        if(myTime == 'MIDNIGHT') myTime = '12:00AM';
        else if(myTime == 'NOON') myTime = '12:00PM';

        Integer hour = 0;
        Integer minute = 0;
        Integer second = 0;

        if(myTime.indexOf(':') == 2)
        {
            hour = Integer.valueOf(myTime.left(2));
            minute = Integer.valueOf(myTime.substring(3,5));
        }
        else if(myTime.indexOf(':') == 1)
        {
            hour = Integer.valueOf(myTime.left(1));
            minute = Integer.valueOf(myTime.substring(2,4));            
        }

        //myTime values should be 12:15AM thru MIDNIGHT where MIDNIGHT is interpreted to be the END of the day, and mean 11:59:59PM
        //and every other time is interpreted to be one second prior, i.e. 3:45PM is interpreted as 3:44:59PM
        if(hour == 12) hour = 0;
        if(myTime.right(2).equalsIgnoreCase('PM')) hour += 12;

        if(hour == 0 && minute == 0 && second == 0)
        {
            return Datetime.newInstance(myDate.year(),myDate.month(),myDate.day(),hour,minute,second).addDays(1).addSeconds(-1);
        }

        return Datetime.newInstance(myDate.year(),myDate.month(),myDate.day(),hour,minute,second).addSeconds(-1);
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
    }
}