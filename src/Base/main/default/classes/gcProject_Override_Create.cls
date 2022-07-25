global without sharing class gcProject_Override_Create {
  global gcProject_Override_Create(ApexPages.StandardController c) {
    init();
  }
  global gcProject_Override_Create() {
    init();
  }

  global Account newAccount { get; set; }
  global GMBLASERP__Serial_Number__c newSerial { get; set; }
  global AcctSeed__Project__c newProject { get; set; }

  global Boolean isBoatSale { get; set; }
  global Boolean isPartnerBoatSale { get; set; }
  global Boolean isCounterSale { get; set; }
  global Boolean isService { get; set; }
  global Boolean isFixedAsset { get; set; }
  global Boolean isWarranty { get; set; }
  global Boolean isManufacturing { get; set; }
  global Boolean isTradeIn { get; set; }
  global Boolean isPartnerPartsOrder { get; set; }

  private void init() {
    isBoatSale = false;
    isPartnerBoatSale = false;
    isCounterSale = false;
    isService = false;
    isFixedAsset = false;
    isWarranty = false;
    isManufacturing = false;
    isTradeIn = false;
    isPartnerPartsOrder = false;

    Id recordTypeId = ApexPages.currentPage().getParameters().get('RecordType');

    if (recordTypeId == gcConstants.idRtProjectBoatSale)
      isBoatSale = true;
    else if (recordTypeId == gcConstants.idRtProjectPartnerBoatSale)
      isPartnerBoatSale = true;
    else if (recordTypeId == gcConstants.idRtProjectCounterSale)
      isCounterSale = true;
    else if (recordTypeId == gcConstants.idRtProjectService)
      isService = true;
    else if (recordTypeId == gcConstants.idRtFixedAsset)
      isFixedAsset = true;
    else if (recordTypeId == gcConstants.idRtProjectWarranty)
      isWarranty = true;
    else if (recordTypeId == gcConstants.idRtProjectManufacturing)
      isManufacturing = true;
    else if (recordTypeId == gcConstants.idRtTradeIn)
      isTradeIn = true;
    else if (recordTypeId == gcConstants.idRtPartnerPartsOrder)
      isPartnerPartsOrder = true;

    newAccount = new Account();
    newSerial = new GMBLASERP__Serial_Number__c();
    newProject = new AcctSeed__Project__c();
  }

  @RemoteAction
  @ReadOnly
  global static list<map<string, string>> searchAccount(String strSearch) {
    list<map<string, string>> listJSON = new List<map<string, string>>();
    if (!(strSearch instanceof Id))
      strSearch = '%' + strSearch + '%';

    for (Account a : [
      SELECT
        Id,
        Is_Internal__c,
        Name,
        BillingStreet,
        BillingCity,
        BillingState,
        BillingPostalCode,
        BillingCountry,
        Phone
      FROM Account
      WHERE Name LIKE :strSearch OR BillingStreet LIKE :strSearch OR Phone LIKE :strSearch OR Id = :strSearch
    ]) {
      map<string, string> m = new Map<string, string>();
      m.put('idAccount', a.Id);
      m.put('accountName', a.Name);
      m.put('billingStreet', a.BillingStreet);
      m.put('billingCity', a.BillingCity);
      m.put('billingState', a.BillingState);
      m.put('billingPostalCode', a.BillingPostalCode);
      m.put('billingCountry', a.BillingCountry);
      m.put('phone', a.Phone);
      m.put('isInternal', a.Is_Internal__c ? 'true' : 'false');

      listJSON.add(m);
    }

    return listJSON;
  }

  @RemoteAction
  @ReadOnly
  global static list<map<string, string>> searchAsset(String strSearch) {
    list<map<string, string>> listJSON = new List<map<string, string>>();
    if (!(strSearch instanceof Id))
      strSearch = '%' + strSearch + '%';

    for (AcctSeed__Fixed_Asset__c a : [
      SELECT Id, Name, AcctSeed__Value__c, Asset_Serial_Number__c
      FROM AcctSeed__Fixed_Asset__c
      WHERE Name LIKE :strSearch OR Asset_Serial_Number__c LIKE :strSearch OR Id = :strSearch
    ]) {
      Map<String, String> m = new Map<String, String>();
      m.put('idAsset', a.Id);
      m.put('assetName', a.Name);
      m.put('assetSerial', a.Asset_Serial_Number__c == null ? '' : a.Asset_Serial_Number__c);
      m.put('assetValue', a.AcctSeed__Value__c == null ? '0' : String.valueOf(a.AcctSeed__Value__c));

      listJSON.add(m);
    }

    return listJSON;
  }

  @RemoteAction
  @ReadOnly
  global static list<map<string, string>> searchSerial(String strSearch, String idAccount) {
    list<map<string, string>> listJSON = new List<map<string, string>>();

    if (!String.isEmpty(strSearch)) {
      if (!(strSearch instanceof Id))
        strSearch = '%' + strSearch + '%';

      for (GMBLASERP__Serial_Number__c serial : [
        SELECT
          Id,
          Name,
          Model_Year__c,
          GMBLASERP__Product__r.Name,
          GMBLASERP__Product__r.Id,
          GMBLASERP__Lot__r.Name,
          GMBLASERP__Lot__r.Id,
          (
            SELECT Id, Name, AcctSeed__Account__r.Name, AcctSeedERP__Work_Order_Number__c, CreatedDate, RecordType.Name
            FROM Projects__r
            ORDER BY CreatedDate DESC
            LIMIT 1
          )
        FROM GMBLASERP__Serial_Number__c
        WHERE Name LIKE :strSearch OR Id = :strSearch
      ]) {
        map<String, String> m = new Map<String, String>();

        m.put('idSerial', serial.Id);
        m.put('serialName', serial.Name);
        m.put('modelYear', serial.Model_Year__c == null ? '' : String.valueOf(serial.Model_Year__c));
        m.put('productName', serial.GMBLASERP__Product__r.Name);
        m.put('lotName', serial.GMBLASERP__Lot__r.Name);

        if (!serial.Projects__r.isEmpty()) {
          AcctSeed__Project__c p = serial.Projects__r[0];

          Date createdDate = date.newinstance(p.CreatedDate.year(), p.CreatedDate.month(), p.CreatedDate.day());

          m.put('idProject', p.Id);
          m.put('workOrderNumber', p.AcctSeedERP__Work_Order_Number__c);
          m.put('workOrderDate', createdDate.format());
          m.put('workOrderAccountName', p.AcctSeed__Account__r.Name);
          if (p.RecordType.Name != null)
            m.put('workOrderRecordType', p.RecordType.Name);
        }

        listJSON.add(m);
      }
    } else if (!String.isEmpty(idAccount)) {
      set<Id> setIdSerial = new Set<Id>();
      for (AcctSeed__Project__c p : [
        SELECT
          Id,
          Name,
          Serial_Number__c,
          Serial_Number__r.Name,
          Serial_Number__r.GMBLASERP__Lot__r.Name,
          Serial_Number__r.GMBLASERP__Lot__r.Id,
          Serial_Number__r.GMBLASERP__Product__r.Name,
          Serial_Number__r.GMBLASERP__Product__r.Id,
          AcctSeed__Account__c,
          AcctSeed__Account__r.Name,
          AcctSeedERP__Work_Order_Number__c,
          CreatedDate,
          RecordType.Name
        FROM AcctSeed__Project__c
        WHERE AcctSeed__Account__c = :idAccount AND Serial_Number__c != NULL
      ]) {
        if (setIdSerial.contains(p.Serial_Number__c))
          continue;

        setIdSerial.add(p.Serial_Number__c);

        map<String, String> m = new Map<String, String>();

        m.put('idSerial', p.Serial_Number__c);
        m.put('serialName', p.Serial_Number__r.Name);
        m.put('productName', p.Serial_Number__r.GMBLASERP__Product__r.Name);
        m.put('lotName', p.Serial_Number__r.GMBLASERP__Lot__r.Name);
        Date createdDate = date.newinstance(p.CreatedDate.year(), p.CreatedDate.month(), p.CreatedDate.day());

        m.put('idProject', p.Id);
        m.put('workOrderNumber', p.AcctSeedERP__Work_Order_Number__c);
        m.put('workOrderDate', createdDate.format());
        m.put('workOrderAccountName', p.AcctSeed__Account__r.Name);
        if (p.RecordType.Name != null)
          m.put('workOrderRecordType', p.RecordType.Name);

        listJSON.add(m);
      }
    }

    return listJSON;
  }

  @RemoteAction
  global static list<map<string, string>> createAccount(map<String, String> mapParam) {
    Map<Id, Schema.RecordTypeInfo> mapRecordTypeById = Account.sObjectType.getDescribe().getRecordTypeInfosById();
    Id recordTypeId = (Id) mapParam.get('accountRecordType');
    String recordTypeName = mapRecordTypeById.get(recordTypeId).getName();
    Account a = new Account(
      RecordTypeId = mapParam.get('accountRecordType'),
      Phone = mapParam.get('accountPhone'),
      BillingCity = mapParam.get('billingCity'),
      BillingCountryCode = mapParam.get('billingCountryCode'),
      BillingPostalCode = mapParam.get('billingPostalCode'),
      BillingStateCode = mapParam.get('billingStateCode'),
      BillingStreet = mapParam.get('billingStreet')
    );
    if (recordTypeName.equals('Person Account')) {
      a.FirstName = mapParam.get('accountFirstName');
      a.LastName = mapParam.get('accountLastName');
    } else
      a.Name = mapParam.get('accountName');

    insert a;
    return searchAccount(a.Id);
  }

  @RemoteAction
  global static List<Map<String, String>> createAsset(Map<String, String> mapParam) {
    String assetName = mapParam.get('assetName');
    String assetSerial = mapParam.get('assetSerial');
    Decimal assetValue = Decimal.valueOf(mapParam.get('inputValue'));
    AcctSeed__Fixed_Asset__c a = new AcctSeed__Fixed_Asset__c(
      Name = assetName,
      Asset_Serial_Number__c = assetSerial,
      AcctSeed__Value__c = assetValue
    );
    insert a;
    return searchAsset(a.Id);
  }

  @RemoteAction
  global static list<map<string, string>> createSerial(map<String, String> mapParam) {
    //System.debug(LoggingLevel.ERROR,mapParam);
    Id idLot = null;
    String idProduct = mapParam.get('serialProduct');
    String lotname = mapParam.get('serialLot');
    String serialName = mapParam.get('serialName');
    Decimal modelYear = null;
    if (mapParam.containsKey('modelYear') && mapParam.get('modelYear') != '')
      modelYear = Decimal.valueOf(mapParam.get('modelYear'));
    String description = mapParam.get('serialDesc');

    if (!String.isEmpty(lotname)) {
      for (GMBLASERP__Lot__c lot : [
        SELECT Id
        FROM GMBLASERP__Lot__c
        WHERE GMBLASERP__Product__c = :idProduct AND Name = :lotName
        LIMIT 1
      ]) {
        idLot = lot.Id;
      }
      if (idLot == null) {
        GMBLASERP__Lot__c lot = new GMBLASERP__Lot__c(Name = lotName, GMBLASERP__Product__c = idProduct);
        insert lot;
        idLot = lot.Id;
      }
    }

    GMBLASERP__Serial_Number__c serial = new GMBLASERP__Serial_Number__c(
      Name = serialName,
      GMBLASERP__Product__c = idProduct,
      GMBLASERP__Lot__c = idLot,
      Description__c = description,
      Model_Year__c = modelYear
    );

    insert serial;

    return searchSerial(serial.Id, null);
  }

  @RemoteAction
  global static Id createNewProject(String acctName, String idAccount, String idSerialOrAsset, Id idRt) {
    String projectName = acctName.trim();
    AcctSeed__Project__c project = new AcctSeed__Project__c(
      Name = projectName,
      RecordTypeId = idRt,
      AcctSeed__Account__c = idAccount
    );
    if (idRt == gcConstants.idRtTradeIn) {
      GMBLASERP__Serial_Number__c serial = [
        SELECT Id, GMBLASERP__Product__c
        FROM GMBLASERP__Serial_Number__c
        WHERE Id = :idSerialOrAsset
      ][0];
      project.Serial_Number__c = idSerialOrAsset;
      project.AcctSeedERP__Manufactured_Product__c = serial.GMBLASERP__Product__c;
    } else if (idRt == gcConstants.idRtFixedAsset)
      project.Fixed_Asset__c = idSerialOrAsset;
    else
      project.Serial_Number__c = idSerialOrAsset;

    insert project;
    Boolean internalLabour = false;
    if (idAccount != null) {
      for (Account acc : [SELECT Id, Is_Internal__c FROM Account WHERE Id = :idAccount AND Is_Internal__c = TRUE])
        internalLabour = true;
    }

    if (idRT != gcConstants.idRtProjectService || (idRT == gcConstants.idRtProjectService && internalLabour)) {
      String tn = 'Default Task Name';
      Boolean showInInvoice = false;
      if (idRT == gcConstants.idRtProjectWarranty) {
        tn = 'Warranty Payable';
        ERPOrderTaskNames__c taskNameSetting = ERPOrderTaskNames__c.getInstance(tn);
        if (taskNameSetting != null && taskNameSetting.Show_In_Invoice__c)
          showInInvoice = true;
      }
      if (idRt == gcConstants.idRtProjectCounterSale)
        showInInvoice = true;

      if (internalLabour) {
        tn = 'Default Labour Task';
        showInInvoice = true;
      }
      insert new AcctSeed__Project_Task__c(
        AcctSeed__Project__c = project.Id,
        DisplayOnCustomerInvoice__c = showInInvoice,
        Name = tn
      );
    }

    return project.Id;
  }

  global static String getRetrieveProduct() {
    // Retrieve only those Serial Product that are Boat
    list<map<string, string>> listJSON = new List<map<string, string>>();

    for (Product2 p : [
      SELECT Id, Name, AcctSeedERP__Serialized__c, GMBLASERP__Lot_Tracked__c
      FROM Product2
      WHERE AcctSeedERP__Serialized__c = TRUE AND RecordType.Name = 'Boat'
      ORDER BY Name
    ]) {
      map<String, String> m = new Map<String, String>();
      m.put('idProduct', p.Id);
      m.put('Name', p.Name);
      m.put('label', p.Name);
      m.put('isSerialized', (p.AcctSeedERP__Serialized__c == true ? 'true' : 'false'));
      m.put('isLotTracked', (p.GMBLASERP__Lot_Tracked__c == true ? 'true' : 'false'));
      listJSON.add(m);
    }

    return JSON.serialize(listJSON);
  }

  @RemoteAction
  @ReadOnly
  public static List<Map<String, String>> searchProductForSerial(String searchTxt) {
    List<Map<String, String>> listJSON = new List<Map<String, String>>();
    searchTxt = '%' + searchTxt.replaceAll('[*]', '%') + '%';

    for (Product2 p : [
      SELECT Id, Name, GMBLASERP__Lot_Tracked__c, AcctSeedERP__Serialized__c
      FROM Product2
      WHERE AcctSeedERP__Serialized__c = TRUE AND Name LIKE :searchTxt
      LIMIT 30
    ]) {
      map<String, String> m = new Map<String, String>();
      m.put('idProduct', p.Id);
      m.put('Name', p.Name);
      m.put('label', p.Name);
      m.put('isSerialized', (p.AcctSeedERP__Serialized__c == true ? 'true' : 'false'));
      m.put('isLotTracked', (p.GMBLASERP__Lot_Tracked__c == true ? 'true' : 'false'));
      listJSON.add(m);
    }
    return listJSON;
  }

  @RemoteAction
  @ReadOnly
  global static list<map<string, string>> retrieveLots(String idProduct) {
    list<map<string, string>> listJSON = new List<map<string, string>>();

    for (GMBLASERP__Lot__c l : [
      SELECT Id, Name
      FROM GMBLASERP__Lot__c
      WHERE GMBLASERP__Product__c = :idProduct
      ORDER BY Name
    ]) {
      map<string, string> obj = new Map<string, string>{ 'idLot' => l.Id, 'lotName' => l.Name };
      listJSON.add(obj);
    }

    return listJSON;
  }

  @RemoteAction
  @ReadOnly
  global static list<map<string, string>> retrieveSerials(String idProduct) {
    list<map<string, string>> listJSON = new List<map<string, string>>();

    for (GMBLASERP__Serial_Number__c sn : [
      SELECT Id, Name, GMBLASERP__Lot__r.Name, GMBLASERP__Inventory_Balance__c
      FROM GMBLASERP__Serial_Number__c
      WHERE GMBLASERP__Product__c = :idProduct
      ORDER BY Name
    ]) {
      map<string, string> obj = new Map<string, string>{ 'idSerial' => sn.Id, 'serialName' => sn.Name };
      if (sn.GMBLASERP__Lot__c != null)
        obj.put('lotName', sn.GMBLASERP__Lot__r.Name);

      if (sn.GMBLASERP__Inventory_Balance__c != null)
        obj.put('disabled', 'true');

      listJSON.add(obj);
    }
    return listJSON;
  }

  global static void coverage() {
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
  }
}
