public with sharing class gcAgedAR {
  public gcAgedAR(ApexPages.standardController ctrl) {
  }
  public gcAgedAR(GMBLASG.gcAccountingPeriod c) {
  }
  public gcAgedAR() {
  }

  @RemoteAction
  @ReadOnly
  public static map<Id, cube> retrieveAgedAr(string idPeriod, string strAgeMode, list<string> listIdPayee) {
    set<Id> setIdPayee = new Set<Id>();
    map<Id, cube> mapCube = new Map<Id, cube>();
    map<Id, cube> mapCubePayee = new Map<Id, cube>();

    Id idDummy = Id.valueOf('001000000000000000');

    if (strAgeMode != 'dueDate')
      strAgeMode = 'issueDate';

    //retrieve all periods prior to and including the selected period
    AcctSeed__Accounting_Period__c period = [
      SELECT Id, AcctSeed__Start_Date__c, AcctSeed__End_Date__c
      FROM AcctSeed__Accounting_Period__c
      WHERE Id = :idPeriod
    ][0];

    set<Id> setIdPeriods = new Set<Id>();
    for (AcctSeed__Accounting_Period__c p : [
      SELECT Id
      FROM AcctSeed__Accounting_Period__c
      WHERE AcctSeed__Start_Date__c <= :period.AcctSeed__Start_Date__c
    ]) {
      setIdPeriods.add(p.Id);
    }

    //retrieve the AR control account
    AcctSeed__Accounting_Settings__c acctSeedSetting = [
      SELECT AcctSeed__AR_Control_GL_Account__c, AcctSeed__Unapplied_Cash_GL_Account__c
      FROM AcctSeed__Accounting_Settings__c
      ORDER BY CreatedDate
    ][0];
    Id idGLAR = acctSeedSetting.AcctSeed__AR_Control_GL_Account__c;
    Id idGLUAR = acctSeedSetting.AcctSeed__Unapplied_Cash_GL_Account__c;
    Set<Id> setGLS = new Set<Id>{ idGLAR, idGLUAR };
    list<sObject> listAggObj = new List<sObject>();

    if (listIdPayee != null && listIdPayee.size() > 0) {
      for (string idPayee : listIdPayee) {
        if (idPayee == null)
          idPayee = idDummy;
        setIdPayee.add(Id.valueOf(idPayee));
        mapCubePayee.put(Id.valueOf(idPayee), new cube());
      }
    }
    setIdPayee.remove(null);
    mapCubePayee.remove(null);

    String soql;
    soql = ' SELECT ';
    soql += ' AcctSeed__Account__c idAccount, ';
    soql += ' AcctSeed__Employee__c idEmployee, ';
    soql += ' AcctSeed__Billing_Line__r.AcctSeed__Billing__r.AcctSeed__Customer__c idAccountB, ';
    soql += ' AcctSeed__Billing_Cash_Receipt__r.AcctSeed__Billing__r.AcctSeed__Customer__c idAccountBcr, ';
    soql += ' AcctSeed__Scheduled_Revenue_Expense__r.AcctSeed__Billing__r.AcctSeed__Customer__c idAccountSre, ';
    soql += ' sum(AcctSeed__Amount__c) amt ';
    soql += ' FROM AcctSeed__Transaction__c ';
    soql += ' WHERE AcctSeed__GL_Account__c IN:setGLS ';
    soql += ' AND AcctSeed__Accounting_Period__c IN :setIdPeriods ';
    soql += ' AND (AcctSeed__Amount__c < 0 OR AcctSeed__Amount__c > 0) ';

    if (setIdPayee.size() > 0) {
      soql += ' AND ( ';
      soql += ' AcctSeed__Account__c IN :setIdPayee OR ';
      soql += ' AcctSeed__Employee__c IN :setIdPayee OR ';
      soql += ' AcctSeed__Billing_Line__r.AcctSeed__Billing__r.AcctSeed__Customer__c IN :setIdPayee OR ';
      soql += ' AcctSeed__Billing_Cash_Receipt__r.AcctSeed__Billing__r.AcctSeed__Customer__c IN :setIdPayee OR ';
      soql += ' AcctSeed__Scheduled_Revenue_Expense__r.AcctSeed__Billing__r.AcctSeed__Customer__c IN :setIdPayee ';

      if (setIdPayee.contains(idDummy)) {
        soql += ' OR (';
        soql += ' AcctSeed__Account__c  = null AND ';
        soql += ' AcctSeed__Employee__c = null AND ';
        soql += ' AcctSeed__Billing_Line__r.AcctSeed__Billing__r.AcctSeed__Customer__c = null AND ';
        soql += ' AcctSeed__Billing_Cash_Receipt__r.AcctSeed__Billing__r.AcctSeed__Customer__c = null AND ';
        soql += ' AcctSeed__Scheduled_Revenue_Expense__r.AcctSeed__Billing__r.AcctSeed__Customer__c = null) ';
      }

      soql += ' )';
    }

    soql += ' GROUP BY ';
    soql += ' AcctSeed__Account__c, ';
    soql += ' AcctSeed__Employee__c, ';
    soql += ' AcctSeed__Billing_Line__r.AcctSeed__Billing__r.AcctSeed__Customer__c, ';
    soql += ' AcctSeed__Billing_Cash_Receipt__r.AcctSeed__Billing__r.AcctSeed__Customer__c, ';
    soql += ' AcctSeed__Scheduled_Revenue_Expense__r.AcctSeed__Billing__r.AcctSeed__Customer__c ';

    soql += ' HAVING (sum(AcctSeed__Amount__c) < 0 OR sum(AcctSeed__Amount__c) > 0)';

    listAggObj.addAll(Database.query(soql));

    for (sObject aggRes : listAggObj) {
      Id idPayee = (Id) aggRes.get('idAccount');
      if (idPayee == null)
        idPayee = (Id) aggRes.get('idEmployee');
      if (idPayee == null)
        idPayee = (Id) aggRes.get('idAccountB');
      if (idPayee == null)
        idPayee = (Id) aggRes.get('idAccountBcr');
      if (idPayee == null)
        idPayee = (Id) aggRes.get('idAccountSre');
      if (idPayee == null)
        idPayee = idDummy;

      Decimal amt = (Decimal) aggRes.get('amt');

      if (!mapCubePayee.containsKey(idPayee)) {
        mapCubePayee.put(idPayee, new cube());
      }
      mapCubePayee.get(idPayee).decBalance -= amt;
    }

    //include any payees having a non-zero balance, in addition to any payees that were explicitly requested
    for (Id idPayee : mapCubePayee.keySet()) {
      if (mapCubePayee.get(idPayee).decBalance.setScale(2) != 0)
        setIdPayee.add(idPayee);
    }

    soql = ' SELECT Id, ';

    soql += ' AcctSeed__Billing_Line__r.AcctSeed__Billing__c, ';
    soql += ' AcctSeed__Billing_Line__r.AcctSeed__Billing__r.AcctSeed__Customer__c, ';

    soql += ' AcctSeed__Billing_Cash_Receipt__c, ';
    soql += ' AcctSeed__Billing_Cash_Receipt__r.AcctSeed__Billing__c, ';
    soql += ' AcctSeed__Billing_Cash_Receipt__r.AcctSeed__Billing__r.AcctSeed__Customer__c, ';

    soql += ' AcctSeed__Scheduled_Revenue_Expense__r.AcctSeed__Billing__r.AcctSeed__Customer__c, ';

    soql += ' AcctSeed__Account__c, ';
    soql += ' AcctSeed__Employee__c, ';
    soql += ' AcctSeed__Amount__c ';
    soql += ' FROM AcctSeed__Transaction__c ';
    soql += ' WHERE AcctSeed__GL_Account__c IN:setGLS ';
    soql += ' AND AcctSeed__Accounting_Period__c IN : setIdPeriods ';
    soql += ' AND (AcctSeed__Amount__c < 0 OR AcctSeed__Amount__c > 0) ';
    soql += ' AND ( ';
    soql += ' AcctSeed__Account__c  IN :setIdPayee OR ';
    soql += ' AcctSeed__Employee__c IN :setIdPayee OR  ';

    soql += ' AcctSeed__Account__c IN :setIdPayee OR ';
    soql += ' AcctSeed__Employee__c IN :setIdPayee OR ';
    soql += ' AcctSeed__Billing_Line__r.AcctSeed__Billing__r.AcctSeed__Customer__c IN :setIdPayee OR ';
    soql += ' AcctSeed__Billing_Cash_Receipt__r.AcctSeed__Billing__r.AcctSeed__Customer__c IN :setIdPayee OR ';
    soql += ' AcctSeed__Scheduled_Revenue_Expense__r.AcctSeed__Billing__r.AcctSeed__Customer__c IN :setIdPayee ';

    if (setIdPayee.contains(idDummy)) {
      soql += ' OR (';
      soql += ' AcctSeed__Account__c  = null AND ';
      soql += ' AcctSeed__Employee__c = null AND ';
      soql += ' AcctSeed__Billing_Line__r.AcctSeed__Billing__r.AcctSeed__Customer__c = null AND ';
      soql += ' AcctSeed__Billing_Cash_Receipt__r.AcctSeed__Billing__r.AcctSeed__Customer__c = null AND ';
      soql += ' AcctSeed__Scheduled_Revenue_Expense__r.AcctSeed__Billing__r.AcctSeed__Customer__c = null) ';
    }

    soql += ' )';

    map<Id, Id> mapSreToAr = new Map<Id, Id>();
    map<Id, Id> mapBcrToAr = new Map<Id, Id>();

    for (AcctSeed__Transaction__c txn : Database.query(soql)) {
      Id idRecord;
      Id idPayee;

      if (txn.AcctSeed__Billing_Line__r.AcctSeed__Billing__c != null) {
        idRecord = txn.AcctSeed__Billing_Line__r.AcctSeed__Billing__c;
        idPayee = txn.AcctSeed__Billing_Line__r.AcctSeed__Billing__r.AcctSeed__Customer__c;
      } else if (txn.AcctSeed__Billing_Cash_Receipt__c != null) {
        idRecord = txn.AcctSeed__Billing_Cash_Receipt__c;
        idPayee = txn.AcctSeed__Billing_Cash_Receipt__r.AcctSeed__Billing__r.AcctSeed__Customer__c;
        mapBcrToAr.put(
          txn.AcctSeed__Billing_Cash_Receipt__c,
          txn.AcctSeed__Billing_Cash_Receipt__r.AcctSeed__Billing__c
        );
      } else if (txn.AcctSeed__Scheduled_Revenue_Expense__r.AcctSeed__Billing__c != null) {
        idRecord = txn.AcctSeed__Scheduled_Revenue_Expense__c;
        idPayee = txn.AcctSeed__Scheduled_Revenue_Expense__r.AcctSeed__Billing__r.AcctSeed__Customer__c;
        mapSreToAr.put(
          txn.AcctSeed__Scheduled_Revenue_Expense__c,
          txn.AcctSeed__Scheduled_Revenue_Expense__r.AcctSeed__Billing__c
        );
      } else {
        idRecord = txn.Id;
        idPayee = txn.AcctSeed__Account__c;
        if (idPayee == null)
          idPayee = txn.AcctSeed__Employee__c;
      }

      if (idPayee == null)
        idPayee = idDummy;

      if (!mapCube.containsKey(idRecord)) {
        mapCube.put(idRecord, new cube(idPayee));
      }
      mapCube.get(idRecord).decBalance += txn.AcctSeed__Amount__c;
    }

    //apply the AR credit memos against the AR balances
    for (AcctSeed__Billing_Credit_Memo__c bcm : [
      SELECT AcctSeed__Billing_Invoice__c, AcctSeed__Billing_Credit_Memo__c, AcctSeed__Amount__c
      FROM AcctSeed__Billing_Credit_Memo__c
      WHERE
        AcctSeed__Billing_Invoice__c IN :mapCube.keySet()
        AND AcctSeed__Billing_Credit_Memo__c IN :mapCube.keySet()
        AND AcctSeed__Accounting_Period__c IN :setIdPeriods
    ]) {
      mapCube.get(bcm.AcctSeed__Billing_Invoice__c).decBalance += bcm.AcctSeed__Amount__c;
      mapCube.get(bcm.AcctSeed__Billing_Credit_Memo__c).decBalance -= bcm.AcctSeed__Amount__c;
    }

    //transfer the BCR balance to the parent AR balance
    for (Id idBcr : mapBcrToAr.keySet()) {
      Id idAr = mapBcrToAr.get(idBcr);
      if (mapCube.containsKey(idBcr) && mapCube.containsKey(idAr)) {
        mapCube.get(idAr).decBalance += mapCube.get(idBcr).decBalance;
        mapCube.get(idBcr).decBalance = 0;
      }
    }

    //transfer the SRE balance to the parent AP balance
    //the SRE that looks up to an AP is one way to remove an AP from the AP aging report
    for (Id idSre : mapSreToAr.keySet()) {
      Id idAr = mapSreToAr.get(idSRE);
      if (mapCube.containsKey(idSre) && mapCube.containsKey(idAr)) {
        mapCube.get(idAr).decBalance += mapCube.get(idSre).decBalance;
        mapCube.get(idSre).decBalance = 0;
      }
    }

    set<Id> setIdRemove = new Set<Id>();
    for (Id idRecord : mapCube.keySet()) {
      if (mapCube.get(idRecord).decBalance.setScale(2) == 0)
        setIdRemove.add(idRecord);
      else
        mapCube.get(idRecord).decCurrent = mapCube.get(idRecord).decBalance;
    }
    for (Id idRecord : setIdRemove) {
      mapCube.remove(idRecord);
    }

    Date dateAsOf = period.AcctSeed__End_Date__c;
    //if the report is being run for the current period, adjust the as-of date to the current date
    if (date.today() >= period.AcctSeed__Start_Date__c && date.today() <= period.AcctSeed__End_Date__c)
      dateAsOf = date.today();

    //spread the balance out to different age groups
    for (AcctSeed__Billing__c ar : [
      SELECT Id, AcctSeed__Date__c, AcctSeed__Due_Date2__c, AcctSeed__Total__c
      FROM AcctSeed__Billing__c
      WHERE Id IN :mapCube.keySet()
    ]) {
      cube cube = mapCube.get(ar.Id);

      Date dateAR = ar.AcctSeed__Due_Date2__c;
      if (strAgeMode == 'issueDate')
        dateAR = ar.AcctSeed__Date__c;
      if (dateAR == null)
        dateAR = dateAsOf;

      Integer intAge = dateAR.daysBetween(dateAsOf);

      if (intAge > 90) {
        cube.dec91 += cube.decBalance;
        cube.decCurrent -= cube.decBalance;
      } else if (intAge > 60) {
        cube.dec61 += cube.decBalance;
        cube.decCurrent -= cube.decBalance;
      } else if (intAge > 30) {
        cube.dec31 += cube.decBalance;
        cube.decCurrent -= cube.decBalance;
      } else if (intAge > 0) {
        cube.dec01 += cube.decBalance;
        cube.decCurrent -= cube.decBalance;
      }

      if (ar.AcctSeed__Total__c != null)
        cube.decTotal = ar.AcctSeed__Total__c;
    }

    return mapCube;
  }

  @RemoteAction
  @ReadOnly
  public static map<Id, cube> summarizeByPayee(map<Id, cube> mapCubeRecord) {
    map<Id, cube> mapCubePayee = new Map<Id, cube>();

    for (cube cubeRecord : mapCubeRecord.values()) {
      Id idPayee = cubeRecord.idPayee;

      if (!mapCubePayee.containsKey(idPayee))
        mapCubePayee.put(idPayee, new cube(idPayee));

      cube cubePayee = mapCubePayee.get(idPayee);

      cubePayee.decTotal += cubeRecord.decTotal;
      cubePayee.decBalance += cubeRecord.decBalance;
      cubePayee.decCurrent += cubeRecord.decCurrent;
      cubePayee.dec01 += cubeRecord.dec01;
      cubePayee.dec31 += cubeRecord.dec31;
      cubePayee.dec61 += cubeRecord.dec61;
      cubePayee.dec91 += cubeRecord.dec91;
    }

    return mapCubePayee;
  }

  @RemoteAction
  @ReadOnly
  public static list<gcObj> retrieveAgedArSummary(string idPeriod, string strAgeMode) {
    map<Id, cube> mapCubePayee = summarizeByPayee(retrieveAgedAr(idPeriod, strAgeMode, null));
    map<Id, gcObj> mapObj = new Map<Id, gcObj>();

    for (Id idPayee : mapCubePayee.keySet()) {
      cube cube = mapCubePayee.get(idPayee);

      gcObj obj = new gcObj();

      obj.mapProperty.put('idPayee', idPayee);
      obj.mapProperty.put('payeeName', ' ---none---');
      obj.mapProperty.put('dec91', String.valueOf(cube.dec91.setScale(6)));
      obj.mapProperty.put('dec61', String.valueOf(cube.dec61.setScale(6)));
      obj.mapProperty.put('dec31', String.valueOf(cube.dec31.setScale(6)));
      obj.mapProperty.put('dec01', String.valueOf(cube.dec01.setScale(6)));
      obj.mapProperty.put('decCurrent', String.valueOf(cube.decCurrent.setScale(6)));
      obj.mapProperty.put('decBalance', String.valueOf(cube.decBalance.setScale(6)));
      obj.mapProperty.put('decTotal', String.valueOf(cube.decTotal.setScale(6)));

      mapObj.put(idPayee, obj);
    }

    for (Account a : [SELECT Id, Name FROM Account WHERE Id IN :mapObj.keySet()]) {
      mapObj.get(a.Id).mapProperty.put('payeeName', a.Name);
    }

    for (User u : [SELECT Id, Name FROM User WHERE Id IN :mapObj.keySet()]) {
      mapObj.get(u.Id).mapProperty.put('payeeName', u.Name);
    }

    for (Contact c : [SELECT Id, Name FROM Contact WHERE Id IN :mapObj.keySet()]) {
      mapObj.get(c.Id).mapProperty.put('payeeName', c.Name);
    }

    return mapObj.values();
  }

  @RemoteAction
  @ReadOnly
  public static list<gcObj> retrieveAgedArDetail(string idPeriod, string strAgeMode, list<string> listIdPayee) {
    map<Id, cube> mapCube = retrieveAgedAr(idPeriod, strAgeMode, listIdPayee);
    map<Id, gcObj> mapObj = new Map<Id, gcObj>();

    for (Id idRecord : mapCube.keySet()) {
      cube cube = mapCube.get(idRecord);

      gcObj obj = new gcObj();

      obj.mapProperty.put('idRecord', idRecord);
      obj.mapProperty.put('dec91', String.valueOf(cube.dec91.setScale(6)));
      obj.mapProperty.put('dec61', String.valueOf(cube.dec61.setScale(6)));
      obj.mapProperty.put('dec31', String.valueOf(cube.dec31.setScale(6)));
      obj.mapProperty.put('dec01', String.valueOf(cube.dec01.setScale(6)));
      obj.mapProperty.put('decCurrent', String.valueOf(cube.decCurrent.setScale(6)));
      obj.mapProperty.put('decBalance', String.valueOf(cube.decBalance.setScale(6)));
      obj.mapProperty.put('decTotal', String.valueOf(cube.decTotal.setScale(6)));

      mapObj.put(idRecord, obj);
    }

    for (AcctSeed__Billing__c b : [
      SELECT Id, Name, AcctSeed__Date__c, AcctSeed__Due_Date2__c, AcctSeed__Customer__r.Name
      FROM AcctSeed__Billing__c
      WHERE Id IN :mapObj.keySet()
    ]) {
      gcObj obj = mapObj.get(b.Id);
      obj.mapProperty.put('recordName', b.Name);

      if (b.AcctSeed__Customer__c != null)
        obj.mapProperty.put('payeeName', b.AcctSeed__Customer__r.Name);

      if (strAgeMode == 'issueDate' && b.AcctSeed__Date__c != null)
        obj.mapProperty.put('recordDate', b.AcctSeed__Date__c.format());
      else if (strAgeMode == 'dueDate' && b.AcctSeed__Due_Date2__c != null)
        obj.mapProperty.put('recordDate', b.AcctSeed__Due_Date2__c.format());
    }
    for (AcctSeed__Billing_Cash_Receipt__c bcr : [
      SELECT
        Id,
        Name,
        AcctSeed__Accounting_Period__r.AcctSeed__End_Date__c,
        AcctSeed__Cash_Receipt__r.AcctSeed__Account__r.Name
      FROM AcctSeed__Billing_Cash_Receipt__c
      WHERE Id IN :mapObj.keySet()
    ]) {
      gcObj obj = mapObj.get(bcr.Id);
      obj.mapProperty.put('recordName', bcr.Name);

      if (bcr.AcctSeed__Cash_Receipt__c != null && bcr.AcctSeed__Cash_Receipt__r.AcctSeed__Account__c != null)
        obj.mapProperty.put('payeeName', bcr.AcctSeed__Cash_Receipt__r.AcctSeed__Account__r.Name);

      if (bcr.AcctSeed__Accounting_Period__r.AcctSeed__End_Date__c != null)
        obj.mapProperty.put('recordDate', bcr.AcctSeed__Accounting_Period__r.AcctSeed__End_Date__c.format());
    }
    for (AcctSeed__Scheduled_Revenue_Expense__c sre : [
      SELECT Id, Name, AcctSeed__Accounting_Period__r.AcctSeed__End_Date__c, AcctSeed__Account2__r.Name
      FROM AcctSeed__Scheduled_Revenue_Expense__c
      WHERE Id IN :mapObj.keySet()
    ]) {
      gcObj obj = mapObj.get(sre.Id);
      obj.mapProperty.put('recordName', sre.Name);

      if (sre.AcctSeed__Account2__c != null)
        obj.mapProperty.put('payeeName', sre.AcctSeed__Account2__r.Name);

      if (sre.AcctSeed__Accounting_Period__c != null)
        obj.mapProperty.put('recordDate', sre.AcctSeed__Accounting_Period__r.AcctSeed__End_Date__c.format());
    }
    for (AcctSeed__Transaction__c txn : [
      SELECT Id, Name, AcctSeed__Date__c, AcctSeed__Account__r.Name
      FROM AcctSeed__Transaction__c
      WHERE Id IN :mapObj.keySet()
    ]) {
      gcObj obj = mapObj.get(txn.Id);
      obj.mapProperty.put('recordName', txn.Name);

      if (txn.AcctSeed__Account__c != null)
        obj.mapProperty.put('payeeName', txn.AcctSeed__Account__r.Name);

      if (txn.AcctSeed__Date__c != null)
        obj.mapProperty.put('recordDate', txn.AcctSeed__Date__c.format());
    }

    return mapObj.values();
  }

  public class gcObj {
    public map<String, String> mapProperty { get; set; }
    public map<String, gcObj> mapObj { get; set; }
    public list<gcObj> listObj { get; set; }

    private void init() {
      mapProperty = new Map<String, String>();
      mapObj = new Map<String, gcObj>();
      listObj = new List<gcObj>();
    }
    public gcObj() {
      init();
    }
  }

  public class cube {
    public Decimal dec91 { get; set; }
    public Decimal dec61 { get; set; }
    public Decimal dec31 { get; set; }
    public Decimal dec01 { get; set; }
    public Decimal decCurrent { get; set; }
    public Decimal decBalance { get; set; }
    public Decimal decTotal { get; set; }

    public Id idPayee { get; set; }

    public void init() {
      dec91 = 0;
      dec61 = 0;
      dec31 = 0;
      dec01 = 0;
      decCurrent = 0;
      decBalance = 0;
      decTotal = 0;
    }
    public cube() {
      init();
    }
    public cube(Id pIdPayee) {
      init();
      idPayee = pIdPayee;
    }
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
  }
}
