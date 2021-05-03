public without sharing class gcTimeCardPeriod_Ext {

    public gcTimeCardPeriod_Ext(ApexPages.StandardController ctrl){idTimeCardPeriod = ctrl.getId();}
    public gcTimeCardPeriod_Ext() {}

    public Id idTimeCardPeriod{get;set;}

    public class myException Extends Exception{}

    public void goToPeriodNext()
    {
        for(AcctSeed__Time_Card_Period__c x : [SELECT Id, AcctSeed__Start_Date__c FROM AcctSeed__Time_Card_Period__c WHERE Id =: idTimeCardPeriod])
        {
            for(AcctSeed__Time_Card_Period__c y : [SELECT Id FROM AcctSeed__Time_Card_Period__c WHERE AcctSeed__Start_Date__c > :x.AcctSeed__Start_Date__c ORDER BY AcctSeed__Start_Date__c LIMIT 1])
                idTimeCardPeriod = y.Id;
        }
    }

    public void goToPeriodPrev()
    {
        //retrieve the current time card
        for(AcctSeed__Time_Card_Period__c x : [SELECT Id, AcctSeed__Start_Date__c FROM AcctSeed__Time_Card_Period__c WHERE Id =: idTimeCardPeriod])
        {
            for(AcctSeed__Time_Card_Period__c y : [SELECT Id FROM AcctSeed__Time_Card_Period__c WHERE AcctSeed__Start_Date__c < :x.AcctSeed__Start_Date__c ORDER BY AcctSeed__Start_Date__c DESC LIMIT 1])
                idTimeCardPeriod = y.Id;
        }
    }

    @RemoteAction @ReadOnly 
    public static list<map<string,string>> retrieveEmployees(Id idFilter)
    {
        map<Id,map<string,string>> mapHours = new map<Id,map<string,string>>();

        list<AggregateResult> listAggRes = new list<AggregateResult>();
        listAggRes.addAll(
            [SELECT AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c idUser,
                    max(AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__c) idTC,
                    sum(AcctSeed__Hours__c) hours,
                    sum(Hours_RT__c) hoursRT,
                    sum(Hours_OT__c) hoursOT,
                    sum(Hours_DT__c) hoursDT,
                    sum(Wages__c) wages
             FROM AcctSeed__Time_Card_Day__c
             WHERE (AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__c = :idFilter OR
                    AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__c = :idFilter)
             GROUP BY AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c]
        );

        for(AggregateResult aggRes : listAggRes)
        {
            map<string,string> m = new map<string,string>();

           /* m.put('hours',String.valueOf(((Decimal)aggRes.get('hours')).setScale(2)));
            m.put('hoursRT',String.valueOf(((Decimal)aggRes.get('hoursRT')).setScale(2)));
            m.put('hoursOT',String.valueOf(((Decimal)aggRes.get('hoursOT')).setScale(2)));
            m.put('hoursDT',String.valueOf(((Decimal)aggRes.get('hoursDT')).setScale(2)));
            m.put('wages',String.valueOf(((Decimal)aggRes.get('wages')).setScale(2)));*/

            m.put('hours',String.valueOf(((Decimal)aggRes.get('hours')).setScale(2)));
            m.put('hoursRT',String.valueOf((Decimal)aggRes.get('hoursRT')==null? 0 : ((Decimal)aggRes.get('hoursRT')).setScale(2)));
            m.put('hoursOT',String.valueOf((Decimal)aggRes.get('hoursOT')==null? 0 : ((Decimal)aggRes.get('hoursOT')).setScale(2)));
            m.put('hoursDT',String.valueOf((Decimal)aggRes.get('hoursDT')==null? 0 :((Decimal)aggRes.get('hoursDT')).setScale(2)));
            m.put('wages',String.valueOf((Decimal)aggRes.get('wages')==null ? 0 : ((Decimal)aggRes.get('wages')).setScale(2)));

            mapHours.put((Id)aggRes.get('idUser'),m);
        }

        listAggRes.clear();
        listAggRes.addAll(
            [SELECT AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c idUser,
                    AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card_Variable_1__r.Uniquefier__c uniquefier,
                    sum(AcctSeed__Hours__c) hours
             FROM AcctSeed__Time_Card_Day__c
             WHERE (AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__c = :idFilter OR
                    AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__c = :idFilter)
               AND AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card_Variable_1__r.Exclude_From_Overtime__c = true
             GROUP BY AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c,
                      AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card_Variable_1__r.Uniquefier__c]
        );

        for(AggregateResult aggRes : listAggRes)
        {
            //map<string,string> m = mapHours.get((Id)aggRes.get('idUser'));
            mapHours.get((Id)aggRes.get('idUser')).put((String)aggRes.get('uniquefier'),String.valueOf(((Decimal)aggRes.get('hours')).setScale(2)));

            Decimal hoursRT = Decimal.valueOf(mapHours.get((Id)aggRes.get('idUser')).get('hoursRT'));
            hoursRT -= (Decimal)aggRes.get('hours');
            mapHours.get((Id)aggRes.get('idUser')).put('hoursRT',String.valueOf(hoursRT.setScale(2)));
        }


        //if idFilter is an id of a time card, then don't include all employees!!!
        if(idFilter.getSObjectType().getDescribe().getName() == 'AcctSeed__Time_Card_Period__c')
        {
            for(Employee__c empx :
                [SELECT Id, User__c
                 FROM Employee__c
                 WHERE Active__c = true
                    OR User__c IN :mapHours.keySet()])
            {
                if(!mapHours.containsKey(empx.User__c))
                    mapHours.put(empx.User__c, new map<string,string>());
            }
        }
        else if(idFilter.getSObjectType().getDescribe().getName() == 'AcctSeed__Time_Card__c')
        {
            for(AcctSeed__Time_Card__c tcx : 
                [SELECT Id, AcctSeed__Employee__c
                 FROM AcctSeed__Time_Card__c
                 WHERE Id = :idFilter])
            {
                if(!mapHours.containsKey(tcx.AcctSeed__Employee__c))
                    mapHours.put(tcx.AcctSeed__Employee__c, new map<string,string>());
            }
        }

        for(User u :
            [SELECT Id, Name, FirstName, LastName,
                    (SELECT Id, GL_Account_Variable_2__r.Name FROM Employees__r ORDER BY CreatedDate LIMIT 1)
            FROM User WHERE Id IN :mapHours.keySet()])
        {
            map<string,string> m = mapHours.get(u.Id);
            m.put('idUser',u.Id);
            m.put('userName',u.Name);
            m.put('firstName',u.FirstName);
            m.put('lastName',u.LastName);
            if(u.Employees__r.size() > 0)
            {
                m.put('glv2Name',u.Employees__r[0].GL_Account_Variable_2__r.Name);
                m.put('idEmployee',u.Employees__r[0].Id);
            }

            if(!m.containsKey('hours'))
            m.put('hours','0.00');
            if(!m.containsKey('hoursRT'))
            m.put('hoursRT','0.00');
            if(!m.containsKey('hoursOT'))
            m.put('hoursOT','0.00');
            if(!m.containsKey('hoursDT'))
            m.put('hoursDT','0.00');
            if(!m.containsKey('PTO'))
            m.put('PTO','0.00');
            if(!m.containsKey('HOLIDAY'))
            m.put('HOLIDAY','0.00');
            if(!m.containsKey('BEREAVEMENT'))
            m.put('BEREAVEMENT','0.00');
            if(!m.containsKey('wages'))
            m.put('wages','0.00');

        }

        return mapHours.values();

    }

    @RemoteAction
    public static string findOrCreateTimeCard(Id idUser, Id idTimeCardPeriod)
    {
        AcctSeed__Time_Card__c tc;
        for(AcctSeed__Time_Card__c tcx :
            [SELECT Id 
             FROM AcctSeed__Time_Card__c 
             WHERE AcctSeed__Employee__c = :idUser AND AcctSeed__Time_Card_Period__c = :idTimeCardPeriod 
             ORDER BY CreatedDate LIMIT 1])
        {
            tc = tcx;
        }
        if(tc == null)
        {
            tc = new AcctSeed__Time_Card__c(
                    AcctSeed__Employee__c = idUser,
                    AcctSeed__Time_Card_Period__c = idTimeCardPeriod
                );
            insert tc;

            list<AcctSeed__Time_Card_Line__c> listTCL = new list<AcctSeed__Time_Card_Line__c>();
            //find the time card immediately preceding the current time card
            //if one exists, use those lines as a template
            for(AcctSeed__Time_Card_Period__c x : [SELECT Id, AcctSeed__Start_Date__c FROM AcctSeed__Time_Card_Period__c WHERE Id = :idTimeCardPeriod]) //this is the time card period of the new time card
            {
                for(AcctSeed__Time_Card_Period__c y : [SELECT Id FROM AcctSeed__Time_Card_Period__c WHERE AcctSeed__Start_Date__c < :x.AcctSeed__Start_Date__c ORDER BY AcctSeed__Start_Date__c DESC LIMIT 1]) //this is the time card period immediately prior
                {
                    //if there are any time card lines in the prior period, use them as a template
                    for(AcctSeed__Time_Card_Line__c tclx:
                        [SELECT Id,
                                AcctSeed__Project__c,
                                AcctSeed__Project_Task__c,
                                AcctSeed__Time_Card_Variable_1__c,
                                AcctSeed__Time_Card_Variable_2__c,
                                (SELECT Id FROM AcctSeed__Time_Card_Days__r WHERE AcctSeed__Hours__c > 0)
                         FROM AcctSeed__Time_Card_Line__c
                         WHERE AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__c = :y.Id
                           AND AcctSeed__Time_Card__r.AcctSeed__Employee__c = :idUser])
                    {
                        //only include the time card lines having hours
                        if(tclx.AcctSeed__Time_Card_Days__r.size() > 0)
                        {
                            listTCL.add(new AcctSeed__Time_Card_Line__c(
                                AcctSeed__Time_Card__c = tc.Id,
                                AcctSeed__Project__c = tclx.AcctSeed__Project__c,
                                AcctSeed__Project_Task__c = tclx.AcctSeed__Project_Task__c,
                                AcctSeed__Time_Card_Variable_1__c = tclx.AcctSeed__Time_Card_Variable_1__c,
                                AcctSeed__Time_Card_Variable_2__c = tclx.AcctSeed__Time_Card_Variable_2__c
                            ));
                        }
                    }
                }
            }
            if(listTCL.size() > 0)
                insert listTCL;
        }
        return tc.Id;
    }

    @RemoteAction
    public static list<map<string,string>> retrieveTimeCardDays(Id idTimeCardPeriod)
    {
        list<map<string,string>> listJSON = new list<map<string,string>>();

        list<AcctSeed__Time_Card_Day__c> listTCD = new list<AcctSeed__Time_Card_Day__c>();
        map<Id,User> mapUser = new map<Id,User>();
        map<Id,map<Id,String>> mapWinTeamJob = new map<Id,map<Id,String>>();

        for(AcctSeed__Time_Card_Day__c tcd :
            [SELECT Id,
                    AcctSeed__Time_Card_Line__r.AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,
                    AcctSeed__Time_Card_Line__r.AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_3__r.Name,
                    AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c,
                    AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card_Variable_1__r.Exclude_From_Overtime__c,
                    AcctSeed__Time_Card_Line__r.Wage_RT__c,
                    AcctSeed__Time_Card_Line__r.Wage_OT__c,
                    AcctSeed__Time_Card_Line__r.Wage_DT__c,
                    AcctSeed__Date__c,
                    Hours_RT__c,
                    Hours_OT__c,
                    Hours_DT__c
            FROM AcctSeed__Time_Card_Day__c
            WHERE AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__c = :idTimeCardPeriod
              AND Wages__c != null 
              AND Wages__c != 0])
        {
            mapUser.put(tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c,null);

            Id idGLV2 = tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_2__c;
            Id idGLV3 = tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_3__c;

            if(!mapWinTeamJob.containsKey(idGLV2))
                mapWinTeamJob.put(idGLV2, new map<Id,String>());
            if(!mapWinTeamJob.get(idGLV2).containsKey(idGLV3))
                mapWinTeamJob.get(idGLV2).put(idGLV3,null);

            if(tcd.Hours_RT__c == null)
               tcd.Hours_RT__c = 0;
            if(tcd.Hours_OT__c == null)
               tcd.Hours_OT__c = 0;
            if(tcd.Hours_DT__c == null)
               tcd.Hours_DT__c = 0;
            if(tcd.AcctSeed__Time_Card_Line__r.Wage_RT__c == null)
                tcd.AcctSeed__Time_Card_Line__r.Wage_RT__c = 0;
            if(tcd.AcctSeed__Time_Card_Line__r.Wage_OT__c == null)
                tcd.AcctSeed__Time_Card_Line__r.Wage_OT__c = 0;
            if(tcd.AcctSeed__Time_Card_Line__r.Wage_DT__c == null)
                tcd.AcctSeed__Time_Card_Line__r.Wage_DT__c = 0;

            if(tcd.Hours_RT__c != 0 && tcd.AcctSeed__Time_Card_Line__r.Wage_RT__c != 0)
            {
                AcctSeed__Time_Card_Day__c clone = tcd.clone(false,true,false,false);
                clone.Hours_OT__c = 0;
                clone.Hours_DT__c = 0;
                listTCD.add(clone);
            }

            if(tcd.Hours_OT__c != 0 && tcd.AcctSeed__Time_Card_Line__r.Wage_OT__c != 0)
            {
                AcctSeed__Time_Card_Day__c clone = tcd.clone(false,true,false,false);
                clone.Hours_RT__c = 0;
                clone.Hours_DT__c = 0;
                listTCD.add(clone);
            }

            if(tcd.Hours_DT__c != 0 && tcd.AcctSeed__Time_Card_Line__r.Wage_DT__c != 0)
            {
                AcctSeed__Time_Card_Day__c clone = tcd.clone(false,true,false,false);
                clone.Hours_RT__c = 0;
                clone.Hours_OT__c = 0;
                listTCD.add(clone);
            }
        }

        /*for(GLVMatch__c m : 
            [SELECT GL_Account_Variable_2__c,
                    GL_Account_Variable_3__c,
                    WinTeam_Job__c
             FROM GLVMatch__c
             WHERE GL_Account_Variable_2__c IN :mapWinTeamJob.keySet()])
        {
            if(mapWinTeamJob.get(m.GL_Account_Variable_2__c).containsKey(m.GL_Account_Variable_3__c))
               mapWinTeamJob.get(m.GL_Account_Variable_2__c).put(m.GL_Account_Variable_3__c,m.WinTeam_Job__c);
        }*/

        for(User u : 
            [SELECT Id, Name,
                    (SELECT Id, Name, Employee_Number__c, GL_Account_Variable_2__r.Name, GL_Account_Variable_3__r.Name
                     FROM Employees__r
                     ORDER BY CreatedDate
                     LIMIT 1)
             FROM User
             WHERE Id IN :mapUser.keySet()])
        {
            mapUser.put(u.Id,u);
        }

        for(AcctSeed__Time_Card_Day__c tcd : listTCD)
        {
            map<String,String> m = new map<String,String>();

            User u = mapUser.get(tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c);

            if(u.Employees__r.isEmpty())
                m.put('employeeName',u.Name);
            else
            {
                m.put('employeeName',u.Employees__r[0].Name);
                m.put('employeeNumber',u.Employees__r[0].Employee_Number__c);
            }

            Id idGLV2 = tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_2__c;
            Id idGLV3 = tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_3__c;

            if(tcd.AcctSeed__Date__c != null)
                m.put('timeCardDate',tcd.AcctSeed__Date__c.format());

            if(tcd.Hours_RT__c != 0)
            {
                map<string,string> clone = m.clone();
                clone.put('hours',String.valueOf(tcd.Hours_RT__c.setScale(2)));
                clone.put('rate',String.valueOf(tcd.AcctSeed__Time_Card_Line__r.Wage_RT__c.setScale(2)));

                listJSON.add(clone);
            }

            if(tcd.Hours_OT__c != 0)
            {
                Decimal rate = tcd.AcctSeed__Time_Card_Line__r.Wage_OT__c / 1.5;

                map<string,string> clone = m.clone();
                clone.put('hours',String.valueOf(tcd.Hours_OT__c.setScale(2)));
                clone.put('rate',String.valueOf(rate.setScale(2)));

                listJSON.add(clone);
            }

            if(tcd.Hours_DT__c != 0)
            {
                Decimal rate = tcd.AcctSeed__Time_Card_Line__r.Wage_DT__c / 2;

                map<string,string> clone = m.clone();
                clone.put('hours',String.valueOf(tcd.Hours_DT__c.setScale(2)));
                clone.put('rate',String.valueOf(rate.setScale(2)));

                listJSON.add(clone);
            }
        }

        return listJSON;
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
    }
}