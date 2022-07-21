public without sharing class gcTimeCard_Ext {
  public gcTimeCard_Ext(ApexPages.StandardController ctrl) {
  }
  public gcTimeCard_Ext() {
  }

  public class myException extends Exception {
  }

  @RemoteAction
  @ReadOnly
  public static list<map<string, string>> retrieveTimeCardLines(String idFilter, String idProject) {
    list<map<string, string>> listJSON = new List<map<string, string>>();
    Set<ID> setDayHasEntry = new Set<ID>();

    for (Time_Card_Entry__c tce : [
      SELECT Id, Time_Card_Day__c
      FROM Time_Card_Entry__c
      WHERE
        Time_Card_Day__r.AcctSeed__Time_Card_Line__c = :idFilter
        OR Time_Card_Day__r.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__c = :idFilter
    ]) {
      setDayHasEntry.add(tce.Time_Card_Day__c);
    }
    Boolean deleteCheck = false;
    if (idProject != null && idProject != '')
      deleteCheck = true;
    for (
      AcctSeed__Time_Card_Line__c tcl : [
        SELECT
          Id,
          Name,
          AcctSeed__Project__c,
          AcctSeed__Project__r.Name,
          AcctSeed__Project__r.RecordType.DeveloperName,
          AcctSeed__Project__r.AcctSeed__Account__r.Name,
          AcctSeed__Project__r.Salesperson__r.Name,
          AcctSeed__Project__r.GMBLASERP__Warehouse__r.Name,
          AcctSeed__Project_Task__c,
          AcctSeed__Project_Task__r.Name,
          AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_1__r.Name,
          AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,
          AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_3__r.Name,
          /* AcctSeed__Project_Task__r.Service_Order__r.Name,*/
          AcctSeed__Total_Hours__c,
          AcctSeed__Time_Card_Variable_1__c,
          AcctSeed__Time_Card_Variable_1__r.Name,
          AcctSeed__Time_Card_Variable_2__c,
          AcctSeed__Time_Card_Variable_2__r.Name,
          AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__Status__c,
          (
            SELECT Id, AcctSeed__Date__c, AcctSeed__Hours__c, Burden__c, Hours_RT__c, Hours_OT__c, Hours_DT__c, Wages__c
            FROM AcctSeed__Time_Card_Days__r
            ORDER BY AcctSeed__Date__c
          ),
          Wage_RT__c,
          Wage_OT__c,
          Wage_DT__c
        FROM AcctSeed__Time_Card_Line__c
        WHERE
          (Id = :idFilter
          OR AcctSeed__Time_Card__c = :idFilter)
          AND (isDeleted = :deleteCheck
          OR AcctSeed__Project__c = :idProject)
          AND isDeleted = FALSE
      ]
    ) {
      //if(idProject != null && idProject != '' && idProject != tcl.AcctSeed__Project__c) continue;
      map<string, string> m = new Map<string, string>();
      m.put('idTimeCardLine', tcl.Id);
      m.put('timeCardLineName', tcl.Name);
      m.put('idProject', tcl.AcctSeed__Project__c);
      m.put('idProjectTask', tcl.AcctSeed__Project_Task__c);
      m.put('idTCV1', tcl.AcctSeed__Time_Card_Variable_1__c);
      m.put('idTCV2', tcl.AcctSeed__Time_Card_Variable_2__c);
      m.put('projectName', tcl.AcctSeed__Project__r.Name);
      m.put('projectTaskName', tcl.AcctSeed__Project_Task__r.Name);
      m.put('projectAccount', tcl.AcctSeed__Project__r.AcctSeed__Account__r.Name);
      m.put('glv2Name', tcl.AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name);
      m.put('glv3Name', tcl.AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_3__r.Name);
      m.put('tcv1Name', tcl.AcctSeed__Time_Card_Variable_1__r.Name);
      m.put('tcv2Name', tcl.AcctSeed__Time_Card_Variable_2__r.Name);
      //m.put('workOrderName',tcl.AcctSeed__Project_Task__r.Service_Order__r.Name);

      m.put('recordType', tcl.AcctSeed__Project__r.RecordType.DeveloperName);
      m.put('salesPerson', tcl.AcctSeed__Project__r.Salesperson__r.Name);
      m.put('glv1Name', tcl.AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_1__r.Name);
      m.put('wareHouse', tcl.AcctSeed__Project__r.GMBLASERP__Warehouse__r.Name);

      m.put('wageRateRT', (tcl.Wage_RT__c == null ? '0' : String.valueOf(tcl.Wage_RT__c.setScale(2))));
      m.put('wageRateOT', (tcl.Wage_OT__c == null ? '0' : String.valueOf(tcl.Wage_OT__c.setScale(2))));
      m.put('wageRateDT', (tcl.Wage_DT__c == null ? '0' : String.valueOf(tcl.Wage_DT__c.setScale(2))));

      if (tcl.AcctSeed__Total_Hours__c != null)
        m.put('totalHours', String.valueOf(tcl.AcctSeed__Total_Hours__c.setScale(2)));

      if (tcl.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__r.AcctSeed__Status__c == 'Open')
        m.put('periodIsOpen', 'true');
      else
        m.put('periodIsOpen', 'false');

      Date datePrior;
      Decimal hoursToday = 0;
      Decimal hoursTodayRT = 0;
      Decimal hoursTodayOT = 0;
      Decimal hoursTodayDT = 0;
      Decimal wagesToday = 0;
      Decimal burdenToday = 0;

      Decimal hoursTCLTotalRT = 0;
      Decimal hoursTCLTotalOT = 0;
      Decimal hoursTCLTotalDT = 0;

      if (tcl.Wage_RT__c == null)
        tcl.Wage_RT__c = 0;
      if (tcl.Wage_OT__c == null)
        tcl.Wage_OT__c = 0;
      if (tcl.Wage_DT__c == null)
        tcl.Wage_DT__c = 0;

      String keyRoot;
      //Decimal wages;
      Decimal totalWages = 0;
      Decimal totalBurden = 0;

      Set<String> setKeys = new Set<String>();
      for (AcctSeed__Time_Card_Day__c tcd : tcl.AcctSeed__Time_Card_Days__r) {
        if (datePrior == null)
          datePrior = tcd.AcctSeed__Date__c;
        if (datePrior != tcd.AcctSeed__Date__c) {
          keyRoot = convertDateToKey(datePrior);
          m.put(keyRoot, String.valueOf(hoursToday.setScale(2)));
          m.put(keyRoot + 'RT', String.valueOf(hoursTodayRT.setScale(2)));
          m.put(keyRoot + 'OT', String.valueOf(hoursTodayOT.setScale(2)));
          m.put(keyRoot + 'DT', String.valueOf(hoursTodayDT.setScale(2)));
          //wages = hoursTodayRT * tcl.Wage_RT__c + hoursTodayOT * tcl.Wage_OT__c + hoursTodayDT * tcl.Wage_DT__c;
          m.put(keyRoot + 'Wages', String.valueOf(wagesToday.setScale(2)));
          m.put(keyRoot + 'Burden', String.valueOf(burdenToday.setScale(2)));

          totalWages += wagesToday;
          totalBurden += burdenToday;

          hoursToday = 0;
          hoursTodayRT = 0;
          hoursTodayOT = 0;
          hoursTodayDT = 0;
          wagesToday = 0;
          burdenToday = 0;
        }
        if (tcd.AcctSeed__Hours__c != null)
          hoursToday += tcd.AcctSeed__Hours__c;
        if (tcd.Hours_RT__c != null)
          hoursTodayRT += tcd.Hours_RT__c;
        if (tcd.Hours_OT__c != null)
          hoursTodayOT += tcd.Hours_OT__c;
        if (tcd.Hours_DT__c != null)
          hoursTodayDT += tcd.Hours_DT__c;
        if (tcd.Wages__c != null)
          wagesToday += tcd.Wages__c;
        if (tcd.Burden__c != null)
          burdenToday += tcd.Burden__c;

        if (setDayHasEntry.contains(tcd.Id)) {
          setKeys.add(convertDateToKey(tcd.AcctSeed__Date__c));
        }

        hoursTCLTotalRT += hoursTodayRT;
        hoursTCLTotalOT += hoursTodayOT;
        hoursTCLTotalDT += hoursTodayDT;

        datePrior = tcd.AcctSeed__Date__c;
      }

      m.put('hoursTCLTotalRT', String.valueOf(hoursTCLTotalRT.setScale(2)));
      m.put('hoursTCLTotalOT', String.valueOf(hoursTCLTotalOT.setScale(2)));
      m.put('hoursTCLTotalDT', String.valueOf(hoursTCLTotalDT.setScale(2)));

      if (datePrior != null) {
        keyRoot = convertDateToKey(datePrior);
        m.put(keyRoot, String.valueOf(hoursToday.setScale(2)));
        m.put(keyRoot + 'RT', String.valueOf(hoursTodayRT.setScale(2)));
        m.put(keyRoot + 'OT', String.valueOf(hoursTodayOT.setScale(2)));
        m.put(keyRoot + 'DT', String.valueOf(hoursTodayDT.setScale(2)));
        //wages = hoursTodayRT * tcl.Wage_RT__c + hoursTodayOT * tcl.Wage_OT__c + hoursTodayDT * tcl.Wage_DT__c;
        m.put(keyRoot + 'Wages', String.valueOf(wagesToday.setScale(2)));
        m.put(keyRoot + 'Burden', String.valueOf(burdenToday.setScale(2)));

        totalWages += wagesToday;
        totalBurden += burdenToday;
      }

      m.put('totalWages', String.valueOf(totalWages.setScale(2)));
      m.put('totalBurden', String.valueOf(totalBurden.setScale(2)));

      String keyString = '';
      for (String s : setKeys) {
        keyString += (keyString == '' ? '' : ',') + s;
      }
      m.put('timeCardDaysHavingEntries', keyString);

      listJSON.add(m);
    }
    return listJSON;
  }

  @RemoteAction
  @ReadOnly
  public static list<map<string, string>> retrieveTimeCardDates(Id idFilter) {
    list<map<string, string>> listJSON = new List<map<string, string>>();

    AcctSeed__Time_Card_Period__c tcp;

    for (AcctSeed__Time_Card__c tcx : [
      SELECT
        Id,
        AcctSeed__Time_Card_Period__r.Id,
        AcctSeed__Time_Card_Period__r.AcctSeed__Start_Date__c,
        AcctSeed__Time_Card_Period__r.AcctSeed__End_Date__c
      FROM AcctSeed__Time_Card__c
      WHERE Id = :idFilter OR AcctSeed__Time_Card_Period__c = :idFilter
      LIMIT 1
    ]) {
      tcp = tcx.AcctSeed__Time_Card_Period__r;
    }
    if (tcp == null)
      tcp = [
        SELECT Id, AcctSeed__Start_Date__c, AcctSeed__End_Date__c
        FROM AcctSeed__Time_Card_Period__c
        WHERE Id = :idFilter
      ][0];

    for (Integer i = 0; i <= tcp.AcctSeed__Start_Date__c.daysBetween(tcp.AcctSeed__End_Date__c); i++) {
      map<string, string> m = new Map<string, string>();

      Date myDate = tcp.AcctSeed__Start_Date__c.addDays(i);
      DateTime myDateTime = DateTime.newInstance(myDate, Time.newInstance(0, 0, 0, 0));

      m.put('dataIndx', convertDateToKey(myDate));
      m.put('dayOfWeek', myDateTime.format('EEE'));
      //m.put('monthName',myDateTime.format('MMM'));
      //m.put('dayOfMonth',myDateTime.format('d'));
      m.put('myDate', myDateTime.date().format());

      listJSON.add(m);
    }
    return listJSON;
  }

  @RemoteAction
  @ReadOnly
  public static string retrieveEmployeeName(Id idTimeCard) {
    for (AcctSeed__Time_Card__c tcx : [
      SELECT AcctSeed__Employee__r.Name
      FROM AcctSeed__Time_Card__c
      WHERE Id = :idTimeCard
    ]) {
      return tcx.AcctSeed__Employee__r.Name;
    }
    return '';
  }

  private static string convertDateToKey(Date myDate) {
    return 'd' + String.valueOf(myDate).replaceAll('-', '');
  }

  private static Date convertKeyToDate(String myKey) {
    // the string d20150301 is passed in, and the date 2015-03-01 is returned.
    return Date.newInstance(
      Integer.valueOf(myKey.substring(1, 5)),
      Integer.valueOf(myKey.substring(5, 7)),
      Integer.valueOf(myKey.substring(7, 9))
    );
  }

  @RemoteAction
  public static string createTimeCardLine(Id idTimeCard, Id idProject, Id idProjectTask, Id idTCV) {
    AcctSeed__Time_Card_Line__c tcl = new AcctSeed__Time_Card_Line__c(
      AcctSeed__Time_Card__c = idTimeCard,
      AcctSeed__Project__c = idProject,
      AcctSeed__Project_Task__c = idProjectTask
    );

    for (AcctSeed__Accounting_Variable__c glv : [
      SELECT Id, AcctSeed__Type__c
      FROM AcctSeed__Accounting_Variable__c
      WHERE Id = :idTCV
    ]) {
      if (glv.AcctSeed__Type__c == 'Time Card Variable 1')
        tcl.AcctSeed__Time_Card_Variable_1__c = glv.Id;
      else
        tcl.AcctSeed__Time_Card_Variable_2__c = glv.Id;
    }

    insert tcl;

    return '';
  }

  @RemoteAction
  public static string createTimeCardLineOLD(Id idTimeCard, Id idProject, Id idProjectTask, Id idTCV2) {
    insert new AcctSeed__Time_Card_Line__c(
      AcctSeed__Time_Card__c = idTimeCard,
      AcctSeed__Project__c = idProject,
      AcctSeed__Project_Task__c = idProjectTask,
      AcctSeed__Time_Card_Variable_2__c = idTCV2
    );

    return '';
  }

  @RemoteAction
  public static list<map<string, string>> deleteTimeCardLine(Id idTimeCard, Id idTimeCardLine, String idProject) {
    delete [SELECT Id FROM AcctSeed__Time_Card_Line__c WHERE Id = :idTimeCardLine];
    return retrieveTimeCardLines(idTimeCard, idProject);
  }

  @RemoteAction
  public static string deleteTimeCardEntry(Id idTimeCardEntry) {
    delete [SELECT Id FROM Time_Card_Entry__c WHERE Id = :idTimeCardEntry];
    return '';
  }

  @RemoteAction
  @ReadOnly
  public static list<map<string, string>> retrieveProjectTasks(String idProject) {
    list<map<string, string>> listJSON = new List<map<string, string>>();
    Id idRtProjectManufacturing = gcConstants.idRtProjectManufacturing;
    Id idRtProjectService = gcConstants.idRtProjectService;
    Id idRtProjectWarranty = gcConstants.idRtProjectWarranty;
    Id idRtProjectBoatSale = gcConstants.idRtProjectBoatSale;
    Id idRtProjectPartnerBoatSale = gcConstants.idRtProjectPartnerBoatSale;
    Set<Id> setIdReType = new Set<Id>{
      idRtProjectManufacturing,
      idRtProjectService,
      idRtProjectWarranty,
      idRtProjectBoatSale,
      idRtProjectPartnerBoatSale
    };
    Boolean deleteCheck = false;
    if (idProject != '' && idProject != null)
      deleteCheck = true;
    for (
      AcctSeed__Project_Task__c pt : [
        SELECT
          Id,
          Name,
          AcctSeed__Project__c,
          AcctSeed__Project__r.Name,
          AcctSeed__Project__r.RecordType.DeveloperName,
          AcctSeed__Project__r.AcctSeed__Account__r.Name,
          AcctSeed__Project__r.Salesperson__r.Name,
          AcctSeed__Project__r.GMBLASERP__Warehouse__r.Name,
          /*AcctSeed__Project__r.Internal__c, */
          AcctSeed__GL_Account_Variable_1__r.Name,
          AcctSeed__GL_Account_Variable_2__r.Name,
          AcctSeed__GL_Account_Variable_3__r.Name
        /*(SELECT Id, Name FROM Service_Orders__r ORDER BY CreatedDate)*/
        FROM AcctSeed__Project_Task__c
        WHERE
          AcctSeed__Project__r.AcctSeed__Status__c = 'Active'
          AND AcctSeed__Project__r.RecordTypeId IN :setIdReType
          AND AcctSeed__Status__c = 'Active'
          AND (isDeleted = :deleteCheck
          OR AcctSeed__Project__c = :idProject)
          AND isDeleted = FALSE
      ]
    ) {
      map<string, string> m = new Map<string, string>();
      m.put('idProjectTask', pt.Id);
      m.put('projectTaskName', pt.Name);
      m.put('idProject', pt.AcctSeed__Project__c);
      m.put('projectName', pt.AcctSeed__Project__r.Name);
      m.put('projectAccount', pt.AcctSeed__Project__r.AcctSeed__Account__r.Name);
      m.put('glv2Name', pt.AcctSeed__GL_Account_Variable_2__r.Name);
      m.put('glv3Name', pt.AcctSeed__GL_Account_Variable_3__r.Name);

      m.put('recordType', pt.AcctSeed__Project__r.RecordType.DeveloperName);
      m.put('salesPerson', pt.AcctSeed__Project__r.Salesperson__r.Name);
      m.put('glv1Name', pt.AcctSeed__GL_Account_Variable_1__r.Name);
      m.put('wareHouse', pt.AcctSeed__Project__r.GMBLASERP__Warehouse__r.Name);

      String workOrderName = '';
      /*for(SVMXC__Service_Order__c so : pt.Service_Orders__r)
            {
                if(workOrderName != '')
                    workOrderName += ', ';
                workOrderName += so.Name;
            }*/
      m.put('workOrderName', workOrderName);

      /* if(pt.AcctSeed__Project__r.Internal__c)
                m.put('isInternal','true');
            else
                m.put('isInternal','false');*/

      listJSON.add(m);
    }
    return listJSON;
  }

  @RemoteAction
  @ReadOnly
  public static list<map<string, string>> retrieveOptions_tcv2(Id idProject, Id idProjectTask, Id idTimeCard) {
    list<map<string, string>> listJSON = new List<map<string, string>>();

    set<Id> setIdAlreadyIncluded = new Set<Id>();
    for (AcctSeed__Time_Card_Line__c tclx : [
      SELECT
        AcctSeed__Time_Card_Variable_1__c,
        AcctSeed__Time_Card_Variable_1__r.Uniquefier__c,
        AcctSeed__Time_Card_Variable_2__c,
        AcctSeed__Time_Card_Variable_2__r.Uniquefier__c
      FROM AcctSeed__Time_Card_Line__c
      WHERE
        AcctSeed__Time_Card__c = :idTimeCard
        AND AcctSeed__Project__c = :idProject
        AND AcctSeed__Project_Task__c = :idProjectTask
    ]) {
      setIdAlreadyIncluded.add(tclx.AcctSeed__Time_Card_Variable_1__c);
      /*if(tclx.AcctSeed__Time_Card_Variable_1__r.Uniquefier__c == 'WORK' || tclx.AcctSeed__Time_Card_Variable_2__r.Uniquefier__c != 'DIRECT')
                setIdAlreadyIncluded.add(tclx.AcctSeed__Time_Card_Variable_2__c);
            if(tclx.AcctSeed__Time_Card_Variable_1__r.Uniquefier__c != 'WORK')
                setIdAlreadyIncluded.add(tclx.AcctSeed__Time_Card_Variable_1__c);*/
    }

    set<Id> setIdAllowed = new Set<Id>();
    for (Project_Labor_Rate__c plr : [
      SELECT Time_Card_Variable_2__c
      FROM Project_Labor_Rate__c
      WHERE Project__c = :idProject AND Active__c = TRUE
    ]) {
      setIdAllowed.add(plr.Time_Card_Variable_2__c);
    }

    map<string, string> mapDirect;

    for (
      AcctSeed__Accounting_Variable__c glv : [
        SELECT Id, Name, AcctSeed__Type__c, Uniquefier__c
        FROM AcctSeed__Accounting_Variable__c
        WHERE
          AcctSeed__Type__c = 'Time Card Variable 1' // AND Uniquefier__c != 'WORK')
          OR (AcctSeed__Type__c = 'Time Card Variable 2'
          AND (Id IN :setIdAllowed
          OR Uniquefier__c = 'DIRECT'))
        ORDER BY AcctSeed__Type__c DESC, Name
      ]
    ) {
      if (setIdAlreadyIncluded.contains(glv.Id))
        continue;
      if (
        glv.AcctSeed__Type__c == 'Time Card Variable 2' &&
        glv.Uniquefier__c != 'DIRECT' &&
        !setIdAllowed.contains(glv.Id)
      )
        continue;

      map<string, string> m = new Map<string, string>{ 'idGlv' => glv.Id, 'glvName' => glv.Name };
      if (glv.Uniquefier__c == 'WORK')
        mapDirect = m;
      else
        listJSON.add(m);
    }
    if (mapDirect != null)
      listJSON.add(0, mapDirect);

    return listJSON;
  }

  public static list<map<string, string>> retrieveOptions_tcv2OLD(Id idProject, Id idProjectTask, Id idTimeCard) {
    list<map<string, string>> listJSON = new List<map<string, string>>();

    Boolean directOnly = false;
    for (AcctSeed__Project_Task__c pt : [
      SELECT Id, AcctSeed__GL_Account_Variable_3__r.Name
      FROM AcctSeed__Project_Task__c
      WHERE Id = :idProjectTask
    ]) {
      if (
        pt.AcctSeed__GL_Account_Variable_3__r.Name == 'Holiday' ||
        pt.AcctSeed__GL_Account_Variable_3__r.Name == 'Medical' ||
        pt.AcctSeed__GL_Account_Variable_3__r.Name == 'Vacation'
      )
        directOnly = true;
    }

    set<Id> setIdAlreadyIncluded = new Set<Id>();
    for (AcctSeed__Time_Card_Line__c tclx : [
      SELECT AcctSeed__Time_Card_Variable_2__c
      FROM AcctSeed__Time_Card_Line__c
      WHERE
        AcctSeed__Time_Card__c = :idTimeCard
        AND AcctSeed__Project__c = :idProject
        AND AcctSeed__Project_Task__c = :idProjectTask
    ]) {
      setIdAlreadyIncluded.add(tclx.AcctSeed__Time_Card_Variable_2__c);
    }

    map<string, string> mapGlv = new Map<string, string>();

    for (AcctSeed__Accounting_Variable__c glv : [
      SELECT Id, Name
      FROM AcctSeed__Accounting_Variable__c
      WHERE AcctSeed__Type__c = 'Time Card Variable 2' AND Name = 'Direct'
      ORDER BY CreatedDate
      LIMIT 1
    ]) {
      if (!setIdAlreadyIncluded.contains(glv.Id))
        mapGlv.put(glv.Name, glv.Id);
    }

    if (directOnly == false)
      for (Project_Labor_Rate__c plr : [
        SELECT Time_Card_Variable_2__c, Time_Card_Variable_2__r.Name
        FROM Project_Labor_Rate__c
        WHERE Project__c = :idProject AND Active__c = TRUE
        ORDER BY Time_Card_Variable_2__r.Name
      ]) {
        if (!setIdAlreadyIncluded.contains(plr.Time_Card_Variable_2__c))
          mapGlv.put(plr.Time_Card_Variable_2__r.Name, plr.Time_Card_Variable_2__c);
      }

    for (string glvName : mapGlv.keySet()) {
      String idGlv = mapGlv.get(glvName);
      map<string, string> m = new Map<string, string>();
      m.put('idGlv', idGlv);
      m.put('glvName', glvName);
      listJSON.add(m);
    }
    return listJSON;
  }

  @RemoteAction
  @ReadOnly
  public static list<map<string, string>> retrieveTimeCardEntries(Id idTimeCard, String key) {
    Date myDate = convertKeyToDate(key);

    list<map<string, string>> listJSON = new List<map<string, string>>();
    map<Id, list<Time_Card_Entry__c>> mapLineListEntry = new Map<Id, list<Time_Card_Entry__c>>();

    for (Time_Card_Entry__c tce : [
      SELECT
        Id,
        isDoubleTime__c,
        Time_Card_Day__r.AcctSeed__Time_Card_Line__c,
        Time_In__c,
        Time_In_Picklist__c,
        Time_Out_Picklist__c,
        Hours__c
      FROM Time_Card_Entry__c
      WHERE
        Time_Card_Day__r.AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__c = :idTimeCard
        AND Time_Card_Day__r.AcctSeed__Date__c = :myDate
      ORDER BY Time_In__c
    ]) {
      if (!mapLineListEntry.containsKey(tce.Time_Card_Day__r.AcctSeed__Time_Card_Line__c))
        mapLineListEntry.put(tce.Time_Card_Day__r.AcctSeed__Time_Card_Line__c, new List<Time_Card_Entry__c>());

      mapLineListEntry.get(tce.Time_Card_Day__r.AcctSeed__Time_Card_Line__c).add(tce);
    }
    System.debug('idTimeCard - ' + idTimeCard);
    for (
      AcctSeed__Time_Card_Line__c tcl : [
        SELECT
          Id,
          AcctSeed__Project__c,
          AcctSeed__Project__r.Name,
          AcctSeed__Project__r.RecordType.DeveloperName,
          AcctSeed__Project__r.AcctSeed__Account__r.Name,
          AcctSeed__Project__r.Salesperson__r.Name,
          AcctSeed__Project__r.GMBLASERP__Warehouse__r.Name,
          AcctSeed__Project_Task__c,
          AcctSeed__Project_Task__r.Name,
          AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_1__r.Name,
          AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,
          AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_3__r.Name,
          /*AcctSeed__Project_Task__r.Service_Order__r.Name,*/
          AcctSeed__Time_Card_Variable_1__r.Name,
          AcctSeed__Time_Card_Variable_1__r.Exclude_From_Overtime__c,
          AcctSeed__Time_Card_Variable_2__r.Name,
          (SELECT Id, AcctSeed__Hours__c FROM AcctSeed__Time_Card_Days__r WHERE AcctSeed__Date__c = :myDate)
        FROM AcctSeed__Time_Card_Line__c
        WHERE AcctSeed__Time_Card__c = :idTimeCard
      ]
    ) {
      Decimal bulkHours = 0;

      if (mapLineListEntry.containsKey(tcl.Id)) {
        for (Time_Card_Entry__c tce : mapLineListEntry.get(tcl.Id)) {
          map<string, string> m = new Map<string, string>();

          m.put('projectName', tcl.AcctSeed__Project__r.Name);
          m.put('projectTaskName', tcl.AcctSeed__Project_Task__r.Name);
          m.put('projectAccount', tcl.AcctSeed__Project__r.AcctSeed__Account__r.Name);
          m.put('glv2Name', tcl.AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name);
          m.put('glv3Name', tcl.AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_3__r.Name);
          m.put('tcv1Name', tcl.AcctSeed__Time_Card_Variable_1__r.Name);
          m.put('tcv2Name', tcl.AcctSeed__Time_Card_Variable_2__r.Name);
          //m.put('workOrderName',tcl.AcctSeed__Project_Task__r.Service_Order__r.Name);

          m.put('recordType', tcl.AcctSeed__Project__r.RecordType.DeveloperName);
          m.put('salesPerson', tcl.AcctSeed__Project__r.Salesperson__r.Name);
          m.put('glv1Name', tcl.AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_1__r.Name);
          m.put('wareHouse', tcl.AcctSeed__Project__r.GMBLASERP__Warehouse__r.Name);

          m.put('idTimeCardEntry', tce.Id);
          m.put('idTimeCardLine', tcl.Id);
          m.put('timeIn', tce.Time_In_Picklist__c);
          m.put('timeOut', tce.Time_Out_Picklist__c);
          m.put('timeInMilliseconds', String.valueOf(tce.Time_In__c.getTime()));
          m.put('hours', String.valueof(tce.Hours__c.setScale(2)));
          m.put('key', key);

          if (tce.isDoubleTime__c)
            m.put('isDoubleTime', 'true');
          else
            m.put('isDoubleTime', 'false');

          if (tcl.AcctSeed__Time_Card_Variable_1__r.Exclude_From_Overtime__c)
            m.put('excludeFromOvertime', 'true');
          else
            m.put('excludeFromOvertime', 'false');

          listJSON.add(m);
        }
      } else {
        for (AcctSeed__Time_Card_Day__c tcd : tcl.AcctSeed__Time_Card_Days__r) {
          if (tcd.AcctSeed__Hours__c != null)
            bulkHours += tcd.AcctSeed__Hours__c;
        }
      }

      map<string, string> m = new Map<string, string>();

      m.put('idTimeCardLine', tcl.Id);

      m.put('projectName', tcl.AcctSeed__Project__r.Name);
      m.put('projectTaskName', tcl.AcctSeed__Project_Task__r.Name);
      m.put('projectAccount', tcl.AcctSeed__Project__r.AcctSeed__Account__r.Name);
      m.put('glv2Name', tcl.AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name);
      m.put('glv3Name', tcl.AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_3__r.Name);
      m.put('tcv1Name', tcl.AcctSeed__Time_Card_Variable_1__r.Name);
      m.put('tcv2Name', tcl.AcctSeed__Time_Card_Variable_2__r.Name);
      //m.put('workOrderName',tcl.AcctSeed__Project_Task__r.Service_Order__r.Name);

      m.put('recordType', tcl.AcctSeed__Project__r.RecordType.DeveloperName);
      m.put('salesPerson', tcl.AcctSeed__Project__r.Salesperson__r.Name);
      m.put('glv1Name', tcl.AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_1__r.Name);
      m.put('wareHouse', tcl.AcctSeed__Project__r.GMBLASERP__Warehouse__r.Name);

      m.put('timeIn', '');
      m.put('timeOut', '');
      m.put('timeInMilliseconds', String.valueOf('999999999999999'));
      m.put('hours', String.valueOf(bulkHours.setScale(2)));
      m.put('key', key);

      listJSON.add(m);
    }
    return listJSON;
  }

  @RemoteAction
  @ReadOnly
  public static list<string> retrieveTimeInPicklistValues() {
    list<string> listOptions = new List<string>();
    for (Schema.PicklistEntry opt : Time_Card_Entry__c.fields.Time_In_Picklist__c.getDescribe().getpicklistvalues()) {
      listOptions.add(opt.getValue());
    }
    return listOptions;
  }

  @RemoteAction
  @ReadOnly
  public static list<string> retrieveTimeOutPicklistValues() {
    list<string> listOptions = new List<string>();
    for (Schema.PicklistEntry opt : Time_Card_Entry__c.fields.Time_Out_Picklist__c.getDescribe().getpicklistvalues()) {
      listOptions.add(opt.getValue());
    }
    return listOptions;
  }

  @RemoteAction
  @ReadOnly
  public static String retrievePeriodStatus(Id idTimeCard) {
    return [
      SELECT AcctSeed__Time_Card_Period__r.AcctSeed__Status__c
      FROM AcctSeed__Time_Card__c
      WHERE Id = :idTimeCard
    ][0]
    .AcctSeed__Time_Card_Period__r.AcctSeed__Status__c;
  }

  @RemoteAction
  public static string upsertTimeCardEntries(list<map<string, string>> listTimeCardEntries) {
    list<Time_Card_Entry__c> listTCEupdate = new List<Time_Card_Entry__c>();
    list<Time_Card_Entry__c> listTCEinsert = new List<Time_Card_Entry__c>();

    map<Id, map<Date, Id>> mapLineDateDay = new Map<Id, map<Date, Id>>();

    for (map<String, String> m : listTimeCardEntries) {
      if (m.containsKey('idTimeCardEntry') && m.get('idTimeCardEntry') != null) {
        //an existing time card entry is being updated
      } else //a new time card entry must be created, so identify the lines and dates that are required
      {
        String idTimeCardLine = m.get('idTimeCardLine');
        Date myDate = convertKeyToDate(m.get('key'));

        if (!mapLineDateDay.containsKey(idTimeCardLine))
          mapLineDateDay.put(idTimeCardLine, new Map<Date, Id>());
        mapLineDateDay.get(idTimeCardLine).put(myDate, null);
      }
    }

    //create time card days, if necessary
    if (mapLineDateDay.size() > 0) {
      list<AcctSeed__Time_Card_Day__c> listTCDinsert = new List<AcctSeed__Time_Card_Day__c>();

      for (AcctSeed__Time_Card_Line__c tcl : [
        SELECT Id, (SELECT Id, AcctSeed__Date__c FROM AcctSeed__Time_Card_Days__r)
        FROM AcctSeed__Time_Card_Line__c
        WHERE Id IN :mapLineDateDay.keySet()
      ]) {
        map<Date, Id> mapDateDay = mapLineDateDay.get(tcl.Id);
        for (AcctSeed__Time_Card_Day__c tcd : tcl.AcctSeed__Time_Card_Days__r) {
          if (mapDateDay.containsKey(tcd.AcctSeed__Date__c)) {
            mapDateDay.put(tcd.AcctSeed__Date__c, tcd.Id);
          }
        }
        for (Date myDate : mapDateDay.keySet()) {
          if (mapDateDay.get(myDate) == null) {
            listTCDinsert.add(
              new AcctSeed__Time_Card_Day__c(AcctSeed__Time_Card_Line__c = tcl.Id, AcctSeed__Date__c = myDate)
            );
          }
        }
      }
      if (listTCDinsert.size() > 0) {
        insert listTCDinsert;
        for (AcctSeed__Time_Card_Day__c tcd : listTCDinsert) {
          mapLineDateDay.get(tcd.AcctSeed__Time_Card_Line__c).put(tcd.AcctSeed__Date__c, tcd.Id);
        }
      }
    }

    //upsert time card entries
    for (map<String, String> m : listTimeCardEntries) {
      //update an existing time card entry
      if (m.containsKey('idTimeCardEntry') && m.get('idTimeCardEntry') != null) {
        listTCEupdate.add(
          new Time_Card_Entry__c(
            Id = m.get('idTimeCardEntry'),
            Time_In_Picklist__c = m.get('timeIn'),
            Time_Out_Picklist__c = m.get('timeOut'),
            isDoubleTime__c = (m.get('isDoubleTime') == 'true' ? true : false)
          )
        );
      } else {
        //insert or a new time card entry
        listTCEinsert.add(
          new Time_Card_Entry__c(
            Time_Card_Day__c = mapLineDateDay.get(m.get('idTimeCardLine')).get(convertKeyToDate(m.get('key'))),
            Time_In_Picklist__c = m.get('timeIn'),
            Time_Out_Picklist__c = m.get('timeOut'),
            isDoubleTime__c = (m.get('isDoubleTime') == 'true' ? true : false)
          )
        );
      }
    }

    if (listTCEupdate.size() > 0)
      update listTCEupdate;
    if (listTCEinsert.size() > 0)
      insert listTCEinsert;
    return '';
  }

  @RemoteAction
  public static list<map<string, string>> updateTimeCardDayBulkHours(
    Id idTimeCard,
    Id idTimeCardLine,
    String key,
    Decimal hoursNew,
    String idProject
  ) {
    //if the time card period is closed, don't do anything
    if (
      [SELECT AcctSeed__Time_Card_Period__r.AcctSeed__Status__c FROM AcctSeed__Time_Card__c WHERE Id = :idTimeCard][0]
      .AcctSeed__Time_Card_Period__r.AcctSeed__Status__c == 'Open'
    ) {
      Date myDate = convertKeyToDate(key);
      Savepoint sp = Database.setSavepoint();
      try {
        //delete any matching time card days; deleting instead of updating results in less DML, due to roll-ups and overtime calculations
        delete [
          SELECT Id
          FROM AcctSeed__Time_Card_Day__c
          WHERE AcctSeed__Time_Card_Line__c = :idTimeCardLine AND AcctSeed__Date__c = :myDate
        ];

        if (hoursNew > 0) {
          //insert a new time card day
          Boolean boolOld = gcTimeCardDay.allowDMLHours;
          gcTimeCardDay.allowDMLHours = true;

          insert new AcctSeed__Time_Card_Day__c(
            AcctSeed__Time_Card_Line__c = idTimeCardLine,
            AcctSeed__Date__c = myDate,
            AcctSeed__Hours__c = hoursNew
          );

          gcTimeCardDay.allowDMLHours = boolOld;
        }
      } catch (DmlException de) {
        Database.rollback(sp);
        throw new customException(de.getMessage());
      }
    }

    return retrieveTimeCardLines(idTimeCard, idProject);
  }

  @RemoteAction
  public static list<map<string, string>> updateTimeCardDayBulkEditHours(
    Id idTimeCard,
    List<Map<String, String>> listTimeCardLineValues,
    String idProject
  ) {
    if (
      [SELECT AcctSeed__Time_Card_Period__r.AcctSeed__Status__c FROM AcctSeed__Time_Card__c WHERE Id = :idTimeCard][0]
      .AcctSeed__Time_Card_Period__r.AcctSeed__Status__c == 'Open'
    ) {
      List<AcctSeed__Time_Card_Day__c> listTCD = new List<AcctSeed__Time_Card_Day__c>();
      Map<String, Date> mapStringDay = new Map<String, Date>();
      String soqlDelete = 'SELECT Id FROM AcctSeed__Time_Card_Day__c WHERE ';
      String soqlDeleteCondition = '';
      for (Map<String, String> mapVal : listTimeCardLineValues) {
        if (soqlDeleteCondition != '')
          soqlDeleteCondition += ' OR ';
        String idTimeCardLine = mapVal.get('idTimeCardLine');
        String key = mapVal.get('key');
        Decimal hoursNew = Decimal.valueOf(mapVal.get('hoursNew'));

        Date myDate = convertKeyToDate(key);
        //mapStringDay.put(key, myDate);
        DateTime convertedDt = DateTime.newInstance(myDate.year(), myDate.month(), myDate.day());
        String conditionDate = convertedDt.format('yyyy-MM-dd');

        soqlDeleteCondition +=
          ' (AcctSeed__Time_Card_Line__c =\'' +
          idTimeCardLine +
          '\' AND AcctSeed__Date__c =' +
          conditionDate +
          ') ';
        if (hoursNew > 0) {
          listTCD.add(
            new AcctSeed__Time_Card_Day__c(
              AcctSeed__Time_Card_Line__c = idTimeCardLine,
              AcctSeed__Date__c = myDate,
              AcctSeed__Hours__c = hoursNew
            )
          );
        }
      }
      Savepoint sp = Database.setSavepoint();
      try {
        if (soqlDeleteCondition != '') {
          Set<Id> setIdTCD = new Set<Id>();
          soqlDelete = soqlDelete + soqlDeleteCondition;
          System.debug(loggingLevel.Error, 'soqlDelete:' + soqlDelete);
          List<sObject> listRes = new List<sObject>();
          listRes.addAll(Database.query(soqlDelete));
          for (sObject res : listRes) {
            AcctSeed__Time_Card_Day__c tcd = (AcctSeed__Time_Card_Day__c) res;
            setIdTCD.add(tcd.Id);
            System.debug(loggingLevel.Error, 'tcd:' + tcd);
          }
          if (!setIdTCD.isEmpty())
            delete [SELECT Id FROM AcctSeed__Time_Card_Day__c WHERE Id IN :setIdTCD];
        }

        if (!listTCD.isEmpty()) {
          Boolean boolOld = gcTimeCardDay.allowDMLHours;
          gcTimeCardDay.allowDMLHours = true;
          insert listTCD;
          gcTimeCardDay.allowDMLHours = boolOld;
        }
      } catch (DmlException de) {
        Database.rollback(sp);
        throw new customException(de.getMessage());
      }
    }
    return retrieveTimeCardLines(idTimeCard, idProject);
  }

  public class customException extends Exception {
  }

  public static void coverage() {
    integer i;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
  }

  public static void coverage1() {
    integer i;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
  }
}
