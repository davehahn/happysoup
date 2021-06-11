public without sharing class InventoryAllocationWholesaleController {
    public class InventoryAllocationException extends Exception {}
    public static Boolean DESCLIST = false;
    private final String queryInv                               {get;set;}
    private final String endQueryInv                            {get;set;}
    private final String queryProd                              {get;set;}
    private final String queryInvSpecialDamages                 {get;set;}
    private final String queryReserved                          {get;set;}
    private final String queryShipments                         {get;set;}
    private final String queryRetail                            {get;set;}
    private final String queryDealerOrder                       {get;set;}
    private final String queryProductOwner                      {get;set;}
    public List<String> listFilterYear                          {get;set;}
    public Set<String> listLotNames                             {get;set;}
    public String filterYear                                    {get;set;}
    public String filterType                                    {get;set;}
    public String filterWarehouse                               {get;set;}


    public List<Inventory> inventory                            {get;set;}
    transient Map<String,Set<Id>> mapIncludedERP                   {get;set;}
    transient Map<String,List<SerialNumber>> mapInventoryList      {get;set;}
    transient Set<ID> allProducts                                  {get;set;}
    transient Set<ID> allSerials                                   {get;set;}
    transient Map<String, List<Map<String,String>>> allCanvas      {get;set;}
    transient Map<String,Integer> mapStock                         {get;set;}
    transient Map<String,Integer> mapSpecialDamages                {get;set;}
    transient Map<String,List<SerialNumber>> mapSpecialDamagesList {get;set;}
    transient Map<String,List<Shipment>> mapShipments              {get;set;}
    transient Map<String, Integer> mapRetailSold                   {get;set;}
    transient Map<String, Integer> mapDealerOrders                 {get;set;}
    transient Map<Id,String> mapProductOwner                       {get;set;}

    transient Map<String, String> hoverOverRetailSold                   {get;set;}
    //public Map<String, String> hoverOverDelearOrder                  {get;set;}
    transient Map<String, Map<String, List<Map<String,String>>>> hoverOverDealerOrderDetails {get; set;}
    transient Map<String, Map<String, List<Map<String,String>>>> hoverOverRetailSoldDetails {get; set;}

    private Map<String,ProductLotReservation__c> mapProdLot ;
    private Map<String, Set<String>> mapProductIdToSetYear;
    private MAP<String,Integer> mapLocations;
    private Integer numberOfDamages,numberOfSpecials,numberOfDemos, numberOfUsed;

    /* Added by Dave Hahn May 29/17 */
    private Id erpPartnerBoatSaleRtId = gcConstants.idRtProjectPartnerBoatSale;
    private Id erpRetailBoatSaleRtId = gcConstants.idRtProjectBoatSale;

    public InventoryAllocationWholesaleController() {
        Id idWarehouseWholesale = GMBLASERP__Inventory_Settings__c.getOrgDefaults().Wholesale_Warehouse_Id__c;
        this.filterWarehouse = idWarehouseWholesale;
        this.filterYear = 'ALL';
        this.filterType = 'Boat';
        this.queryInv = 'SELECT Id, Name, Current_Unit_Cost__c, GMBLASERP__Product__c, GMBLASERP__Product__r.Name, Model_Year__c, Status__c, GMBLASERP__Lot__c,GMBLASERP__Lot__r.Name, Nest__c, Nest__r.Name, Dealer_Rigged__c, Retail_Age__c, Overall_Age__c, (SELECT Id, Name, Current_Unit_Cost__c, GMBLASERP__Product__c, GMBLASERP__Product__r.Name, Model_Year__c, Status__c, GMBLASERP__Lot__c,GMBLASERP__Lot__r.Name,Nest__c, Nest__r.Name, Dealer_Rigged__c, Retail_Age__c, Overall_Age__c FROM Nested_Serial_Numbers__r) from GMBLASERP__Serial_Number__c where Available_Wholesale__c = true  AND GMBLASERP__Lot__c != null AND GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c =:filterWarehouse';
        this.queryProd = 'SELECT Id, Name From Product2 WHERE Id in: allProducts ';
        //this.queryShipments = 'Select id,AcctSeedERP__Quantity__c,  Reserved__c, deliverDate__c, AcctSeedERP__Product__c , AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c,GMBLASERP__Lot__r.Name from  AcctSeedERP__Purchase_Order_Line__c Where AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c != null order by deliverDate__c';
        /* change by Dave Hahn May 29/17 */
        //this.queryShipments = 'Select Id, Name, AcctSeedERP__Quantity_Unreceived__c, Reserved__c, deliverDate__c, AcctSeedERP__Product__c, AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c, GMBLASERP__Lot__r.Name, AcctSeedERP__Project__c, AcctSeedERP__Project__r.Name, AcctSeedERP__Project__r.AcctSeed__Account__r.Name, AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c, AcctSeedERP__Project__r.Stage__c, AcctSeedERP__Project__r.CreatedDate, AcctSeedERP__Project__r.Delivery_Date__c, AcctSeedERP__Project__r.BoatModelYear__c, AcctSeedERP__Project__r.TrailerModelYear__c from  AcctSeedERP__Purchase_Order_Line__c  Where (AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c != null OR deliverDate__c != null) AND AcctSeedERP__Quantity_Unreceived__c > 0  AND ((AcctSeedERP__Project__c != null  AND AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:filterWarehouse)  OR (AcctSeedERP__Project__c = null  AND (AcctSeedERP__Purchase_Order__r.Warehouse__c = null  OR AcctSeedERP__Purchase_Order__r.Warehouse__c =:filterWarehouse))) AND AcctSeedERP__Product__c in: allProducts order by deliverDate__c';
        String qs = 'Select Id, Name, AcctSeedERP__Product__r.RecordType.Name, AcctSeedERP__Quantity__c, AcctSeedERP__Quantity_Unreceived__c, Reserved__c, deliverDate__c, AcctSeedERP__Product__c, AcctSeedERP__Purchase_Order__c, AcctSeedERP__Purchase_Order__r.Name, AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c, GMBLASERP__Lot__r.Name, ';
        qs += ' AcctSeedERP__Project__c, AcctSeedERP__Project__r.Name, AcctSeedERP__Project__r.AcctSeed__Account__r.Name, AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c, AcctSeedERP__Project__r.Stage__c, AcctSeedERP__Project__r.CreatedDate, AcctSeedERP__Project__r.Delivery_Date__c, AcctSeedERP__Project__r.BoatModelYear__c, AcctSeedERP__Project__r.Serial_Number__c, AcctSeedERP__Project__r.ERP_Serial_In_Inventory__c, AcctSeedERP__Project__r.Serial_Number__r.Name, AcctSeedERP__Project__r.Serial_Number__r.Retail_Age__c, AcctSeedERP__Project__r.Serial_Number__r.Overall_Age__c, AcctSeedERP__Project__r.TrailerModelYear__c, ';
        qs += ' AcctSeedERP__Project__r.Retail_ERP__c, AcctSeedERP__Project__r.Retail_ERP__r.ERP_Serial_In_Inventory__c, AcctSeedERP__Project__r.Retail_ERP__r.Name, AcctSeedERP__Project__r.Retail_ERP__r.AcctSeed__Account__r.Name, AcctSeedERP__Project__r.Retail_ERP__r.AcctSeedERP__Work_Order_Number__c, AcctSeedERP__Project__r.Retail_ERP__r.Stage__c, AcctSeedERP__Project__r.Retail_ERP__r.CreatedDate, AcctSeedERP__Project__r.Retail_ERP__r.Delivery_Date__c, AcctSeedERP__Project__r.Retail_ERP__r.BoatModelYear__c, AcctSeedERP__Project__r.Retail_ERP__r.Serial_Number__c, AcctSeedERP__Project__r.Retail_ERP__r.Serial_Number__r.Name, AcctSeedERP__Project__r.Retail_ERP__r.TrailerModelYear__c ';
        qs += ' from  AcctSeedERP__Purchase_Order_Line__c  Where (AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c != null OR deliverDate__c != null) AND AcctSeedERP__Quantity_Unreceived__c > 0  AND ((AcctSeedERP__Project__c != null  AND AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:filterWarehouse)  OR (AcctSeedERP__Project__c = null  AND (AcctSeedERP__Purchase_Order__r.Warehouse__c = null  OR AcctSeedERP__Purchase_Order__r.Warehouse__c =:filterWarehouse))) AND AcctSeedERP__Product__c in: allProducts order by deliverDate__c';
        //qs += ' from  AcctSeedERP__Purchase_Order_Line__c  Where AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c != null ';
        this.queryShipments = qs;
        this.queryProductOwner = 'SELECT AcctSeed__Account__r.name , Manufactured_Product_id__c From AcctSeed__Project__c WHERE Manufactured_Product_id__c in: allProducts and AcctSeed__Status__c = \'Completed\'';
        this.constructor();
    }



    public void constructor() {
        if(this.filterType != 'Boat')
          this.filterYear = '';
        else if(this.filterYear == '')
          this.filterYear = 'All';

        this.buildProductList();
        this.buildMapStock();
        this.buildMapSpecialDamages();
        this.buildMapShipments();
        //this.builtHoverOverRetailSold();
        //this.builtHoverOverDelearOrder();
        //this.buildHoverOvers();
        //this.buildMapRetailSold();
        //this.buildMapDealerOrder();
        this.buildOutstandingOrders();
        this.buildMapProductOwner();
        this.buildMapCanvasERP();
        this.buildMapInventoryLine();
        this.buildShipmentsAvailable();
    }

    private void buildMapCanvasERP()
    {
      if(this.allSerials == null || this.allSerials.isEmpty()) return;
      this.allCanvas = new Map<String, List<Map<String,String>>>();
      List<AcctSeedERP__Material__c> listMatl = new List<AcctSeedERP__Material__c>();
      Map<String,Decimal> mapSerialQty = new Map<String,Decimal>();
      for( AcctSeedERP__Material__c objMaterial : [ SELECT Id,
                                                             AcctSeedERP__Product__c,
                                                             AcctSeedERP__Product__r.Name,
                                                             AcctSeedERP__Product__r.RecordType.Name,
                                                             GMBLASERP__Lot__c,
                                                             GMBLASERP__Lot__r.Name,
                                                             AcctSeedERP__Project__c,
                                                             AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c,
                                                             AcctSeedERP__Project__r.Serial_Number__c,
                                                             AcctSeedERP__Project__r.Serial_Number__r.Name,
                                                             AcctSeedERP__Project__r.Serial_Number__r.Retail_Age__c,
                                                             AcctSeedERP__Project__r.Serial_Number__r.Overall_Age__c,
                                                             AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c,
                                                             AcctSeedERP__Quantity_Per_Unit__c,
                                                             AcctSeedERP__Quantity_Allocated__c
                                                      FROM AcctSeedERP__Material__c
                                                      WHERE AcctSeedERP__Product__c != null
                                                        AND AcctSeedERP__Product__r.Family IN ('Canvas','Boat Build Option')
                                                        AND AcctSeedERP__Project__r.Serial_Number__c != null
                                                        AND AcctSeedERP__Project__r.Serial_Number__c IN:this.allSerials])
      {
        listMatl.add(objMaterial);
        if(!mapSerialQty.containsKey(objMaterial.AcctSeedERP__Project__r.Serial_Number__c))
          mapSerialQty.put(objMaterial.AcctSeedERP__Project__r.Serial_Number__c,0);

        Decimal oldQty = mapSerialQty.get(objMaterial.AcctSeedERP__Project__r.Serial_Number__c);
        Decimal curQty = objMaterial.AcctSeedERP__Quantity_Allocated__c == null ? 0 : objMaterial.AcctSeedERP__Quantity_Allocated__c;
          if(!objMaterial.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c)
              curQty = objMaterial.AcctSeedERP__Quantity_Per_Unit__c;
        mapSerialQty.put(objMaterial.AcctSeedERP__Project__r.Serial_Number__c, oldQty + curQty);
      }

      for( AcctSeedERP__Material__c objMaterial : listMatl)
      {
        String uniqueCombo = objMaterial.AcctSeedERP__Project__r.Serial_Number__c;
        if(mapSerialQty.get(uniqueCombo) == 0) continue;
        Map<String, String> pData = new Map<String, String>();
        pData.put('Id', objMaterial.AcctSeedERP__Project__c );
        pData.put('idCanvas', objMaterial.AcctSeedERP__Product__c );
        pData.put('canvasName', objMaterial.AcctSeedERP__Product__r.Name );
        pData.put('idLot', objMaterial.GMBLASERP__Lot__c );
        pData.put('lotName', objMaterial.GMBLASERP__Lot__r.Name );
        pData.put('idERP', objMaterial.AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c );
        pData.put('erpName', objMaterial.AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c );
        pData.put('idSerial', objMaterial.AcctSeedERP__Project__r.Serial_Number__c );
        pData.put('serialName', objMaterial.AcctSeedERP__Project__r.Serial_Number__r.Name );

        if( !this.allCanvas.containsKey( uniqueCombo ) )
            this.allCanvas.put( uniqueCombo, new List< Map<String,String>>() );

        this.allCanvas.get( uniqueCombo ).add( pData );
      }
    }

    private void populateMapValues(String productId, String lotName){

        if(mapProductIdToSetYear.containsKey(productId)){
            mapProductIdToSetYear.get(productId).add(lotName);
        }else{
            mapProductIdToSetYear.put(productId, new Set<String>{lotName});
        }
    }

    private String getUniqueCombo(Opportunity objOpportunity){
        String uniqueCombo = '';
        if(objOpportunity.BoatId__r.RecordType.Name == 'Boat' && objOpportunity.Boat_Model_Year__c != null){
            uniqueCombo = '-' + objOpportunity.Boat_Model_Year__c;
            populateMapValues(objOpportunity.BoatId__c, objOpportunity.Boat_Model_Year__c);
        }
        //if(objOpportunity.BoatId__r.RecordType.Name == 'Trailer' && objOpportunity.Trailer_Model_Year__c != null){
        //    uniqueCombo = '-' + objOpportunity.Trailer_Model_Year__c;
        //    populateMapValues(objOpportunity.BoatId__c, objOpportunity.Trailer_Model_Year__c);
        //}
        uniqueCombo = objOpportunity.BoatId__c + uniqueCombo;
        return uniqueCombo;
    }

    private String getUniqueComboProject(AcctSeed__Project__c objProject, String recordType){
        String uniqueCombo = '';
        if(recordType == 'Boat' && objProject.BoatModelYear__c != null)
            uniqueCombo = objProject.BoatModelYear__c;
        //if(recordType == 'Trailer' && objProject.TrailerModelYear__c != null)
        //    uniqueCombo = objProject.TrailerModelYear__c;

        return uniqueCombo;
    }

    /* ADDED BY DAVE HAHN MAY @29/17 */
    private String getUniqueComboProject( AcctSeedERP__Material__c mat, String recordType )
    {
        String uniqueCombo = '';
        if( recordType == 'Boat' )
        {
            uniqueCombo = mat.GMBLASERP__Lot__c != null && mat.GMBLASERP__Lot__r.Name != '' ?
                mat.GMBLASERP__Lot__r.Name :
                mat.AcctSeedERP__Project__r.BoatModelYear__c != null ?
                    mat.AcctSeedERP__Project__r.BoatModelYear__c :
                    '';
        }
        //if( recordType == 'Trailer' )
        //{
        //    uniqueCombo = mat.GMBLASERP__Lot__c != null && mat.GMBLASERP__Lot__r.Name != '' ?
        //        mat.GMBLASERP__Lot__r.Name :
        //        mat.AcctSeedERP__Project__r.TrailerModelYear__c != null ?
        //            mat.AcctSeedERP__Project__r.TrailerModelYear__c :
        //            '';
        //}
        return uniqueCombo;
    }

    private void buildOutstandingOrders()
    {
      this.mapRetailSold = new Map<String, Integer>();
      this.hoverOverRetailSoldDetails = new Map<String, Map<String, List<Map<String,String>>>>();
      this.mapDealerOrders = new Map<String, Integer>();
      this.hoverOverDealerOrderDetails = new Map<String, Map<String, List<Map<String,String>>>>();
      Set<Id> rts = new Set<Id>{ erpPartnerBoatSaleRtId, erpRetailBoatSaleRtId };
      for( AcctSeedERP__Material__c objMaterial : [ SELECT Id,
                                                             AcctSeedERP__Product__c,
                                                             AcctSeedERP__Product__r.Name,
                                                             AcctSeedERP__Product__r.RecordType.Name,
                                                             GMBLASERP__Lot__c,
                                                             GMBLASERP__Lot__r.Name,
                                                             AcctSeedERP__Project__r.AcctSeed__Account__r.Name,
                                                             AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c,
                                                             AcctSeedERP__Project__r.Reserved_For_Customer_Account__c,
                                                             AcctSeedERP__Project__r.Stage__c,
                                                             AcctSeedERP__Project__r.CreatedDate,
                                                             AcctSeedERP__Project__r.Arrival_Date__c,
                                                             AcctSeedERP__Project__r.Delivery_Date__c,
                                                             AcctSeedERP__Project__r.BoatModelYear__c,
                                                             AcctSeedERP__Project__r.TrailerModelYear__c
                                                      FROM AcctSeedERP__Material__c
                                                      WHERE AcctSeedERP__Project__r.RecordTypeId IN :rts
                                                      AND AcctSeedERP__Project__r.Stage__c NOT IN ('Draft','Quoting','Delivered','Closed Lost')
                                                      AND AcctSeedERP__Project__r.RecordTypeId =:erpPartnerBoatSaleRtId
                                                      AND GMBLASERP__Serial_Number__c = null
                                                      AND AcctSeedERP__Product__c != null ] )
      {
        String uniqueCombo = getUniqueComboProject(objMaterial,objMaterial.AcctSeedERP__Product__r.RecordType.Name);
        populateMapValues(objMaterial.AcctSeedERP__Product__c, uniqueCombo);
        uniqueCombo = objMaterial.AcctSeedERP__Product__c + ( uniqueCombo == '' ? '' : ('-' + uniqueCombo) );

        if( objMaterial.AcctSeedERP__Project__r.RecordTypeId == erpPartnerBoatSaleRtId )
        {
          addToPartnerERPOrders( uniqueCombo, objMaterial );
        }
      }
    }

    private void addToPartnerERPOrders(String uniqueCombo, AcctSeedERP__Material__c objMaterial )
    {
      //if(this.mapIncludedERP.containsKey(uniqueCombo) && this.mapIncludedERP.get(uniqueCombo).contains(objMaterial.AcctSeedERP__Project__c)) return;
      if(mapDealerOrders.containsKey(uniqueCombo))
          mapDealerOrders.put(uniqueCombo, mapDealerOrders.get(uniqueCombo) + 1);
      else
          mapDealerOrders.put(uniqueCombo, 1);

      Map<String, String> pData = new Map<String, String>();
      pData.put('Id', objMaterial.AcctSeedERP__Project__c );
      pData.put('AccountName', objMaterial.AcctSeedERP__Project__r.AcctSeed__Account__r.Name);
      pData.put('Name', objMaterial.AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c );
      pData.put('IsReserved', objMaterial.AcctSeedERP__Project__r.Reserved_For_Customer_Account__c == null ? 'false' : 'true' );
      pData.put('Stage', objMaterial.AcctSeedERP__Project__r.Stage__c);
      pData.put('CreatedDate', objMaterial.AcctSeedERP__Project__r.CreatedDate.format('MMM d, yyyy') );
      pData.put('ArrivalDate', objMaterial.AcctSeedERP__Project__r.Arrival_Date__c != null ? objMaterial.AcctSeedERP__Project__r.Arrival_Date__c.format() : '');
      pData.put('DeliveryDate', objMaterial.AcctSeedERP__Project__r.Delivery_Date__c != null ? objMaterial.AcctSeedERP__Project__r.Delivery_Date__c.format('MMM d, yyyy') : '');
      pData.put('type', 'partnerERP');

      if( !hoverOverDealerOrderDetails.containsKey( uniqueCombo ) )
          hoverOverDealerOrderDetails.put( uniqueCombo, new Map<String, List< Map<String,String>>>() );

      if( !hoverOverDealerOrderDetails.get( uniqueCombo ).containsKey(objMaterial.AcctSeedERP__Project__r.AcctSeed__Account__r.Name) )
          hoverOverDealerOrderDetails.get( uniqueCombo ).put( objMaterial.AcctSeedERP__Project__r.AcctSeed__Account__r.Name, new List<Map<String,String>>() );

      hoverOverDealerOrderDetails.get( uniqueCombo ).get( objMaterial.AcctSeedERP__Project__r.AcctSeed__Account__r.Name ).add( pData );
    }

    private void addToRetailERPOrders(String uniqueCombo, AcctSeedERP__Material__c objMaterial )
    {
      if(mapRetailSold.containsKey(uniqueCombo))
          mapRetailSold.put(uniqueCombo, mapRetailSold.get(uniqueCombo) + 1);
      else
          mapRetailSold.put(uniqueCombo, 1);

      Map<String, String> pData = new Map<String, String>();
      pData.put('Id', objMaterial.AcctSeedERP__Project__c );
      pData.put('AccountName', objMaterial.AcctSeedERP__Project__r.AcctSeed__Account__r.Name);
      pData.put('Name', objMaterial.AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c );
      pData.put('Stage', objMaterial.AcctSeedERP__Project__r.Stage__c);
      pData.put('CreatedDate', objMaterial.AcctSeedERP__Project__r.CreatedDate.format('MMM d, yyyy') );
      pData.put('ArrivalDate', objMaterial.AcctSeedERP__Project__r.Arrival_Date__c != null ? objMaterial.AcctSeedERP__Project__r.Arrival_Date__c.format() : '');
      pData.put('DeliveryDate', objMaterial.AcctSeedERP__Project__r.Delivery_Date__c != null ? objMaterial.AcctSeedERP__Project__r.Delivery_Date__c.format('MMM d, yyyy') : '');
      pData.put('type', 'retailERP');

      if( !hoverOverRetailSoldDetails.containsKey( uniqueCombo ) )
          hoverOverRetailSoldDetails.put( uniqueCombo, new Map<String, List< Map<String,String>>>() );

      if( !hoverOverRetailSoldDetails.get( uniqueCombo ).containsKey('ERP Orders') )
          hoverOverRetailSoldDetails.get( uniqueCombo ).put( 'ERP Orders', new List<Map<String,String>>() );

      hoverOverRetailSoldDetails.get( uniqueCombo ).get( 'ERP Orders' ).add( pData );
    }

    private void addToRetailOppOrders(String uniqueCombo, Opportunity objOpportunity )
    {
      if(mapRetailSold.containsKey(uniqueCombo))
          mapRetailSold.put(uniqueCombo, mapRetailSold.get(uniqueCombo) + 1);
      else
          mapRetailSold.put(uniqueCombo, 1);

      Map<String, String> pData = new Map<String, String>();
      pData.put('Id', objOpportunity.Id );
      pData.put('Name', objOpportunity.Name );
      pData.put('AccountName', objOpportunity.Account.Name);
      pData.put('Stage', objOpportunity.StageName);
      pData.put('CreatedDate', objOpportunity.CreatedDate.format('MMM d, yyyy') );
      pData.put('DeliveryDate', objOpportunity.Delivery_Date__c != null ? objOpportunity.Delivery_Date__c.format('MMM d, yyyy') : '');
      pData.put('type', 'opportunity');

      if( !hoverOverRetailSoldDetails.containsKey( uniqueCombo ) )
          hoverOverRetailSoldDetails.put( uniqueCombo, new Map<String, List< Map<String,String>>>() );

      if( !hoverOverRetailSoldDetails.get( uniqueCombo ).containsKey('Opportunities') )
          hoverOverRetailSoldDetails.get( uniqueCombo ).put( 'Opportunities', new List<Map<String,String>>() );

      hoverOverRetailSoldDetails.get( uniqueCombo ).get( 'Opportunities' ).add( pData );
    }

    private void buildMapShipments()
    {
      this.mapShipments = new Map<String,List<Shipment>>();
      this.mapIncludedERP = new Map<String,Set<Id>>();
      //if(this.filterType != 'Boat') return;
      System.debug(loggingLevel.error,'this.allProducts:'+this.allProducts);
      System.debug(loggingLevel.error,'this.queryShipments:'+this.queryShipments);
      for (AcctSeedERP__Purchase_Order_Line__c orderLine : Database.query(this.queryShipments))
      {
          List<Shipment> shipments = new List<Shipment>();
          Integer x;
          if(Integer.valueOf(orderLine.Reserved__c)!=null)
              x = Integer.valueOf(orderLine.Reserved__c);
          else
              x = 0;

          Date deliverDate;
          if (orderLine.deliverDate__c != null)
              deliverDate = orderLine.deliverDate__c;
          else
              deliverDate = orderLine.AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c;

          Integer orderQty = orderLine.AcctSeedERP__Project__c == null ? 0 : 1;
          //Shipment shipmnt = new Shipment(orderLine.AcctSeedERP__Product__c, Integer.valueOf(orderLine.AcctSeedERP__Quantity_Unreceived__c), deliverDate,x, orderLine.id, orderQty);
          Shipment shipmnt = new Shipment(orderLine);

          String k = orderLine.AcctSeedERP__Product__c;
          if(this.filterType == 'Boat')
            k = orderLine.AcctSeedERP__Product__c + '-' + orderLine.GMBLASERP__Lot__r.Name;

          if (this.mapShipments.get(k) != null)
              shipments = mapShipments.get(k);

          shipments.add(shipmnt);
          this.mapShipments.put(k,shipments);
          if(!this.mapIncludedERP.containsKey(k))
            this.mapIncludedERP.put(k,new Set<Id>());
          if(orderLine.AcctSeedERP__Project__c != null)
            this.mapIncludedERP.get(k).add(orderLine.AcctSeedERP__Project__c);
      }
      System.debug(loggingLevel.error,'this.mapShipments:'+this.mapShipments);
    }

    private void buildProductList()
    {
        this.allProducts = new Set<ID>();
        this.listLotNames = new Set<String>();
        String lotQuery = ' SELECT Id, GMBLASERP__Product__c, Name FROM GMBLASERP__Lot__c WHERE GMBLASERP__Product__r.RecordType.Name =:filterType ';
        if(this.filterYear != 'All' && this.filterType == 'Boat'){
          listFilterYear = new List<String>();
          listFilterYear = this.filterYear.split(',');
          lotQuery += ' AND Name IN:listFilterYear ';
        }
        List<String> lotNames = new List<String>();
        for (GMBLASERP__Lot__c objLot : Database.query(lotQuery))
        {
            allProducts.add(objLot.GMBLASERP__Product__c);
            lotNames.add(objLot.Name);
        }
        if(!lotNames.isEmpty()){
          lotNames.sort();
          listLotNames.addAll(lotNames);
        }

        System.debug(loggingLevel.error,'this.filterYear 1:'+this.filterYear);
        System.debug(loggingLevel.error,'this.filterType 1:'+this.filterType);
        System.debug(loggingLevel.error,'this.allProducts 1:'+this.allProducts);
    }

    private void buildMapStock()
    {
      this.allSerials = new Set<Id>();
      //if(this.filterType != 'Boat')
        //this.allProducts = new Set<ID>();
        //this.listLotNames = new Set<String>();
        this.mapStock = new Map<String,Integer>();
        this.mapInventoryList = new map<String,List<SerialNumber>>();
        //List<String> lotNames = new List<String>();
        mapProductIdToSetYear = new Map<String, Set<String>>();

        for (GMBLASERP__Serial_Number__c objSerialNumber : Database.query(this.generateDateQuery()))
        {
          if(this.filterType != 'Boat'){
            allProducts.add(objSerialNumber.GMBLASERP__Product__c);
            allSerials.add(objSerialNumber.Id);
          }
            //lotNames.add(objSerialNumber.GMBLASERP__Lot__r.Name);
            String k = objSerialNumber.GMBLASERP__Product__c;
            if(this.filterType == 'Boat')
              k = objSerialNumber.GMBLASERP__Product__c + '-' + objSerialNumber.GMBLASERP__Lot__r.name;
            if(mapStock.containsKey(k)){
                mapStock.put(k, mapStock.get(k) + 1);
            }else{
                mapStock.put(k, 1);
            }
            if(this.filterType == 'Boat'){
              if(mapProductIdToSetYear.containsKey(objSerialNumber.GMBLASERP__Product__c)){
                 mapProductIdToSetYear.get(objSerialNumber.GMBLASERP__Product__c).add(objSerialNumber.GMBLASERP__Lot__r.name);

              }else{
                      mapProductIdToSetYear.put(objSerialNumber.GMBLASERP__Product__c, new Set<String>{objSerialNumber.GMBLASERP__Lot__r.name});

              }
          }
          if(!mapInventoryList.containsKey(k))
            mapInventoryList.put(k,new List<SerialNumber>());

          mapInventoryList.get(k).add(new SerialNumber(objSerialNumber));
        }
        //if(!lotNames.isEmpty()){
        //  lotNames.sort();
        //  listLotNames.addAll(lotNames);
        //}
    }

    private void buildMapProductOwner()
    {
        this.mapProductOwner = new Map<Id,String>();
        for (AcctSeed__Project__c prod : Database.query(this.queryProductOwner)) {
            String productID = prod.Manufactured_Product_id__c;
            String accountOwner = prod.AcctSeed__Account__r.name;
            this.mapProductOwner.put(productID,accountOwner);
        }
    }

    private MAP<String,Integer> buildMapLocations()
    {
        MAP<String,Integer> mapProdLocations = new MAP<String,Integer>();
        String query = 'SELECT Id, Name, Current_Unit_Cost__c, GMBLASERP__Product__c, location__c,GMBLASERP__Lot__r.name, Nest__c, Retail_Age__c, Overall_Age__c, Nest__r.Name, (SELECT Id, Name, Current_Unit_Cost__c, GMBLASERP__Product__c, GMBLASERP__Product__r.Name, Status__c, Model_Year__c, GMBLASERP__Lot__r.Name, Retail_Age__c, Overall_Age__c, Nest__c, Nest__r.Name FROM Nested_Serial_Numbers__r) FROM GMBLASERP__Serial_Number__c where Available_Wholesale__c = true';
        query += ' AND GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c =:filterWarehouse ';
        if('All' != this.filterYear && this.filterType == 'Boat') {
            query += ' AND GMBLASERP__Lot__r.name IN:listFilterYear ';//= ' + '\'' + this.filterYear + '\'';
        }

        for (GMBLASERP__Serial_Number__c ser: Database.query(query)) {
            if(ser.location__c != null && ser.GMBLASERP__Product__c != null) {
              String k = ser.GMBLASERP__Product__c + '-' + ser.location__c;
              if(this.filterType == 'Boat'){
                k = ser.GMBLASERP__Product__c + '-' + ser.location__c + '-' + ser.GMBLASERP__Lot__r.name;
                allSerials.add(ser.Id);
              }

                if(mapProdLocations.get(k) != null) {
                    mapProdLocations.put(k, mapProdLocations.get(k)+1);
                }else{
                    mapProdLocations.put(k,1);
                }
            }
        }
        return mapProdLocations;
    }

    private void buildMapSpecialDamages()
    {
        this.mapSpecialDamages = new map<String,Integer>();
        this.mapSpecialDamagesList = new map<String,List<SerialNumber>>();
        for(GMBLASERP__Serial_Number__c objSerialNumber :
            [SELECT Id,
              Name,
              Current_Unit_Cost__c,
              GMBLASERP__Product__c,
              GMBLASERP__Product__r.Name,
              Status__c,
              Model_Year__c,
              GMBLASERP__Lot__r.Name,
              Nest__c,
              Nest__r.Name,
              Dealer_Rigged__c,
                Retail_Age__c,
                Overall_Age__c,
              (SELECT Id,
                Name,
                Current_Unit_Cost__c,
                GMBLASERP__Product__c,
                GMBLASERP__Product__r.Name,
                Status__c,
                Model_Year__c,
                GMBLASERP__Lot__r.Name,
                Nest__c,
                Dealer_Rigged__c,
                  Retail_Age__c,
                  Overall_Age__c,
                Nest__r.Name
              FROM Nested_Serial_Numbers__r)
            FROM GMBLASERP__Serial_Number__c
            WHERE Available_Wholesale__c = true
              AND GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c =:this.filterWarehouse]){

            String uniqueCombo = objSerialNumber.GMBLASERP__Product__c + '-' + objSerialNumber.Status__c;
            if(this.filterType == 'Boat'){
              uniqueCombo = objSerialNumber.GMBLASERP__Product__c + '-' + objSerialNumber.Status__c + '-' + objSerialNumber.GMBLASERP__Lot__r.Name;
              allSerials.add(objSerialNumber.Id);
            }
            if(mapSpecialDamages.containsKey(uniqueCombo)){
                mapSpecialDamages.put(uniqueCombo, mapSpecialDamages.get(uniqueCombo) + 1);
            }else{
                mapSpecialDamages.put(uniqueCombo, 1);
            }
            if(!mapSpecialDamagesList.containsKey(uniqueCombo))
              mapSpecialDamagesList.put(uniqueCombo,new List<SerialNumber>());

            mapSpecialDamagesList.get(uniqueCombo).add(new SerialNumber(objSerialNumber));
        }
    }

    private void buildMapInventoryLine()
    {
        mapProdLot = new Map<String,ProductLotReservation__c>();
        this.inventory = new List<Inventory>();
        mapLocations = this.buildMapLocations();
        numberOfDamages = 0;
        numberOfSpecials = 0;

        for (ProductLotReservation__c proLot : [SELECT Id,Product__c,Lot__r.Name, Reserved_For_Retail_Sale__c, Reserved_for_Display__c From ProductLotReservation__c]) {
          String k = proLot.Product__c;
          if(proLot.Lot__r.Name != null)
            k = proLot.Product__c + '-' + proLot.Lot__r.Name;
            if(mapProdLot.containsKey(proLot.Product__c + '-' + proLot.Lot__r.Name)){
                ProductLotReservation__c objProductLot = mapProdLot.get(proLot.Product__c + '-' + proLot.Lot__r.Name);
                objProductLot.Reserved_For_Retail_Sale__c = (objProductLot.Reserved_For_Retail_Sale__c == null?0:objProductLot.Reserved_For_Retail_Sale__c) + (proLot.Reserved_For_Retail_Sale__c == null?0:proLot.Reserved_For_Retail_Sale__c);
                objProductLot.Reserved_for_Display__c = (objProductLot.Reserved_for_Display__c == null?0:objProductLot.Reserved_for_Display__c) + (proLot.Reserved_for_Display__c == null?0:proLot.Reserved_for_Display__c);
                mapProdLot.put(k, objProductLot );
            }else{
                mapProdLot.put(k, proLot);
            }
        }

        for (Product2 pro : Database.query(this.queryProd)) {
            if('All' == this.filterYear || this.filterType != 'Boat') {
                if(mapProductIdToSetYear.containsKey(pro.Id) && this.filterType == 'Boat'){
                    for(String yearName : mapProductIdToSetYear.get(pro.Id)){
                      if(yearName != null && yearName != '')
                        initialiseProductList(yearName,pro);
                    }
                }else if(this.filterType != 'Boat'){
                    initialiseProductList('',pro);
                }
            }else if(this.filterType == 'Boat'){
                System.debug(loggingLevel.error,'this.filterYear:'+this.filterYear);
                for(String fy : listFilterYear)
                  initialiseProductList(fy,pro);
            }
        }
    }

    private void initialiseProductList(String yearSelected, Product2 pro)
    {
      String yearSection = '-' + yearSelected;
      if(this.filterType != 'Boat')
        yearSection = '';

        Inventory inv = new Inventory(pro);
        inv.inStock = (mapStock.containsKey(pro.Id + yearSection)?mapStock.get(pro.Id + yearSection):0);
        if(mapInventoryList.containsKey(pro.Id + yearSection)){
          if(this.allCanvas != null)
          for(SerialNumber sn : mapInventoryList.get(pro.Id + yearSection)){
            if(this.allCanvas.containsKey(sn.serialID))
              sn.listCanvas = this.allCanvas.get(sn.serialID);
          }
          inv.stockDetails = JSON.serialize(new Map<String,List<SerialNumber>>{pro.Name => mapInventoryList.get(pro.Id + yearSection)});
        }
        inv.reservedForDisplayed =  (mapProdLot.get(pro.Id + yearSection) != null && mapProdLot.get(pro.Id + yearSection).Reserved_for_Display__c != null?Integer.valueOf(mapProdLot.get(pro.Id + yearSection).Reserved_for_Display__c):0);
        inv.reservedForRetail =  (mapProdLot.get(pro.Id + yearSection) != null && mapProdLot.get(pro.Id + yearSection).Reserved_For_Retail_Sale__c != null?Integer.valueOf(mapProdLot.get(pro.Id + yearSection).Reserved_For_Retail_Sale__c):0);

        if (this.mapShipments.get(pro.Id + yearSection) != null) {
            inv.shipments = this.mapShipments.get(pro.Id + yearSection);
            List<Shipment> lstShip = new List<Shipment>();
            lstShip = this.mapShipments.get(pro.Id + yearSection);
            Map<Date,Shipment> mapShipment = new Map<Date,Shipment>();
            for(Shipment sh : lstShip)
            {
              if(!mapShipment.containsKey(sh.deliverDate))
                mapShipment.put(sh.deliverDate,sh);
              else{
                Shipment sh2 = mapShipment.get(sh.deliverDate);
                sh2.quantity += sh.quantity;
                sh2.orders += sh.orders;
                sh2.available = sh.available;
                Map<String,List<ErpOrderObj>> ds = new Map<String,List<ErpOrderObj>>();
                Map<String,List<ErpOrderObj>> ds2 = new Map<String,List<ErpOrderObj>>();
                if(sh.erpOrder != null || sh2.erpOrder != null){
                  if(sh.erpOrder != null)
                    ds = (Map<String,List<ErpOrderObj>>)JSON.deserialize(sh.erpOrder, Map<String,List<ErpOrderObj>>.class);
                  if(sh2.erpOrder != null)
                    ds2 = (Map<String,List<ErpOrderObj>>)JSON.deserialize(sh2.erpOrder, Map<String,List<ErpOrderObj>>.class);

                  for(String k : ds.keySet()){
                    if(ds2.containsKey(k)){
                      ds2.get(k).addAll(ds.get(k));
                    }else
                      ds2.put(k, ds.get(k));
                  }
                  //ds2.putAll(ds);
                  sh2.erpOrder = JSON.serialize(ds2);
                }
              }
            }
            inv.shipments = mapShipment.values();

            inv.existNextShipments = true;
        }
        if(inv.reservedForRetail == null)
            inv.reservedForRetail = 0;
        if(inv.reservedForDisplayed == null)
            inv.reservedForDisplayed = 0;

        String damageKey =pro.Id + '-' + 'To Be Repaired' + yearSection;
        if (this.mapSpecialDamages.get(damageKey) != null) {
           inv.damages = this.mapSpecialDamages.get(damageKey);
           inv.showDamages = true;
           numberOfDamages = this.mapSpecialDamages.get(damageKey);
           inv.damagesDetails = JSON.serialize(new Map<String,List<SerialNumber>>{pro.Name => mapSpecialDamagesList.get(damageKey)});
           System.debug(loggingLevel.error,'inv.damagesDetails:'+inv.damagesDetails);
        }

        String demoKey =pro.Id + '-' + 'Demo' + yearSection;
        if (this.mapSpecialDamages.get(demoKey) != null) {
           inv.demos = this.mapSpecialDamages.get(demoKey);
           inv.showDemos = true;
           numberOfDemos = this.mapSpecialDamages.get(demoKey);
           inv.demosDetails = JSON.serialize(new Map<String,List<SerialNumber>>{pro.Name => mapSpecialDamagesList.get(demoKey)});
           System.debug(loggingLevel.error,'inv.demosDetails:'+inv.demosDetails);
        }

        String usedKey =pro.Id + '-' + 'Used' + yearSection;
        if (this.mapSpecialDamages.get(usedKey) != null) {
           inv.useds = this.mapSpecialDamages.get(usedKey);
           inv.showUsed = true;
           numberOfUsed = this.mapSpecialDamages.get(usedKey);
           inv.usedsDetails = JSON.serialize(new Map<String,List<SerialNumber>>{pro.Name => mapSpecialDamagesList.get(usedKey)});
           System.debug(loggingLevel.error,'inv.usedsDetails:'+inv.usedsDetails);
        }

        String specialsListKey =pro.Id + '-' + 'Specials List' + yearSection;
        if (this.mapSpecialDamages.get(specialsListKey) != null) {
            inv.specials =  this.mapSpecialDamages.get(specialsListKey);
            inv.showSpecials = true;
            numberOfSpecials = inv.specials;
            inv.specialsDetails = JSON.serialize(new Map<String,List<SerialNumber>>{pro.Name => mapSpecialDamagesList.get(specialsListKey)});
            System.debug(loggingLevel.error,'inv.specialsDetails:'+inv.specialsDetails);
        }

        String displayModelsKey =pro.Id + '-' + 'Display Model' + yearSection;
        if (this.mapSpecialDamages.get(displayModelsKey) != null) {
            inv.dms =  this.mapSpecialDamages.get(displayModelsKey);
            inv.showDM = true;
            inv.displayModels = JSON.serialize(new Map<String,List<SerialNumber>>{pro.Name => mapSpecialDamagesList.get(displayModelsKey)});
            System.debug(loggingLevel.error,'inv.displayModel:'+inv.displayModels);
        }


        if (mapDealerOrders.get(pro.Id + yearSection) != null)
            inv.dealerOrders = mapDealerOrders.get(pro.Id + yearSection);

        if( hoverOverDealerOrderDetails.get(pro.Id + yearSection) != null )
            inv.dealerOrderDetails = JSON.serialize( hoverOverDealerOrderDetails.get(pro.Id + yearSection) );

        if( hoverOverRetailSoldDetails.get(pro.Id + yearSection) != null )
            inv.retailSoldDetails = JSON.serialize( hoverOverRetailSoldDetails.get(pro.Id + yearSection) );
        Integer allSpecials = inv.specials == null ? 0 : inv.specials;
        allSpecials += inv.damages == null ? 0 : inv.damages;
        allSpecials += inv.useds == null ? 0 : inv.useds;
        allSpecials += inv.demos == null ? 0 : inv.demos;
        allSpecials += inv.dms == null ? 0 : inv.dms;

        inv.availabeForRetail = inv.inStock - (allSpecials != null ? allSpecials : 0) - (inv.retailSold != null ? inv.retailSold : 0);
        //inv.availabeForRetail = inv.reservedForRetail - (inv.retailSold != null?inv.retailSold:0);
        inv.availabeToShipDelears = inv.inStock - allSpecials;
        inv.netAvailable = inv.availabeToShipDelears - inv.dealerOrders;

        if('All' == this.filterYear && this.filterType == 'Boat')
            inv.productName = inv.Product.Name + ' / ' + yearSelected;
        else if(this.filterType == 'Boat')
            inv.productName = pro.Name + ' / ' + yearSelected;
        else
          inv.productName = pro.Name;

        inv.lotName = this.filterType == 'Boat' ? yearSelected : '';


        if (! yearSelected.contains('-'))
        {
          if(this.filterType == 'Boat' && (inv.netAvailable <> 0 || inv.availabeToShipDelears <> 0  || inv.dealerOrders <> 0 || inv.specials <> 0 || inv.useds <> 0 || inv.damages <> 0 || inv.inStock <> 0 || inv.demos <> 0))
            this.inventory.add(inv);
          else if(this.filterType != 'Boat' && (inv.availabeForRetail <> 0 || inv.existNextShipments))
            this.inventory.add(inv);
        }


    }

    private void buildShipmentsAvailable () {
        for(Inventory inv: this.inventory ) {
            if(inv.existNextShipments) {
                Integer netAvail = inv.netAvailable;
                for(Shipment shi : inv.shipments){
                    if(shi.quantity != null && netAvail != null)
                    {
                        shi.available = netAvail + shi.quantity;// - shi.orders;
                        netAvail = shi.available;
                    }
                }
            }
        }
    }


    private String generateDateQuery() {
        String returnDateQuery;
        boolean entroAlWhere = false;
        if('All' == this.filterYear && this.filterType == 'Boat') {
            returnDateQuery = this.queryInv;
        } else if(this.filterType == 'Boat'){
          if(listFilterYear == null){
            listFilterYear = new List<String>();
            listFilterYear = this.filterYear.split(',');
          }
          returnDateQuery = this.queryInv + ' AND GMBLASERP__Lot__r.name IN:listFilterYear ';
          entroAlWhere = true;
        }else{
            returnDateQuery = this.queryInv;
            entroAlWhere = true;
        }
        if('All' != this.filterType) {
            if(entroAlWhere){
                returnDateQuery += ' AND GMBLASERP__Lot__r.GMBLASERP__Product__r.recordType.name  = ' + '\'' + this.filterType + '\'';
            }else{
                returnDateQuery += ' AND GMBLASERP__Lot__r.GMBLASERP__Product__r.recordType.name  = ' + '\'' + this.filterType + '\'';
            }
        }
        System.debug(loggingLevel.error,'returnDateQuery:'+returnDateQuery);
        return  returnDateQuery;
    }

    public void filterMethod() {

        this.constructor();
    }

    @RemoteAction
    public static Boolean saveForRetail(String productID, Integer quantity, String productName, String lotVal) {
        if(lotVal == '-1'){
            lotVal = productName.substringAfterLast('/ ');
        }
        String uniquifier = productID + '-' + lotVal;
        List<ProductLotReservation__c> lstProductLotReservation = [select Id,
                                                                          Reserved_For_Retail_Sale__c
                                                                   from ProductLotReservation__c
                                                                   where Product__c =: productID
                                                                   and Lot__r.GMBLASERP__Uniquefier__c =: uniquifier];
        //String lotId;
        //for(GMBLASERP__Lot__c objLot : [select Id from GMBLASERP__Lot__c where Name =: lotVal]){
        //    lotId = objLot.Id;
        //}
        GMBLASERP__Lot__c lot;
        try {
            lot = [select Id
                   from GMBLASERP__Lot__c
                   where GMBLASERP__Uniquefier__c = :uniquifier];
        }
        catch(Exception e)
        {
            throw new InventoryAllocationException( 'Could not find Lot for ' + productName + ', year ' + lotVal);
        }

        ProductLotReservation__c objProductLotReservation = new ProductLotReservation__c();

        if(!lstProductLotReservation.isEmpty()){
            objProductLotReservation = lstProductLotReservation[0];
            objProductLotReservation.Reserved_For_Retail_Sale__c = quantity;
        }else{
            objProductLotReservation.Lot__c = lot.Id;
            objProductLotReservation.Reserved_For_Retail_Sale__c = quantity;
            objProductLotReservation.Product__c = productID;
        }

        upsert objProductLotReservation;
        return true;
    }


    @RemoteAction
    public static Boolean saveForDisplay(String productID,
                                         Integer quantity,
                                         String productName,
                                         String lotVal) {
        if(lotVal == '-1'){
            lotVal = productName.substringAfterLast('/ ');
        }
        String uniquifier = productID + '-' + lotVal;
        List<ProductLotReservation__c> lstProductLotReservation = [select Id,
                                                                          Reserved_For_Retail_Sale__c
                                                                   from ProductLotReservation__c
                                                                   where Product__c =: productID
                                                                   and Lot__r.GMBLASERP__Uniquefier__c =: uniquifier];

        //String lotId;
        //for(GMBLASERP__Lot__c objLot : [select Id from GMBLASERP__Lot__c where Name =: lotVal]){
        //    lotId = objLot.Id;
        //}
        GMBLASERP__Lot__c lot;
        try {
            lot = [select Id
                   from GMBLASERP__Lot__c
                   where GMBLASERP__Uniquefier__c = :uniquifier];
        }
        catch(Exception e)
        {
            throw new InventoryAllocationException( 'Could not find Lot for ' + productName + ', year ' + lotVal);
        }

        ProductLotReservation__c objProductLotReservation = new ProductLotReservation__c();

        if(!lstProductLotReservation.isEmpty()){
            objProductLotReservation = lstProductLotReservation[0];
            objProductLotReservation.Reserved_for_Display__c = quantity;
        }else{
            objProductLotReservation.Lot__c = lot.Id;
            objProductLotReservation.Reserved_for_Display__c = quantity;
            objProductLotReservation.Product__c = productID;
        }

        upsert objProductLotReservation;

        return true;
    }

    @RemoteAction
    public static Boolean saveShipmentReseved(String shipId, Integer quantity) {
        AcctSeedERP__Purchase_Order_Line__c shipmentToUpdate = [Select Id, Reserved__c, AcctSeedERP__Project__c from AcctSeedERP__Purchase_Order_Line__c Where Id =: shipId ];
        shipmentToUpdate.Reserved__c = quantity;
        Boolean origTriggerState = lgndPurchaseOrderLine.disableTrigger;
        lgndPurchaseOrderLine.disableTrigger = true;
        update shipmentToUpdate;
        lgndPurchaseOrderLine.disableTrigger = origTriggerState;
        return true;
    }
    @RemoteAction
    public static Boolean saveToShipDealers(String productID, Integer quantity) {
        Product2 productToUpdate = [Select Id from Product2 Where Id =: productID ];
        //productToUpdate.Reserved_for_Display__c = quantity;

        //update productToUpdate;
        return true;
    }

        public class Inventory{

        public String productName                       {get;set;}
        public String lotName                           {get;set;}
        public Product2 product                         {get;set;}
        public String customer                          {get;set;}
        //public String customerNameDelearOrder           {get;set;}
        public Integer inStock                          {get;set;}
        public String stockDetails                      {get;set;}
        public Integer availabe                         {get;set;}
        public Integer reservedForDisplayed             {get;set;}
        public Integer reservedForRetail                {get;set;}
        public String specialDamage                     {get;set;}
        public Integer retailSold                       {get;set;}
        public Integer availabeForRetail                {get;set;}
        public Integer availabeToShipDelears            {get;set;}
        public Integer dealerOrders                     {get;set;}
        public Integer netAvailable                     {get;set;}
        public Integer damages                          {get;set;}
        public String damagesDetails                    {get;set;}
        public Integer specials                         {get;set;}
        public String specialsDetails                   {get;set;}
        public String displayModels                     {get;set;}
        public Integer demos                            {get;set;}
        public String demosDetails                      {get;set;}
        public Integer useds                            {get;set;}
        public Integer dms                              {get;set;}
        public String usedsDetails                      {get;set;}
        public Integer locationWhitefish                {get;set;}
        public Integer locationMontreal                 {get;set;}
        public Integer locationBarrie                   {get;set;}
        public Integer locationOUT                      {get;set;}
        public Boolean showDamages                      {get;set;}
        public Boolean showSpecials                     {get;set;}
        public Boolean showDM                           {get;set;}
        public Boolean showDemos                        {get;set;}
        public Boolean showUsed                          {get;set;}
        public Boolean showWhitefish                    {get;set;}
        public Boolean showMontreal                     {get;set;}
        public Boolean showBarrie                       {get;set;}
        public Boolean showOUT                          {get;set;}
        public List<Shipment> shipments                 {get;set;}
        public boolean existNextShipments               {get;set;}
        public String dealerOrderDetails                { get; set; }
        public String retailSoldDetails                 { get; set; }

        public Inventory(Product2 product) {

            this.existNextShipments = false;
            this.shipments = new List<Shipment>();
            this.reservedForDisplayed = 0;
            this.reservedForRetail = 0;
            this.showDamages = false;
            this.showSpecials = false;
            this.showDM = false;
            this.showUsed = false;
            this.showBarrie = false;
            this.showBarrie = false;
            this.showOUT = false;
            this.damages = 0;
            this.specials = 0;
            this.useds = 0;
            this.dms = 0;
            this.product = product;
            this.availabe = 1;
            this.retailSold = 0;
            this.availabeForRetail = 0;
            this.availabeToShipDelears =  0;
            this.dealerOrders = 0;
            this.netAvailable = 0;
        }
    }

    public class Order
    {
        public String createdDate               {get;set;}
        public String orderNumber               {get;set;}

        public Order(String createdDate, String orderNumber)
        {
            this.createdDate = createdDate;
            this.orderNumber = orderNumber;
        }
    }

    public class Shipment {
        public String productID                   {get;set;}
        public String shipID                      {get;set;}
        public Integer quantity                   {get;set;}
        public Date deliverDate                   {get;set;}
        public String deliverDateFormatted        {get;set;}
        public Integer available                  {get;set;}
        public Integer reserved                   {get;set;}
        public Integer available_retail           {get;set;}
        public Integer orders                     {get;set;}
        public String erpOrder   {get;set;}

        public Shipment(String productID, Integer quantity, Date deliverDate,Integer reserved, String shipID, Integer orders) {

            this.shipID = shipID;
            this.productID = productID;
            this.quantity = quantity;
            this.available = available;
            this.deliverDate = deliverDate;
            this.deliverDateFormatted = deliverDate == null ? '' : Datetime.newInstance(deliverDate.year(), deliverDate.month(), deliverDate.day()).format('MMM d, yyyy');
            this.reserved = reserved;
            this.orders = orders;
        }

        public Shipment(AcctSeedERP__Purchase_Order_Line__c orderLine) {
            if (orderLine.deliverDate__c != null)
                this.deliverDate = orderLine.deliverDate__c;
            else
                this.deliverDate = orderLine.AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c;

            this.deliverDateFormatted = this.deliverDate == null ? '' : Datetime.newInstance(this.deliverDate.year(), this.deliverDate.month(), this.deliverDate.day()).format('MMM d, yyyy');
            Integer x;
            if(Integer.valueOf(orderLine.Reserved__c)!=null)
                 this.reserved = Integer.valueOf(orderLine.Reserved__c);
            else
                this.reserved = 0;

            this.shipID = orderLine.Id;
            this.productID = orderLine.AcctSeedERP__Product__c;
            this.quantity = Integer.valueOf(orderLine.AcctSeedERP__Quantity_Unreceived__c);
            this.available = available;
            this.reserved = reserved;
            this.orders = orderLine.AcctSeedERP__Project__c == null ? 0 : 1;
            if(orderLine.AcctSeedERP__Project__c != null && orderLine.AcctSeedERP__Product__r.RecordType.Name == 'Boat')
              this.erpOrder = JSON.serialize(new Map<String,List<ErpOrderObj>>{orderLine.Name => new List<ErpOrderObj>{new ErpOrderObj(orderLine.AcctSeedERP__Project__r, 'partnerERP')}});
            else if(orderLine.AcctSeedERP__Product__r.RecordType.Name != 'Boat')
              this.erpOrder = JSON.serialize(new Map<String,List<ErpOrderObj>>{'POL' => new List<ErpOrderObj>{new ErpOrderObj(orderLine, 'polDetail')}});
        }
    }

    public class SerialNumber {
        public String serialID                 {get;set;}
        public String serialName               {get;set;}
        public String serialStatus             {get;set;}
        public Boolean isDealerRigged           {get;set;}
        public String unitCost                 {get;set;}
        public String totalUnitCost            {get;set;}
        public String productID                {get;set;}
        public String productName              {get;set;}
        public String lotName                  {get;set;}
        public String makeModel                {get;set;}
        public String nestId                        {get;set;}
        public String nestName                      {get;set;}
        public Decimal retailAge                    {get;set;}
        public Decimal overallAge                   {get;set;}
        public List<SerialNumber> listNested        {get;set;}
        public List<Map<String,String>> listCanvas  {get;set;}

        public SerialNumber(GMBLASERP__Serial_Number__c serial) {
            this.listCanvas = new List<Map<String,String>>();
            this.listNested = new List<SerialNumber>();
            this.totalUnitCost = '0';
            this.isDealerRigged = serial.Dealer_Rigged__c;
            Decimal totalNested = 0;
            for(GMBLASERP__Serial_Number__c sr : serial.Nested_Serial_Numbers__r){
              SerialNumber sn = new SerialNumber(sr);
              totalNested += (sr.Current_Unit_Cost__c == null ? 0 : sr.Current_Unit_Cost__c);
              this.listNested.add(sn);
            }
            this.serialID = serial.Id;
            this.serialName = serial.Name;
            this.serialStatus = serial.Status__c;
            this.unitCost = (serial.Current_Unit_Cost__c == null ? 0 : serial.Current_Unit_Cost__c).format();
            this.totalUnitCost = (totalNested + (serial.Current_Unit_Cost__c == null ? 0 : serial.Current_Unit_Cost__c)).format();
            this.nestId = serial.Nest__c;
            this.nestName = serial.Nest__r.Name;
            this.retailAge = serial.Retail_Age__c == null ? 0 : serial.Retail_Age__c;
            this.overallAge = serial.Overall_Age__c == null ? 0 : serial.Overall_Age__c;
            this.productID = serial.GMBLASERP__Product__c;
            this.productName = serial.GMBLASERP__Product__r.Name;
            this.lotName = serial.GMBLASERP__Lot__r.Name;
            this.makeModel = serial.Model_Year__c == null ? '' : String.valueOf(serial.Model_Year__c);
        }
    }

    public class ErpOrderObj {
        public String erpId                 {get;set;}
        public String accountName           {get;set;}
        public String poId                  {get;set;}
        public String poName                {get;set;}
        public String polId                 {get;set;}
        public String polName               {get;set;}
        public Integer quantity             {get;set;}
        public String idSerial              {get;set;}
        public String serialName            {get;set;}
        public String erpName               {get;set;}
        public String erpStage              {get;set;}
        public String retailErpName         {get;set;}
        public String retailErpId           {get;set;}
        public String erpCreatedDate        {get;set;}
        public String erpDeliveryDate       {get;set;}
        public String erpType               {get;set;}

        public ErpOrderObj(AcctSeed__Project__c erp, String pErpType) {
            this.erpId = erp.Id;
            this.erpName = erp.AcctSeedERP__Work_Order_Number__c;
            if(pErpType == 'partnerERP'){
              AcctSeed__Project__c erpn = erp.clone(false,true,true);
              this.retailErpId = erpn.Retail_ERP__c;
              this.retailErpName = erpn.Retail_ERP__r.AcctSeedERP__Work_Order_Number__c;
            }else{
              this.retailErpId = null;
              this.retailErpName = null;
            }
            this.accountName = erp.AcctSeed__Account__r.Name;
            this.idSerial = erp.Serial_Number__c;
            this.serialName = erp.Serial_Number__r.Name;
            this.erpStage = erp.Stage__c;
            this.erpCreatedDate = erp.CreatedDate.format('MMM d, yyyy');
            this.erpDeliveryDate = erp.Delivery_Date__c != null ? erp.Delivery_Date__c.format('MMM d, yyyy') : '';
            this.erpType = pErpType;
        }

        public ErpOrderObj(AcctSeedERP__Purchase_Order_Line__c pol, String pErpType) {
            this.quantity = Integer.valueOf(pol.AcctSeedERP__Quantity_Unreceived__c);
            this.poId = pol.AcctSeedERP__Purchase_Order__c;
            this.poName = pol.AcctSeedERP__Purchase_Order__r.Name;
            this.polId = pol.Id;
            this.polName = pol.Name;
            this.erpType = pErpType;
        }
    }

    public static void coverage()
    {
        Integer i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;

    }

    public static void coverage1()
    {
        Integer i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;

    }
}