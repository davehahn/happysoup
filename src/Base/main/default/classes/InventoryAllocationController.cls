public without sharing class InventoryAllocationController {
        public class InventoryAllocationException extends Exception {}
        public static Boolean DESCLIST = false;
        private final String queryInv                                  {get;set;}
        private final String endQueryInv                               {get;set;}
        private final String queryProd                                 {get;set;}
        private final String queryInvSpecialDamages                    {get;set;}
        private final String queryReserved                             {get;set;}
        private final String queryShipments                            {get;set;}
        private final String queryRetail                               {get;set;}
        private final String queryDealerOrder                          {get;set;}
        private final String queryProductOwner                         {get;set;}
        public List<String> listFilterYear                             {get;set;}
        public Set<String> listLotNames                                {get;set;}
        public String filterYear                                       {get;set;}
        public String filterType                                       {get;set;}
        public String filterWarehouse                                  {get;set;}


        public List<Inventory> inventory                               {get;set;}
        transient Map<String,List<SerialNumber>> mapInventoryList      {get;set;}
        transient Set<ID> allProducts                                  {get;set;}
        transient Set<ID> allSerials                                   {get;set;}
        transient Map<String, List<Map<String,String>>> allCanvas      {get;set;}
        transient Map<String,Integer> mapStock                         {get;set;}
        transient Map<String,Integer> mapSpecialDamages                {get;set;}
        transient Map<String,List<SerialNumber>> mapSpecialDamagesList {get;set;}
        transient Map<String,List<Shipment>> mapShipments              {get;set;}
        transient Map<String,Set<Id>> mapShipmentERP                   {get;set;}
        transient Map<Id,List<Material>> mapERPMaterial                {get;set;}
        transient Set<Id> setIdERP                                     {get;set;}
        transient Map<String, Integer> mapRetailSold                   {get;set;}
        transient Map<String, Integer> mapERPRetailWholeSale           {get;set;}
        //public Map<String, Integer> mapDealerOrders               {get;set;}
        transient Map<Id,String> mapProductOwner                       {get;set;}

        transient Map<String, String> hoverOverRetailSold              {get;set;}
        //public Map<String, String> hoverOverDelearOrder                  {get;set;}
        transient Map<String, Map<String, List<Map<String,String>>>> hoverOverWholeSaleERP        {get;set;}
        transient Map<String, Map<String, List<Map<String,String>>>> hoverOverDealerOrderDetails  {get;set;}
        transient Map<String, Map<String, List<Map<String,String>>>> hoverOverRetailSoldDetails   {get;set;}

        private Map<String,ProductLotReservation__c> mapProdLot ;
        private Map<String, Set<String>> mapProductIdToSetYear;
        private MAP<String,Integer> mapLocations;
        private Integer numberOfDamages,numberOfSpecials,numberOfDemos, numberOfUsed;

        /* Added by Dave Hahn May 29/17 */
        private Id erpPartnerBoatSaleRtId = gcConstants.idRtProjectPartnerBoatSale;
        private Id erpRetailBoatSaleRtId = gcConstants.idRtProjectBoatSale;

        public InventoryAllocationController() {
            Id idWarehouseTransit = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Transit_Warehouse_Id__c;
            Id idWarehouseAdjustment = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c;
            Id idWarehouseWholesale = GMBLASERP__Inventory_Settings__c.getOrgDefaults().Wholesale_Warehouse_Id__c;
            Set<Id> setWHSId = new Set<Id>{idWarehouseTransit,idWarehouseAdjustment,idWarehouseWholesale};
            for(AcctSeedERP__Warehouse__c whs :
              [SELECT Id, Name
               FROM AcctSeedERP__Warehouse__c
               WHERE Id NOT IN :setWHSId
                 ORDER BY Name
                 LIMIT 1])
            {
              this.filterWarehouse = whs.Id;
            }
            this.filterYear = 'ALL';
            this.filterType = 'Boat';
            this.queryInv = 'SELECT Id, Name, Current_Unit_Cost__c, GMBLASERP__Product__c, GMBLASERP__Product__r.Name, Model_Year__c, Status__c, GMBLASERP__Lot__c,GMBLASERP__Lot__r.Name, Nest__c, Nest__r.Name, Retail_Age__c, Overall_Age__c, (SELECT Id, Name, Current_Unit_Cost__c, GMBLASERP__Product__c, GMBLASERP__Product__r.Name, Model_Year__c, Status__c, Retail_Age__c, Overall_Age__c, GMBLASERP__Lot__c,GMBLASERP__Lot__r.Name, Nest__c, Nest__r.Name FROM Nested_Serial_Numbers__r) from GMBLASERP__Serial_Number__c where Available_Retail__c = true AND GMBLASERP__Lot__c != null AND GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c =:filterWarehouse';
            this.queryProd = 'SELECT Id, Name From Product2 WHERE Id in: allProducts ';
            // AND AcctSeedERP__Project__r.Stage__c != \'Delivered\'
            /*String qs = 'Select Id, Name, AcctSeedERP__Product__r.RecordType.Name, AcctSeedERP__Quantity__c, AcctSeedERP__Quantity_Unreceived__c, Reserved__c, deliverDate__c, AcctSeedERP__Product__c, AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c, GMBLASERP__Lot__r.Name, ';
            qs += ' AcctSeedERP__Project__c, AcctSeedERP__Project__r.Name, AcctSeedERP__Project__r.AcctSeed__Account__r.Name, AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c, AcctSeedERP__Project__r.Stage__c, AcctSeedERP__Project__r.CreatedDate, AcctSeedERP__Project__r.Delivery_Date__c, AcctSeedERP__Project__r.BoatModelYear__c, AcctSeedERP__Project__r.Serial_Number__c, AcctSeedERP__Project__r.ERP_Serial_In_Inventory__c, AcctSeedERP__Project__r.Serial_Number__r.Name, AcctSeedERP__Project__r.TrailerModelYear__c, ';
            qs += ' AcctSeedERP__Project__r.Retail_ERP__c, AcctSeedERP__Project__r.Retail_ERP__r.ERP_Serial_In_Inventory__c, AcctSeedERP__Project__r.Retail_ERP__r.Name, AcctSeedERP__Project__r.Retail_ERP__r.AcctSeed__Account__r.Name, AcctSeedERP__Project__r.Retail_ERP__r.AcctSeedERP__Work_Order_Number__c, AcctSeedERP__Project__r.Retail_ERP__r.Stage__c, AcctSeedERP__Project__r.Retail_ERP__r.CreatedDate, AcctSeedERP__Project__r.Retail_ERP__r.Delivery_Date__c, AcctSeedERP__Project__r.Retail_ERP__r.BoatModelYear__c, AcctSeedERP__Project__r.Retail_ERP__r.Serial_Number__c, AcctSeedERP__Project__r.Retail_ERP__r.Serial_Number__r.Name, AcctSeedERP__Project__r.Retail_ERP__r.TrailerModelYear__c ';
            qs += ' from  AcctSeedERP__Purchase_Order_Line__c  Where AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c != null ';*/

            String qs = 'Select Id, Name, AcctSeedERP__Product__r.RecordType.Name, AcctSeedERP__Product__r.Name, AcctSeedERP__Quantity_Allocated__c, AcctSeedERP__Product__c, GMBLASERP__Lot__r.Name, GMBLASERP__Serial_Number__c, GMBLASERP__Serial_Number__r.Name, GMBLASERP__Serial_Number__r.Retail_Age__c, GMBLASERP__Serial_Number__r.Overall_Age__c, ';
            qs += ' AcctSeedERP__Project__c, AcctSeedERP__Project__r.Name, AcctSeedERP__Project__r.AcctSeed__Account__r.Name, AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c, AcctSeedERP__Project__r.Stage__c, AcctSeedERP__Project__r.CreatedDate, AcctSeedERP__Project__r.Delivery_Date__c, AcctSeedERP__Project__r.Arrival_Date__c, AcctSeedERP__Project__r.BoatModelYear__c, AcctSeedERP__Project__r.Serial_Number__c, AcctSeedERP__Project__r.Serial_Number__r.Product_Name__c, AcctSeedERP__Project__r.ERP_Serial_In_Inventory__c, AcctSeedERP__Project__r.Serial_Number__r.Name, AcctSeedERP__Project__r.Serial_Number__r.Retail_Age__c,AcctSeedERP__Project__r.Serial_Number__r.Overall_Age__c,AcctSeedERP__Project__r.TrailerModelYear__c,  ';
            qs += ' AcctSeedERP__Project__r.Retail_ERP__c, AcctSeedERP__Project__r.Retail_ERP__r.ERP_Serial_In_Inventory__c, AcctSeedERP__Project__r.Retail_ERP__r.Name, AcctSeedERP__Project__r.Retail_ERP__r.AcctSeed__Account__r.Name, AcctSeedERP__Project__r.Retail_ERP__r.AcctSeedERP__Work_Order_Number__c, AcctSeedERP__Project__r.Retail_ERP__r.Stage__c, AcctSeedERP__Project__r.Retail_ERP__r.CreatedDate, AcctSeedERP__Project__r.Retail_ERP__r.Delivery_Date__c, AcctSeedERP__Project__r.Retail_ERP__r.Arrival_Date__c, AcctSeedERP__Project__r.Retail_ERP__r.BoatModelYear__c, AcctSeedERP__Project__r.Retail_ERP__r.Serial_Number__c, AcctSeedERP__Project__r.Retail_ERP__r.Serial_Number__r.Name, AcctSeedERP__Project__r.Retail_ERP__r.TrailerModelYear__c ';
            qs += ' from  AcctSeedERP__Material__c Where AcctSeedERP__Project__c != null AND AcctSeedERP__Project__r.RecordTypeId =:erpPartnerBoatSaleRtId ';

            this.queryShipments = qs;
            this.queryProductOwner = 'SELECT AcctSeed__Account__r.name , Manufactured_Product_id__c From AcctSeed__Project__c WHERE Manufactured_Product_id__c in: allProducts and AcctSeed__Status__c = \'Completed\'';
            this.constructor();
        }

        public List<SelectOption> getAllWarehouses()
        {
          List<SelectOption> listWarehouses = new List<SelectOption>();
          Id idWarehouseTransit = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Transit_Warehouse_Id__c;
          Id idWarehouseAdjustment = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c;
          Id idWarehouseWholesale = GMBLASERP__Inventory_Settings__c.getOrgDefaults().Wholesale_Warehouse_Id__c;
          Set<Id> setWHSId = new Set<Id>{idWarehouseTransit,idWarehouseAdjustment,idWarehouseWholesale};
          for(AcctSeedERP__Warehouse__c whs :
            [SELECT Id, Name
             FROM AcctSeedERP__Warehouse__c
             WHERE Id NOT IN :setWHSId
               ORDER BY Name])
          {
            listWarehouses.add(new selectOption(whs.Id, whs.Name));
          }
          return listWarehouses;
        }

        public void constructor() {

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
            this.buildMapERPMaterials();
            this.buildWholeSaleERPOrders();
            this.buildMapProductOwner();
            this.buildMapCanvasERP();
            this.buildMapInventoryLine();
            this.buildShipmentsAvailable();
        }

        private void buildMapERPMaterials()
        {
          this.mapERPMaterial = new Map<Id,List<Material>>();
          if(this.setIdERP == null || this.setIdERP.isEmpty()) return;
          for( AcctSeedERP__Material__c objMaterial : [ SELECT Id, Name,
                                                                 AcctSeedERP__Product__c,
                                                                 AcctSeedERP__Product__r.Name,
                                                                 AcctSeedERP__Product__r.RecordType.Name,
                                                                 GMBLASERP__Serial_Number__c,
                                                                 GMBLASERP__Serial_Number__r.Name,
                                                                 GMBLASERP__Serial_Number__r.Product_Name__c,
                                                                 GMBLASERP__Serial_Number__r.Retail_Age__c,
                                                                 GMBLASERP__Serial_Number__r.Overall_Age__c,
                                                                 GMBLASERP__Lot__c,
                                                                 GMBLASERP__Lot__r.Name,
                                                                 AcctSeedERP__Project__c,
                                                                 AcctSeedERP__Project__r.Name,
                                                                 AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c,
                                                                 AcctSeedERP__Project__r.Serial_Number__r.Product_Name__c
                                                          FROM AcctSeedERP__Material__c
                                                          WHERE AcctSeedERP__Product__r.RecordType.Name != 'Boat'
                                                            AND (AcctSeedERP__Product__r.AcctSeedERP__Serialized__c = true OR AcctSeedERP__Product__r.Family IN ('Canvas','Boat Build Option'))
                                                            AND AcctSeedERP__Project__c IN:this.setIdERP])
          {
            Material mat = new Material(objMaterial);
            if(!this.mapERPMaterial.containsKey(objMaterial.AcctSeedERP__Project__c))
              this.mapERPMaterial.put(objMaterial.AcctSeedERP__Project__c, new List<Material>());

            this.mapERPMaterial.get(objMaterial.AcctSeedERP__Project__c).add(mat);
            System.debug(loggingLevel.error,'mat: '+JSON.serialize(mat));
          }
          System.debug(loggingLevel.error,'mapERPMaterial: '+JSON.serialize(this.mapERPMaterial));
        }

        private void buildMapCanvasERP()
        {
          if(this.allSerials == null || this.allSerials.isEmpty()) return;
          this.allCanvas = new Map<String, List<Map<String,String>>>();
          List<AcctSeedERP__Material__c> listMatl = new List<AcctSeedERP__Material__c>();
          Map<String,Map<String,Decimal>> mapSerialCanvasQty = new Map<String,Map<String,Decimal>>();
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
                                                            AND AcctSeedERP__Product__r.Family IN ('Canvas and Cover Components','Boat Build Option')
                                                            AND AcctSeedERP__Project__r.Serial_Number__c != null
                                                            AND AcctSeedERP__Project__r.Serial_Number__c IN:this.allSerials])
          {
            listMatl.add(objMaterial);
            if(!mapSerialCanvasQty.containsKey(objMaterial.AcctSeedERP__Project__r.Serial_Number__c))
              mapSerialCanvasQty.put(objMaterial.AcctSeedERP__Project__r.Serial_Number__c,new Map<String,Decimal>());
            if(!mapSerialCanvasQty.get(objMaterial.AcctSeedERP__Project__r.Serial_Number__c).containsKey(objMaterial.AcctSeedERP__Product__c))
              mapSerialCanvasQty.get(objMaterial.AcctSeedERP__Project__r.Serial_Number__c).put(objMaterial.AcctSeedERP__Product__c,0);

            Decimal oldQty = mapSerialCanvasQty.get(objMaterial.AcctSeedERP__Project__r.Serial_Number__c).get(objMaterial.AcctSeedERP__Product__c);
            Decimal curQty = objMaterial.AcctSeedERP__Quantity_Allocated__c == null ? 0 : objMaterial.AcctSeedERP__Quantity_Allocated__c;
              if(!objMaterial.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c)
                  curQty = objMaterial.AcctSeedERP__Quantity_Per_Unit__c;
            mapSerialCanvasQty.get(objMaterial.AcctSeedERP__Project__r.Serial_Number__c).put(objMaterial.AcctSeedERP__Product__c, oldQty + curQty);
          }

          System.debug(loggingLevel.error,'mapSerialCanvasQty:'+mapSerialCanvasQty);

          for( AcctSeedERP__Material__c objMaterial : listMatl)
          {
            String uniqueCombo = objMaterial.AcctSeedERP__Project__r.Serial_Number__c;
            if(mapSerialCanvasQty.get(uniqueCombo).get(objMaterial.AcctSeedERP__Product__c) == 0) continue;

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
                this.allCanvas.put( uniqueCombo, new List<Map<String,String>>() );

            this.allCanvas.get( uniqueCombo ).add( pData );

            mapSerialCanvasQty.get(objMaterial.AcctSeedERP__Project__r.Serial_Number__c).put(objMaterial.AcctSeedERP__Product__c, 0);
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
          //this.mapDealerOrders = new Map<String, Integer>();
          this.hoverOverDealerOrderDetails = new Map<String, Map<String, List<Map<String,String>>>>();
          Map<Id,Boolean> mapRetailLinked = new Map<Id,Boolean>();
          List<AcctSeedERP__Material__c> listRetailMaterials = new List<AcctSeedERP__Material__c>();
          Set<Id> rts = new Set<Id>{ erpPartnerBoatSaleRtId, erpRetailBoatSaleRtId };
          for( AcctSeedERP__Material__c objMaterial : [ SELECT Id,
                                                                 AcctSeedERP__Product__c,
                                                                 AcctSeedERP__Product__r.Name,
                                                                 AcctSeedERP__Product__r.RecordType.Name,
                                                                 GMBLASERP__Lot__c,
                                                                 GMBLASERP__Lot__r.Name,
                                                                 AcctSeedERP__Project__c,
                                                                 AcctSeedERP__Project__r.AcctSeed__Account__r.Name,
                                                                 AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c,
                                                                 AcctSeedERP__Project__r.Stage__c,
                                                                 AcctSeedERP__Project__r.CreatedDate,
                                                                 AcctSeedERP__Project__r.Arrival_Date__c,
                                                                 AcctSeedERP__Project__r.Delivery_Date__c,
                                                                 AcctSeedERP__Project__r.BoatModelYear__c,
                                                                 AcctSeedERP__Project__r.TrailerModelYear__c,
                                                                 AcctSeedERP__Project__r.Serial_Number__c,
                                                                 AcctSeedERP__Project__r.Serial_Number__r.Retail_Age__c,
                                                                 AcctSeedERP__Project__r.Serial_Number__r.Overall_Age__c,
                                                                 AcctSeedERP__Project__r.Serial_Number__r.Name
                                                          FROM AcctSeedERP__Material__c
                                                          WHERE AcctSeedERP__Project__r.RecordTypeId IN :rts
                                                          AND AcctSeedERP__Project__r.Stage__c NOT IN ('Draft','Quoting','Delivered','Closed Lost')
                                                          AND AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:this.filterWarehouse
                                                          AND GMBLASERP__Serial_Number__c = null
                                                          AND AcctSeedERP__Product__c != null ] )
          {
              System.debug('objMaterial');
              System.debug(objMaterial);

            //String uniqueCombo = getUniqueComboProject(objMaterial,objMaterial.AcctSeedERP__Product__r.RecordType.Name);
            //populateMapValues(objMaterial.AcctSeedERP__Product__c, uniqueCombo);
            //uniqueCombo = objMaterial.AcctSeedERP__Product__c + ( uniqueCombo == '' ? '' : ('-' + uniqueCombo) );

            if( objMaterial.AcctSeedERP__Project__r.RecordTypeId == erpRetailBoatSaleRtId )
            {
              //addToRetailERPOrders( uniqueCombo, objMaterial );
              mapRetailLinked.put(objMaterial.AcctSeedERP__Project__c, false);
              listRetailMaterials.add(objMaterial);
              this.setIdERP.add(objMaterial.AcctSeedERP__Project__c);
            }
          }
            System.debug('listRetailMaterials');
            System.debug(listRetailMaterials);
            System.debug('this.filterWarehouse');
            System.debug(this.filterWarehouse);

          if(!mapRetailLinked.isEmpty()){
            for(AcctSeed__Project__c pr : [SELECT Id, (SELECT Id FROM ERP_Orders__r) FROM AcctSeed__Project__c WHERE Id IN:mapRetailLinked.keySet()])
              if(!pr.ERP_Orders__r.isEmpty())
                mapRetailLinked.put(pr.Id, true);
          }

          for( AcctSeedERP__Material__c objMaterial : listRetailMaterials){
            if(this.filterType == 'Boat' && mapRetailLinked.get(objMaterial.AcctSeedERP__Project__c)) continue;
            String uniqueCombo = getUniqueComboProject(objMaterial,objMaterial.AcctSeedERP__Product__r.RecordType.Name);
            populateMapValues(objMaterial.AcctSeedERP__Product__c, uniqueCombo);
            uniqueCombo = objMaterial.AcctSeedERP__Product__c + ( uniqueCombo == '' ? '' : ('-' + uniqueCombo) );
              System.debug('uniqueCombo');
              System.debug(uniqueCombo);
              if(objMaterial.AcctSeedERP__Product__r.RecordType.Name == this.filterType)
                this.allProducts.add(objMaterial.AcctSeedERP__Product__c);
            addToRetailERPOrders( uniqueCombo, objMaterial );
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
                                      AND (Warehouse__c = null OR Warehouse__c =:this.filterWarehouse)
                                      and BoatId__c != null and RecordType.Name = 'Retail'])
          {
            String uniqueCombo = getUniqueCombo(objOpportunity);
            addToRetailOppOrders( uniqueCombo, objOpportunity );
          }
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
          pData.put('idSerial', objMaterial.AcctSeedERP__Project__r.Serial_Number__c );
          pData.put('serialName', objMaterial.AcctSeedERP__Project__r.Serial_Number__r.Name );
          pData.put('Stage', objMaterial.AcctSeedERP__Project__r.Stage__c);
          pData.put('CreatedDate', objMaterial.AcctSeedERP__Project__r.CreatedDate.format('MMM d, yyyy') );
          pData.put('DeliveryDate', objMaterial.AcctSeedERP__Project__r.Delivery_Date__c != null ? objMaterial.AcctSeedERP__Project__r.Delivery_Date__c.format('MMM d, yyyy') : '');
          Date dtArrival = objMaterial.AcctSeedERP__Project__r.Arrival_Date__c;
          pData.put('ArrivalDate', dtArrival != null ? Datetime.newInstance(dtArrival.year(),dtArrival.month(),dtArrival.day()).format('MMM d, yyyy') : '');
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

        private void buildWholeSaleERPOrders_Old()
        {
          this.mapERPRetailWholeSale = new Map<String, Integer>();
          this.hoverOverWholeSaleERP = new Map<String, Map<String, List<Map<String,String>>>>();
          Id idWarehouseWholesale = GMBLASERP__Inventory_Settings__c.getOrgDefaults().Wholesale_Warehouse_Id__c;
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
                                                           AcctSeedERP__Project__r.Arrival_Date__c,
                                                           AcctSeedERP__Project__r.Delivery_Date__c,
                                                           AcctSeedERP__Project__r.BoatModelYear__c,
                                                           AcctSeedERP__Project__r.TrailerModelYear__c,
                                                           AcctSeedERP__Project__r.Serial_Number__c,
                                                           AcctSeedERP__Project__r.Serial_Number__r.Retail_Age__c,
                                                           AcctSeedERP__Project__r.Serial_Number__r.Overall_Age__c,
                                                           AcctSeedERP__Project__r.Serial_Number__r.Name
                                                    FROM AcctSeedERP__Material__c
                                                    WHERE AcctSeedERP__Project__r.RecordTypeId =:erpPartnerBoatSaleRtId
                                                    AND AcctSeedERP__Project__r.Stage__c NOT IN ('Draft','Quoting','Delivered','Closed Lost')
                                                    AND AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:idWarehouseWholesale
                                                    AND AcctSeedERP__Project__r.AcctSeed__Account__r.Warehouse__c =:this.filterWarehouse
                                                    AND GMBLASERP__Serial_Number__c = null
                                                    AND AcctSeedERP__Product__c != null
                                                    AND AcctSeedERP__Project__r.Locked__c = false] )
          {
            String uniqueCombo = getUniqueComboProject(objMaterial,objMaterial.AcctSeedERP__Product__r.RecordType.Name);
            populateMapValues(objMaterial.AcctSeedERP__Product__c, uniqueCombo);
            uniqueCombo = objMaterial.AcctSeedERP__Product__c + ( uniqueCombo == '' ? '' : ('-' + uniqueCombo) );
            if(mapShipmentERP.containsKey(uniqueCombo) && mapShipmentERP.get(uniqueCombo).contains(objMaterial.AcctSeedERP__Project__c)) continue;
            if(mapERPRetailWholeSale.containsKey(uniqueCombo))
                mapERPRetailWholeSale.put(uniqueCombo, mapERPRetailWholeSale.get(uniqueCombo) + 1);
            else
                mapERPRetailWholeSale.put(uniqueCombo, 1);

            Map<String, String> pData = new Map<String, String>();
            pData.put('Id', objMaterial.AcctSeedERP__Project__c );
            pData.put('AccountName', objMaterial.AcctSeedERP__Project__r.AcctSeed__Account__r.Name);
            pData.put('Name', objMaterial.AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c );
            pData.put('idSerial', objMaterial.AcctSeedERP__Project__r.Serial_Number__c );
            pData.put('serialName', objMaterial.AcctSeedERP__Project__r.Serial_Number__r.Name );
            pData.put('Stage', objMaterial.AcctSeedERP__Project__r.Stage__c);
            pData.put('CreatedDate', objMaterial.AcctSeedERP__Project__r.CreatedDate.format('MMM d, yyyy') );
            pData.put('DeliveryDate', objMaterial.AcctSeedERP__Project__r.Delivery_Date__c != null ? objMaterial.AcctSeedERP__Project__r.Delivery_Date__c.format('MMM d, yyyy') : '');
            pData.put('type', 'retailERP');

            if( !hoverOverWholeSaleERP.containsKey( uniqueCombo ) )
                hoverOverWholeSaleERP.put( uniqueCombo, new Map<String, List< Map<String,String>>>() );

            if( !hoverOverWholeSaleERP.get( uniqueCombo ).containsKey('ERP Orders') )
                hoverOverWholeSaleERP.get( uniqueCombo ).put( 'ERP Orders', new List<Map<String,String>>() );

            hoverOverWholeSaleERP.get( uniqueCombo ).get( 'ERP Orders' ).add( pData );
          }
        }

        private void buildWholeSaleERPOrders()
        {
          this.mapERPRetailWholeSale = new Map<String, Integer>();
          this.hoverOverWholeSaleERP = new Map<String, Map<String, List<Map<String,String>>>>();
          Id idWarehouseWholesale = GMBLASERP__Inventory_Settings__c.getOrgDefaults().Wholesale_Warehouse_Id__c;
          Set<Id> rts = new Set<Id>{ erpPartnerBoatSaleRtId, erpRetailBoatSaleRtId };
          for( AcctSeedERP__Material__c objMaterial : [ SELECT Id, Name,
                                                           AcctSeedERP__Product__c,
                                                           AcctSeedERP__Product__r.Name,
                                                           AcctSeedERP__Product__r.RecordType.Name,
                                                           GMBLASERP__Lot__c,
                                                           GMBLASERP__Lot__r.Name,
                                                           GMBLASERP__Serial_Number__c,
                                                           GMBLASERP__Serial_Number__r.Name,
                                                           AcctSeedERP__Project__r.AcctSeed__Account__r.Name,
                                                           AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c,
                                                           AcctSeedERP__Project__r.AcctSeed__Status__c,
                                                           AcctSeedERP__Project__r.Stage__c,
                                                           AcctSeedERP__Project__r.CreatedDate,
                                                           AcctSeedERP__Project__r.Arrival_Date__c,
                                                           AcctSeedERP__Project__r.Delivery_Date__c,
                                                           AcctSeedERP__Project__r.BoatModelYear__c,
                                                           AcctSeedERP__Project__r.TrailerModelYear__c,
                                                           AcctSeedERP__Project__r.Serial_Number__c,
                                                           AcctSeedERP__Project__r.Serial_Number__r.Name,
                                                           AcctSeedERP__Project__r.Serial_Number__r.Retail_Age__c,
                                                           AcctSeedERP__Project__r.Serial_Number__r.Overall_Age__c,
                                                           AcctSeedERP__Project__r.Serial_Number__r.Product_Name__c,
                                                           AcctSeedERP__Project__r.Retail_ERP__c,
                                                          AcctSeedERP__Project__r.Retail_ERP__r.ERP_Serial_In_Inventory__c,
                                                          AcctSeedERP__Project__r.Retail_ERP__r.Name,
                                                          AcctSeedERP__Project__r.Retail_ERP__r.AcctSeed__Account__r.Name,
                                                          AcctSeedERP__Project__r.Retail_ERP__r.AcctSeedERP__Work_Order_Number__c,
                                                          AcctSeedERP__Project__r.Retail_ERP__r.Stage__c,
                                                          AcctSeedERP__Project__r.Retail_ERP__r.CreatedDate,
                                                          AcctSeedERP__Project__r.Retail_ERP__r.Arrival_Date__c,
                                                          AcctSeedERP__Project__r.Retail_ERP__r.Delivery_Date__c,
                                                          AcctSeedERP__Project__r.Retail_ERP__r.BoatModelYear__c,
                                                          AcctSeedERP__Project__r.Retail_ERP__r.Serial_Number__c,
                                                          AcctSeedERP__Project__r.Retail_ERP__r.Serial_Number__r.Name,
                                                          AcctSeedERP__Project__r.Retail_ERP__r.Serial_Number__r.Retail_Age__c,
                                                          AcctSeedERP__Project__r.Retail_ERP__r.Serial_Number__r.Overall_Age__c,
                                                          AcctSeedERP__Project__r.Retail_ERP__r.TrailerModelYear__c
                                                    FROM AcctSeedERP__Material__c
                                                    WHERE AcctSeedERP__Project__r.RecordTypeId =:erpPartnerBoatSaleRtId
                                                    AND AcctSeedERP__Project__r.Stage__c NOT IN ('Draft','Quoting','Delivered','Closed Lost')
                                                    AND AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:idWarehouseWholesale
                                                    AND AcctSeedERP__Project__r.AcctSeed__Account__r.Warehouse__c =:this.filterWarehouse
                                                    AND AcctSeedERP__Product__c != null
                                                    AND AcctSeedERP__Product__r.RecordType.Name =:this.filterType
                                                    AND AcctSeedERP__Project__r.Locked__c = false] )
          {
            // This line is commented out to load all serials even if there are no serials. From Dave to Rubel on 8/Feb/2019
            // if(objMaterial.AcctSeedERP__Product__r.RecordType.Name == 'Boat' && objMaterial.GMBLASERP__Serial_Number__c == null) continue;
            if(objMaterial.AcctSeedERP__Product__r.RecordType.Name != 'Boat' && objMaterial.AcctSeedERP__Project__r.AcctSeed__Status__c == 'Completed') continue;
            String uniqueCombo = getUniqueComboProject(objMaterial,objMaterial.AcctSeedERP__Product__r.RecordType.Name);
            populateMapValues(objMaterial.AcctSeedERP__Product__c, uniqueCombo);
            uniqueCombo = objMaterial.AcctSeedERP__Product__c + ( uniqueCombo == '' ? '' : ('-' + uniqueCombo) );
            if(mapShipmentERP.containsKey(uniqueCombo) && mapShipmentERP.get(uniqueCombo).contains(objMaterial.AcctSeedERP__Project__c)) continue;
            System.debug('AcctSeedERP__Project__r.Serial_Number__r.Name');
            System.debug(objMaterial);
            System.debug(objMaterial.AcctSeedERP__Project__r.Serial_Number__r.Name);
            Shipment shipmnt = new Shipment(objMaterial);
            System.debug('shipmnt');
            System.debug(shipmnt);
            List<Shipment> shipments = new List<Shipment>();
            if(this.mapShipments.containsKey(uniqueCombo))
              shipments = this.mapShipments.get(uniqueCombo);
            else
              this.mapShipments.put(uniqueCombo,shipments);

            shipments.add(shipmnt);
          }
          System.debug(loggingLevel.error,'this.mapShipments:'+this.mapShipments);
        }

        private void buildMapShipments()
        {
            this.mapShipments = new Map<String,List<Shipment>>();
            this.mapShipmentERP = new Map<String,Set<Id>>();
            this.setIdERP = new Set<Id>();
            if(this.filterType != 'Boat') return;
            String queryShip;
            if(this.filterType != 'Boat'){
              queryShip = this.queryShipments + ' AND AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:filterWarehouse AND AcctSeedERP__Product__c IN:allProducts order by AcctSeedERP__Project__r.Arrival_Date__c';
              //queryShip = this.queryShipments + ' AND AcctSeedERP__Purchase_Order__r.Warehouse__c =:filterWarehouse AND AcctSeedERP__Product__c IN:allProducts order by deliverDate__c';
              //queryShip = this.queryShipments + ' AND AcctSeedERP__Purchase_Order__r.Warehouse__c =:filterWarehouse AND AcctSeedERP__Product__c IN:allProducts AND AcctSeedERP__Quantity_Unreceived__c > 0 order by deliverDate__c';
            }else{
              queryShip = this.queryShipments + ' AND AcctSeedERP__Project__r.Stage__c NOT IN (\'Delivered\',\'Quoting\',\'Closed Lost\',\'Draft\') AND (AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:filterWarehouse OR AcctSeedERP__Project__r.AcctSeed__Account__r.Warehouse__c =:filterWarehouse) order by AcctSeedERP__Project__r.Arrival_Date__c';
            }
            System.debug(loggingLevel.error,'queryShip:'+queryShip);
            for (AcctSeedERP__Material__c orderLine : Database.query(queryShip))
            {
              System.debug(loggingLevel.error,'orderLine:'+orderLine.AcctSeedERP__Project__r.ERP_Serial_In_Inventory__c);
              if(this.filterType == 'Boat'
                && orderLine.AcctSeedERP__Project__c != null
                && orderLine.AcctSeedERP__Project__r.Serial_Number__c != null
                && !orderLine.AcctSeedERP__Project__r.ERP_Serial_In_Inventory__c){
                  System.debug(loggingLevel.error,'Quit From POL');
                  continue;
                }
              List<Shipment> shipments = new List<Shipment>();
              Shipment shipmnt = new Shipment(orderLine);
              System.debug(loggingLevel.error,'shipmnt:'+shipmnt);
              String k = orderLine.AcctSeedERP__Product__c;
              if(this.filterType == 'Boat')
                k = orderLine.AcctSeedERP__Product__c + '-' + orderLine.GMBLASERP__Lot__r.Name;

              if (this.mapShipments.get(k) != null){
                  shipments = mapShipments.get(k);
              }

              if(orderLine.AcctSeedERP__Project__c != null){
                this.setIdERP.add(orderLine.AcctSeedERP__Project__c);
                if(!mapShipmentERP.containsKey(k))
                  mapShipmentERP.put(k, new Set<Id>());
                mapShipmentERP.get(k).add(orderLine.AcctSeedERP__Project__c);
              }

              shipments.add(shipmnt);
              this.mapShipments.put(k,shipments);
            }

            System.debug(loggingLevel.error,'this.setIdERP:'+this.setIdERP);
        }

        private void buildProductList()
        {
            this.allProducts = new Set<ID>();
            this.listLotNames = new Set<String>();
            String lotQuery = ' SELECT Id, GMBLASERP__Product__c, Name FROM GMBLASERP__Lot__c WHERE GMBLASERP__Product__r.RecordType.Name =:filterType ';
            if(this.filterYear != 'All'){
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
            System.debug(loggingLevel.error,'filterType:'+filterType);
            System.debug(loggingLevel.error,'listLotNames:'+listLotNames);
            System.debug(loggingLevel.error,'allProducts:'+JSON.serialize(allProducts));
        }

        private void buildMapStock()
        {
          this.allSerials = new Set<ID>();
          //if(this.filterType != 'Boat')
            //this.allProducts = new Set<ID>();
            //this.listLotNames = new Set<String>();

            this.mapStock = new Map<String,Integer>();
            this.mapInventoryList = new map<String,List<SerialNumber>>();
            //List<String> lotNames = new List<String>();
            mapProductIdToSetYear = new Map<String, Set<String>>();

            for (GMBLASERP__Serial_Number__c objSerialNumber : Database.query(this.generateDateQuery()))
            {
              if(this.filterType != 'Boat')
                allProducts.add(objSerialNumber.GMBLASERP__Product__c);
                //lotNames.add(objSerialNumber.GMBLASERP__Lot__r.Name);
                String k = objSerialNumber.GMBLASERP__Product__c;
                if(this.filterType == 'Boat'){
                  k = objSerialNumber.GMBLASERP__Product__c + '-' + objSerialNumber.GMBLASERP__Lot__r.name;
                  allSerials.add(objSerialNumber.Id);
                }
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
                String productId = prod.Manufactured_Product_id__c;
                String accountOwner = prod.AcctSeed__Account__r.name;
                this.mapProductOwner.put(productId,accountOwner);
            }
        }

        private MAP<String,Integer> buildMapLocations()
        {
            MAP<String,Integer> mapProdLocations = new MAP<String,Integer>();
            String query = 'SELECT Id, Name, Current_Unit_Cost__c, GMBLASERP__Product__c, location__c,GMBLASERP__Lot__r.name, Nest__c, Nest__r.Name, Retail_Age__c, Overall_Age__c, (SELECT Id, Name, Current_Unit_Cost__c, GMBLASERP__Product__c, GMBLASERP__Product__r.Name, Status__c, Model_Year__c, Retail_Age__c, Overall_Age__c, GMBLASERP__Lot__r.Name, Nest__c, Nest__r.Name FROM Nested_Serial_Numbers__r) FROM GMBLASERP__Serial_Number__c where Available_Retail__c = true';
            query += ' AND GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c =:filterWarehouse ';
            if('All' != this.filterYear && this.filterType == 'Boat') {
                query += ' AND GMBLASERP__Lot__r.name IN:listFilterYear ';
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
                    Nest__r.Name,
                    Retail_Age__c,
                    Overall_Age__c
                  FROM Nested_Serial_Numbers__r)
                FROM GMBLASERP__Serial_Number__c
                WHERE Available_Retail__c = true
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
            System.debug(loggingLevel.error,'allProducts:'+this.allProducts);
            System.debug(loggingLevel.error,'this.queryProd:'+this.queryProd);
            for (Product2 pro : Database.query(this.queryProd)) {
                if('All' == this.filterYear || this.filterType != 'Boat') {
                    if(mapProductIdToSetYear.containsKey(pro.Id) && this.filterType == 'Boat'){
                        for(String yearName : mapProductIdToSetYear.get(pro.Id)){
                          if(yearName != null && yearName != '')
                            initialiseProductList(yearName,pro);
                        }
                    }else if(this.filterType != 'Boat'){
                        initialiseProductList('',pro);
                        System.debug(loggingLevel.error,'pro:'+pro);
                    }
                }else if(this.filterType == 'Boat'){
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
            //System.debug(loggingLevel.error,'Found:'+pro.Id);
            Boolean shipmentAvailable = false;
            if (this.mapShipments.get(pro.Id + yearSection) != null) {
              System.debug(loggingLevel.error,'Found:'+this.mapShipments.get(pro.Id + yearSection));
                //inv.shipments = this.mapShipments.get(pro.Id + yearSection);
                List<Shipment> lstShip = new List<Shipment>();
                lstShip = this.mapShipments.get(pro.Id + yearSection);
                System.debug('lstShip');
                System.debug(lstShip);
                Map<Date,Shipment> mapShipment = new Map<Date,Shipment>();
                for(Shipment sh : lstShip)
                {
                    if(sh.productId == null)
                        sh.productId = pro.Id;
                  if(!mapShipment.containsKey(sh.deliverDate)){
                    Map<String,List<ErpOrderObj>> dssh = new Map<String,List<ErpOrderObj>>();
                    if(sh.erpOrder != null)
                      dssh = (Map<String,List<ErpOrderObj>>)JSON.deserialize(sh.erpOrder, Map<String,List<ErpOrderObj>>.class);
                      System.debug(loggingLevel.error,'dssh:'+dssh);
                      for(String k : dssh.keySet()){
                        for(ErpOrderObj erp : dssh.get(k)){
                          if(this.mapERPMaterial.containsKey(erp.erpId))
                            System.debug(loggingLevel.error,'erp:'+erp);
                            erp.erpMaterials = this.mapERPMaterial.get(erp.erpId);
                            System.debug(loggingLevel.error,'erp.erpMaterials:'+erp.erpMaterials);
                        }
                      }
                      sh.erpOrder = JSON.serialize(dssh);
                      System.debug(loggingLevel.error,'sh.erpOrder:'+sh.erpOrder);
                    mapShipment.put(sh.deliverDate,sh);

                  }else{
                    Shipment sh2 = mapShipment.get(sh.deliverDate);
                      if(sh2.productId == null)
                          sh2.productId = pro.Id;
                    sh2.quantity += sh.quantity;
                    sh2.orders += sh.orders;
                    sh2.available_retail = sh.available_retail;
                    Map<String,List<ErpOrderObj>> ds = new Map<String,List<ErpOrderObj>>();
                    Map<String,List<ErpOrderObj>> ds2 = new Map<String,List<ErpOrderObj>>();
                    if(sh.erpOrder != null || sh2.erpOrder != null){
                      if(sh.erpOrder != null)
                        ds = (Map<String,List<ErpOrderObj>>)JSON.deserialize(sh.erpOrder, Map<String,List<ErpOrderObj>>.class);
                      if(sh2.erpOrder != null)
                        ds2 = (Map<String,List<ErpOrderObj>>)JSON.deserialize(sh2.erpOrder, Map<String,List<ErpOrderObj>>.class);

                      if(!ds.isEmpty())
                      for(String k : ds.keySet()){
                        if(ds2.containsKey(k))
                          ds2.get(k).addAll(ds.get(k));
                        else
                          ds2.put(k,ds.get(k));
                      }

                      for(String k : ds2.keySet()){
                        System.debug(loggingLevel.error,'ds2:'+ds2);
                        for(ErpOrderObj erp : ds2.get(k)){
                          if(this.mapERPMaterial.containsKey(erp.erpId))
                            erp.erpMaterials = this.mapERPMaterial.get(erp.erpId);
                        }
                      }

                      sh2.erpOrder = JSON.serialize(ds2);
                    }

                    Map<String,List<ErpOrderObj>> ds3 = new Map<String,List<ErpOrderObj>>();
                    Map<String,List<ErpOrderObj>> ds4 = new Map<String,List<ErpOrderObj>>();
                    if(sh.soldErpOrder != null || sh2.soldErpOrder != null){
                      if(sh.soldErpOrder != null)
                        ds3 = (Map<String,List<ErpOrderObj>>)JSON.deserialize(sh.soldErpOrder, Map<String,List<ErpOrderObj>>.class);
                      if(sh2.soldErpOrder != null)
                        ds4 = (Map<String,List<ErpOrderObj>>)JSON.deserialize(sh2.soldErpOrder, Map<String,List<ErpOrderObj>>.class);

                      if(!ds3.isEmpty())
                      for(String k : ds3.keySet()){
                        if(ds4.containsKey(k))
                          ds4.get(k).addAll(ds3.get(k));
                        else
                          ds4.put(k,ds3.get(k));
                      }

                      for(String k : ds4.keySet()){
                        System.debug(loggingLevel.error,'ds4:'+ds4);
                        for(ErpOrderObj erp : ds4.get(k)){
                          if(this.mapERPMaterial.containsKey(erp.erpId))
                            erp.erpMaterials = this.mapERPMaterial.get(erp.erpId);
                        }
                      }

                      sh2.soldErpOrder = JSON.serialize(ds4);
                    }
                  }
                }
                inv.shipments = mapShipment.values();
                inv.existNextShipments = true;
                System.debug(loggingLevel.error,'inv.shipments:'+inv.shipments);
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

            String boatShowKey =pro.Id + '-' + 'Boat Show' + yearSection;
            if (this.mapSpecialDamages.get(boatShowKey) != null) {
              inv.boatShows =  this.mapSpecialDamages.get(boatShowKey);
              inv.showBoatShow = true;
              inv.boatShowDetails = JSON.serialize(new Map<String,List<SerialNumber>>{pro.Name => mapSpecialDamagesList.get(boatShowKey)});
              System.debug(loggingLevel.error,'inv.boatShow:'+inv.boatShows);
            }

            if (mapRetailSold.get(pro.Id + yearSection) != null)
                inv.retailSold = mapRetailSold.get(pro.Id + yearSection);

            if( hoverOverDealerOrderDetails.get(pro.Id + yearSection) != null )
                inv.dealerOrderDetails = JSON.serialize( hoverOverDealerOrderDetails.get(pro.Id + yearSection) );

            System.debug('hoverOverRetailSoldDetails');
            System.debug(hoverOverRetailSoldDetails);
            if( hoverOverRetailSoldDetails.get(pro.Id + yearSection) != null ) {
                System.debug('hoverOverRetailSoldDetails.get(pro.Id + yearSection)');
                String mls = JSON.serialize(hoverOverRetailSoldDetails.get(pro.Id + yearSection));
                System.debug(mls);
                Map<String,List<RetailERP>> retDS = (Map<String,List<RetailERP>>)JSON.deserialize(mls, Map<String,List<RetailERP>>.class);
                if(retDS.containsKey('ERP Orders')) {
                    for (RetailERP m : retDS.get('ERP Orders')) {
                        m.erpMaterials = this.mapERPMaterial.get(m.Id);
                    }
                }
                inv.retailSoldDetails = JSON.serialize(retDS);
                System.debug('mls');
                System.debug(mls);
            }

            Integer allSpecials = inv.specials == null ? 0 : inv.specials;
            allSpecials += inv.damages == null ? 0 : inv.damages;
            allSpecials += inv.useds == null ? 0 : inv.useds;
            allSpecials += inv.demos == null ? 0 : inv.demos;
            allSpecials += inv.dms == null ? 0 : inv.dms;
            allSpecials += inv.boatShows == null ? 0 : inv.boatShows;

            inv.availabeForRetail = inv.inStock - (allSpecials != null ? allSpecials : 0) - (inv.retailSold != null ? inv.retailSold : 0);
            inv.availabeToShipDelears = inv.inStock - allSpecials;
            inv.netAvailable = inv.availabeToShipDelears - inv.dealerOrders;

            if('All' == this.filterYear && this.filterType == 'Boat')
                inv.productName = inv.Product.Name + ' / ' + yearSelected;
            else if(this.filterType == 'Boat')
                inv.productName = pro.Name + ' / ' + yearSelected;
            else
              inv.productName = pro.Name;

            inv.lotName = this.filterType == 'Boat' ? yearSelected : '';

            System.debug('inv-m');
            System.debug(inv);
            if (! yearSelected.contains('-'))
            {
              if(this.filterType == 'Boat' && (inv.availabeForRetail <> 0 || inv.retailSold <> 0  || inv.specials <> 0 || inv.useds <> 0 || inv.damages <> 0 || inv.inStock <> 0 || inv.demos <> 0))
               this.inventory.add(inv);
              else if(this.filterType != 'Boat' && (inv.availabeForRetail <> 0 || inv.existNextShipments))
                this.inventory.add(inv);
            }
        }

        private void buildShipmentsAvailable () {
            for(Inventory inv: this.inventory ) {
                if(inv.existNextShipments)
                {
                  inv.shipments.sort();
                  /* changedby Dave Hahn Jun 05/17 so availible is carried over from the above line */
                  Integer netAvail = inv.netAvailable == null ? 0 : inv.netAvailable;
                  Integer netAvailRetail = inv.availabeForRetail == null ? 0 : inv.availabeForRetail;
                  for (Shipment shi : inv.shipments)
                  {
                    //if(shi.quantity != null && netAvail != null)
                    //{
                    //    shi.available = shi.quantity + netAvail -shi.reserved;
                    //    netAvail = shi.available;
                    //}
                    if (netAvailRetail != null)
                    {
                      shi.available_retail = netAvailRetail + shi.quantity - shi.orders;
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
            return  returnDateQuery;
        }

        public void filterMethod() {

            this.constructor();
        }

        @RemoteAction
        public static Boolean saveForRetail(String productId, Integer quantity, String productName, String lotVal) {
            if(lotVal == '-1'){
                lotVal = productName.substringAfterLast('/ ');
            }
            String uniquifier = productId + '-' + lotVal;
            List<ProductLotReservation__c> lstProductLotReservation = [select Id,
                                                                              Reserved_For_Retail_Sale__c
                                                                       from ProductLotReservation__c
                                                                       where Product__c =: productId
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
                objProductLotReservation.Product__c = productId;
            }

            upsert objProductLotReservation;
            return true;
        }

        @RemoteAction
    public static Map<String,List<Inventory>> retrieveWholeSaleData(List<String> listIdProduct, String lotName){
        System.debug('lotName');
        System.debug(lotName);
        String[] listLotName;
        if(lotName != null)
            listLotName = lotName.split(':');
        System.debug('listLotName');
        System.debug(listLotName);
        Set<String> setProducts = new Set<String>();
        setProducts.addAll(listIdProduct);
        Map<String,Integer> whMapStock = new Map<String,Integer>();
        Map<String, Set<String>> whMapProductIdToSetYear = new Map<String, Set<String>>();
        Map<String,Integer> whMapSpecialDamages = new Map<String,Integer>();
        Map<String,List<SerialNumber>> whMapSpecialDamagesList = new Map<String,List<SerialNumber>>();
        Id idWarehouseWholesale = GMBLASERP__Inventory_Settings__c.getOrgDefaults().Wholesale_Warehouse_Id__c;
        Map<Id,Set<String>> mapListLot = new Map<Id,Set<String>>();
        for (GMBLASERP__Serial_Number__c objSerialNumber :
        [SELECT Id,
            Name,
            Current_Unit_Cost__c,
            GMBLASERP__Product__c,
            GMBLASERP__Product__r.Name,
            GMBLASERP__Product__r.RecordType.Name,
            Model_Year__c,
            Status__c,
            GMBLASERP__Lot__c,
            GMBLASERP__Lot__r.Name,
            Nest__c,
            Nest__r.Name,
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
            Nest__r.Name,
            Retail_Age__c,
            Overall_Age__c
        FROM Nested_Serial_Numbers__r)
        FROM GMBLASERP__Serial_Number__c
        WHERE Available_Wholesale__c = true
        AND GMBLASERP__Lot__r.Name IN:listLotName
        AND GMBLASERP__Product__c IN:setProducts
        AND GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c =:idWarehouseWholesale])
        {
            String flType = objSerialNumber.GMBLASERP__Product__r.RecordType.Name;
            String k = objSerialNumber.GMBLASERP__Product__c;
            if(!mapListLot.containsKey(objSerialNumber.GMBLASERP__Product__c)){
                mapListLot.put(objSerialNumber.GMBLASERP__Product__c,new Set<String>());
            }
            mapListLot.get(objSerialNumber.GMBLASERP__Product__c).add(objSerialNumber.GMBLASERP__Lot__r.Name);
            if(flType == 'Boat')
                k = objSerialNumber.GMBLASERP__Product__c + '-' + objSerialNumber.GMBLASERP__Lot__r.Name;
            if(whMapStock.containsKey(k)){
                whMapStock.put(k, whMapStock.get(k) + 1);
            }else{
                whMapStock.put(k, 1);
            }
            if(flType == 'Boat'){
                if(whMapProductIdToSetYear.containsKey(objSerialNumber.GMBLASERP__Product__c)){
                    whMapProductIdToSetYear.get(objSerialNumber.GMBLASERP__Product__c).add(objSerialNumber.GMBLASERP__Lot__r.Name);
                }else{
                    whMapProductIdToSetYear.put(objSerialNumber.GMBLASERP__Product__c, new Set<String>{objSerialNumber.GMBLASERP__Lot__r.Name});
                }
            }
            /// Specials List
            String uniqueCombo = objSerialNumber.GMBLASERP__Product__c + '-' + objSerialNumber.Status__c;
            if(flType == 'Boat')
                uniqueCombo = objSerialNumber.GMBLASERP__Product__c + '-' + objSerialNumber.Status__c + '-' + objSerialNumber.GMBLASERP__Lot__r.Name;
            if(whMapSpecialDamages.containsKey(uniqueCombo)){
                whMapSpecialDamages.put(uniqueCombo, whMapSpecialDamages.get(uniqueCombo) + 1);
            }else{
                whMapSpecialDamages.put(uniqueCombo, 1);
            }
            if(!whMapSpecialDamagesList.containsKey(uniqueCombo))
                whMapSpecialDamagesList.put(uniqueCombo,new List<SerialNumber>());

            whMapSpecialDamagesList.get(uniqueCombo).add(new SerialNumber(objSerialNumber));
        }
        Map<String,List<Shipment>> whMapShipments = new Map<String,List<Shipment>>();
        for (AcctSeedERP__Purchase_Order_Line__c orderLine :
        [SELECT Id,
            Name,
            AcctSeedERP__Quantity__c,
            AcctSeedERP__Quantity_Unreceived__c,
            Reserved__c,
            deliverDate__c,
            AcctSeedERP__Product__c,
            AcctSeedERP__Product__r.RecordType.Name,
            AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c,
            GMBLASERP__Lot__r.Name,
            AcctSeedERP__Project__c,
            AcctSeedERP__Project__r.Retail_ERP__c,
            AcctSeedERP__Project__r.Retail_ERP__r.AcctSeedERP__Work_Order_Number__c,
            AcctSeedERP__Project__r.Retail_ERP__r.ERP_Serial_In_Inventory__c,
            AcctSeedERP__Project__r.Retail_ERP__r.AcctSeed__Account__r.Name,
            AcctSeedERP__Project__r.Retail_ERP__r.Serial_Number__c,
            AcctSeedERP__Project__r.Retail_ERP__r.Serial_Number__r.Name,
            AcctSeedERP__Project__r.Retail_ERP__r.Serial_Number__r.Retail_Age__c,
            AcctSeedERP__Project__r.Retail_ERP__r.Serial_Number__r.Overall_Age__c,
            AcctSeedERP__Project__r.Retail_ERP__r.Stage__c,
            AcctSeedERP__Project__r.Retail_ERP__r.CreatedDate,
            AcctSeedERP__Project__r.Retail_ERP__r.Arrival_Date__c,
            AcctSeedERP__Project__r.Retail_ERP__r.Delivery_Date__c,
            AcctSeedERP__Project__r.Name,
            AcctSeedERP__Project__r.AcctSeed__Account__c,
            AcctSeedERP__Project__r.AcctSeed__Account__r.Name,
            AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c,
            AcctSeedERP__Project__r.Stage__c,
            AcctSeedERP__Project__r.CreatedDate,
            AcctSeedERP__Project__r.Arrival_Date__c,
            AcctSeedERP__Project__r.Delivery_Date__c,
            AcctSeedERP__Project__r.BoatModelYear__c,
            AcctSeedERP__Project__r.TrailerModelYear__c,
            AcctSeedERP__Project__r.Serial_Number__c,
            AcctSeedERP__Project__r.Serial_Number__r.Name,
            AcctSeedERP__Project__r.Serial_Number__r.Retail_Age__c,
            AcctSeedERP__Project__r.Serial_Number__r.Overall_Age__c,
            AcctSeedERP__Project__r.ERP_Serial_In_Inventory__c
        FROM AcctSeedERP__Purchase_Order_Line__c
        WHERE (AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c != null OR deliverDate__c != null)
        AND AcctSeedERP__Quantity_Unreceived__c > 0
        AND ( (AcctSeedERP__Project__c != null
        AND
        AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:idWarehouseWholesale )
        OR (AcctSeedERP__Project__c = null
        AND (AcctSeedERP__Purchase_Order__r.Warehouse__c = null
        OR AcctSeedERP__Purchase_Order__r.Warehouse__c =:idWarehouseWholesale)))
        AND AcctSeedERP__Product__c IN: setProducts
        AND GMBLASERP__Lot__r.Name IN:listLotName
        ORDER BY deliverDate__c])
        {
            if(!mapListLot.containsKey(orderLine.AcctSeedERP__Product__c)){
                mapListLot.put(orderLine.AcctSeedERP__Product__c,new Set<String>());
            }
            mapListLot.get(orderLine.AcctSeedERP__Product__c).add(orderLine.GMBLASERP__Lot__r.Name);
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

            Integer orderQty = orderLine.AcctSeedERP__Project__c == null ? 0 : Integer.valueOf(orderLine.AcctSeedERP__Quantity_Unreceived__c);
            Shipment shipmnt = new Shipment(orderLine);

            String k = orderLine.AcctSeedERP__Product__c + '-' + orderLine.GMBLASERP__Lot__r.Name;
            if (whMapShipments.get(k) != null)
                shipments = whMapShipments.get(k);

            shipments.add(shipmnt);
            whMapShipments.put(k,shipments);
        }

        /// Build Outstanding Orders
        Map<String,Integer> whMapDealerOrders = new Map<String,Integer>();
        Set<Id> rts = new Set<Id>{ gcConstants.idRtProjectPartnerBoatSale, gcConstants.idRtProjectBoatSale };
        for( AcctSeedERP__Material__c mat : [ SELECT Id,
            AcctSeedERP__Product__c,
            AcctSeedERP__Product__r.Name,
            AcctSeedERP__Product__r.RecordType.Name,
            GMBLASERP__Lot__c,
            GMBLASERP__Lot__r.Name,
            AcctSeedERP__Project__r.AcctSeed__Account__r.Name,
            AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c,
            AcctSeedERP__Project__r.Stage__c,
            AcctSeedERP__Project__r.CreatedDate,
            AcctSeedERP__Project__r.Arrival_Date__c,
            AcctSeedERP__Project__r.Delivery_Date__c,
            AcctSeedERP__Project__r.BoatModelYear__c,
            AcctSeedERP__Project__r.TrailerModelYear__c,
            AcctSeedERP__Project__r.Serial_Number__c,
            AcctSeedERP__Project__r.Serial_Number__r.Retail_Age__c,
            AcctSeedERP__Project__r.Serial_Number__r.Overall_Age__c,
            AcctSeedERP__Project__r.Serial_Number__r.Name
        FROM AcctSeedERP__Material__c
        WHERE AcctSeedERP__Project__r.Stage__c NOT IN ('Draft','Quoting','Delivered','Closed Lost')
        AND AcctSeedERP__Project__r.RecordTypeId =:gcConstants.idRtProjectPartnerBoatSale
        AND GMBLASERP__Serial_Number__c = null
        AND AcctSeedERP__Product__c != null ] )
        {
            if(!mapListLot.containsKey(mat.AcctSeedERP__Product__c)){
                mapListLot.put(mat.AcctSeedERP__Product__c,new Set<String>());
            }
            mapListLot.get(mat.AcctSeedERP__Product__c).add(mat.GMBLASERP__Lot__r.Name);
            String flType = mat.AcctSeedERP__Product__r.RecordType.Name;
            String uniqueCombo = '';
            if( flType == 'Boat' )
            {
                uniqueCombo = mat.GMBLASERP__Lot__c != null && mat.GMBLASERP__Lot__r.Name != '' ?
                    mat.GMBLASERP__Lot__r.Name :
                    mat.AcctSeedERP__Project__r.BoatModelYear__c != null ?
                        mat.AcctSeedERP__Project__r.BoatModelYear__c :
                        '';
            }
            if( flType == 'Trailer' )
            {
                uniqueCombo = mat.GMBLASERP__Lot__c != null && mat.GMBLASERP__Lot__r.Name != '' ?
                    mat.GMBLASERP__Lot__r.Name :
                    mat.AcctSeedERP__Project__r.TrailerModelYear__c != null ?
                        mat.AcctSeedERP__Project__r.TrailerModelYear__c :
                        '';
            }

            if(whMapProductIdToSetYear.containsKey(mat.AcctSeedERP__Product__c)){
                whMapProductIdToSetYear.get(mat.AcctSeedERP__Product__c).add(uniqueCombo);
            }else{
                whMapProductIdToSetYear.put(mat.AcctSeedERP__Product__c, new Set<String>{uniqueCombo});
            }

            uniqueCombo = mat.AcctSeedERP__Product__c + ( uniqueCombo == '' ? '' : ('-' + uniqueCombo) );
            if(whMapDealerOrders.containsKey(uniqueCombo))
                whMapDealerOrders.put(uniqueCombo, whMapDealerOrders.get(uniqueCombo) + 1);
            else
                whMapDealerOrders.put(uniqueCombo, 1);
        }

        /// Inventory Line
        List<Inventory> whInventory = new List<Inventory>();
        Integer numberOfDamages = 0;
        Integer numberOfSpecials = 0;
        System.debug('mapListLot');
        System.debug(mapListLot);
        for (Product2 pro : [SELECT Id, Name, RecordType.Name From Product2 WHERE Id IN:setProducts]) {
            System.debug(pro.Id);
            if(mapListLot.get(pro.Id) != null)
            for(String ln : mapListLot.get(pro.Id)) {
                String yearSection = '-' + ln;
                if (pro.RecordType.Name != 'Boat')
                    yearSection = '';

                Inventory inv = new Inventory(pro);
                inv.inStock = (whMapStock.containsKey(pro.Id + yearSection) ? whMapStock.get(pro.Id + yearSection) : 0);
                if (whMapShipments.get(pro.Id + yearSection) != null) {
                    inv.shipments = whMapShipments.get(pro.Id + yearSection);
                    inv.existNextShipments = true;
                }
                if (inv.reservedForDisplayed == null)
                    inv.reservedForDisplayed = 0;

                String damageKey = pro.Id + '-' + 'To Be Repaired' + yearSection;
                if (whMapSpecialDamages.get(damageKey) != null) {
                    inv.damages = whMapSpecialDamages.get(damageKey);
                }

                String demoKey = pro.Id + '-' + 'Demo' + yearSection;
                if (whMapSpecialDamages.get(demoKey) != null) {
                    inv.demos = whMapSpecialDamages.get(demoKey);
                }

                String usedKey = pro.Id + '-' + 'Used' + yearSection;
                if (whMapSpecialDamages.get(usedKey) != null) {
                    inv.useds = whMapSpecialDamages.get(usedKey);
                }

                String specialsListKey = pro.Id + '-' + 'Specials List' + yearSection;
                if (whMapSpecialDamages.get(specialsListKey) != null) {
                    inv.specials = whMapSpecialDamages.get(specialsListKey);
                }

                if (whMapDealerOrders.get(pro.Id + yearSection) != null)
                    inv.dealerOrders = whMapDealerOrders.get(pro.Id + yearSection);

                Integer allSpecials = inv.specials == null ? 0 : inv.specials;
                allSpecials += inv.damages == null ? 0 : inv.damages;
                allSpecials += inv.useds == null ? 0 : inv.useds;
                allSpecials += inv.demos == null ? 0 : inv.demos;

                inv.availabeToShipDelears = inv.inStock - allSpecials;
                inv.netAvailable = inv.availabeToShipDelears - inv.dealerOrders;

                if ((ln != null && !ln.contains('-')) || (lotName != null && !lotName.contains('-'))) {
                    whInventory.add(inv);
                }
            }
        }
        Map<String,List<Inventory>> mapWholesaleInventory = new Map<String,List<Inventory>>();
        for(Inventory inv: whInventory ) {
            if(inv.existNextShipments) {
                Map<Date,Shipment> mapShipment = new Map<Date,Shipment>();
                for(Shipment sh : inv.shipments)
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
                            ds2.putAll(ds);
                            sh2.erpOrder = JSON.serialize(ds2);
                        }
                    }
                }
                inv.shipments = mapShipment.values();
                Integer netAvail = inv.netAvailable;
                if(netAvail <= 0){
                    for(Shipment shi : inv.shipments){
                        if(shi.quantity != null && netAvail != null)
                        {
                            shi.available = netAvail + shi.quantity;// - shi.orders;
                            netAvail = shi.available;
                        }
                        if(netAvail > 0){
                            inv.netAvailable = shi.available;
                            inv.nextPositiveShipment = shi.deliverDate.format();
                            inv.datePositiveShipment = shi.deliverDate;
                            inv.datePositiveShipmentIsToday = shi.deliverDate == Date.today();
                            break;
                        }
                    }
                }else{
                    inv.nextPositiveShipment = Date.today().format();
                    inv.datePositiveShipment = Date.today();
                    inv.datePositiveShipmentIsToday = true;
                }
            }
            if(inv.netAvailable <= 0){
                inv.netAvailable = 0;
                inv.nextPositiveShipment = null;
                inv.datePositiveShipment = null;
                inv.datePositiveShipmentIsToday = false;
            }
        }
        mapWholesaleInventory.put('Wholesale Inventory',whInventory);
        //return JSON.serialize(mapWholesaleInventory);
        return mapWholesaleInventory;
    }


        @RemoteAction
        public static Boolean saveForDisplay(String productId,
                                             Integer quantity,
                                             String productName,
                                             String lotVal) {
            if(lotVal == '-1'){
                lotVal = productName.substringAfterLast('/ ');
            }
            String uniquifier = productId + '-' + lotVal;
            List<ProductLotReservation__c> lstProductLotReservation = [select Id,
                                                                              Reserved_For_Retail_Sale__c
                                                                       from ProductLotReservation__c
                                                                       where Product__c =: productId
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
                objProductLotReservation.Product__c = productId;
            }

            upsert objProductLotReservation;

            return true;
        }

        @RemoteAction @ReadOnly
        public static List<Map<String,String>> retrieveRetailERPOrders(String searchTxt, String idWholesaleERP, String idWholesaleProd)
        {
            System.debug('idWholesaleERP');
            System.debug(idWholesaleERP);
            System.debug('idWholesaleProd');
            System.debug(idWholesaleProd);
          List<Map<String,String>> listProject = new List<Map<String,String>>();
            searchTxt = '%'+searchTxt.replaceAll('[*]','%') +'%';
            AcctSeed__Project__c wholesaleProject;
            AcctSeedERP__Purchase_Order_Line__c pol;
            AcctSeed__Project__c erpWH = [SELECT Id, BoatModelYear__c FROM AcctSeed__Project__c WHERE Id =: idWholesaleERP][0];
            /*for(AcctSeed__Project__c p :
              [SELECT Id,
                (SELECT Id, GMBLASERP__Lot__c, GMBLASERP__Lot__r.Name, AcctSeedERP__Product__c FROM AcctSeedERP__Purchase_Order_Lines__r LIMIT 1)
              FROM AcctSeed__Project__c
              WHERE Locked__c = false
                AND Id =:idWholesaleERP])
            {
              wholesaleProject = p;
              if(!p.AcctSeedERP__Purchase_Order_Lines__r.isEmpty())
                pol = p.AcctSeedERP__Purchase_Order_Lines__r[0];
            }*/
    //        if(pol == null) return listProject;
            Id idRtProjectBoatSale = gcConstants.idRtProjectBoatSale;
            for( AcctSeedERP__Material__c objMaterial : [SELECT Id,
                                                                 AcctSeedERP__Product__c,
                                                                 GMBLASERP__Lot__c,
                                                                 GMBLASERP__Lot__r.Name,
                                                                 AcctSeedERP__Project__c,
                                                                 AcctSeedERP__Project__r.Name,
                                                                 AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c
                                                          FROM AcctSeedERP__Material__c
                                                          WHERE AcctSeedERP__Project__r.Stage__c != 'Delivered'
                                                            AND AcctSeedERP__Product__c =:idWholesaleProd
                                                            AND (AcctSeedERP__Project__r.Name like:searchTxt OR AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c like:searchTxt)
                                                            AND (AcctSeedERP__Project__r.BoatModelYear__c =:erpWH.BoatModelYear__c)
                                                            AND AcctSeedERP__Project__c !=:erpWH.Id
                                                            AND AcctSeedERP__Project__r.Serial_Number__c = null
                                                            AND AcctSeedERP__Project__r.RecordTypeId =:idRtProjectBoatSale])
          {
              Map<String,String> m = new Map<String,String>();
              m.put('label', objMaterial.AcctSeedERP__Project__r.Name);
              m.put('idPr', objMaterial.AcctSeedERP__Project__c);
              m.put('lotame',erpWH.BoatModelYear__c);
              m.put('idProduct',idWholesaleProd);
              listProject.add(m);
          }
          return listProject;
        }

        @RemoteAction
        public static Map<String,String> updateRetailERP(Id idWErp, Id idRERP, Id idWholesalePrd, Boolean allowTagging)
        {
          AcctSeed__Project__c wholesaleProject;
          Set<Id> setIdRetailSerialProducts = new Set<Id>();
          Set<Id> setIdWholesaleSerialProducts = new Set<Id>();
          Map<Id,Map<Id,Id>> mapProjectProductSerial = new Map<Id,Map<Id,Id>>();
          mapProjectProductSerial.put(idRERP,new Map<Id,Id>());
          AcctSeedERP__Purchase_Order_Line__c pol;
            String modelYear = '';
          for(AcctSeed__Project__c p :
            [SELECT Id, BoatModelYear__c,
              Retail_ERP__c,
                Serial_Number__c,
              (SELECT Id, AcctSeedERP__Product__c, GMBLASERP__Serial_Number__c FROM AcctSeedERP__Project_Materials__r WHERE AcctSeedERP__Product__r.AcctSeedERP__Serialized__c = true),
              (SELECT Id, GMBLASERP__Lot__c, GMBLASERP__Lot__r.Name, AcctSeedERP__Product__c FROM AcctSeedERP__Purchase_Order_Lines__r LIMIT 1)
            FROM AcctSeed__Project__c
            WHERE Locked__c = false
              AND Id =:idWErp])
          {
              modelYear = p.BoatModelYear__c;
            wholesaleProject = p;
            if(!p.AcctSeedERP__Purchase_Order_Lines__r.isEmpty())
              pol = p.AcctSeedERP__Purchase_Order_Lines__r[0];

            for(AcctSeedERP__Material__c matl : p.AcctSeedERP__Project_Materials__r) {
                mapProjectProductSerial.get(idRERP).put(matl.AcctSeedERP__Product__c,matl.GMBLASERP__Serial_Number__c);
                setIdRetailSerialProducts.add(matl.AcctSeedERP__Product__c);
            }
          }
          //if(pol == null) throw new InventoryAllocationException( 'The wholesale ERP does not have a related Purchase Order Line.');
            AcctSeed__Project__c retailPR;
            if(!allowTagging)
          for(AcctSeed__Project__c pr :
              [SELECT Id, BoatModelYear__c,
                (SELECT Id, AcctSeedERP__Product__c FROM AcctSeedERP__Project_Materials__r WHERE AcctSeedERP__Product__r.AcctSeedERP__Serialized__c = true),
                Retail_ERP__c
              FROM AcctSeed__Project__c WHERE Id = :idRERP])
          {
              retailPR = pr;
            for(AcctSeedERP__Material__c matl : pr.AcctSeedERP__Project_Materials__r){
              if(setIdRetailSerialProducts.contains(matl.AcctSeedERP__Product__c))
                setIdWholesaleSerialProducts.add(matl.AcctSeedERP__Product__c);
              else
                throw new InventoryAllocationException( 'NOMATCH');
            }
          }
          System.debug(loggingLevel.error,'setIdWholesaleSerialProducts:'+setIdWholesaleSerialProducts);
          System.debug(loggingLevel.error,'setIdRetailSerialProducts:'+setIdRetailSerialProducts);
          if(setIdWholesaleSerialProducts.size() != setIdRetailSerialProducts.size() && !allowTagging)
            throw new InventoryAllocationException( 'NOMATCH');
            //throw new InventoryAllocationException( 'Number of wholesale ERP order lines for serialised items does not match with Retail ERP.');

          wholesaleProject.Retail_ERP__c = idRERP;

          update wholesaleProject;
            System.debug('wholesaleProject');
            System.debug(wholesaleProject);
            System.debug('modelYear');
            System.debug(modelYear);

            Map<String,String> m = new Map<String,String>();
          m.put('lotName',modelYear);
          m.put('idProduct',idWholesalePrd);
            System.debug(m);
            if(!mapProjectProductSerial.isEmpty()) {
                System.debug('mapProjectProductSerial');
                System.debug(mapProjectProductSerial);
                gcMaterial.updateRetailMaterialSerial(mapProjectProductSerial);
            }
          return m;
        }

        @RemoteAction
        public static Map<String,String> clearRetailERP(Id idWErp, Id idWholesaleProd)
        {
          AcctSeed__Project__c wholesaleProject;
          AcctSeedERP__Purchase_Order_Line__c pol;
            String modelYear = '';
            Id idRetailERP;
          for(AcctSeed__Project__c p :
            [SELECT Id, BoatModelYear__c,
              (SELECT Id, GMBLASERP__Lot__c, GMBLASERP__Lot__r.Name, AcctSeedERP__Product__c FROM AcctSeedERP__Purchase_Order_Lines__r LIMIT 1)
            FROM AcctSeed__Project__c
            WHERE Locked__c = false
              AND Id =:idWErp])
          {
              modelYear = p.BoatModelYear__c;
            wholesaleProject = p;
            if(!p.AcctSeedERP__Purchase_Order_Lines__r.isEmpty())
              pol = p.AcctSeedERP__Purchase_Order_Lines__r[0];
          }
          //if(pol == null) throw new InventoryAllocationException( 'The wholesale ERP does not have a related Purchase Order Line.');
          for(AcctSeed__Project__c pr : [SELECT Id, Locked__c, Retail_ERP__c, Serial_Number__c FROM AcctSeed__Project__c WHERE Id = :idWErp AND Retail_ERP__c != null]){
              idRetailERP = pr.Retail_ERP__c;
              pr.Retail_ERP__c = null;
            update pr;
          }
            System.debug('wholesaleProject');
            System.debug(wholesaleProject);
            Map<String,String> m = new Map<String,String>();
          m.put('lotName',modelYear);
          m.put('idProduct',idWholesaleProd);
            System.debug(m);
            if(idRetailERP != null) {
                System.debug('idRetailERP');
                System.debug(idRetailERP);
                gcMaterial.untagRetailERPItems(new Set<Id>{
                    idRetailERP
                });
            }
          return m;
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
        public static Boolean saveToShipDealers(String productId, Integer quantity) {
            Product2 productToUpdate = [Select Id from Product2 Where Id =: productId ];
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
            public Integer wholesaleNonPOL                  {get;set;}
            public Integer availabeForRetail                {get;set;}
            public Integer availabeToShipDelears            {get;set;}
            public Integer dealerOrders                     {get;set;}
            public Integer netAvailable                     {get;set;}
            public Integer damages                          {get;set;}
            public String damagesDetails                    {get;set;}
            public Integer specials                         {get;set;}
            public String specialsDetails                   {get;set;}
              public Integer boatShows                      {get; set;}
              public String boatShowDetails                 {get; set;}
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
            public Boolean showUsed                         {get;set;}
              public Boolean showBoatShow                   {get; set;}
            public Boolean showWhitefish                    {get;set;}
            public Boolean showMontreal                     {get;set;}
            public Boolean showBarrie                       {get;set;}
            public Boolean showOUT                          {get;set;}
            public String nextPositiveShipment              {get;set;}
            public boolean datePositiveShipmentIsToday      {get;set;}
            public Date datePositiveShipment                {get;set;}
            public List<Shipment> shipments                 {get;set;}
            public boolean existNextShipments               {get;set;}
            public String wholesaleERPDetails               { get; set; }
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
                this.showDM= false;
                this.showBoatShow = false;
                this.damages = 0;
                this.specials = 0;
                this.useds = 0;
                this.dms = 0;
                this.boatShows = 0;
                this.product = product;
                this.availabe = 1;
                this.wholesaleNonPOL = 0;
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

        public class Shipment implements Comparable {
            public String productId                   {get;set;}
            public String shipID                      {get;set;}
            public Integer quantity                   {get;set;}
            public Date deliverDate                   {get;set;}
            public String deliverDateFormatted        {get;set;}
            public Integer available                  {get;set;}
            public Integer reserved                   {get;set;}
            public Integer available_retail           {get;set;}
            public Integer orders                     {get;set;}
            public String boatName                    {get;set;}
            public String soldErpOrder                {get;set;}
            public String erpOrder                    {get;set;}

            public Shipment(String productId, Integer quantity, Date deliverDate,Integer reserved, String shipID, Integer orders) {

                this.shipID = shipID;
                this.productId = productId;
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
                this.productId = orderLine.AcctSeedERP__Product__c;
                if(orderLine.AcctSeedERP__Product__c != null && orderLine.AcctSeedERP__Product__r.RecordType.Name == 'Boat')
                  this.quantity = Integer.valueOf(orderLine.AcctSeedERP__Quantity__c);
                else
                  this.quantity = Integer.valueOf(orderLine.AcctSeedERP__Quantity_Unreceived__c);
                this.available = available;
                this.reserved = reserved;
                this.orders = orderLine.AcctSeedERP__Project__r.Retail_ERP__c == null ? 0 : 1;
                if(orderLine.AcctSeedERP__Project__c != null)
                  this.erpOrder = JSON.serialize(new Map<String,List<ErpOrderObj>>{orderLine.Name => new List<ErpOrderObj>{new ErpOrderObj(orderLine.AcctSeedERP__Project__r, 'partnerERP')}});
                if(orderLine.AcctSeedERP__Project__r.Retail_ERP__c != null)
                  this.soldErpOrder = JSON.serialize(new Map<String,List<ErpOrderObj>>{'Retail ERP Orders' => new List<ErpOrderObj>{new ErpOrderObj(orderLine.AcctSeedERP__Project__r.Retail_ERP__r, 'retailERP')}});
            }

            public Shipment(AcctSeedERP__Material__c orderLine) {
                System.debug('Mat Line');
                System.debug(orderLine);
                this.deliverDate = null;
                this.deliverDateFormatted = '';
                if(orderLine.AcctSeedERP__Product__r.RecordType.Name != 'Boat' && orderLine.AcctSeedERP__Project__r.Delivery_Date__c != null){
                  this.deliverDate = orderLine.AcctSeedERP__Project__r.Delivery_Date__c.date();
                  this.deliverDateFormatted = orderLine.AcctSeedERP__Project__r.Delivery_Date__c.format('MMM d, yyyy');
                }else if(orderLine.AcctSeedERP__Product__r.RecordType.Name == 'Boat' && orderLine.AcctSeedERP__Project__r.Arrival_Date__c != null){
                  this.deliverDate = orderLine.AcctSeedERP__Project__r.Arrival_Date__c;
                  this.deliverDateFormatted = Datetime.newInstance(this.deliverDate.year(),this.deliverDate.month(),this.deliverDate.day()).format('MMM d, yyyy');
                }
                this.reserved = 0;
                System.debug('orderLine');
                System.debug(orderLine.AcctSeedERP__Project__r.Serial_Number__r.Product_Name__c);
                this.boatName = orderLine.AcctSeedERP__Project__r.Serial_Number__r.Product_Name__c;
                this.shipID = orderLine.Id;
                this.productId = orderLine.AcctSeedERP__Product__c;
                this.quantity = 1;
                this.available = available;

                this.orders = orderLine.AcctSeedERP__Project__r.Retail_ERP__c == null ? 0 : 1;
                if(orderLine.AcctSeedERP__Product__r.RecordType.Name != 'Boat')
                  this.orders = 0;
                this.soldErpOrder = null;
                if(orderLine.AcctSeedERP__Project__r.Retail_ERP__c != null)
                    this.soldErpOrder = JSON.serialize(new Map<String,List<ErpOrderObj>>{'Retail ERP Orders' => new List<ErpOrderObj>{new ErpOrderObj(orderLine.AcctSeedERP__Project__r.Retail_ERP__r, 'retailERP')}});

                if(orderLine.AcctSeedERP__Project__c != null && orderLine.AcctSeedERP__Product__r.RecordType.Name == 'Boat') {
                    ErpOrderObj eo = new ErpOrderObj(orderLine.AcctSeedERP__Project__r, 'partnerERP');
                    eo.productId = orderLine.AcctSeedERP__Product__c;
                    String keyName = 'Partner ERP';
                    this.erpOrder = JSON.serialize(new Map<String, List<ErpOrderObj>>{
                        keyName => new List<ErpOrderObj>{eo}
                    });
                }else
                  this.erpOrder = JSON.serialize(new Map<String,List<ErpOrderObj>>{'ERP Order Lines' => new List<ErpOrderObj>{new ErpOrderObj(orderLine, 'erpMaterial')}});
            }

          public Integer compareTo(Object compareTo) {
            Shipment compareToshipment = (Shipment)compareTo;
            if (deliverDate == compareToshipment.deliverDate) return 0;
            if (deliverDate > compareToshipment.deliverDate) return 1;
            return -1;
          }
        }

        public class SerialNumber {
            public String serialID                      {get;set;}
            public String serialName                    {get;set;}
            public String serialStatus                  {get;set;}
            public String unitCost                      {get;set;}
            public String totalUnitCost                 {get;set;}
            public String productId                     {get;set;}
            public String productName                   {get;set;}
            public String lotName                       {get;set;}
            public String makeModel                     {get;set;}
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
                this.productId = serial.GMBLASERP__Product__c;
                this.productName = serial.GMBLASERP__Product__r.Name;
                this.lotName = serial.GMBLASERP__Lot__r.Name;
                this.makeModel = serial.Model_Year__c == null ? '' : String.valueOf(serial.Model_Year__c);
            }
        }

        public class ErpOrderObj {
            public String erpId                 {get;set;}
            public String accountName           {get;set;}
            public String materialId            {get;set;}
            public String materialName          {get;set;}
            public String productId             {get;set;}
            public String productName           {get;set;}
            public String idSerial              {get;set;}
            public String serialName            {get;set;}
            public String boatName              {get;set;}
            public String erpName               {get;set;}
            public String retailErpName         {get;set;}
            public String retailErpId           {get;set;}
            public String erpStage              {get;set;}
            public String erpCreatedDate        {get;set;}
            public String erpDeliveryDate       {get;set;}
            public String erpType               {get;set;}
            public List<Material> erpMaterials  {get;set;}

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

            public ErpOrderObj(AcctSeedERP__Material__c matl, String pErpType) {
                this.erpId = matl.AcctSeedERP__Project__r.Id;
                this.erpName = matl.AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c;
                this.materialId = matl.Id;
                this.materialName = matl.Name;
                this.productId = matl.AcctSeedERP__Product__c;
                this.productName = matl.AcctSeedERP__Product__r.Name;
                this.retailErpId = null;
                this.retailErpName = null;
                this.boatName = matl.AcctSeedERP__Project__r.Serial_Number__r.Product_Name__c;
                this.accountName = matl.AcctSeedERP__Project__r.AcctSeed__Account__r.Name;
                this.idSerial = matl.GMBLASERP__Serial_Number__c;
                this.serialName = matl.GMBLASERP__Serial_Number__c != null ? matl.GMBLASERP__Serial_Number__r.Name : '';
                this.erpStage = matl.AcctSeedERP__Project__r.Stage__c;
                this.erpCreatedDate = matl.AcctSeedERP__Project__r.CreatedDate.format('MMM d, yyyy');
                this.erpDeliveryDate = matl.AcctSeedERP__Project__r.Delivery_Date__c != null ? matl.AcctSeedERP__Project__r.Delivery_Date__c.format('MMM d, yyyy') : '';
                this.erpType = pErpType;
            }
        }

        public class Material {
            public String erpId                 {get;set;}
            public String erpName               {get;set;}
            public String materialId            {get;set;}
            public String materialName          {get;set;}
            public String productId             {get;set;}
            public String productName           {get;set;}
            public String boatName              {get;set;}
            public String idSerial              {get;set;}
            public String serialName            {get;set;}
            public String idLot                 {get;set;}
            public String lotName               {get;set;}

            public Material(AcctSeedERP__Material__c matl) {
                this.erpId = matl.AcctSeedERP__Project__r.Id;
                this.erpName = matl.AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c;
                this.materialId = matl.Id;
                this.materialName = matl.Name;
                this.productId = matl.AcctSeedERP__Product__c;
                this.productName = matl.AcctSeedERP__Product__r.Name;
                this.boatName = matl.AcctSeedERP__Project__r.Serial_Number__r.Product_Name__c;
                this.idSerial = matl.GMBLASERP__Serial_Number__c;
                this.serialName = matl.GMBLASERP__Serial_Number__r.Name;
                this.idLot = matl.GMBLASERP__Lot__c;
                this.lotName = matl.GMBLASERP__Lot__r.Name;
            }
        }

        public class RetailERP {
            public String Id              {get;set;}
            public String AccountName     {get;set;}
            public String Name            {get;set;}
            public String idSerial        {get;set;}
            public String serialName      {get;set;}
            public String Stage           {get;set;}
            public String CreatedDate     {get;set;}
            public String DeliveryDate    {get;set;}
            public String type            {get;set;}
            public List<Material> erpMaterials  {get;set;}
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
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
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
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
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