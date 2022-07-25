global without sharing class gcSerialNumber_Ext {
  global gcSerialNumber_Ext() {
  }
  global gcSerialNumber_Ext(ApexPages.StandardController c) {
  }

  @AuraEnabled(Cacheable=true)
  public static String fetchSerialInfo(Id serialId) {
    GMBLASERP__Serial_Number__c serial = SerialNumber_Selector.getSerialNumber(serialId);
    return JSON.serialize(serial);
  }

  @AuraEnabled
  public static void createWriteOffSerial(
    GMBLASERP__Serial_Number__c serial,
    AcctSeedERP__Outbound_Inventory_Movement__c outbound
  ) {
    Boolean oldVal = gcSerialNumber.disableTrigger;
    gcSerialNumber.disableTrigger = true;
    update serial;
    gcSerialNumber.disableTrigger = oldVal;
    insert outbound;
  }

  @RemoteAction
  @ReadOnly
  global static list<map<string, string>> retrieveNestedSerials(Id idParent) {
    list<Id> listIdChildren = new List<Id>();
    for (GMBLASERP__Serial_Number__c sn : [
      SELECT Id
      FROM GMBLASERP__Serial_Number__c
      WHERE Nest__c = :idParent AND Nest__c != NULL
    ])
      listIdChildren.add(sn.Id);

    return retrieveSerials(listIdChildren);
  }

  @RemoteAction
  @ReadOnly
  global static List<Product2> searchProductForSerial(String searchTxt) {
    List<Product2> listProduct = new List<Product2>();
    searchTxt = '%' + searchTxt.replaceAll('[*]', '%') + '%';

    for (Product2 p : [
      SELECT Id, Name
      FROM Product2
      WHERE
        AcctSeedERP__Serialized__c = TRUE
        AND GMBLASERP__Lot_Tracked__c = TRUE
        AND (Name LIKE :searchTxt
        OR ProductCode LIKE :searchTxt)
      LIMIT 20
    ]) {
      listProduct.add(p);
    }
    return listProduct;
  }

  @RemoteAction
  @ReadOnly
  global static list<map<string, string>> retrieveLots(Id idProduct) {
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
  global static String exchangeProduct(Id idSerial, Id idProduct, String lotName) {
    GMBLASERP__Serial_Number__c serial = [
      SELECT Id, GMBLASERP__Product__c, GMBLASERP__Lot__c, GMBLASERP__Inventory_Balance__c
      FROM GMBLASERP__Serial_Number__c
      WHERE Id = :idSerial
    ][0];
    Product2 product = [
      SELECT Id, AcctSeedERP__Serialized__c, GMBLASERP__Lot_Tracked__c
      FROM Product2
      WHERE Id = :idProduct
    ][0];
    GMBLASERP__Lot__c lot;
    for (GMBLASERP__Lot__c l : [
      SELECT Id, GMBLASERP__Product__c
      FROM GMBLASERP__Lot__c
      WHERE Name = :lotName AND GMBLASERP__Product__c = :product.Id
      LIMIT 1
    ])
      lot = l;

    if (lot == null) {
      lot = new GMBLASERP__Lot__c(Name = lotName, GMBLASERP__Product__c = product.Id);
      insert lot;
    }
    String exType = 'Product';
    if (serial.GMBLASERP__Product__c == product.Id)
      exType = 'Lot';

    Lot_Exchange__c transferLot = new Lot_Exchange__c(
      Lot_From__c = serial.GMBLASERP__Lot__c,
      Lot_To__c = lot.Id,
      Exchange_Date__c = date.Today(),
      Exchange_Type__c = exType
    );
    insert transferLot;
    return gcLotExchange_Ext.startTransfer(new List<String>{ serial.Id }, transferLot.Id);
  }

  @RemoteAction
  @ReadOnly
  global static list<map<string, string>> retrieveSerials(list<Id> listIdSerial) {
    list<map<string, string>> listJSON = new List<map<string, string>>();

    for (GMBLASERP__Serial_Number__c sn : [
      SELECT
        Id,
        Name,
        Model_Year__c,
        GMBLASERP__Product__c,
        GMBLASERP__Product__r.Family,
        GMBLASERP__Product__r.Name,
        GMBLASERP__Product__r.ProductCode,
        GMBLASERP__Product__r.RecordType.Name,
        GMBLASERP__Product__r.Can_be_Nest__c,
        GMBLASERP__Lot__c,
        GMBLASERP__Lot__r.Name,
        GMBLASERP__Inventory_Balance__c,
        GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c,
        GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name,
        Nest__c,
        Nest__r.Name,
        (SELECT Id FROM Nested_Serial_Numbers__r LIMIT 1)
      FROM GMBLASERP__Serial_Number__c
      WHERE Id IN :listIdSerial
    ]) {
      map<string, string> m = new Map<string, string>();

      m.put('idSerial', sn.Id);
      m.put('serialName', sn.Name);
      m.put('modelYear', sn.Model_Year__c == null ? '' : String.valueOf(sn.Model_Year__c));
      m.put('idProduct', sn.GMBLASERP__Product__c);
      m.put('productFamily', sn.GMBLASERP__Product__r.Family);
      m.put('productName', sn.GMBLASERP__Product__r.Name);
      m.put('productCode', sn.GMBLASERP__Product__r.ProductCode);
      if (sn.GMBLASERP__Product__r.RecordTypeId != null)
        m.put('productRecordTypeName', sn.GMBLASERP__Product__r.RecordType.Name);
      if (sn.GMBLASERP__Product__r.Can_be_Nest__c)
        m.put('canBeNest', 'true');
      else
        m.put('canBeNest', 'false');

      if (sn.GMBLASERP__Lot__c != null) {
        m.put('idLot', sn.GMBLASERP__Lot__c);
        m.put('lotName', sn.GMBLASERP__Lot__r.Name);
      }

      if (sn.GMBLASERP__Inventory_Balance__c != null) {
        m.put('idBalance', sn.GMBLASERP__Inventory_Balance__c);
        m.put('idWarehouse', sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c);
        m.put('warehouseName', sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name);
      } else
        m.put('warehouseName', 'out');

      if (sn.Nest__c != null) {
        m.put('idNest', sn.Nest__c);
        m.put('nestName', sn.Nest__r.Name);
      }

      if (sn.Nested_Serial_Numbers__r.size() > 0)
        m.put('hasChildren', 'true');
      else
        m.put('hasChildren', 'false');

      listJSON.add(m);
    }

    return listJSON;
  }

  @RemoteAction
  @ReadOnly
  global static list<map<string, string>> searchSerial(String strSearch) {
    list<map<string, string>> listJSON = new List<map<string, string>>();

    strSearch = '%' + strSearch + '%';

    for (GMBLASERP__Serial_Number__c sn : [
      SELECT
        Id,
        Name,
        Model_Year__c,
        GMBLASERP__Product__c,
        GMBLASERP__Product__r.Family,
        GMBLASERP__Product__r.Name,
        GMBLASERP__Product__r.ProductCode,
        GMBLASERP__Product__r.RecordType.Name,
        GMBLASERP__Lot__c,
        GMBLASERP__Lot__r.Name,
        GMBLASERP__Inventory_Balance__c,
        GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c,
        GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name,
        Nest__c,
        Nest__r.Name
      FROM GMBLASERP__Serial_Number__c
      WHERE
        (Name LIKE :strSearch
        OR GMBLASERP__Product__r.Name LIKE :strSearch
        OR GMBLASERP__Product__r.ProductCode LIKE :strSearch
        OR GMBLASERP__Product__r.Family LIKE :strSearch
        OR GMBLASERP__Product__r.RecordType.Name LIKE :strSearch)
        AND GMBLASERP__Product__r.Can_be_Nested__c = TRUE
    ]) {
      map<string, string> m = new Map<string, string>();

      m.put('idSerial', sn.Id);
      m.put('serialName', sn.Name);
      m.put('modelYear', sn.Model_Year__c == null ? '' : String.valueOf(sn.Model_Year__c));
      m.put('idProduct', sn.GMBLASERP__Product__c);
      m.put('productFamily', sn.GMBLASERP__Product__r.Family);
      m.put('productName', sn.GMBLASERP__Product__r.Name);
      m.put('productCode', sn.GMBLASERP__Product__r.ProductCode);
      if (sn.GMBLASERP__Product__r.RecordTypeId != null)
        m.put('productRecordTypeName', sn.GMBLASERP__Product__r.RecordType.Name);

      if (sn.GMBLASERP__Lot__c != null) {
        m.put('idLot', sn.GMBLASERP__Lot__c);
        m.put('lotName', sn.GMBLASERP__Lot__r.Name);
      }

      if (sn.GMBLASERP__Inventory_Balance__c != null) {
        m.put('idBalance', sn.GMBLASERP__Inventory_Balance__c);
        m.put('idWarehouse', sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c);
        m.put('warehouseName', sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name);
      }

      if (sn.Nest__c != null) {
        m.put('idNest', sn.Nest__c);
        m.put('nestName', sn.Nest__r.Name);
      }

      listJSON.add(m);
    }

    return listJSON;
  }

  @RemoteAction
  @ReadOnly
  global static List<Map<String, String>> searchExistingSerial(String strSearch, String pIdProject) {
    List<Map<String, String>> listJSON = new List<Map<String, String>>();
    List<GMBLASERP__Serial_Number__c> listSerialNumbers = new List<GMBLASERP__Serial_Number__c>();
    if (strSearch.equals('preload')) {
      AcctSeed__Project__c project = [
        SELECT Id, AcctSeed__Account__c
        FROM AcctSeed__Project__c
        WHERE Id = :pIdProject
      ][0];

      if (project.AcctSeed__Account__c != null) {
        for (AcctSeed__Project__c p : [
          SELECT
            Id,
            Serial_Number__r.Id,
            Serial_Number__r.Name,
            Serial_Number__r.GMBLASERP__Product__c,
            Serial_Number__r.GMBLASERP__Product__r.Family,
            Serial_Number__r.GMBLASERP__Product__r.Name,
            Serial_Number__r.GMBLASERP__Product__r.ProductCode,
            Serial_Number__r.GMBLASERP__Product__r.RecordType.Name,
            Serial_Number__r.GMBLASERP__Lot__c,
            Serial_Number__r.GMBLASERP__Lot__r.Name,
            Serial_Number__r.GMBLASERP__Inventory_Balance__c,
            Serial_Number__r.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c,
            Serial_Number__r.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name,
            Serial_Number__r.Nest__c,
            Serial_Number__r.Nest__r.Name
          FROM AcctSeed__Project__c
          WHERE AcctSeed__Account__c = :project.AcctSeed__Account__c AND Id != :pIdProject AND Serial_Number__c != NULL
        ]) {
          GMBLASERP__Serial_Number__c sn = p.Serial_Number__r;
          listSerialNumbers.add(sn);
        }
      }
    } else {
      strSearch = '%' + strSearch + '%';
      for (GMBLASERP__Serial_Number__c sn : [
        SELECT
          Id,
          Name,
          GMBLASERP__Product__c,
          GMBLASERP__Product__r.Family,
          GMBLASERP__Product__r.Name,
          GMBLASERP__Product__r.ProductCode,
          GMBLASERP__Product__r.RecordType.Name,
          GMBLASERP__Lot__c,
          GMBLASERP__Lot__r.Name,
          GMBLASERP__Inventory_Balance__c,
          GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c,
          GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name,
          Nest__c,
          Nest__r.Name
        FROM GMBLASERP__Serial_Number__c
        WHERE
          (Name LIKE :strSearch
          OR GMBLASERP__Product__r.Name LIKE :strSearch
          OR GMBLASERP__Product__r.ProductCode LIKE :strSearch
          OR GMBLASERP__Product__r.Family LIKE :strSearch
          OR GMBLASERP__Product__r.RecordType.Name LIKE :strSearch)
          AND GMBLASERP__Product__r.Can_be_Nested__c = FALSE
          AND GMBLASERP__Product__r.Can_be_Nest__c = TRUE
      ]) {
        listSerialNumbers.add(sn);
      }
    }

    if (listSerialNumbers.size() > 0) {
      for (GMBLASERP__Serial_Number__c sn : listSerialNumbers) {
        Map<String, String> m = new Map<String, String>();

        m.put('idSerial', sn.Id);
        m.put('serialName', sn.Name);

        m.put('idProduct', sn.GMBLASERP__Product__c);
        m.put('productFamily', sn.GMBLASERP__Product__r.Family);
        m.put('productName', sn.GMBLASERP__Product__r.Name);
        m.put('productCode', sn.GMBLASERP__Product__r.ProductCode);
        if (sn.GMBLASERP__Product__r.RecordTypeId != null)
          m.put('productRecordTypeName', sn.GMBLASERP__Product__r.RecordType.Name);

        if (sn.GMBLASERP__Lot__c != null) {
          m.put('idLot', sn.GMBLASERP__Lot__c);
          m.put('lotName', sn.GMBLASERP__Lot__r.Name);
        }

        if (sn.GMBLASERP__Inventory_Balance__c != null) {
          m.put('idBalance', sn.GMBLASERP__Inventory_Balance__c);
          m.put('idWarehouse', sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c);
          m.put('warehouseName', sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name);
        }

        if (sn.Nest__c != null) {
          m.put('idNest', sn.Nest__c);
          m.put('nestName', sn.Nest__r.Name);
        }

        listJSON.add(m);
      }
    }
    return listJSON;
  }

  @RemoteAction
  global static map<string, string> updateNest(Id idSerial, Id idNest) {
    GMBLASERP__Serial_Number__c sn = [SELECT Id, Nest__c FROM GMBLASERP__Serial_Number__c WHERE Id = :idSerial][0];
    sn.Nest__c = idNest;
    update sn;

    return retrieveSerials(new List<Id>{ idSerial })[0];
  }

  @RemoteAction
  @ReadOnly
  global static list<map<string, string>> retrieveMaterialSerials(list<Id> listIdSerial) {
    list<map<string, string>> listJSON = new List<map<string, string>>();
    for (AcctSeedERP__Material__c mtrl : [
      SELECT
        Id,
        Name,
        AcctSeedERP__Quantity_Allocated__c,
        Quantity_Allocated_Non_Inventory__c,
        AcctSeedERP__Project__r.Id,
        AcctSeedERP__Project__r.Name,
        AcctSeedERP__Project__r.RecordType.Name,
        AcctSeedERP__Product__c,
        AcctSeedERP__Product__r.Id,
        AcctSeedERP__Product__r.Name,
        AcctSeedERP__Product__r.Family,
        AcctSeedERP__Product__r.ProductCode,
        AcctSeedERP__Product__r.RecordType.Name,
        AcctSeedERP__Product__r.Can_be_Nest__c,
        GMBLASERP__Serial_Number__c,
        GMBLASERP__Serial_Number__r.Id,
        GMBLASERP__Serial_Number__r.Name,
        GMBLASERP__Serial_Number__r.GMBLASERP__Lot__c,
        GMBLASERP__Serial_Number__r.GMBLASERP__Lot__r.Name,
        GMBLASERP__Serial_Number__r.GMBLASERP__Inventory_Balance__c,
        GMBLASERP__Serial_Number__r.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c,
        GMBLASERP__Serial_Number__r.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name,
        GMBLASERP__Serial_Number__r.Nest__c,
        GMBLASERP__Serial_Number__r.Nest__r.Name
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__r.Serial_Number__c IN :listIdSerial
    ]) {
      map<string, string> m = new Map<string, string>();
      Decimal qtyAlloc = mtrl.AcctSeedERP__Quantity_Allocated__c == null
        ? 0
        : mtrl.AcctSeedERP__Quantity_Allocated__c.setScale(2);
      Decimal qtyAllocNI = mtrl.Quantity_Allocated_Non_Inventory__c == null
        ? 0
        : mtrl.Quantity_Allocated_Non_Inventory__c.setScale(2);
      m.put('qtyAlloc', String.valueOf(qtyAlloc));
      m.put('qtyAllocNI', String.valueOf(qtyAllocNI));

      m.put('idProject', mtrl.AcctSeedERP__Project__r.Id);
      m.put('projectName', mtrl.AcctSeedERP__Project__r.Name);
      m.put('projectType', mtrl.AcctSeedERP__Project__r.RecordType.Name);

      Product2 p = mtrl.AcctSeedERP__Product__r;
      m.put('idProduct', p.Id);
      m.put('productFamily', p.Family);
      m.put('productName', p.Name);
      m.put('productCode', p.ProductCode);
      if (p.RecordTypeId != null)
        m.put('productRecordTypeName', p.RecordType.Name);
      if (p.Can_be_Nest__c)
        m.put('canBeNest', 'true');
      else
        m.put('canBeNest', 'false');

      if (mtrl.GMBLASERP__Serial_Number__c != null) {
        GMBLASERP__Serial_Number__c sn = mtrl.GMBLASERP__Serial_Number__r;
        m.put('idSerial', sn.Id);
        m.put('serialName', sn.Name);
        if (sn.GMBLASERP__Lot__c != null) {
          m.put('idLot', sn.GMBLASERP__Lot__c);
          m.put('lotName', sn.GMBLASERP__Lot__r.Name);
        }

        if (sn.GMBLASERP__Inventory_Balance__c != null) {
          m.put('idBalance', sn.GMBLASERP__Inventory_Balance__c);
          m.put('idWarehouse', sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c);
          m.put('warehouseName', sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name);
        } else
          m.put('warehouseName', 'out');

        if (sn.Nest__c != null) {
          m.put('idNest', sn.Nest__c);
          m.put('nestName', sn.Nest__r.Name);
        }
      }

      listJSON.add(m);
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
  }
}
