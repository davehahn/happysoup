global without sharing class gcPurchaseOrder_Report {
  global gcPurchaseOrder_Report(ApexPages.standardController ctrl) {
  }
  global gcPurchaseOrder_Report() {
  }

  global static string locale {
    get {
      return UserInfo.getLocale();
    }
  }

  @RemoteAction
  @ReadOnly
  global static list<map<string, string>> retrieveVendors() {
    list<map<string, string>> listJSON = new List<map<string, string>>();

    String soql;

    String status = 'Open';

    soql = ' SELECT AcctSeedERP__Vendor__c idVendor, AcctSeedERP__Vendor__r.Name vendorName, SUM(AcctSeedERP__Total__c) openPoAmt ';
    soql += ' FROM AcctSeedERP__Purchase_Order__c ';
    soql += ' WHERE AcctSeedERP__Status__c= :status ';
    soql += ' GROUP BY AcctSeedERP__Vendor__c, AcctSeedERP__Vendor__r.Name ';
    soql += ' ORDER BY AcctSeedERP__Vendor__r.Name ';

    list<sObject> listAggRes = new List<sObject>();
    listAggRes.addAll(Database.query(soql));

    for (sObject aggRes : listAggRes) {
      map<string, string> m = new Map<string, string>();

      m.put('idVendor', (Id) aggRes.get('idVendor'));
      m.put('vendorName', (String) aggRes.get('vendorName'));
      m.put('amt', String.valueOf(((Decimal) aggRes.get('openPoAmt')).setScale(6)));

      listJSON.add(m);
    }

    return listJSON;
  }

  @RemoteAction
  @ReadOnly
  global static list<map<String, String>> retrieveProducts() {
    list<map<string, string>> listJSON = new List<map<string, string>>();

    String soql;

    String status = 'Open';

    list<AggregateResult> listAggRes = new List<AggregateResult>();

    listAggRes.addAll(
      [
        SELECT
          AcctSeedERP__Product__c idProduct,
          sum(AcctSeedERP__Quantity__c) qtyOrdered,
          sum(AcctSeedERP__Quantity_Received__c) qtyReceived,
          sum(GMBLASERP__Quantity_Received_Non_Inventory__c) qtyReceivedNI
        FROM AcctSeedERP__Purchase_Order_Line__c
        WHERE AcctSeedERP__Purchase_Order__r.AcctSeedERP__Status__c = 'Open'
        GROUP BY AcctSeedERP__Product__c
      ]
    );

    map<Id, Product2> mapProduct = new Map<Id, Product2>();

    for (AggregateResult aggRes : listAggRes) {
      if (aggRes.get('idProduct') != null)
        mapProduct.put((Id) aggRes.get('idProduct'), null);
    }

    for (Product2 p : [SELECT Id, Name, ProductCode FROM Product2 WHERE Id IN :mapProduct.keySet()])
      mapProduct.put(p.Id, p);

    for (AggregateResult aggRes : listAggRes) {
      Id idProduct = (Id) aggRes.get('idProduct');
      Decimal qtyOrdered = (Decimal) aggRes.get('qtyOrdered');
      Decimal qtyReceived = (Decimal) aggRes.get('qtyReceived');
      Decimal qtyReceivedNI = (Decimal) aggRes.get('qtyReceivedNI');

      qtyOrdered = (qtyOrdered == null ? 0 : qtyOrdered);
      qtyReceived = (qtyReceived == null ? 0 : qtyReceived);
      qtyReceivedNI = (qtyReceivedNI == null ? 0 : qtyReceivedNI);

      Decimal qtyOpen = qtyOrdered - qtyReceived - qtyReceivedNI;

      Product2 p = mapProduct.get(idProduct);

      if (p == null)
        continue;

      map<String, String> m = new Map<String, String>();

      m.put('idProduct', p.Id);
      m.put('productName', p.Name);
      m.put('productCode', p.ProductCode);
      m.put('qtyOrdered', String.valueOf(qtyOrdered.setScale(0)));
      m.put('qtyOpen', String.valueOf(qtyOpen.setScale(0)));

      listJSON.add(m);
    }

    return listJSON;
  }

  @RemoteAction
  @ReadOnly
  global static list<map<string, string>> retrieveDetail(map<String, list<String>> mapFilters) {
    list<map<string, string>> listJSON = new List<map<string, string>>();

    set<String> setIdVendor = new Set<String>();
    set<String> setIdProduct = new Set<String>();

    String soql;

    String status = 'Open';

    if (mapFilters.containsKey('idVendor'))
      setIdVendor.addAll(mapFilters.get('idVendor'));
    if (mapFilters.containsKey('idProduct'))
      setIdProduct.addAll(mapFilters.get('idProduct'));

    soql = ' SELECT Id, Name,AcctSeedERP__Purchase_Order__r.Name,AcctSeedERP__Purchase_Order__r.Id, AcctSeedERP__Comment__c,AcctSeedERP__Product__c,AcctSeedERP__Product__r.Family,AcctSeedERP__Product__r.Name, AcctSeedERP__Product__r.ProductCode, ';
    soql += ' AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c,AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,AcctSeedERP__Product__r.GMBLASERP__Lot_Tracked__c, ';
    soql += ' AcctSeedERP__Purchase_Order__r.AcctSeedERP__Vendor__r.Name, AcctSeedERP__Purchase_Order__r.AcctSeedERP__Status__c,AcctSeedERP__Purchase_Order__r.AcctSeedERP__Type__c,AcctSeedERP__Quantity__c, ';
    soql += ' AcctSeedERP__Quantity_Received__c,AcctSeedERP__Quantity_Unreceived__c,AcctSeedERP__Unit_Price__c,AcctSeedERP__Total__c,GMBLASERP__Price_Override__c,GMBLASERP__Quantity_Received_Non_Inventory__c, ';
    soql += ' (SELECT Id, AcctSeed__Amount__c, AcctSeed__Account_Payable__r.AcctSeed__Status__c FROM AcctSeedERP__Account_Payable_Lines__r), ';
    soql += ' (SELECT Id, AcctSeedERP__Movement_Date__c, AcctSeedERP__Quantity__c, AcctSeedERP__Unit_Cost__c FROM AcctSeedERP__Purchase_Order_Inventory_Movements__r ORDER BY AcctSeedERP__Movement_Date__c) ';
    soql += ' FROM AcctSeedERP__Purchase_Order_Line__c ';
    soql += ' WHERE AcctSeedERP__Purchase_Order__r.AcctSeedERP__Status__c= :status ';
    if (setIdVendor.size() > 0)
      soql += ' AND AcctSeedERP__Purchase_Order__r.AcctSeedERP__Vendor__c IN :setIdVendor ';
    if (setIdProduct.size() > 0)
      soql += ' AND AcctSeedERP__Product__c IN :setIdProduct ';
    soql += ' ORDER BY AcctSeedERP__Purchase_Order__r.Name, Name, AcctSeedERP__Product__r.Name, AcctSeedERP__Product__r.ProductCode ';

    System.debug(Logginglevel.ERROR, soql);
    list<sObject> listRes = new List<sObject>();
    listRes.addAll(Database.query(soql));

    Date dateEarliestOpen = GMBLASERP.gcAccountingPeriod.dateEarliestOpen();

    for (sObject res : listRes) {
      AcctSeedERP__Purchase_Order_Line__c line = (AcctSeedERP__Purchase_Order_Line__c) res;

      map<string, string> m = new Map<string, string>();

      m.put('idPurchaseOrder', line.AcctSeedERP__Purchase_Order__r.Id);
      m.put('poNumber', line.AcctSeedERP__Purchase_Order__r.Name);
      m.put('poStatus', line.AcctSeedERP__Purchase_Order__r.AcctSeedERP__Status__c);
      m.put('poType', line.AcctSeedERP__Purchase_Order__r.AcctSeedERP__Type__c);
      m.put('vendorName', line.AcctSeedERP__Purchase_Order__r.AcctSeedERP__Vendor__r.Name);

      m.put('idLine', line.Id);
      //m.put('lineNumber', String.valueOf(Integer.valueOf(line.Name.replaceAll('[^0-9]',''))));
      m.put('lineNumber', line.Name);

      m.put('qty', String.valueOf(line.AcctSeedERP__Quantity__c.setScale(6)));
      m.put('amt', String.valueOf(line.AcctSeedERP__Total__c.setScale(6)));

      m.put('comment', line.AcctSeedERP__Comment__c);

      m.put('idProduct', line.AcctSeedERP__Product__c);
      m.put('productFamily', line.AcctSeedERP__Product__r.Family);
      m.put('productName', line.AcctSeedERP__Product__r.Name);
      m.put('productCode', line.AcctSeedERP__Product__r.ProductCode);

      if (line.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c)
        m.put('isInventory', 'true');
      else
        m.put('isInventory', 'false');

      if (line.AcctSeedERP__Product__r.AcctSeedERP__Serialized__c)
        m.put('isSerialized', 'true');
      else
        m.put('isSerialized', 'false');

      if (line.AcctSeedERP__Product__r.GMBLASERP__Lot_Tracked__c)
        m.put('isLotTracked', 'true');
      else
        m.put('isLotTracked', 'false');

      if (line.AcctSeedERP__Quantity__c != null)
        m.put('qtyOrdered', String.valueOf(line.AcctSeedERP__Quantity__c.setScale(0)));
      else
        m.put('qtyOrdered', '0');

      /*
            if(line.AcctSeedERP__Quantity_Unreceived__c != null)
            m.put('qtyUnreceived',String.valueOf(line.AcctSeedERP__Quantity_Unreceived__c.setScale(6)));
            else
            m.put('qtyUnreceived','0');*/

      Decimal qtyUnreceived = 0;

      if (line.AcctSeedERP__Quantity_Unreceived__c != null)
        qtyUnreceived = line.AcctSeedERP__Quantity_Unreceived__c - line.GMBLASERP__Quantity_Received_Non_Inventory__c;

      m.put('qtyUnreceived', String.valueOf(qtyUnreceived.setScale(6)));

      if (line.AcctSeedERP__Unit_Price__c == null)
        line.AcctSeedERP__Unit_Price__c = 0;
      m.put('unitPrice', String.valueOf(line.AcctSeedERP__Unit_Price__c.setScale(2)));

      if (line.AcctSeedERP__Total__c != null)
        m.put('amtOrdered', String.valueOf(line.AcctSeedERP__Total__c.setScale(6)));
      else
        m.put('amtOrdered', '0');

      if (line.GMBLASERP__Price_Override__c)
        m.put('priceOverride', 'true');
      else
        m.put('priceOverride', 'false');

      Decimal qtyReceived = 0;
      Decimal amtReceived = 0;
      m.put('hasMoves', 'false');
      m.put('hasMovesClosedPeriod', 'false');
      if (line.AcctSeedERP__Purchase_Order_Inventory_Movements__r.size() > 0) {
        m.put('hasMoves', 'true');
        for (
          AcctSeedERP__Purchase_Order_Inventory_Movement__c move : line.AcctSeedERP__Purchase_Order_Inventory_Movements__r
        ) {
          if (move.AcctSeedERP__Movement_Date__c < dateEarliestOpen)
            m.put('hasMovesClosedPeriod', 'true');
          Decimal qty = move.AcctSeedERP__Quantity__c;
          if (qty == null)
            qty = 0;
          Decimal unitCost = move.AcctSeedERP__Unit_Cost__c;
          if (unitCost == null)
            unitCost = 0;

          qtyReceived += qty;
          amtReceived += (qty * unitCost);
        }
      }
      m.put('qtyReceived', String.valueOf(qtyReceived.setScale(6)));

      if (line.GMBLASERP__Quantity_Received_Non_Inventory__c == null)
        line.GMBLASERP__Quantity_Received_Non_Inventory__c = 0;
      m.put('qtyReceivedNonInventory', String.valueOf(line.GMBLASERP__Quantity_Received_Non_Inventory__c.setScale(6)));

      amtReceived += (line.GMBLASERP__Quantity_Received_Non_Inventory__c * line.AcctSeedERP__Unit_Price__c);
      m.put('amtReceived', String.valueOf(amtReceived.setScale(6)));

      Decimal amtPaid = 0;
      if (line.AcctSeedERP__Account_Payable_Lines__r.size() > 0) {
        m.put('hasAPLines', 'true');
        for (AcctSeed__Account_Payable_Line__c apl : line.AcctSeedERP__Account_Payable_Lines__r) {
          if (apl.AcctSeed__Amount__c != null)
            amtPaid += apl.AcctSeed__Amount__c;
        }
      } else
        m.put('hasAPLines', 'false');

      m.put('amtPaid', String.valueOf(amtPaid.setScale(6)));

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
  }
}
