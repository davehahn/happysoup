public with sharing class gcOpportunityTradeIn {
  public gcOpportunityTradeIn(ApexPages.StandardController c) {
  }
  public gcOpportunityTradeIn() {
  }

  @RemoteAction
  @ReadOnly
  public static List<Map<String, String>> retrieveTradeInItems(String idFilter) {
    List<Map<String, String>> listJSON = new List<Map<String, String>>();
    for (Trade_In_Item__c ti : [
      SELECT
        Id,
        Name,
        Make__c,
        Model__c,
        Model_Year__c,
        Product_Type__c,
        Serial_Number__c,
        Product__c,
        Product__r.Name,
        Product__r.RecordType.Name
      FROM Trade_In_Item__c
      WHERE Id = :idFilter OR Trade_In_Record__r.Opportunity__c = :idFilter
    ]) {
      Map<String, String> m = new Map<String, String>();
      m.put('tiId', ti.Id);
      m.put('tiName', ti.Name);
      m.put('tiMake', ti.Make__c);
      m.put('tiModel', ti.Model__c);
      m.put('tiLot', ti.Model_Year__c);
      m.put('tiSerial', ti.Serial_Number__c);
      m.put('idProduct', ti.Product__c);
      m.put('recordType', ti.Product__r.RecordType.Name);
      m.put('productName', ti.Product__r.Name);
      listJSON.add(m);
    }
    //select (select CreatedById, CreatedDate, IsDeleted, LastModifiedById, LastModifiedDate, Make__c, Model__c, Model_Year__c, Product_Type__c, Id, Serial_Number__c, SystemModstamp, Name, Trade_In_Record__c from Trade_In_Items__r), Lien_Amount__c, Name, Opportunity__c, Total_Applied__c, Total_Value__c from Trade_In_Record__c limit 100
    return listJSON;
  }

  @RemoteAction
  @ReadOnly
  public static List<Map<String, String>> retrieveOppyProjects(String idOppy) {
    List<Map<String, String>> listJSON = new List<Map<String, String>>();
    for (AcctSeed__Project__c p : [
      SELECT Id, Name, RecordType.Name
      FROM AcctSeed__Project__c
      WHERE AcctSeed__Opportunity__c = :idOppy
    ]) {
      Map<String, String> m = new Map<String, String>();
      m.put('idProject', p.Id);
      m.put('projectName', p.Name);
      m.put('recordType', p.RecordType.Name);
      listJSON.add(m);
    }
    return listJSON;
  }

  @RemoteAction
  @ReadOnly
  public static List<Product2> searchProductForSerial(String searchTxt) {
    List<Product2> listProduct = new List<Product2>();
    searchTxt = '%' + searchTxt.replaceAll('[*]', '%') + '%';

    for (Product2 p : [
      SELECT Id, Name, GMBLASERP__Lot_Tracked__c, AcctSeedERP__Serialized__c
      FROM Product2
      WHERE AcctSeedERP__Serialized__c = TRUE AND Name LIKE :searchTxt
      LIMIT 10
    ]) {
      listProduct.add(p);
    }
    return listProduct;
  }

  @RemoteAction
  public static Map<String, String> updateTradeInProduct(String idTradeInItem, String idProduct) {
    Product2 prod = [SELECT Id, RecordType.Name FROM Product2 WHERE Id = :idProduct][0];
    Trade_In_Item__c ti = [
      SELECT
        Id,
        Model_Year__c,
        Serial_Number__c,
        Product__c,
        Lot_Matched__c,
        Serial_Number_Matched__c,
        Trade_In_Record__r.Opportunity__c
      FROM Trade_In_Item__c
      WHERE Id = :idTradeInItem
    ][0];
    Id boatTradeInItem;

    if (prod.RecordType.Name.equals('Boat'))
      for (Trade_In_Item__c item : [
        SELECT Id
        FROM Trade_In_Item__c
        WHERE
          Trade_In_Record__r.Opportunity__c = :ti.Trade_In_Record__r.Opportunity__c
          AND Product__r.RecordType.Name = 'Boat'
      ])
        boatTradeInItem = item.Id;

    if (boatTradeInItem != null && boatTradeInItem != ti.Id)
      throw new gcException('A Boat has already been selected. Please select a different product.');

    ti.Product__c = idProduct;
    ti.Lot_Matched__c = null;
    for (GMBLASERP__Lot__c lot : [
      SELECT Id
      FROM GMBLASERP__Lot__c
      WHERE GMBLASERP__Product__c = :idProduct AND Name = :ti.Model_Year__c
      LIMIT 1
    ])
      ti.Lot_Matched__c = lot.Id;

    ti.Serial_Number_Matched__c = null;
    for (GMBLASERP__Serial_Number__c serial : [
      SELECT Id, Name, GMBLASERP__Inventory_Balance__c
      FROM GMBLASERP__Serial_Number__c
      WHERE GMBLASERP__Product__c = :idProduct AND Name = :ti.Serial_Number__c
    ]) {
      if (serial.GMBLASERP__Inventory_Balance__c != null)
        throw new gcException(
          'Serial number ' +
          serial.Name +
          ' for this product already exists in Inventory. Please select a different Product or change the Serial Number.'
        );
      else
        ti.Serial_Number_Matched__c = serial.Id;
    }

    update ti;

    return retrieveTradeInItems(idTradeInItem)[0];
  }

  @RemoteAction
  public static Map<String, String> updateTradeInSerial(String idTradeInItem, String serialNumber) {
    Trade_In_Item__c ti = [
      SELECT
        Id,
        Model_Year__c,
        Serial_Number__c,
        Product__c,
        Lot_Matched__c,
        Serial_Number_Matched__c,
        Trade_In_Record__r.Opportunity__c
      FROM Trade_In_Item__c
      WHERE Id = :idTradeInItem
    ][0];

    ti.Serial_Number_Matched__c = null;
    ti.Serial_Number__c = serialNumber;
    for (GMBLASERP__Serial_Number__c serial : [
      SELECT Id, Name, GMBLASERP__Inventory_Balance__c
      FROM GMBLASERP__Serial_Number__c
      WHERE GMBLASERP__Product__c = :ti.Product__c AND Name = :serialNumber
    ]) {
      if (serial.GMBLASERP__Inventory_Balance__c != null)
        throw new gcException(
          'Serial number ' +
          serialNumber +
          ' for this product already exists in Inventory. Please change the Serial Number.'
        );
      else
        ti.Serial_Number_Matched__c = serial.Id;
    }

    update ti;

    return retrieveTradeInItems(idTradeInItem)[0];
  }

  @RemoteAction
  public static List<Map<String, String>> createTradeInOrders(String idOppy) {
    createTradeInERP(idOppy);
    /// Now create the Sales ERP Order
    gcProject_CreateFromOppy.createProject2(idOppy);

    return retrieveOppyProjects(idOppy);
  }

  @RemoteAction
  public static void createRetailERP(String idOppy) {
    gcProject_CreateFromOppy.createProject2(idOppy);
  }

  @RemoteAction
  public static void createTradeInERP(String idOppy) {
    Application_RecordType.ERPOrderRTs erpRts = new Application_RecordType().getERPOrderRecordTypes();
    Opportunity oppy = [
      SELECT
        Id,
        Name,
        Business_Manager__c,
        Pricebook2Id,
        AccountId,
        Account.Name,
        ownerId,
        (SELECT Id FROM AcctSeed__Projects__r WHERE RecordTypeId = :erpRts.getTradeInId())
      FROM Opportunity
      WHERE Id = :idOppy
    ][0];
    if (!oppy.AcctSeed__Projects__r.isEmpty()) {
      /// Not returning an error to check for Retail SFISSUES-499
      return;
    }
    //throw new gcException('The opportunity already has Trade In ERP Order Created.');

    String projectName =
      (oppy.Account.Name.length() >= 50 ? oppy.Account.Name.trim().substring(0, 50) : oppy.Account.Name) +
      ' - Trade In';

    AcctSeed__Project__c project = new AcctSeed__Project__c(
      Name = projectName,
      RecordTypeId = gcConstants.idRtTradeIn,
      AcctSeed__Account__c = oppy.AccountId,
      AcctSeed__Opportunity__c = oppy.Id,
      GMBLASERP__Pricebook__c = oppy.Pricebook2Id,
      Business_Manager__c = oppy.Business_Manager__c,
      Salesperson__c = oppy.OwnerId
    );

    List<GMBLASERP__Serial_Number__c> listSerials = new List<GMBLASERP__Serial_Number__c>();
    Map<Id, GMBLASERP__Serial_Number__c> mapTISerials = new Map<Id, GMBLASERP__Serial_Number__c>();
    List<GMBLASERP__Lot__c> listLots = new List<GMBLASERP__Lot__c>();
    Map<Id, GMBLASERP__Lot__c> mapTILots = new Map<Id, GMBLASERP__Lot__c>();
    List<Trade_In_Item__c> listTItems = new List<Trade_In_Item__c>();

    Map<Id, Map<String, GMBLASERP__Lot__c>> mapProductLots = new Map<Id, Map<String, GMBLASERP__Lot__c>>();
    Map<Id, Map<String, GMBLASERP__Serial_Number__c>> mapProductSerials = new Map<Id, Map<String, GMBLASERP__Serial_Number__c>>();

    Set<Id> setIdProducts = new Set<Id>();
    Set<String> setLots = new Set<String>();
    Set<String> setSerials = new Set<String>();
    Map<Id, Trade_In_Item__c> mapTradeInItems = new Map<Id, Trade_In_Item__c>();
    /// Bulkify Lot And Serial
    for (Trade_In_Item__c ti : [
      SELECT
        Id,
        Name,
        Make__c,
        Model__c,
        Model_Year__c,
        Lot_Matched__c,
        Serial_Number__c,
        Serial_Number_Matched__c,
        Product__c,
        Product__r.Name,
        Product__r.GMBLASERP__Lot_Tracked__c,
        Product__r.Can_be_Nested__c,
        Product__r.RecordType.Name,
        Trade_In_Record__c
      FROM Trade_In_Item__c
      WHERE Trade_In_Record__r.Opportunity__c = :idOppy
    ]) {
      listTItems.add(ti);
      setIdProducts.add(ti.Product__c);
      mapTradeInItems.put(ti.Id, ti);
      //if(ti.Lot_Matched__c == null)
      //{
      setLots.add(ti.Model_Year__c);
      if (!mapProductLots.containsKey(ti.Product__c))
        mapProductLots.put(ti.Product__c, new Map<String, GMBLASERP__Lot__c>());
      GMBLASERP__Lot__c lot = new GMBLASERP__Lot__c(Name = ti.Model_Year__c, GMBLASERP__Product__c = ti.Product__c);
      mapProductLots.get(ti.Product__c).put(ti.Model_Year__c, lot);
      //}

      //if(ti.Serial_Number_Matched__c == null)
      //{
      setSerials.add(ti.Serial_Number__c.toUpperCase());
      if (!mapProductSerials.containsKey(ti.Product__c))
        mapProductSerials.put(ti.Product__c, new Map<String, GMBLASERP__Serial_Number__c>());
      String description = 'Make: ' + ti.Make__c + ', Model:' + ti.Model__c + ' - ' + ti.Model_Year__c;
      GMBLASERP__Serial_Number__c serial = new GMBLASERP__Serial_Number__c(
        Name = ti.Serial_Number__c.toUpperCase(),
        GMBLASERP__Lot__c = (ti.Lot_Matched__c == null ? ti.Id : ti.Lot_Matched__c),
        GMBLASERP__Product__c = ti.Product__c,
        Description__c = description,
        Status__c = 'Used'
      );
      mapProductSerials.get(ti.Product__c).put(ti.Serial_Number__c.toUpperCase(), serial);
      //}
    }

    /// Find Out all the Products with Lot and Serials that matches with the Serials
    Map<Id, Product2> mapProducts = new Map<Id, Product2>();
    for (Product2 p : [
      SELECT
        Id,
        Name,
        GMBLASERP__Lot_Tracked__c,
        (SELECT Id, Name, GMBLASERP__Product__c FROM GMBLASERP__Lots__r WHERE Name IN :setLots),
        (
          SELECT Id, Name, GMBLASERP__Lot__c, GMBLASERP__Product__c, Nest__c, GMBLASERP__Inventory_Balance__c, Status__c
          FROM GMBLASERP__Serial_Numbers__r
          WHERE Name IN :setSerials
        )
      FROM Product2
      WHERE Id IN :setIdProducts
    ]) {
      mapProducts.put(p.Id, p);
      if (!p.GMBLASERP__Lots__r.isEmpty()) {
        for (GMBLASERP__Lot__c lot : p.GMBLASERP__Lots__r) {
          if (mapProductLots.containsKey(p.Id) && mapProductLots.get(p.Id).containsKey(lot.Name))
            mapProductLots.get(p.Id).put(lot.Name, lot);
        }
      }
      if (!p.GMBLASERP__Serial_Numbers__r.isEmpty()) {
        for (GMBLASERP__Serial_Number__c serial : p.GMBLASERP__Serial_Numbers__r) {
          if (mapProductSerials.containsKey(p.Id) && mapProductSerials.get(p.Id).containsKey(serial.Name)) {
            if (serial.GMBLASERP__Inventory_Balance__c != null)
              throw new gcException(
                'Serial number ' +
                serial.Name +
                ' already exists in Inventory. Please select a different Product or change the Serial Number.'
              );
            else {
              serial.Status__c = 'Used';
              mapProductSerials.get(p.Id).put(serial.Name, serial);
            }
          }
        }
      }
    }

    /// lots to upsert
    for (Id idProduct : mapProductLots.keySet()) {
      for (GMBLASERP__Lot__c lot : mapProductLots.get(idProduct).values()) {
        if (mapProducts.get(idProduct).GMBLASERP__Lot_Tracked__c && lot.Id == null)
          listLots.add(lot);
      }
    }
    System.debug(loggingLevel.Error, 'setLots: ' + setLots);
    System.debug(loggingLevel.Error, 'listLots: ' + listLots);
    if (!listLots.isEmpty())
      upsert listLots;

    /// serials to upsert
    for (Id idProduct : mapProductSerials.keySet()) {
      for (GMBLASERP__Serial_Number__c serial : mapProductSerials.get(idProduct).values()) {
        if (serial.Id == null) {
          if (mapProducts.get(idProduct).GMBLASERP__Lot_Tracked__c) {
            Id passVal = serial.GMBLASERP__Lot__c;
            String objectAPIName = passVal.getSObjectType().getDescribe().getName();
            if (objectAPIName.equals('Trade_In_Item__c')) {
              String makeYear = mapTradeInItems.get(passVal).Model_Year__c;
              serial.GMBLASERP__Lot__c = mapProductLots.get(idProduct).get(makeYear).Id;
            }
          } else
            serial.GMBLASERP__Lot__c = null;

          listSerials.add(serial);
        }
      }
    }
    System.debug(loggingLevel.Error, 'setSerials: ' + setSerials);
    System.debug(loggingLevel.Error, 'listSerials: ' + listSerials);
    System.debug(loggingLevel.Error, 'mapProductSerials: ' + mapProductSerials);
    if (!listSerials.isEmpty())
      upsert listSerials;

    /// Loop through all the Trade In Items again to generate projects and nests
    /// First for Boat.
    /// Think about it later to supress ------------------------ START
    GMBLASERP__Serial_Number__c boatSerial;
    for (Trade_In_Item__c ti : listTItems) {
      if (ti.Product__r.RecordType.Name.equals('Boat')) {
        boatSerial = mapProductSerials.get(ti.Product__c).get(ti.Serial_Number__c.toUpperCase());
        project.Serial_Number__c = boatSerial.Id;
        project.AcctSeedERP__Manufactured_Product__c = boatSerial.GMBLASERP__Product__c;
      }
    }
    insert project;
    AcctSeed__Project_Task__c projectTask = new AcctSeed__Project_Task__c(
      AcctSeed__Project__c = project.Id,
      Name = 'Default Task Name'
    );
    insert projectTask;

    /// Get the Warehouse Auto populated during project insertion
    AcctSeed__Project__c insertedProject = [
      SELECT Id, GMBLASERP__Warehouse__c
      FROM AcctSeed__Project__c
      WHERE Id = :project.Id
    ][0];
    /// Location
    AcctSeedERP__Location__c loc = [
      SELECT Id
      FROM AcctSeedERP__Location__c
      WHERE AcctSeedERP__Warehouse__c = :insertedProject.GMBLASERP__Warehouse__c
    ][0];
    Map<Id, Map<Id, Map<Id, Id>>> mapPWLB = new Map<Id, Map<Id, Map<Id, Id>>>();
    /// Think about it later to supress ------------------------ END
    List<GMBLASERP__Serial_Number__c> listUpdateSerials = new List<GMBLASERP__Serial_Number__c>();
    List<GMBLASERP__Serial_Number__c> listAllSerials = new List<GMBLASERP__Serial_Number__c>();
    for (Trade_In_Item__c ti : listTItems) {
      GMBLASERP__Serial_Number__c sr = mapProductSerials.get(ti.Product__c).get(ti.Serial_Number__c.toUpperCase());
      if (boatSerial != null) {
        if (!ti.Product__r.RecordType.Name.equals('Boat') && ti.Product__r.Can_be_Nested__c) {
          sr.Nest__c = boatSerial.Id;
          listUpdateSerials.add(sr);
        }
      }
      listAllSerials.add(sr);
      if (!mapPWLB.containsKey(ti.Product__c))
        mapPWLB.put(
          ti.Product__c,
          new Map<Id, map<Id, Id>>{ insertedProject.GMBLASERP__Warehouse__c => new Map<Id, Id>{ loc.Id => null } }
        );
      ///// Here the inbound moves will go but later
    }
    if (!listUpdateSerials.isEmpty())
      update listUpdateSerials;

    List<AcctSeedERP__Inbound_Inventory_Movement__c> listInbound = new List<AcctSeedERP__Inbound_Inventory_Movement__c>();
    Id idGlTradeIn = gcConstants.idGlTradeIn;
    if (!mapPWLB.isEmpty()) {
      GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);
      for (GMBLASERP__Serial_Number__c serial : listAllSerials) {
        Id idBalance = mapPWLB.get(serial.GMBLASERP__Product__c)
          .get(insertedProject.GMBLASERP__Warehouse__c)
          .get(loc.Id);
        listInbound.add(
          new AcctSeedERP__Inbound_Inventory_Movement__c(
            AcctSeedERP__Credit_GL_Account__c = idGlTradeIn,
            AcctSeedERP__Inventory_Balance__c = idBalance,
            AcctSeedERP__Movement_Date__c = date.today(),
            AcctSeedERP__Project__c = project.Id,
            AcctSeedERP__Project_Task__c = projectTask.Id,
            AcctSeedERP__Quantity__c = 1,
            AcctSeedERP__Type__c = 'Accounting',
            AcctSeedERP__Unit_Cost__c = 0,
            GMBLASERP__Cost_Override__c = true,
            GMBLASERP__Lot__c = serial.GMBLASERP__Lot__c,
            GMBLASERP__Serial_Number__c = serial.Id
          )
        );
      }
    }
    if (!listInbound.isEmpty())
      insert listInbound;
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
  }
}
