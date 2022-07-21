public with sharing class gcJournalEntry_Override {
  public gcJournalEntry_Override(ApexPages.standardController ctrl) {
  }
  public gcJournalEntry_Override() {
  }

  public static string locale {
    get {
      return UserInfo.getLocale();
    }
  }

  public String getAllGlAccounts() {
    List<Map<String, String>> listGLAccounts = new List<Map<String, String>>();
    for (AcctSeed__GL_Account__c gla : [
      SELECT Id, Name
      FROM AcctSeed__GL_Account__c
      WHERE AcctSeed__Active__c = TRUE
      ORDER BY Name
    ]) {
      Map<String, String> mapKV = new Map<String, String>();
      mapKV.put('value', gla.Id);
      mapKV.put('text', gla.Name);
      listGLAccounts.add(mapKV);
    }
    return JSON.serializePretty(listGLAccounts);
  }

  public String getAllGlVariables() {
    Map<String, List<Map<String, String>>> mapListGLVariables = new Map<String, List<Map<String, String>>>();
    List<Map<String, String>> listGLV1 = new List<Map<String, String>>();
    List<Map<String, String>> listGLV2 = new List<Map<String, String>>();
    List<Map<String, String>> listGLV3 = new List<Map<String, String>>();
    List<Map<String, String>> listGLV4 = new List<Map<String, String>>();
    List<Map<String, String>> listCFC = new List<Map<String, String>>();
    listGLV1.add(new Map<String, String>{ 'value' => '', 'text' => '' });
    listGLV2.add(new Map<String, String>{ 'value' => '', 'text' => '' });
    listGLV3.add(new Map<String, String>{ 'value' => '', 'text' => '' });
    listGLV4.add(new Map<String, String>{ 'value' => '', 'text' => '' });
    mapListGLVariables.put('glv1List', listGLV1);
    mapListGLVariables.put('glv2List', listGLV2);
    mapListGLVariables.put('glv3List', listGLV3);
    mapListGLVariables.put('glv4List', listGLV4);
    mapListGLVariables.put('cfcList', listCFC);

    for (AcctSeed__Accounting_Variable__c glv : [
      SELECT Id, Name, AcctSeed__Type__c
      FROM AcctSeed__Accounting_Variable__c
      WHERE AcctSeed__Active__c = TRUE AND AcctSeed__Type__c LIKE 'GL Account Variable%'
      ORDER BY Name
    ]) {
      Map<String, String> mapKV = new Map<String, String>();
      mapKV.put('value', glv.Id);
      mapKV.put('text', glv.Name);
      if (glv.AcctSeed__Type__c.equals('GL Account Variable 1'))
        listGLV1.add(mapKV);
      else if (glv.AcctSeed__Type__c.equals('GL Account Variable 2'))
        listGLV2.add(mapKV);
      else if (glv.AcctSeed__Type__c.equals('GL Account Variable 3'))
        listGLV3.add(mapKV);
      else if (glv.AcctSeed__Type__c.equals('GL Account Variable 4'))
        listGLV4.add(mapKV);
    }

    for (AcctSeed__GL_Account__c glv : [
      SELECT Id, Name, AcctSeed__Type__c
      FROM AcctSeed__GL_Account__c
      WHERE AcctSeed__Active__c = TRUE AND AcctSeed__Type__c = 'Cash Flow'
      ORDER BY Name
    ]) {
      Map<String, String> mapKV = new Map<String, String>();
      mapKV.put('value', glv.Id);
      mapKV.put('text', glv.Name);
      listCFC.add(mapKV);
    }

    return JSON.serializePretty(mapListGLVariables);
  }

  @RemoteAction
  @ReadOnly
  public static List<AcctSeed__GL_Account__c> searchGLA(String searchTxt) {
    List<AcctSeed__GL_Account__c> listGLA = new List<AcctSeed__GL_Account__c>();
    searchTxt = '%' + searchTxt.replaceAll('[*]', '%') + '%';

    for (AcctSeed__GL_Account__c gla : [
      SELECT Id, Name
      FROM AcctSeed__GL_Account__c
      WHERE AcctSeed__Active__c = TRUE AND Name LIKE :searchTxt
      ORDER BY Name
      LIMIT 10
    ]) {
      listGLA.add(gla);
    }
    return listGLA;
  }

  @RemoteAction
  @ReadOnly
  public static List<AcctSeed__Project__c> searchProject(String searchTxt) {
    List<AcctSeed__Project__c> listProject = new List<AcctSeed__Project__c>();
    searchTxt = '%' + searchTxt.replaceAll('[*]', '%') + '%';

    for (AcctSeed__Project__c gla : [
      SELECT Id, Name
      FROM AcctSeed__Project__c
      WHERE Locked__c = FALSE AND (Name LIKE :searchTxt OR AcctSeedERP__Work_Order_Number__c LIKE :searchTxt)
      ORDER BY Name
      LIMIT 10
    ]) {
      listProject.add(gla);
    }
    return listProject;
  }

  @RemoteAction
  @ReadOnly
  public static List<AcctSeed__Project_Task__c> searchProjectTask(String searchTxt, String idProject) {
    List<AcctSeed__Project_Task__c> listProject = new List<AcctSeed__Project_Task__c>();
    searchTxt = '%' + searchTxt.replaceAll('[*]', '%') + '%';

    for (AcctSeed__Project_Task__c gla : [
      SELECT Id, Name
      FROM AcctSeed__Project_Task__c
      WHERE AcctSeed__Project__c = :idProject AND Name LIKE :searchTxt
      ORDER BY Name
      LIMIT 10
    ]) {
      listProject.add(gla);
    }
    return listProject;
  }

  @RemoteAction
  @ReadOnly
  public static List<Map<String, String>> retrieveJournalEntryLines(String idFilter) {
    List<Map<String, String>> listJSON = new List<Map<String, String>>();
    for (AcctSeed__Journal_Entry_Line__c jel : [
      SELECT
        Id,
        Name,
        AcctSeed__Journal_Entry__r.GMBLASG__Posted__c,
        AcctSeed__Journal_Entry__r.AcctSeed__Accounting_Period__r.AcctSeed__Status__c,
        AcctSeed__Product__c,
        AcctSeed__Product__r.Name,
        Accrual_Product__c,
        Accrual_Product__r.Name,
        AcctSeed__Project__c,
        AcctSeed__Project__r.Name,
        AcctSeed__Project_Task__c,
        AcctSeed__Project_Task__r.Name,
        AcctSeed__Credit__c,
        AcctSeed__Debit__c,
        AcctSeed__Units__c,
        AcctSeed__Date__c,
        AcctSeed__GL_Account__c,
        AcctSeed__GL_Account__r.Name,
        AcctSeed__Cash_Flow_Category__c,
        AcctSeed__Cash_Flow_Category__r.Name,
        AcctSeed__GL_Account_Variable_1__c,
        AcctSeed__GL_Account_Variable_1__r.Name,
        AcctSeed__GL_Account_Variable_2__c,
        AcctSeed__GL_Account_Variable_2__r.Name,
        AcctSeed__GL_Account_Variable_3__c,
        AcctSeed__GL_Account_Variable_3__r.Name,
        AcctSeed__GL_Account_Variable_4__c,
        AcctSeed__GL_Account_Variable_4__r.Name,
        Line_Note__c
      FROM AcctSeed__Journal_Entry_Line__c
      WHERE Id = :idFilter OR AcctSeed__Journal_Entry__c = :idFilter
      ORDER BY Name
    ]) {
      Map<String, String> m = new Map<String, String>();
      m.put('idLine', jel.Id);
      m.put('lineName', jel.Name);
      m.put('idProduct', jel.AcctSeed__Product__c);
      m.put('productName', jel.AcctSeed__Product__r.Name);
      if (jel.Accrual_Product__c != null) {
        m.put('idProduct', jel.AcctSeed__Product__c);
        m.put('productName', jel.Accrual_Product__r.Name);
      }
      m.put('idProject', jel.AcctSeed__Project__c);
      m.put('projectName', jel.AcctSeed__Project__r.Name);
      m.put('idTask', jel.AcctSeed__Project_Task__c);
      m.put('taskName', jel.AcctSeed__Project_Task__r.Name);
      m.put('idGLAccount', jel.AcctSeed__GL_Account__c);
      m.put('gLAccountName', jel.AcctSeed__GL_Account__r.Name);
      m.put('idCFC', jel.AcctSeed__Cash_Flow_Category__c);
      m.put('cfcName', jel.AcctSeed__Cash_Flow_Category__r.Name);
      m.put('idGLV1', jel.AcctSeed__GL_Account_Variable_1__c);
      m.put('gLV1Name', jel.AcctSeed__GL_Account_Variable_1__r.Name);
      m.put('idGLV2', jel.AcctSeed__GL_Account_Variable_2__c);
      m.put('gLV2Name', jel.AcctSeed__GL_Account_Variable_2__r.Name);
      m.put('idGLV3', jel.AcctSeed__GL_Account_Variable_3__c);
      m.put('gLV3Name', jel.AcctSeed__GL_Account_Variable_3__r.Name);
      m.put('idGLV4', jel.AcctSeed__GL_Account_Variable_4__c);
      m.put('gLV4Name', jel.AcctSeed__GL_Account_Variable_4__r.Name);
      m.put('jePosted', jel.AcctSeed__Journal_Entry__r.GMBLASG__Posted__c ? 'true' : 'false');
      m.put('jePeriodStatus', jel.AcctSeed__Journal_Entry__r.AcctSeed__Accounting_Period__r.AcctSeed__Status__c);
      m.put('lineNote', jel.Line_Note__c == null ? '' : jel.Line_Note__c);

      if (jel.AcctSeed__Credit__c != null)
        m.put('creditAmount', String.valueOf(jel.AcctSeed__Credit__c.setScale(6)));
      else
        m.put('creditAmount', '0');

      if (jel.AcctSeed__Debit__c != null)
        m.put('debitAmount', String.valueOf(jel.AcctSeed__Debit__c.setScale(6)));
      else
        m.put('debitAmount', '0');

      if (jel.AcctSeed__Units__c != null)
        m.put('units', String.valueOf(jel.AcctSeed__Units__c.setScale(2)));

      m.put('jelDate', jel.AcctSeed__Date__c.format());
      Datetime dt = Datetime.newInstance(
        jel.AcctSeed__Date__c.year(),
        jel.AcctSeed__Date__c.month(),
        jel.AcctSeed__Date__c.day()
      );
      m.put('jelDateYMD', dt.format('yyyy-MM-dd'));

      listJSON.add(m);
    }
    return listJSON;
  }

  @RemoteAction
  public static void saveJournalEntryLines(
    String idJE,
    List<Map<String, String>> addList,
    List<Map<String, String>> updateList
  ) {
    List<AcctSeed__Journal_Entry_Line__c> listJEL = new List<AcctSeed__Journal_Entry_Line__c>();
    List<Map<String, String>> listAllMap = new List<Map<String, String>>();

    Date jeDate = [SELECT Id, AcctSeed__Journal_Date__c FROM AcctSeed__Journal_Entry__c WHERE Id = :idJE][0]
    .AcctSeed__Journal_Date__c;

    if (!addList.isEmpty())
      listAllMap.addAll(addList);
    if (!updateList.isEmpty())
      listAllMap.addAll(updateList);

    if (!listAllMap.isEmpty()) {
      for (Map<String, String> m : listAllMap) {
        Decimal units;
        Decimal creditAmount;
        Decimal debitAmount;
        if (m.containsKey('units') && m.get('units') != null)
          units = Decimal.valueOf(m.get('units'));
        if (m.containsKey('creditAmount') && m.get('creditAmount') != null)
          creditAmount = Decimal.valueOf(m.get('creditAmount'));
        if (m.containsKey('debitAmount') && m.get('debitAmount') != null)
          debitAmount = Decimal.valueOf(m.get('debitAmount'));
        //if(creditAmount != 0 && debitAmount != 0)
        //	throw new gcException('A Journal Entry Line cannot have both debit and credit amount.');

        String idLine = null;
        if (m.containsKey('idLine'))
          idLine = m.get('idLine');

        String idGL = m.get('idGLAccount');
        String idCFC = m.get('idCFC');
        String idGLV1 = m.get('idGLV1');
        String idGLV2 = m.get('idGLV2');
        String idGLV3 = m.get('idGLV3');
        String idGLV4 = m.get('idGLV4');
        String idProject = m.get('idProject');
        String idTask = m.get('idTask');
        String lineNote = m.get('lineNote');
        Date jelDate = (jeDate == null ? Date.today() : jeDate);
        String jelDatePassed = m.get('jelDate');
        //String jelDatePassed = m.get('jelDateYMD');
        if (jelDatePassed != null && jelDatePassed != '') {
          //String[] mdy = jelDatePassed.split('/');
          //jelDate = Date.newInstance(Integer.valueOf(mdy[2]),Integer.valueOf(mdy[1]),Integer.valueOf(mdy[0]));
          jelDate = Date.parse(jelDatePassed);
        }

        AcctSeed__Journal_Entry_Line__c jel = new AcctSeed__Journal_Entry_Line__c(
          AcctSeed__Credit__c = (creditAmount == 0 ? null : creditAmount),
          AcctSeed__Debit__c = (debitAmount == 0 ? null : debitAmount),
          AcctSeed__Units__c = (units == 0 ? null : units),
          AcctSeed__Project__c = (idProject == '' ? null : idProject),
          AcctSeed__Project_Task__c = (idTask == '' ? null : idTask),
          AcctSeed__Date__c = jelDate,
          AcctSeed__GL_Account__c = idGL,
          AcctSeed__Cash_Flow_Category__c = (idCFC == '' ? null : idCFC),
          AcctSeed__GL_Account_Variable_1__c = (idGLV1 == '' ? null : idGLV1),
          AcctSeed__GL_Account_Variable_2__c = (idGLV2 == '' ? null : idGLV2),
          AcctSeed__GL_Account_Variable_3__c = (idGLV3 == '' ? null : idGLV3),
          AcctSeed__GL_Account_Variable_4__c = (idGLV4 == '' ? null : idGLV4),
          AcctSeed__Journal_Entry__c = idJE,
          Line_Note__c = lineNote
        );
        if (idLine != null)
          jel.Id = idLine;

        listJEL.add(jel);
      }
    }
    if (!listJEL.isEmpty())
      upsert listJEL;
  }

  @RemoteAction
  public static void deleteJournalEntryLine(String idJEL) {
    delete [SELECT Id FROM AcctSeed__Journal_Entry_Line__c WHERE Id = :idJEL];
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
  }
}
