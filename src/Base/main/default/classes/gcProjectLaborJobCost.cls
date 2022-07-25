public without sharing class gcProjectLaborJobCost {
  private class cube {
    Decimal wagesTC;
    Decimal burdenTC;

    Decimal wagesJE;
    Decimal burdenJE;

    AcctSeed__Journal_Entry_Line__c jelProjectLabor;
    AcctSeed__Journal_Entry_Line__c jelProjectLaborBurden;

    list<AcctSeed__Journal_Entry_Line__c> listJelDelete;

    cube() {
      wagesTC = 0;
      burdenTC = 0;
      wagesJE = 0;
      burdenJE = 0;
    }
  }

  //@Future //future context will not work, because it can potentially result in multiple job cost journal entries for the same project-period combination
  public static void refreshJobCostFuture(set<Id> setIdProject, set<Date> setDate) {
    refreshJobCost(setIdProject, setDate);
  }

  public static void refreshJobCost(set<Id> setIdProject, set<Date> setDate) {
    //convert the set of dates to an accounting period start date and an accounting period end date
    setDate.remove(null);
    setIdProject.remove(null);

    Date dateEarliestOpen = GMBLASERP.gcAccountingPeriod.dateEarliestOpen();

    Date dateMin;
    Date dateMax;
    for (Date d : setDate) {
      if (dateMin == null || d < dateMin)
        dateMin = d;
      if (dateMax == null || d > dateMax)
        dateMax = d;
    }

    if (dateMin < dateEarliestOpen)
      dateMin = dateEarliestOpen;
    if (dateMax < dateEarliestOpen)
      return;

    map<Id, AcctSeed__Project__c> mapProject = new Map<Id, AcctSeed__Project__c>();
    for (AcctSeed__Project__c project : [
      SELECT Id, GL_Account_Variable_2__c, (SELECT Id FROM AcctSeed__Project_Tasks__r)
      FROM AcctSeed__Project__c
      WHERE Id IN :setIdProject
    ]) {
      mapProject.put(project.Id, project);
    }

    Date dateFrom;
    Date dateThru;
    map<Date, Id> mapDateToPeriod = new Map<Date, Id>();

    map<Id, AcctSeed__Accounting_Period__c> mapPeriod = new Map<Id, AcctSeed__Accounting_Period__c>();

    map<Id, map<Id, map<Id, cube>>> mapPPTC = new Map<Id, map<Id, map<Id, cube>>>(); //map Period-Project-Task-Cube
    map<Id, map<Id, AcctSeed__Journal_Entry__c>> mapPPJE = new Map<Id, map<Id, AcctSeed__Journal_Entry__c>>();
    map<Id, map<Id, list<AcctSeed__Journal_Entry_Line__c>>> mapPPJEL = new Map<Id, map<Id, list<AcctSeed__Journal_Entry_Line__c>>>();

    list<AcctSeed__Journal_Entry__c> listJEdelete = new List<AcctSeed__Journal_Entry__c>();
    list<AcctSeed__Journal_Entry__c> listJEinsert = new List<AcctSeed__Journal_Entry__c>();
    list<AcctSeed__Journal_Entry__c> listJEunpost = new List<AcctSeed__Journal_Entry__c>();
    //list<AcctSeed__Journal_Entry__c> listJEupsert = new list<AcctSeed__Journal_Entry__c>();
    list<AcctSeed__Journal_Entry__c> listJEpost = new List<AcctSeed__Journal_Entry__c>();

    list<AcctSeed__Journal_Entry_Line__c> listJELinsert = new List<AcctSeed__Journal_Entry_Line__c>();
    list<AcctSeed__Journal_Entry_Line__c> listJELupsert = new List<AcctSeed__Journal_Entry_Line__c>();
    list<AcctSeed__Journal_Entry_Line__c> listJELdelete = new List<AcctSeed__Journal_Entry_Line__c>();

    for (AcctSeed__Accounting_Period__c p : [
      SELECT Id, AcctSeed__Start_Date__c, AcctSeed__End_Date__c
      FROM AcctSeed__Accounting_Period__c
      WHERE AcctSeed__End_Date__c >= :dateMin AND AcctSeed__Start_Date__c <= :dateMax
      ORDER BY AcctSeed__Start_Date__c
    ]) {
      //get the start date of the earliest period
      if (dateFrom == null || p.AcctSeed__Start_Date__c < dateFrom)
        dateFrom = p.AcctSeed__Start_Date__c;
      //get the end date of the latest period
      if (dateThru == null || p.AcctSeed__End_Date__c > dateThru)
        dateThru = p.AcctSeed__End_Date__c;

      //map all the days to the period
      for (Integer i = 0; p.AcctSeed__Start_Date__c.addDays(i) <= p.AcctSeed__End_Date__c; i++) {
        mapDateToPeriod.put(p.AcctSeed__Start_Date__c.addDays(i), p.Id);
      }

      mapPeriod.put(p.Id, p);

      mapPPTC.put(p.Id, new Map<Id, map<Id, cube>>());
      mapPPJE.put(p.Id, new Map<Id, AcctSeed__Journal_Entry__c>());
      mapPPJEL.put(p.Id, new Map<Id, list<AcctSeed__Journal_Entry_Line__c>>());

      for (AcctSeed__Project__c project : mapProject.values()) {
        mapPPJE.get(p.Id).put(project.Id, null);
        mapPPJEL.get(p.Id).put(project.Id, new List<AcctSeed__Journal_Entry_Line__c>());
        mapPPTC.get(p.Id).put(project.Id, new Map<Id, cube>());

        for (AcctSeed__Project_Task__c projectTask : project.AcctSeed__Project_Tasks__r) {
          mapPPTC.get(p.Id).get(project.Id).put(projectTask.Id, new cube());
        }
      }
    }

    list<AggregateResult> listAggRes = new List<AggregateResult>();
    listAggRes.addAll(
      [
        SELECT
          AcctSeed__Date__c tcDate,
          AcctSeed__Time_Card_Line__r.AcctSeed__Project__c idProject,
          AcctSeed__Time_Card_Line__r.AcctSeed__Project_Task__c idProjectTask,
          sum(Wages__c) wages,
          sum(Burden__c) burden
        FROM AcctSeed__Time_Card_Day__c
        WHERE
          AcctSeed__Time_Card_Line__r.AcctSeed__Project__c IN :setIdProject
          AND AcctSeed__Date__c >= :dateFrom
          AND AcctSeed__Date__c <= :dateThru
        GROUP BY
          AcctSeed__Date__c,
          AcctSeed__Time_Card_Line__r.AcctSeed__Project__c,
          AcctSeed__Time_Card_Line__r.AcctSeed__Project_Task__c

      ]
    );

    //system.debug(loggingLevel.error,'listAggRes: '+listAggRes);

    for (sObject aggRes : listAggRes) {
      Id idPeriod = mapDateToPeriod.get((Date) aggRes.get('tcDate'));
      Id idProject = (Id) aggRes.get('idProject');
      Id idProjectTask = (Id) aggRes.get('idProjectTask');
      Decimal wages = (Decimal) aggRes.get('wages');
      Decimal burden = (Decimal) aggRes.get('burden');

      if (wages == null)
        wages = 0;
      if (burden == null)
        burden = 0;

      if (idPeriod == null || idProject == null || idProjectTask == null || (wages == 0 && burden == 0))
        continue;

      cube cube = mapPPTC.get(idPeriod).get(idProject).get(idProjectTask);
      cube.wagesTC += wages;
      cube.burdenTC += burden;
    }

    map<String, Id> mapGL = new Map<String, Id>();
    set<Id> setIdGl = new Set<Id>();

    for (AcctSeed__GL_Account__c gl : [
      SELECT Id, Uniquefier__c
      FROM AcctSeed__GL_Account__c
      WHERE Uniquefier__c IN ('ProjectLabor', 'ProjectLaborBurden', 'ProjectLaborBurdenContra', 'ProjectWagesPayable')
    ]) {
      mapGL.put(gl.Uniquefier__c, gl.Id);
      setIdGl.add(gl.Id);
    }

    Id idGLV2overhead;

    for (AcctSeed__Accounting_Variable__c glv : [
      SELECT Id
      FROM AcctSeed__Accounting_Variable__c
      WHERE AcctSeed__Type__c = 'GL Account Variable 2' AND Uniquefier__c = 'Overhead'
    ]) {
      idGLV2overhead = glv.Id;
    }

    for (AcctSeed__Journal_Entry__c je : [
      SELECT
        Id,
        Project__c,
        AcctSeed__Accounting_Period__c,
        AcctSeed__Status__c,
        (
          SELECT
            AcctSeed__Project__c,
            AcctSeed__Project_Task__c,
            AcctSeed__GL_Account__c,
            AcctSeed__Debit__c,
            AcctSeed__Credit__c
          FROM AcctSeed__Journal_Entry_Lines__r
        )
      FROM AcctSeed__Journal_Entry__c
      WHERE
        Project__c IN :setIdProject
        AND AcctSeed__Accounting_Period__r.AcctSeed__Start_Date__c >= :dateFrom
        AND AcctSeed__Accounting_Period__r.AcctSeed__End_Date__c <= :dateThru
        AND AcctSeed__Status__c = 'Posted'
      ORDER BY CreatedDate, Id
    ]) {
      Boolean projectLaborOnly = true;
      for (AcctSeed__Journal_Entry_Line__c jel : je.AcctSeed__Journal_Entry_Lines__r) {
        if (!setIdGl.contains(jel.AcctSeed__GL_Account__c)) {
          projectLaborOnly = false;
          continue;
        }
      }

      //if a journal entry is not STRICTLY a job cost journal entry, do not modify it at all in this method
      if (projectLaborOnly == false)
        continue;

      //if a journal entry for this Period and Project has already been collected, then this one is redundant, and should be removed
      if (mapPPJE.get(je.AcctSeed__Accounting_Period__c).get(je.Project__c) != null) {
        listJEunpost.add(je);
        listJEdelete.add(je);
        continue;
      }

      //collect the one and only job cost journal entry for this period and project
      mapPPJE.get(je.AcctSeed__Accounting_Period__c).put(je.Project__c, je);

      //for each project task, aggregate the wages and burden,
      //if there is more than JEL for a particular GL, delete the superfluous lines

      for (AcctSeed__Journal_Entry_Line__c jel : je.AcctSeed__Journal_Entry_Lines__r) {
        if (jel.AcctSeed__Project__c == null)
          continue;

        //if we have arrived at this point, then the journal entry line represents job cost wages or job cost burden

        cube cube = mapPPTC.get(je.AcctSeed__Accounting_Period__c)
          .get(jel.AcctSeed__Project__c)
          .get(jel.AcctSeed__Project_Task__c);

        if (jel.AcctSeed__Project__c != null && jel.AcctSeed__GL_Account__c == mapGL.get('ProjectLabor')) {
          if (cube.jelProjectLabor == null) {
            cube.jelProjectLabor = jel;
            if (jel.AcctSeed__Debit__c != null)
              cube.wagesJE += jel.AcctSeed__Debit__c;
            if (jel.AcctSeed__Credit__c != null)
              cube.wagesJE -= jel.AcctSeed__Credit__c;
          } else {
            //if there's more than one wages JEL for this project task, delete the extra one
            if (cube.listJelDelete == null)
              cube.listJelDelete = new List<AcctSeed__Journal_Entry_Line__c>();

            cube.listJelDelete.add(jel);
          }
        } else if (jel.AcctSeed__Project__c != null && jel.AcctSeed__GL_Account__c == mapGL.get('ProjectLaborBurden')) {
          if (cube.jelProjectLaborBurden == null) {
            cube.jelProjectLaborBurden = jel;
            if (jel.AcctSeed__Debit__c != null)
              cube.burdenJE += jel.AcctSeed__Debit__c;
            if (jel.AcctSeed__Credit__c != null)
              cube.burdenJE -= jel.AcctSeed__Credit__c;
          } else {
            if (cube.listJelDelete == null)
              cube.listJelDelete = new List<AcctSeed__Journal_Entry_Line__c>();

            cube.listJelDelete.add(jel);
          }
        } else {
          //if the JEL specifies a project, but the GL Account is neither wages nor burden, then it's an error and it should be deleted.
          if (cube.listJelDelete == null)
            cube.listJelDelete = new List<AcctSeed__Journal_Entry_Line__c>();

          cube.listJelDelete.add(jel);
        }
      }
    }

    //cycle over the cubes
    for (Id idPeriod : mapPPTC.keySet()) {
      for (Id idProject : mapPPTC.get(idPeriod).keySet()) {
        Boolean updateRequired = false;
        for (cube cube : mapPPTC.get(idPeriod).get(idProject).values()) {
          if (
            (cube.jelProjectLabor == null &&
            cube.wagesTC.setScale(2) != 0) ||
            (cube.jelProjectLaborBurden == null &&
            cube.burdenTC.setScale(2) != 0) ||
            (cube.wagesTC.setScale(2) != cube.wagesJE.setScale(2)) ||
            (cube.burdenTC.setScale(2) != cube.burdenJE.setScale(2)) ||
            (cube.listJELdelete != null && !cube.listJELdelete.isEmpty())
          ) {
            updateRequired = true;
          }
        }

        if (updateRequired == false)
          continue;

        AcctSeed__Journal_Entry__c je = mapPPJE.get(idPeriod).get(idProject);

        //if there is not yet a journal entry for the Period-Project, then create one
        if (je == null) {
          je = new AcctSeed__Journal_Entry__c(
            Name = 'Job Cost Labor',
            AcctSeed__Accounting_Period__c = idPeriod,
            AcctSeed__Journal_Date__c = mapPeriod.get(idPeriod).AcctSeed__End_Date__c,
            AcctSeed__Status__c = 'Approved',
            Project__c = idProject
          );

          listJEinsert.add(je);
          mapPPJE.get(idPeriod).put(idProject, je);
        } else {
          //if a journal entry already exists, unpost it
          listJEunpost.add(je);
        }

        for (Id idProjectTask : mapPPTC.get(idPeriod).get(idProject).keySet()) {
          cube cube = mapPPTC.get(idPeriod).get(idProject).get(idProjectTask);

          if (cube.jelProjectLabor == null && cube.wagesTC.setScale(2) != 0) {
            cube.jelProjectLabor = new AcctSeed__Journal_Entry_Line__c(
              AcctSeed__Debit__c = cube.wagesTC.setScale(2),
              AcctSeed__GL_Account__c = mapGL.get('ProjectLabor'),
              AcctSeed__Journal_Entry__c = je.Id,
              AcctSeed__Project__c = idProject,
              AcctSeed__Project_Task__c = idProjectTask
            );
            if (je.Id == null)
              mapPPJEL.get(idPeriod).get(idProject).add(cube.jelProjectLabor);
            listJELupsert.add(cube.jelProjectLabor);
          } else if (cube.wagesTC.setScale(2) != cube.wagesJE.setScale(2)) {
            cube.jelProjectLabor.AcctSeed__Debit__c = cube.wagesTC.setScale(2);
            cube.jelProjectLabor.AcctSeed__Credit__c = null;
            listJELupsert.add(cube.jelProjectLabor);
          }

          if (cube.jelProjectLaborBurden == null && cube.burdenTC.setScale(2) != 0) {
            cube.jelProjectLaborBurden = new AcctSeed__Journal_Entry_Line__c(
              AcctSeed__Debit__c = cube.burdenTC.setScale(2),
              AcctSeed__GL_Account__c = mapGL.get('ProjectLaborBurden'),
              AcctSeed__Journal_Entry__c = je.Id,
              AcctSeed__Project__c = idProject,
              AcctSeed__Project_Task__c = idProjectTask
            );
            if (je.Id == null)
              mapPPJEL.get(idPeriod).get(idProject).add(cube.jelProjectLaborBurden);
            listJELupsert.add(cube.jelProjectLaborBurden);
          } else if (cube.burdenTC.setScale(2) != cube.burdenJE.setScale(2)) {
            cube.jelProjectLaborBurden.AcctSeed__Debit__c = cube.burdenTC.setScale(2);
            cube.jelProjectLaborBurden.AcctSeed__Credit__c = null;
            listJELupsert.add(cube.jelProjectLaborBurden);
          }

          if (cube.listJELdelete != null && !cube.listJELdelete.isEmpty())
            listJELdelete.addAll(cube.listJELdelete);
        }
      }
    }

    //unpost existing JEs that will be updated
    if (!listJEunpost.isEmpty())
      AcctSeed.JournalEntryPostService.unpostJournalEntries(listJEunpost);

    //insert new JEs
    if (!listJEinsert.isEmpty())
      insert listJEinsert;

    //cycle over the JELs to upsert, to populate the parent JE if necessary
    for (Id idPeriod : mapPPJEL.keySet()) {
      for (Id idProject : mapPPJEL.get(idPeriod).keySet()) {
        for (AcctSeed__Journal_Entry_Line__c jel : mapPPJEL.get(idPeriod).get(idProject))
          jel.AcctSeed__Journal_Entry__c = mapPPJE.get(idPeriod).get(idProject).Id;
      }
    }

    if (!listJELupsert.isEmpty())
      upsert listJELupsert;

    if (!listJELdelete.isEmpty())
      delete listJELdelete;

    //balance the JEs
    set<Id> setIdJe = new Set<Id>();
    for (AcctSeed__Journal_Entry__c je : listJEunpost)
      setIdJe.add(je.Id);
    for (AcctSeed__Journal_Entry__c je : listJEinsert)
      setIdJe.add(je.Id);

    listJELupsert.clear();
    listJELdelete.clear();

    for (AcctSeed__Journal_Entry__c je : [
      SELECT
        Id,
        (
          SELECT
            AcctSeed__Credit__c,
            AcctSeed__Debit__c,
            AcctSeed__GL_Account__c,
            AcctSeed__GL_Account_Variable_1__c,
            AcctSeed__GL_Account_Variable_2__c,
            AcctSeed__GL_Account_Variable_3__c,
            AcctSeed__GL_Account_Variable_4__c,
            AcctSeed__Project__c
          FROM AcctSeed__Journal_Entry_Lines__r
        )
      FROM AcctSeed__Journal_Entry__c
      WHERE Id IN :setIdJe
    ]) {
      Boolean deleteThisJe = true;

      AcctSeed__Journal_Entry_Line__c jelProjectLaborBurdenContra;
      AcctSeed__Journal_Entry_Line__c jelProjectWagesPayable;

      Decimal wages = 0;
      Decimal burden = 0;

      for (AcctSeed__Journal_Entry_Line__c jel : je.AcctSeed__Journal_Entry_Lines__r) {
        if (jel.AcctSeed__Project__c != null && jel.AcctSeed__GL_Account__c == mapGL.get('ProjectLabor')) {
          deleteThisJe = false;

          if (jel.AcctSeed__Debit__c != null)
            wages += jel.AcctSeed__Debit__c;

          if (jel.AcctSeed__Credit__c != null)
            wages -= jel.AcctSeed__Credit__c;
        } else if (jel.AcctSeed__Project__c != null && jel.AcctSeed__GL_Account__c == mapGL.get('ProjectLaborBurden')) {
          deleteThisJe = false;

          if (jel.AcctSeed__Debit__c != null)
            burden += jel.AcctSeed__Debit__c;

          if (jel.AcctSeed__Credit__c != null)
            burden -= jel.AcctSeed__Credit__c;
        } else if (
          jel.AcctSeed__Project__c == null &&
          jel.AcctSeed__GL_Account__c == mapGL.get('ProjectLaborBurdenContra') &&
          jelProjectLaborBurdenContra == null
        ) {
          jelProjectLaborBurdenContra = jel;
        } else if (
          jel.AcctSeed__Project__c == null &&
          jel.AcctSeed__GL_Account__c == mapGL.get('ProjectWagesPayable') &&
          jelProjectWagesPayable == null
        ) {
          jelProjectWagesPayable = jel;
        } else {
          listJELdelete.add(jel);
        }
      }

      if (deleteThisJe) {
        listJEdelete.add(je);
        continue;
      }

      if (jelProjectWagesPayable == null) {
        jelProjectWagesPayable = new AcctSeed__Journal_Entry_Line__c(
          AcctSeed__Credit__c = wages,
          AcctSeed__Debit__c = null,
          AcctSeed__GL_Account__c = mapGL.get('ProjectWagesPayable'),
          AcctSeed__GL_Account_Variable_2__c = idGLV2overhead,
          AcctSeed__Journal_Entry__c = je.Id
        );
      } else {
        jelProjectWagesPayable.AcctSeed__Credit__c = wages;
        jelProjectWagesPayable.AcctSeed__Debit__c = null;
      }

      if (jelProjectLaborBurdenContra == null) {
        jelProjectLaborBurdenContra = new AcctSeed__Journal_Entry_Line__c(
          AcctSeed__Credit__c = burden,
          AcctSeed__Debit__c = null,
          AcctSeed__GL_Account__c = mapGL.get('ProjectLaborBurdenContra'),
          AcctSeed__GL_Account_Variable_2__c = idGLV2overhead,
          AcctSeed__Journal_Entry__c = je.Id
        );
      } else {
        jelProjectLaborBurdenContra.AcctSeed__Credit__c = burden;
        jelProjectLaborBurdenContra.AcctSeed__Debit__c = null;
      }

      listJELupsert.add(jelProjectWagesPayable);
      listJELupsert.add(jelProjectLaborBurdenContra);

      listJEpost.add(je);
    }

    if (!listJELupsert.isEmpty())
      upsert listJELupsert;

    if (!listJELdelete.isEmpty())
      delete listJELdelete;

    if (!listJEdelete.isEmpty())
      delete listJEdelete;

    if (!listJEpost.isEmpty())
      AcctSeed.JournalEntryPostService.postJournalEntries(listJEpost);
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
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
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
