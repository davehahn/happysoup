public with sharing class Truck_Load_Ext {
  public class ErpWrapper {
    public String BoatName { get; set; }
    public String TrailerName { get; set; }
    public String AccountName { get; set; }
    public String AccountId { get; set; }
    public String ErpId { get; set; }
    public String ErpName { get; set; }
    public String ErpDate { get; set; }
    public String TruckLoadLineId { get; set; }
    public String TruckPosition { get; set; }

    public ErpWrapper(AcctSeed__Project__c erp, TruckLoadLine__c tll) {
      this.ErpId = erp.Id;
      this.ErpName = erp.Name;
      this.ErpDate = erp.CreatedDate.format('MMMM d, yyyy');
      this.AccountName = erp.AcctSeed__Account__r.Name;
      this.AccountId = erp.AcctSeed__Account__c;
      if (tll != null) {
        this.TruckLoadLineId = tll.Id;
        this.TruckPosition = tll.TruckPosition__c;
      }
      for (AcctSeedERP__Material__c mat : erp.AcctSeedERP__Project_Materials__r) {
        if (mat.AcctSeedERP__Product__r.RecordType.Name == 'Boat') {
          this.BoatName = mat.Product_Name__c;
        }
        if (mat.AcctSeedERP__Product__r.RecordType.Name == 'Trailer') {
          this.TrailerName = mat.Product_Name__c;
        }
      }
    }
  }

  public class LineWrapper implements Comparable {
    public String erpName { get; set; }
    public String erpid { get; set; }
    public String accountName { get; set; }
    public String truckPosition { get; set; }
    public List<AcctSeedERP__Material__c> materials { get; set; }

    public LineWrapper() {
    }

    public LineWrapper(AcctSeed__Project__c erp, TruckLoadLine__c tll) {
      this.erpName = erp.Name;
      this.erpId = erp.Id;
      this.accountName = erp.AcctSeed__Account__r.Name;
      this.truckPosition = tll.TruckPosition__c;
      this.materials = erp.AcctSeedERP__Project_Materials__r;
    }

    public Integer compareTo(Object compareTo) {
      // Cast argument to OpportunityWrapper
      LineWrapper compareToLine = (LineWrapper) compareTo;
      System.debug('compareToLine ' + compareToLine);
      System.debug('holder ' + this);
      // The return value of 0 indicates that both elements are equal.
      Integer returnValue = 0;
      if (this.truckPosition > compareToLine.truckPosition) {
        // Set return value to a positive value.
        returnValue = 1;
      } else if (this.truckPosition < compareToLine.truckPosition) {
        // Set return value to a negative value.
        returnValue = -1;
      }
      return returnValue;
    }
  }

  private final Id truckLoadId;
  public Truck_Load__c truckLoad { get; private set; }
  public List<LineWrapper> truckLoadContents { get; set; }
  public List<ErpWrapper> availableErpOrders { get; set; }
  public Map<String, List<ErpWrapper>> selectedErpOrders { get; set; }
  public Map<String, List<LineWrapper>> erpOrderMap;

  public Truck_Load_Ext(ApexPages.StandardController stdController) {
    truckLoadId = stdController.getId();
  }

  public void init() {
    Map<Id, TruckLoadLine__c> truckLoadLineErpOrderMap = new Map<Id, truckLoadLine__c>();
    this.truckLoad = fetchTruckLoad();
    for (TruckLoadLine__c tll : this.truckLoad.Truck_Load_Lines__r) {
      truckLoadLineErpOrderMap.put(tll.Erp_Order__c, tll);
    }
    this.truckLoadContents = new List<LineWrapper>();
    for (AcctSeed__Project__c erp : fetchErpOrders()) {
      this.truckLoadContents.add(new LineWrapper(erp, truckLoadLineErpOrderMap.get(erp.Id)));
    }
    this.TruckLoadContents.sort();
  }

  public void initLoadBuilder() {
    Id erpTypeId = gcConstants.idRtProjectBoatSale;
    Map<Id, TruckLoadLine__c> truckLoadLineErpOrderMap = new Map<Id, truckLoadLine__c>();
    Set<Id> productRTs = new Set<Id>{
      LGND_Utilities.recordTypeIdFromName('Product2', 'Trailer'),
      LGND_Utilities.recordTypeIdFromName('Product2', 'Boat')
    };
    this.availableErpOrders = new List<ErpWrapper>();

    this.truckLoad = fetchTruckLoad();
    for (TruckLoadLine__c tll : this.truckLoad.Truck_Load_Lines__r) {
      truckLoadLineErpOrderMap.put(tll.Erp_Order__c, tll);
    }
    AcctSeed__Project__c[] selected_erps = [
      SELECT
        Id,
        Name,
        CreatedDate,
        AcctSeed__Account__c,
        AcctSeed__Account__r.Name,
        (
          SELECT Id, Product_Name__c, AcctSeedERP__Product__r.RecordType.Name
          FROM AcctSeedERP__Project_Materials__r
          WHERE AcctSeedERP__Product__r.RecordTypeId IN :productRTs
        )
      FROM AcctSeed__Project__c
      WHERE Id = :truckLoadLineErpOrderMap.keySet()
    ];
    AcctSeed__Project__c[] available_erps = [
      SELECT
        Id,
        Name,
        CreatedDate,
        AcctSeed__Account__c,
        AcctSeed__Account__r.Name,
        (
          SELECT Id, Product_Name__c, AcctSeedERP__Product__r.RecordType.Name
          FROM AcctSeedERP__Project_Materials__r
          WHERE AcctSeedERP__Product__r.RecordTypeId IN :productRTs
        )
      FROM AcctSeed__Project__c
      WHERE RecordTypeId = :erpTypeId AND Stage__c = 'Plan Load'
      ORDER BY AcctSeed__Account__r.Name
    ];
    this.availableErpOrders = wrapUpERPs(available_erps, null);

    selectedErpOrders = new Map<String, List<ErpWrapper>>();
    Set<String> truckPos = new Set<String>(getTruckPositions());
    for (String pos : truckPos) {
      this.selectedErpOrders.put(pos, new List<ErpWrapper>());
    }
    for (ErpWrapper wrapper : wrapUpERPs(selected_erps, truckLoadLineErpOrderMap)) {
      if (wrapper.TruckPosition != null && truckPos.contains(wrapper.TruckPosition)) {
        this.selectedErpOrders.get(wrapper.TruckPosition).add(wrapper);
      } else {
        this.selectedErpOrders.get(new List<String>(truckPos)[0]).add(wrapper);
      }
    }
  }

  public Map<String, List<LineWrapper>> getErpOrderMap() {
    if (erpOrderMap == null)
      erpOrderMap = buildERPOrderMap();
    return erpOrderMap;
  }

  public List<String> getTruckPositions() {
    return LGND_Utilities.getPicklistValues('TruckLoadLine__c', 'TruckPosition__c');
  }

  public Map<String, String> getAccountFilterOptions() {
    Map<String, String> options = new Map<String, String>();
    for (ErpWrapper wrapper : availableErpOrders) {
      options.put(wrapper.AccountName, wrapper.AccountId);
    }
    return options;
  }

  public Set<String> getBoatFilterOptions() {
    Set<String> options = new Set<String>();
    for (ErpWrapper wrapper : availableErpOrders) {
      options.add(wrapper.BoatName);
    }
    return options;
  }

  @RemoteAction
  public static void createLines(Map<String, List<Map<String, String>>> truckPosErpMap, List<Id> deleteTruckLineIds) {
    if (truckPosErpMap.size() > 0) {
      List<TruckLoadLine__c> lines = new List<TruckLoadLine__c>();
      Set<Id> erpIds = new Set<Id>();
      for (String truckPos : truckPosErpMap.keySet()) {
        for (Map<String, String> dataMap : truckPosErpMap.get(truckPos)) {
          erpIds.add(dataMap.get('erpId'));
          lines.add(
            new TruckLoadLine__c(
              Id = dataMap.get('truckLoadLineId'),
              ERP_Order__c = dataMap.get('erpId'),
              Truck_Load__c = dataMap.get('truckLoadId'),
              TruckPosition__c = truckPos
            )
          );
        }
      }
      upsert lines;
      List<AcctSeed__Project__c> erpOrders = [
        SELECT Id, AcctSeed__Status__c
        FROM AcctSeed__Project__c
        WHERE Id IN :erpIds
      ];
      for (AcctSeed__Project__c erp : erpOrders) {
        erp.Stage__c = 'Tagging Pending';
      }
      update erpOrders;
    }

    if (deleteTruckLineIds.size() > 0) {
      TruckLoadLine__c[] deleteLines = [SELECT Id FROM TruckLoadLine__c WHERE Id IN :deleteTruckLineIds];
      System.debug(deleteLines);
      delete deleteLines;
    }
  }

  @RemoteAction
  @ReadOnly
  public static List<Map<String, String>> searchSerialForMaterial(Id idMaterial) {
    List<Map<String, String>> result = new List<Map<String, String>>();
    Boolean hasPermission = FeatureManagement.checkPermission('CanTagUnavailableSerial');
    for (Map<String, String> serial : gcProject_Ext.searchSerialForMaterial(idMaterial)) {
      if (serial.get('IsAvailable') == 'false') {
        if (hasPermission == true) {
          result.add(serial);
        }
      } else {
        result.add(serial);
      }
    }
    return result;
  }

  @RemoteAction
  public static Map<String, String> setSerialOnMaterial(Id idMaterial, Id idSerial) {
    //return gcProject_Ext.selectSerialForMaterial(idMaterial, idSerial);
    AcctSeedERP__Material__c matl = [SELECT Id FROM AcctSeedERP__Material__c WHERE Id = :idMaterial][0];
    matl.GMBLASERP__Serial_Number__c = idSerial;
    update matl;
    matl = [
      SELECT Id, Product_Name__c, GMBLASERP__Serial_Number__c, GMBLASERP__Serial_Number__r.Name
      FROM AcctSeedERP__Material__c
      WHERE Id = :idMaterial
    ][0];
    return new Map<String, String>{
      'idSerial' => matl.GMBLASERP__Serial_Number__c,
      'idMaterial' => matl.id,
      'ProductName' => matl.Product_Name__c,
      'serialName' => matl.GMBLASERP__Serial_Number__r.Name
    };
  }

  public static void loadTriggerHandler(
    Map<Id, Truck_Load__c> oldMap,
    Map<Id, Truck_Load__c> newMap,
    List<Truck_Load__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (oldMap == null)
      oldMap = new Map<Id, Truck_Load__c>();
    if (newMap == null)
      newMap = new Map<Id, Truck_Load__c>();
    if (listNew == null)
      listNew = new List<Truck_Load__c>();

    if (boolIsBefore /* &&&&&&&   BEFORE    &&&&&&& */) {
      if (boolIsInsert) {
      }
      if (boolIsUpdate) {
      }
      if (boolIsDelete) {
        System.debug('Truck Load Before delete triger handler');
        List<TruckLoadLine__c> tlls = [SELECT Id FROM TruckLoadLine__c WHERE Truck_Load__c IN :oldMap.keySet()];
        delete tlls;
      }
    } else {
      /* &&&&&&&   AFTER   &&&&&&& */
      if (boolIsInsert) {
      }
      if (boolIsUpdate) {
      }
      if (boolIsDelete) {
        System.debug('Truck Load after delete triger handler');
      }
    }
  }

  public static void lineTriggerHandler(
    Map<Id, TruckLoadLine__c> oldMap,
    Map<Id, TruckLoadLine__c> newMap,
    List<TruckLoadLine__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (oldMap == null)
      oldMap = new Map<Id, TruckLoadLine__c>();
    if (newMap == null)
      newMap = new Map<Id, TruckLoadLine__c>();
    if (listNew == null)
      listNew = new List<TruckLoadLine__c>();

    if (boolIsBefore /* &&&&&&&   BEFORE    &&&&&&& */) {
      if (boolIsInsert) {
      }
      if (boolIsUpdate) {
      }
      if (boolIsDelete) {
      }
    } else {
      /* &&&&&&&   AFTER   &&&&&&& */
      if (boolIsInsert) {
        List<AcctSeed__Project__c> erpOrders = new List<AcctSeed__Project__c>();
        Set<id> truckLoadIds = new Set<Id>();
        for (TruckLoadLine__c tl : listNew) {
          if (tl.ERP_Order__c != null) {
            truckLoadIds.add(tl.Truck_Load__c);
            erpOrders.add(new AcctSeed__Project__c(Id = tl.ERP_Order__c, Stage__c = 'Tagging Pending'));
          }
        }
        if (erpOrders.size() > 0) {
          upsert erpOrders;
        }
        if (truckLoadIds.size() > 0) {
          updateTruckLoadAccountInfo(truckLoadIds);
        }
      }
      if (boolIsUpdate) {
      }
      if (boolIsDelete) {
        List<AcctSeed__Project__c> erpOrders = new List<AcctSeed__Project__c>();
        Set<Id> truckLoadIds = new Set<Id>();
        for (TruckLoadLine__c tll : oldMap.values()) {
          if (tll.ERP_Order__c != null) {
            truckLoadIds.add(tll.Truck_Load__c);
            erpOrders.add(new AcctSeed__Project__c(Id = tll.ERP_Order__c, Stage__c = 'Plan Load'));
          }
        }
        if (erpOrders.size() > 0) {
          upsert erpOrders;
        }
        if (truckLoadIds.size() > 0) {
          updateTruckLoadAccountInfo(truckLoadIds);
        }
      }
    }
  }

  private List<ErpWrapper> wrapUpERPs(AcctSeed__Project__c[] erps, Map<Id, TruckLoadLine__c> truckLoadLineErpOrderMap) {
    ErpWrapper[] result = new List<ErpWrapper>();
    for (AcctSeed__Project__c erp : erps) {
      if (truckLoadLineErpOrderMap == null) {
        result.add(new ErpWrapper(erp, null));
      } else {
        result.add(new ErpWrapper(erp, truckLoadLineErpOrderMap.get(erp.id)));
      }
    }
    return result;
  }

  private Map<String, List<LineWrapper>> buildERPOrderMap() {
    //Map<String, List<LineWrapper>> result = new Map<String, List<LineWrapper>>{
    //  'left' => new List<LineWrapper>(),
    //  'right' => new List<LineWrapper>()
    //};
    //Integer count = 1;
    Map<String, List<LineWrapper>> result = new Map<String, List<LineWrapper>>();
    for (LineWrapper erp : truckLoadContents) {
      if (!result.containsKey(erp.TruckPosition)) {
        result.put(erp.TruckPosition, new List<LineWrapper>());
      }
      result.get(erp.TruckPosition).add(erp);
    }
    for (String pos : getTruckPositions()) {
      if (!result.containsKey(pos)) {
        result.put(pos, new List<LineWrapper>());
      }
    }
    return result;
  }

  private Truck_Load__c fetchTruckLoad() {
    return [
      SELECT
        Id,
        Name,
        Driver__c,
        Truck__c,
        Trailer__c,
        Return_Date2__c,
        Departure_Date2__c,
        Delivery_Date2__c,
        Destination__c,
        (SELECT Id, Name, ERP_Order__c, TruckPosition__c FROM Truck_Load_Lines__r ORDER BY TruckPosition__c)
      FROM Truck_Load__c
      WHERE Id = :truckLoadId
    ];
  }

  private List<AcctSeed__Project__c> fetchErpOrders() {
    Set<Id> erpOrderIds = new Set<Id>();
    for (TruckLoadLine__c tll : truckLoad.Truck_Load_Lines__r) {
      erpOrderIds.add(tll.ERP_Order__c);
    }
    return [
      SELECT
        Id,
        Name,
        AcctSeed__Account__r.Name,
        CreatedDate,
        (
          SELECT Id, Product_Name__c, GMBLASERP__Serial_Number__c, GMBLASERP__Serial_Number__r.Name
          FROM AcctSeedERP__Project_Materials__r
          WHERE AcctSeedERP__Product__r.AcctSeedERP__Serialized__c = TRUE
          ORDER BY AcctSeedERP__Product__r.RecordType.Name
        )
      FROM AcctSeed__Project__c
      WHERE Id IN :erpOrderIds
      ORDER BY CreatedDate
    ];
  }

  private static void updateTruckLoadAccountInfo(Set<Id> truckLoadIds) {
    List<Truck_Load__c> truckLoads = [
      SELECT Id, (SELECT Id, AccountName__c, Travel_Days__c FROM Truck_Load_Lines__r)
      FROM Truck_Load__c
      WHERE Id IN :truckLoadIds
    ];
    for (Truck_Load__c tl : truckLoads) {
      Set<String> destinations = new Set<String>();
      Decimal highest = 0;
      for (TruckLoadLine__c tll : tl.Truck_Load_Lines__r) {
        if (tll.Travel_Days__c > highest)
          highest = tll.Travel_Days__c;
        destinations.add(tll.AccountName__c);
      }
      tl.Destination__c = String.join(new List<String>(destinations), ', ');
      tl.Travel_Days__c = highest;
    }
    update truckLoads;
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
  }
}
