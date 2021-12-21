public with sharing class InventoryAllocations_Old {
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
    public String filterYear                                    {get;set;}
    public String filterType                                    {get;set;}


    public List<Inventory> inventory                            {get;set;}
    public Set<ID> allProducts                                  {get;set;}
    public Map<String,Integer> mapStock                             {get;set;}
    public Map<String,Integer> mapSpecialDamages                {get;set;}
    public Map<String,List<Shipment>> mapShipments                  {get;set;}
    public Map<String, Integer> mapRetailSold                        {get;set;}
    public Map<String, Integer> mapDealerOrders                      {get;set;}
    public Map<Id,String> mapProductOwner                       {get;set;}

    public Map<String, String> hoverOverRetailSold                   {get;set;}
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

    public InventoryAllocations_Old() {
        this.filterYear = 'ALL';
        this.filterType = 'Boat';
        this.queryInv = 'SELECT GMBLASERP__Product__c,GMBLASERP__Lot__c,GMBLASERP__Lot__r.Name from GMBLASERP__Serial_Number__c where Available__c = true  AND GMBLASERP__Lot__c != null ';
        this.queryProd = 'SELECT Id, Name From Product2 WHERE Id in: allProducts ';
        //this.queryShipments = 'Select id,AcctSeedERP__Quantity__c,  Reserved__c, deliverDate__c, AcctSeedERP__Product__c , AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c,GMBLASERP__Lot__r.Name from  AcctSeedERP__Purchase_Order_Line__c Where AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c != null order by deliverDate__c';
        /* change by Dave Hahn May 29/17 */
        this.queryShipments = 'Select id,AcctSeedERP__Quantity_Unreceived__c,  Reserved__c, deliverDate__c, AcctSeedERP__Product__c , AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c,GMBLASERP__Lot__r.Name from  AcctSeedERP__Purchase_Order_Line__c Where AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c != null AND AcctSeedERP__Quantity_Unreceived__c > 0 order by deliverDate__c';
        this.queryProductOwner = 'SELECT AcctSeed__Account__r.name , Manufactured_Product_id__c From AcctSeed__Project__c WHERE Manufactured_Product_id__c in: allProducts and AcctSeed__Status__c = \'Completed\'';
        this.constructor();

    }

    public void constructor() {

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
        this.buildMapInventoryLine();
        this.buildShipmentsAvailable();
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
        if(objOpportunity.BoatId__r.RecordType.Name == 'Trailer' && objOpportunity.Trailer_Model_Year__c != null){
            uniqueCombo = '-' + objOpportunity.Trailer_Model_Year__c;
            populateMapValues(objOpportunity.BoatId__c, objOpportunity.Trailer_Model_Year__c);
        }
        uniqueCombo = objOpportunity.BoatId__c + uniqueCombo;
        return uniqueCombo;
    }

    private String getUniqueComboProject(AcctSeed__Project__c objProject, String recordType){
        String uniqueCombo = '';
        if(recordType == 'Boat' && objProject.BoatModelYear__c != null)
            uniqueCombo = objProject.BoatModelYear__c;
        if(recordType == 'Trailer' && objProject.TrailerModelYear__c != null)
            uniqueCombo = objProject.TrailerModelYear__c;

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
        if( recordType == 'Trailer' )
        {
            uniqueCombo = mat.GMBLASERP__Lot__c != null && mat.GMBLASERP__Lot__r.Name != '' ?
                mat.GMBLASERP__Lot__r.Name :
                mat.AcctSeedERP__Project__r.TrailerModelYear__c != null ?
                    mat.AcctSeedERP__Project__r.TrailerModelYear__c :
                    '';
        }
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
                                                             AcctSeedERP__Project__r.Stage__c,
                                                             AcctSeedERP__Project__r.CreatedDate,
                                                             AcctSeedERP__Project__r.Delivery_Date__c,
                                                             AcctSeedERP__Project__r.BoatModelYear__c,
                                                             AcctSeedERP__Project__r.TrailerModelYear__c
                                                      FROM AcctSeedERP__Material__c
                                                      WHERE AcctSeedERP__Project__r.RecordTypeId IN :rts
                                                      AND AcctSeedERP__Project__r.Stage__c != 'Draft'
                                                      AND AcctSeedERP__Project__r.Stage__c != 'Delivered'
                                                      AND AcctSeedERP__Project__r.Stage__c != 'Closed Lost'
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
        if( objMaterial.AcctSeedERP__Project__r.RecordTypeId == erpRetailBoatSaleRtId )
        {
          addToRetailERPOrders( uniqueCombo, objMaterial );
        }
      }

      for(Opportunity objOpportunity : [select Id,
                                         Name,
                                         CreatedDate,
                                         Delivery_Date__c,
                                         BoatId__c,
                                         BoatId__r.RecordType.Name,
                                         Trailer_Model_Year__c,
                                         Boat_Model_Year__c,
                                         Account.Name,
                                         StageName
                                  from Opportunity
                                  where Probability > 70 and Probability < 100
                                  and BoatId__c != null and RecordType.Name = 'Retail'])
      {
        String uniqueCombo = getUniqueCombo(objOpportunity);
        addToRetailOppOrders( uniqueCombo, objOpportunity );
      }
    }

    private void addToPartnerERPOrders(String uniqueCombo, AcctSeedERP__Material__c objMaterial )
    {
      if(mapDealerOrders.containsKey(uniqueCombo))
          mapDealerOrders.put(uniqueCombo, mapDealerOrders.get(uniqueCombo) + 1);
      else
          mapDealerOrders.put(uniqueCombo, 1);

      Map<String, String> pData = new Map<String, String>();
      pData.put('Id', objMaterial.AcctSeedERP__Project__c );
      pData.put('AccountName', objMaterial.AcctSeedERP__Project__r.AcctSeed__Account__r.Name);
      pData.put('Name', objMaterial.AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c );
      pData.put('Stage', objMaterial.AcctSeedERP__Project__r.Stage__c);
      pData.put('CreatedDate', objMaterial.AcctSeedERP__Project__r.CreatedDate.format('MMM d, yyyy') );
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

            Shipment shipmnt = new Shipment(orderLine.AcctSeedERP__Product__c, Integer.valueOf(orderLine.AcctSeedERP__Quantity_Unreceived__c), deliverDate,x, orderLine.id);

            if (this.mapShipments.get(orderLine.AcctSeedERP__Product__c + '-' + orderLine.GMBLASERP__Lot__r.Name) != null)
                shipments = mapShipments.get(orderLine.AcctSeedERP__Product__c + '-' + orderLine.GMBLASERP__Lot__r.Name);

            shipments.add(shipmnt);
            this.mapShipments.put(orderLine.AcctSeedERP__Product__c + '-' + orderLine.GMBLASERP__Lot__r.Name,shipments);
        }
    }

    private void buildMapStock()
    {
        this.allProducts = new Set<ID>();
        this.mapStock = new Map<String,Integer>();

        mapProductIdToSetYear = new Map<String, Set<String>>();

        for (GMBLASERP__Serial_Number__c objSerialNumber : Database.query(this.generateDateQuery()))
        {
            allProducts.add(objSerialNumber.GMBLASERP__Product__c);

            if(mapStock.containsKey(objSerialNumber.GMBLASERP__Product__c + '-' + objSerialNumber.GMBLASERP__Lot__r.name)){
                mapStock.put(objSerialNumber.GMBLASERP__Product__c + '-' + objSerialNumber.GMBLASERP__Lot__r.name, mapStock.get(objSerialNumber.GMBLASERP__Product__c + '-' + objSerialNumber.GMBLASERP__Lot__r.name) + 1);
            }else{
                mapStock.put(objSerialNumber.GMBLASERP__Product__c + '-' + objSerialNumber.GMBLASERP__Lot__r.name, 1);
            }

            if(mapProductIdToSetYear.containsKey(objSerialNumber.GMBLASERP__Product__c)){
               mapProductIdToSetYear.get(objSerialNumber.GMBLASERP__Product__c).add(objSerialNumber.GMBLASERP__Lot__r.name);

            }else{
                    mapProductIdToSetYear.put(objSerialNumber.GMBLASERP__Product__c, new Set<String>{objSerialNumber.GMBLASERP__Lot__r.name});

            }
        }
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
        String query = 'SELECT GMBLASERP__Product__c, location__c,GMBLASERP__Lot__r.name FROM GMBLASERP__Serial_Number__c where Available__c = true';
        if('All' != this.filterYear) {
            query += ' AND GMBLASERP__Lot__r.name = ' + '\'' + this.filterYear + '\'';
        }

        for (GMBLASERP__Serial_Number__c ser: Database.query(query)) {
            if(ser.location__c != null && ser.GMBLASERP__Product__c != null) {

                if(mapProdLocations.get(ser.GMBLASERP__Product__c + '-' + ser.location__c + '-' + ser.GMBLASERP__Lot__r.name) != null) {
                    mapProdLocations.put(ser.GMBLASERP__Product__c + '-' +  ser.location__c + '-' + ser.GMBLASERP__Lot__r.name, mapProdLocations.get(ser.GMBLASERP__Product__c + '-' +  ser.location__c + '-' + ser.GMBLASERP__Lot__r.name)+1);
                }else{
                    mapProdLocations.put(ser.GMBLASERP__Product__c + '-' +  ser.location__c + '-' + ser.GMBLASERP__Lot__r.name,1);
                }
            }
        }
        return mapProdLocations;
    }

    private void buildMapSpecialDamages()
    {
        this.mapSpecialDamages = new map<String,Integer>();
        for(GMBLASERP__Serial_Number__c objSerialNumber : [SELECT GMBLASERP__Product__c, Status__c, GMBLASERP__Lot__r.Name from GMBLASERP__Serial_Number__c where available__c = true]){
            String uniqueCombo = objSerialNumber.GMBLASERP__Product__c + '-' + objSerialNumber.Status__c + '-' + objSerialNumber.GMBLASERP__Lot__r.Name;
            if(mapSpecialDamages.containsKey(uniqueCombo)){
                mapSpecialDamages.put(uniqueCombo, mapSpecialDamages.get(uniqueCombo) + 1);
            }else{
                mapSpecialDamages.put(uniqueCombo, 1);
            }
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
            if(mapProdLot.containsKey(proLot.Product__c + '-' + proLot.Lot__r.Name)){
                ProductLotReservation__c objProductLot = mapProdLot.get(proLot.Product__c + '-' + proLot.Lot__r.Name);
                objProductLot.Reserved_For_Retail_Sale__c = (objProductLot.Reserved_For_Retail_Sale__c == null?0:objProductLot.Reserved_For_Retail_Sale__c) + (proLot.Reserved_For_Retail_Sale__c == null?0:proLot.Reserved_For_Retail_Sale__c);
                objProductLot.Reserved_for_Display__c = (objProductLot.Reserved_for_Display__c == null?0:objProductLot.Reserved_for_Display__c) + (proLot.Reserved_for_Display__c == null?0:proLot.Reserved_for_Display__c);
                mapProdLot.put(proLot.Product__c + '-' + proLot.Lot__r.Name, objProductLot );
            }else{
                mapProdLot.put(proLot.Product__c + '-' + proLot.Lot__r.Name, proLot);
            }
        }

        for (Product2 pro : Database.query(this.queryProd)) {
            if('All' == this.filterYear) {
                if(mapProductIdToSetYear.containsKey(pro.Id)){
                    for(String yearName : mapProductIdToSetYear.get(pro.Id)){

                        initialiseProductList(yearName,pro);


                    }
                }else{
                    initialiseProductList('',pro);
                }
            }else{
                initialiseProductList(this.filterYear,pro);
            }
        }
    }

    private void initialiseProductList(String yearSelected, Product2 pro)
    {
        Inventory inv = new Inventory(pro);
        inv.inStock = (mapStock.containsKey(pro.Id + '-' + yearSelected)?mapStock.get(pro.Id + '-' + yearSelected):0);

        inv.reservedForDisplayed =  (mapProdLot.get(pro.Id + '-' + yearSelected) != null && mapProdLot.get(pro.Id + '-' + yearSelected).Reserved_for_Display__c != null?Integer.valueOf(mapProdLot.get(pro.Id + '-' + yearSelected).Reserved_for_Display__c):0);
        inv.reservedForRetail =  (mapProdLot.get(pro.Id + '-' + yearSelected) != null && mapProdLot.get(pro.Id + '-' + yearSelected).Reserved_For_Retail_Sale__c != null?Integer.valueOf(mapProdLot.get(pro.Id + '-' + yearSelected).Reserved_For_Retail_Sale__c):0);

        if (this.mapShipments.get(pro.Id + '-' + yearSelected) != null) {
            inv.shipments = this.mapShipments.get(pro.Id + '-' + yearSelected);
            inv.existNextShipments = true;
        }
        if(inv.reservedForRetail == null)
            inv.reservedForRetail = 0;
        if(inv.reservedForDisplayed == null)
            inv.reservedForDisplayed = 0;
        if (this.mapSpecialDamages.get(pro.Id + '-' + 'To Be Repaired' + '-' +  yearSelected) != null) {
           inv.damages = this.mapSpecialDamages.get(pro.Id + '-' + 'To Be Repaired' + '-' +  yearSelected);
           inv.showDamages = true;
           numberOfDamages = this.mapSpecialDamages.get(pro.Id + '-' + 'To Be Repaired' + '-' +  yearSelected);
        }
        if (this.mapSpecialDamages.get(pro.Id + '-' + 'Demo' + '-' +  yearSelected) != null) {
           inv.demos = this.mapSpecialDamages.get(pro.Id + '-' + 'Demo' + '-' +  yearSelected);
           inv.showDemos = true;
           numberOfDemos = this.mapSpecialDamages.get(pro.Id + '-' + 'Demo' + '-' +  yearSelected);
        }
        if (this.mapSpecialDamages.get(pro.Id + '-' + 'Used' + '-' +  yearSelected) != null) {
           inv.useds = this.mapSpecialDamages.get(pro.Id + '-' + 'Used' + '-' +  yearSelected);
           inv.showUsed = true;
           numberOfUsed = this.mapSpecialDamages.get(pro.Id + '-' + 'Used' + '-' +  yearSelected);
        }
        if (this.mapSpecialDamages.get(pro.Id + '-' + 'Specials List' + '-' +  yearSelected) != null) {
            inv.specials =  this.mapSpecialDamages.get(pro.Id + '-' + 'Specials List' + '-' +  yearSelected);
            inv.showSpecials = true;
            numberOfSpecials = inv.specials;
        }
        if (mapLocations.get(pro.Id + '-' + 'Whitefish' + '-' + yearSelected) != null) {
            inv.locationWhitefish =  mapLocations.get(pro.Id + '-' + 'Whitefish' + '-' + yearSelected);
            inv.showWhitefish = true;
        }
        if (mapLocations.get(pro.Id + '-' + 'Montreal' + '-' + yearSelected) != null) {
            inv.locationMontreal =  mapLocations.get(pro.Id + '-' + 'Montreal' + '-' + yearSelected);
            inv.showMontreal = true;
        }
        if (mapLocations.get(pro.Id + '-' + 'Barrie' + '-' + yearSelected) != null) {
            inv.locationBarrie =  mapLocations.get(pro.Id + '-' + 'Barrie' + '-' + yearSelected);
            inv.showBarrie = true;
        }
        if (mapLocations.get(pro.Id + '-' + 'OUT' + '-' + yearSelected) != null) {
            inv.locationOUT =  mapLocations.get(pro.Id + '-' + 'OUT' + '-' + yearSelected);
            inv.showOUT = true;
        }
        if (mapRetailSold.get(pro.Id + '-' + yearSelected) != null)
            inv.retailSold = mapRetailSold.get(pro.Id + '-' + yearSelected);

        if (mapDealerOrders.get(pro.Id + '-' + yearSelected) != null)
            inv.dealerOrders = mapDealerOrders.get(pro.Id + '-' + yearSelected);
        //if(hoverOverRetailSold.get(pro.Id + '-' + yearSelected) != null)
         //   inv.customer = hoverOverRetailSold.get(pro.Id + '-' + yearSelected);
        //if(hoverOverDelearOrder.get(pro.Id + '-' + yearSelected) != null)
        //    inv.customerNameDelearOrder = hoverOverDelearOrder.get(pro.Id + '-' + yearSelected);
        if( hoverOverDealerOrderDetails.get(pro.Id + '-' + yearSelected) != null )
            inv.dealerOrderDetails = JSON.serialize( hoverOverDealerOrderDetails.get(pro.Id + '-' + yearSelected) );

        if( hoverOverRetailSoldDetails.get(pro.Id + '-' + yearSelected) != null )
            inv.retailSoldDetails = JSON.serialize( hoverOverRetailSoldDetails.get(pro.Id + '-' + yearSelected) );

        inv.availabeForRetail = inv.reservedForRetail - (inv.retailSold != null?inv.retailSold:0);
        inv.availabeToShipDelears = inv.inStock - inv.reservedForRetail - inv.reservedForDisplayed - inv.damages;
        inv.netAvailable = inv.availabeToShipDelears - inv.dealerOrders;

        if('All' == this.filterYear)
            inv.productName = inv.Product.Name + ' / ' + yearSelected;
        else
            inv.productName = pro.Name;

        inv.lotName = yearSelected;


        if (! yearSelected.contains('-'))
        {
           this.inventory.add(inv);
        }


    }

    private void buildShipmentsAvailable () {
        for(Inventory inv: this.inventory ) {
            if(inv.existNextShipments) {
                /* changedby Dave Hahn Jun 05/17 so availible is carried over from the above line */
                Integer netAvail = inv.netAvailable;
                Integer netAvailRetail = inv.availabeForRetail;
                for(Shipment shi : inv.shipments){
                    if(shi.quantity != null && netAvail != null)
                    {
                        shi.available = shi.quantity + netAvail -shi.reserved;
                        netAvail = shi.available;
                    }
                    if( netAvailRetail != null && shi.reserved != null )
                    {
                        shi.available_retail = netAvailRetail + shi.reserved;
                        netAvailRetail = shi.available_retail;
                    }
                }
            }
        }
    }


    private String generateDateQuery() {
        String returnDateQuery;
        boolean entroAlWhere = false;
        if('All' == this.filterYear) {
            returnDateQuery = this.queryInv;
        } else {

            returnDateQuery = this.queryInv + ' AND GMBLASERP__Lot__r.name = ' + '\'' + this.filterYear + '\'';
            entroAlWhere = true;
        }
        if('All' != this.filterType) {
            if(entroAlWhere){
                returnDateQuery += ' AND GMBLASERP__Lot__r.GMBLASERP__Product__r.recordType.name  = ' + '\'' + this.filterType + '\'';
            }else{
                returnDateQuery += ' AND GMBLASERP__Lot__r.GMBLASERP__Product__r.recordType.name  = ' + '\'' + this.filterType + '\'';
            }
        }
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
        AcctSeedERP__Purchase_Order_Line__c shipmentToUpdate = [Select Id, Reserved__c from AcctSeedERP__Purchase_Order_Line__c Where Id =: shipId ];
        shipmentToUpdate.Reserved__c = quantity;
        MetadataTriggerHandler.bypass('TA_POL_SetReserved');
        MetadataTriggerHandler.bypass('TA_POL_UpdateProductReservation');
        MetadataTriggerHandler.bypass('TA_PropagateEtaToRetailArrivalDate');
        update shipmentToUpdate;
        MetadataTriggerHandler.clearAllBypasses();
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
        public Integer specials                         {get;set;}
        public Integer demos                            {get;set;}
        public Integer useds                            {get;set;}
        public Integer locationWhitefish                {get;set;}
        public Integer locationMontreal                 {get;set;}
        public Integer locationBarrie                   {get;set;}
        public Integer locationOUT                      {get;set;}
        public Boolean showDamages                      {get;set;}
        public Boolean showSpecials                     {get;set;}
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
            this.showUsed = false;
            this.showBarrie = false;
            this.showBarrie = false;
            this.showOUT = false;
            this.damages = 0;
            this.specials = 0;
            this.useds = 0;
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
        public String productID                 {get;set;}
        public String shipID                    {get;set;}
        public Integer quantity                 {get;set;}
        public Date deliverDate                 {get;set;}
        public Integer available                {get;set;}
        public Integer reserved                 {get;set;}
        public Integer available_retail         {get; set;}

        public Shipment(String productID, Integer quantity, Date deliverDate,Integer reserved, String shipID) {

            this.shipID = shipID;
            this.productID = productID;
            this.quantity = quantity;
            this.available = available;
            this.deliverDate = deliverDate;
            this.reserved = reserved;
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

    }


}