public without sharing class gcAccountPayable_Override {
  public gcAccountPayable_Override(ApexPages.standardController ctrl) {
  }
  public gcAccountPayable_Override() {
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
    listGLV1.add(new Map<String, String>{ 'value' => '', 'text' => '' });
    listGLV2.add(new Map<String, String>{ 'value' => '', 'text' => '' });
    listGLV3.add(new Map<String, String>{ 'value' => '', 'text' => '' });
    listGLV4.add(new Map<String, String>{ 'value' => '', 'text' => '' });
    mapListGLVariables.put('glv1List', listGLV1);
    mapListGLVariables.put('glv2List', listGLV2);
    mapListGLVariables.put('glv3List', listGLV3);
    mapListGLVariables.put('glv4List', listGLV4);

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
  public static List<Product2> searchProduct(String searchTxt) {
    List<Product2> listProduct = new List<Product2>();
    String likeSearchTxt = '%' + searchTxt.replaceAll('[*]', '%') + '%';

    Set<Id> setIdFound = new Set<Id>();
    for (Product2 gla : [
      SELECT Id, Name
      FROM Product2
      WHERE Name = :searchTxt OR Family = :searchTxt OR ProductCode = :searchTxt
      ORDER BY Name
      LIMIT 5
    ]) {
      listProduct.add(gla);
      setIdFound.add(gla.Id);
    }

    for (Product2 gla : [
      SELECT Id, Name
      FROM Product2
      WHERE
        (Name LIKE :likeSearchTxt
        OR Family LIKE :likeSearchTxt
        OR ProductCode LIKE :likeSearchTxt)
        AND Id NOT IN :setIdFound
      ORDER BY Name
      LIMIT 20
    ]) {
      listProduct.add(gla);
    }
    return listProduct;
  }

  @RemoteAction
  @ReadOnly
  public static List<AcctSeed__Project__c> searchProject(String searchTxt) {
    List<AcctSeed__Project__c> listProject = new List<AcctSeed__Project__c>();
    searchTxt = '%' + searchTxt.replaceAll('[*]', '%') + '%';

    for (AcctSeed__Project__c gla : [
      SELECT Id, Name
      FROM AcctSeed__Project__c
      WHERE Name LIKE :searchTxt OR AcctSeedERP__Work_Order_Number__c LIKE :searchTxt
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
  public static List<Map<String, String>> retrieveAPLines(String idFilter) {
    List<Map<String, String>> listJSON = new List<Map<String, String>>();
    Id idProductSalesTaxFederal = gcConstants.idProductSalesTaxFederal;
    Id idProductSalesTaxProvincial = gcConstants.idProductSalesTaxProvincial;
    Id idProductSalesTaxRetail = gcConstants.idProductSalesTaxRetail;
    Id idProductSalesTaxHarmonized = gcConstants.idProductSalesTaxHarmonized;
    Id idProductPrecisionFix = gcConstants.idProductPrecisionFix;
    for (AcctSeed__Account_Payable_Line__c apl : [
      SELECT
        Id,
        Name,
        AcctSeed__Invoice_Comment__c,
        AcctSeed__Account_Payable__r.GMBLASG__Posted__c,
        AcctSeed__Account_Payable__r.AcctSeed__Accounting_Period__r.AcctSeed__Status__c,
        AcctSeed__Product__c,
        AcctSeed__Product__r.Name,
        AcctSeed__Project__c,
        AcctSeed__Project__r.Name,
        AcctSeed__Project_Task__c,
        AcctSeed__Project_Task__r.Name,
        AcctSeed__Amount__c,
        AcctSeed__Quantity__c,
        AcctSeed__Date__c,
        AcctSeed__Expense_GL_Account__c,
        AcctSeed__Expense_GL_Account__r.Name,
        AcctSeed__GL_Account_Variable_1__c,
        AcctSeed__GL_Account_Variable_1__r.Name,
        AcctSeed__GL_Account_Variable_2__c,
        AcctSeed__GL_Account_Variable_2__r.Name,
        AcctSeed__GL_Account_Variable_3__c,
        AcctSeed__GL_Account_Variable_3__r.Name,
        AcctSeed__GL_Account_Variable_4__c,
        AcctSeed__GL_Account_Variable_4__r.Name
      FROM AcctSeed__Account_Payable_Line__c
      WHERE Id = :idFilter OR AcctSeed__Account_Payable__c = :idFilter
      ORDER BY Name
    ]) {
      Map<String, String> m = new Map<String, String>();
      m.put('idLine', apl.Id);
      m.put('lineName', apl.Name);
      m.put('idProduct', apl.AcctSeed__Product__c);
      m.put('productName', apl.AcctSeed__Product__r.Name);
      m.put('idProject', apl.AcctSeed__Project__c);
      m.put('projectName', apl.AcctSeed__Project__r.Name);
      m.put('idTask', apl.AcctSeed__Project_Task__c);
      m.put('taskName', apl.AcctSeed__Project_Task__r.Name);
      m.put('idGLAccount', apl.AcctSeed__Expense_GL_Account__c);
      m.put('gLAccountName', apl.AcctSeed__Expense_GL_Account__r.Name);
      m.put('idGLV1', apl.AcctSeed__GL_Account_Variable_1__c);
      m.put('gLV1Name', apl.AcctSeed__GL_Account_Variable_1__r.Name);
      m.put('idGLV2', apl.AcctSeed__GL_Account_Variable_2__c);
      m.put('gLV2Name', apl.AcctSeed__GL_Account_Variable_2__r.Name);
      m.put('idGLV3', apl.AcctSeed__GL_Account_Variable_3__c);
      m.put('gLV3Name', apl.AcctSeed__GL_Account_Variable_3__r.Name);
      m.put('idGLV4', apl.AcctSeed__GL_Account_Variable_4__c);
      m.put('gLV4Name', apl.AcctSeed__GL_Account_Variable_4__r.Name);
      m.put('jePosted', apl.AcctSeed__Account_Payable__r.GMBLASG__Posted__c ? 'true' : 'false');
      m.put('jePeriodStatus', apl.AcctSeed__Account_Payable__r.AcctSeed__Accounting_Period__r.AcctSeed__Status__c);
      m.put('lineNote', apl.AcctSeed__Invoice_Comment__c == null ? '' : apl.AcctSeed__Invoice_Comment__c);
      m.put('taxLine', 'false');
      if (
        apl.AcctSeed__Product__c != null &&
        (apl.AcctSeed__Product__c == idProductSalesTaxRetail ||
        apl.AcctSeed__Product__c == idProductSalesTaxProvincial ||
        apl.AcctSeed__Product__c == idProductSalesTaxHarmonized ||
        apl.AcctSeed__Product__c == idProductSalesTaxFederal ||
        apl.AcctSeed__Product__c == idProductPrecisionFix)
      )
        m.put('taxLine', 'true');
      if (apl.AcctSeed__Amount__c != null)
        m.put('aplAmount', String.valueOf(apl.AcctSeed__Amount__c.setScale(6)));
      else
        m.put('aplAmount', '0');

      if (apl.AcctSeed__Quantity__c != null)
        m.put('qty', String.valueOf(apl.AcctSeed__Quantity__c.setScale(6)));

      m.put('aplDate', apl.AcctSeed__Date__c.format());
      Datetime dt = Datetime.newInstance(
        apl.AcctSeed__Date__c.year(),
        apl.AcctSeed__Date__c.month(),
        apl.AcctSeed__Date__c.day()
      );
      m.put('aplDateYMD', dt.format('yyyy-MM-dd'));

      listJSON.add(m);
    }
    return listJSON;
  }

  @RemoteAction
  public static void saveAPLines(String idAP, List<Map<String, String>> addList, List<Map<String, String>> updateList) {
    List<AcctSeed__Account_Payable_Line__c> listJEL = new List<AcctSeed__Account_Payable_Line__c>();
    List<Map<String, String>> listAllMap = new List<Map<String, String>>();

    Date apDate = [SELECT Id, AcctSeed__Date__c FROM AcctSeed__Account_Payable__c WHERE Id = :idAP][0]
    .AcctSeed__Date__c;

    if (!addList.isEmpty())
      listAllMap.addAll(addList);
    if (!updateList.isEmpty())
      listAllMap.addAll(updateList);

    if (!listAllMap.isEmpty()) {
      for (Map<String, String> m : listAllMap) {
        Decimal qty;
        Decimal aplAmount;
        if (m.containsKey('qty') && m.get('qty') != null)
          qty = Decimal.valueOf(m.get('qty'));
        if (m.containsKey('aplAmount') && m.get('aplAmount') != null)
          aplAmount = Decimal.valueOf(m.get('aplAmount'));
        //if(creditAmount != 0 && aplAmount != 0)
        //	throw new gcException('A Journal Entry Line cannot have both debit and credit amount.');

        String idLine = null;
        if (m.containsKey('idLine'))
          idLine = m.get('idLine');

        String idGL = m.get('idGLAccount');
        String idGLV1 = m.get('idGLV1');
        String idGLV2 = m.get('idGLV2');
        String idGLV3 = m.get('idGLV3');
        String idGLV4 = m.get('idGLV4');
        String idProject = m.get('idProject');
        String idProduct = m.get('idProduct');
        String idTask = m.get('idTask');
        String lineNote = m.get('lineNote');
        Date aplDate = (apDate == null ? Date.today() : apDate);
        String jelDatePassed = m.get('aplDate');
        //String jelDatePassed = m.get('aplDateYMD');
        if (jelDatePassed != null && jelDatePassed != '') {
          //String[] mdy = jelDatePassed.split('/');
          //aplDate = Date.newInstance(Integer.valueOf(mdy[2]),Integer.valueOf(mdy[1]),Integer.valueOf(mdy[0]));
          aplDate = Date.parse(jelDatePassed);
        }

        AcctSeed__Account_Payable_Line__c apl = new AcctSeed__Account_Payable_Line__c(
          AcctSeed__Amount__c = (aplAmount == 0 ? null : aplAmount),
          AcctSeed__Quantity__c = (qty == 0 ? null : qty),
          AcctSeed__Product__c = (idProduct == '' ? null : idProduct),
          AcctSeed__Project__c = (idProject == '' ? null : idProject),
          AcctSeed__Project_Task__c = (idTask == '' ? null : idTask),
          AcctSeed__Date__c = aplDate,
          Expense_Revenue_GL_Account__c = idGL,
          AcctSeed__Expense_GL_Account__c = idGL,
          AcctSeed__GL_Account_Variable_1__c = (idGLV1 == '' ? null : idGLV1),
          AcctSeed__GL_Account_Variable_2__c = (idGLV2 == '' ? null : idGLV2),
          AcctSeed__GL_Account_Variable_3__c = (idGLV3 == '' ? null : idGLV3),
          AcctSeed__GL_Account_Variable_4__c = (idGLV4 == '' ? null : idGLV4),
          AcctSeed__Account_Payable__c = idAP,
          AcctSeed__Invoice_Comment__c = lineNote
        );
        if (idLine != null)
          apl.Id = idLine;

        listJEL.add(apl);
      }
    }
    if (!listJEL.isEmpty())
      upsert listJEL;
  }

  @RemoteAction
  public static void deleteAPLine(String idJEL) {
    delete [SELECT Id FROM AcctSeed__Account_Payable_Line__c WHERE Id = :idJEL];
  }
}
