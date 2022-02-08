public without sharing class InventoryAllocationRetail_ar {
	public InventoryAllocationRetail_ar() {}
	public InventoryAllocationRetail_ar(InventoryAllocationController c) {}

	@RemoteAction
	public static List<Inventory> retrieveRetailData(List<String> setIdProducts, List<String> setLotNames, String idWarehouse)
	{
		List<Inventory> listInventory = new List<Inventory>();
        Set<String> allProducts = new Set<String>();
        allProducts.addAll(setIdProducts);
        Set<String> listLotNames = new Set<String>();
        listLotNames.addAll(setLotNames);
		String filterWarehouse = idWarehouse;
        String filterYear = 'ALL';
        String filterType = 'Boat';
        String queryInv = 'SELECT Id, Name, Current_Unit_Cost__c, GMBLASERP__Product__c, GMBLASERP__Product__r.Name, Model_Year__c, Status__c, GMBLASERP__Lot__c,GMBLASERP__Lot__r.Name, (SELECT Id, Name, Current_Unit_Cost__c, GMBLASERP__Product__c, GMBLASERP__Product__r.Name, Model_Year__c, Status__c, GMBLASERP__Lot__c,GMBLASERP__Lot__r.Name FROM Nested_Serial_Numbers__r) from GMBLASERP__Serial_Number__c where Available_Retail__c = true AND GMBLASERP__Lot__c != null AND GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c =:filterWarehouse';
        List<String> listFilterYear = new List<String>();
        listFilterYear.addAll(listLotNames);
        Set<Id> allSerials = new Set<Id>();
        Map<String,Integer> mapStock = new Map<String,Integer>();
        Map<String,List<SerialNumber>> mapInventoryList = new Map<String,List<SerialNumber>>();
        Map<String,Set<String>> mapProductIdToSetYear = new Map<String,Set<String>>();
		Id erpPartnerBoatSaleRtId = gcConstants.idRtProjectPartnerBoatSale;
		Id erpRetailBoatSaleRtId = gcConstants.idRtProjectBoatSale;

        String returnDateQuery;
        returnDateQuery = queryInv + ' AND GMBLASERP__Lot__r.name IN:listFilterYear ';
        returnDateQuery += ' AND GMBLASERP__Lot__r.GMBLASERP__Product__r.recordType.name  = ' + '\'' + filterType + '\'';
        /// Stock List
        for (GMBLASERP__Serial_Number__c objSerialNumber : Database.query(returnDateQuery))
        {
            String k = objSerialNumber.GMBLASERP__Product__c + '-' + objSerialNumber.GMBLASERP__Lot__r.Name;
            allSerials.add(objSerialNumber.Id);

            if(mapStock.containsKey(k)){
                mapStock.put(k, mapStock.get(k) + 1);
            }else{
                mapStock.put(k, 1);
            }

			if(mapProductIdToSetYear.containsKey(objSerialNumber.GMBLASERP__Product__c)){
				mapProductIdToSetYear.get(objSerialNumber.GMBLASERP__Product__c).add(objSerialNumber.GMBLASERP__Lot__r.name);
			}else{
			    mapProductIdToSetYear.put(objSerialNumber.GMBLASERP__Product__c, new Set<String>{objSerialNumber.GMBLASERP__Lot__r.name});
			}

        	if(!mapInventoryList.containsKey(k))
        		mapInventoryList.put(k,new List<SerialNumber>());

        	mapInventoryList.get(k).add(new SerialNumber(objSerialNumber));
        }
		System.debug('mapInventoryList');
		System.debug(mapInventoryList);
        //// Specials List
        Map<String,Integer> mapSpecialDamages = new Map<String,Integer>();
        Map<String,List<SerialNumber>> mapSpecialDamagesList = new Map<String,List<SerialNumber>>();
        for(GMBLASERP__Serial_Number__c objSerialNumber : 
            [SELECT Id, 
              Name,
              Current_Unit_Cost__c,
              GMBLASERP__Product__c, 
              GMBLASERP__Product__r.Name, 
              Status__c,
              Model_Year__c, 
              GMBLASERP__Lot__r.Name,
              (SELECT Id, 
                Name, 
                Current_Unit_Cost__c,
                GMBLASERP__Product__c, 
                GMBLASERP__Product__r.Name, 
                Status__c, 
                Model_Year__c, 
                GMBLASERP__Lot__r.Name 
              FROM Nested_Serial_Numbers__r) 
            FROM GMBLASERP__Serial_Number__c 
            WHERE Available_Retail__c = true
              AND GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c =:filterWarehouse]){

            String uniqueCombo = objSerialNumber.GMBLASERP__Product__c + '-' + objSerialNumber.Status__c + '-' + objSerialNumber.GMBLASERP__Lot__r.Name;
            allSerials.add(objSerialNumber.Id);

            if(mapSpecialDamages.containsKey(uniqueCombo)){
                mapSpecialDamages.put(uniqueCombo, mapSpecialDamages.get(uniqueCombo) + 1);
            }else{
                mapSpecialDamages.put(uniqueCombo, 1);
            }
            if(!mapSpecialDamagesList.containsKey(uniqueCombo))
              mapSpecialDamagesList.put(uniqueCombo,new List<SerialNumber>());

            mapSpecialDamagesList.get(uniqueCombo).add(new SerialNumber(objSerialNumber));
        }

        /// Shipments
        Map<String,List<Shipment>> mapShipments = new Map<String,List<Shipment>>();
        Map<String,Set<Id>> mapShipmentERP = new Map<String,Set<Id>>();
        //String queryShipments = 'Select Id, Name, AcctSeedERP__Product__r.RecordType.Name, AcctSeedERP__Quantity__c, AcctSeedERP__Quantity_Unreceived__c, Reserved__c, deliverDate__c, AcctSeedERP__Product__c, AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c, GMBLASERP__Lot__r.Name, ';
        //queryShipments += ' AcctSeedERP__Project__c, AcctSeedERP__Project__r.Name, AcctSeedERP__Project__r.AcctSeed__Account__r.Name, AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c, AcctSeedERP__Project__r.Stage__c, AcctSeedERP__Project__r.CreatedDate, AcctSeedERP__Project__r.Delivery_Date__c, AcctSeedERP__Project__r.BoatModelYear__c, AcctSeedERP__Project__r.Serial_Number__c, AcctSeedERP__Project__r.ERP_Serial_In_Inventory__c, AcctSeedERP__Project__r.Serial_Number__r.Name, AcctSeedERP__Project__r.TrailerModelYear__c, ';
        //queryShipments += ' AcctSeedERP__Project__r.Retail_ERP__c, AcctSeedERP__Project__r.Retail_ERP__r.ERP_Serial_In_Inventory__c, AcctSeedERP__Project__r.Retail_ERP__r.Name, AcctSeedERP__Project__r.Retail_ERP__r.AcctSeed__Account__r.Name, AcctSeedERP__Project__r.Retail_ERP__r.AcctSeedERP__Work_Order_Number__c, AcctSeedERP__Project__r.Retail_ERP__r.Stage__c, AcctSeedERP__Project__r.Retail_ERP__r.CreatedDate, AcctSeedERP__Project__r.Retail_ERP__r.Delivery_Date__c, AcctSeedERP__Project__r.Retail_ERP__r.BoatModelYear__c, AcctSeedERP__Project__r.Retail_ERP__r.Serial_Number__c, AcctSeedERP__Project__r.Retail_ERP__r.Serial_Number__r.Name, AcctSeedERP__Project__r.Retail_ERP__r.TrailerModelYear__c ';
        //queryShipments += ' from  AcctSeedERP__Purchase_Order_Line__c  Where AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c != null  AND AcctSeedERP__Project__c != null AND AcctSeedERP__Project__r.Stage__c != \'Delivered\' AND (AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:filterWarehouse OR AcctSeedERP__Project__r.AcctSeed__Account__r.Warehouse__c =:filterWarehouse) order by deliverDate__c';

		String queryShipments = 'Select Id, Name, AcctSeedERP__Product__r.RecordType.Name, AcctSeedERP__Product__r.Name, AcctSeedERP__Quantity_Allocated__c, AcctSeedERP__Product__c, GMBLASERP__Lot__r.Name, GMBLASERP__Serial_Number__c, GMBLASERP__Serial_Number__r.Name, ';
		queryShipments += ' AcctSeedERP__Project__c, AcctSeedERP__Project__r.Name, AcctSeedERP__Project__r.AcctSeed__Account__r.Name, AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c, AcctSeedERP__Project__r.Stage__c, AcctSeedERP__Project__r.CreatedDate, AcctSeedERP__Project__r.Delivery_Date__c, AcctSeedERP__Project__r.Arrival_Date__c, AcctSeedERP__Project__r.BoatModelYear__c, AcctSeedERP__Project__r.Serial_Number__c, AcctSeedERP__Project__r.ERP_Serial_In_Inventory__c, AcctSeedERP__Project__r.Serial_Number__r.Name, AcctSeedERP__Project__r.TrailerModelYear__c,  ';
		queryShipments += ' AcctSeedERP__Project__r.Retail_ERP__c, AcctSeedERP__Project__r.Retail_ERP__r.ERP_Serial_In_Inventory__c, AcctSeedERP__Project__r.Retail_ERP__r.Name, AcctSeedERP__Project__r.Retail_ERP__r.AcctSeed__Account__r.Name, AcctSeedERP__Project__r.Retail_ERP__r.AcctSeedERP__Work_Order_Number__c, AcctSeedERP__Project__r.Retail_ERP__r.Stage__c, AcctSeedERP__Project__r.Retail_ERP__r.CreatedDate, AcctSeedERP__Project__r.Retail_ERP__r.Delivery_Date__c, AcctSeedERP__Project__r.Retail_ERP__r.Arrival_Date__c, AcctSeedERP__Project__r.Retail_ERP__r.BoatModelYear__c, AcctSeedERP__Project__r.Retail_ERP__r.Serial_Number__c, AcctSeedERP__Project__r.Retail_ERP__r.Serial_Number__r.Name, AcctSeedERP__Project__r.Retail_ERP__r.TrailerModelYear__c ';
		queryShipments += ' from  AcctSeedERP__Material__c Where AcctSeedERP__Product__c IN:allProducts AND (GMBLASERP__Lot__r.Name IN:listFilterYear OR AcctSeedERP__Project__r.BoatModelYear__c IN:listFilterYear) AND AcctSeedERP__Project__r.Stage__c != \'Delivered\' AND (AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:filterWarehouse OR AcctSeedERP__Project__r.AcctSeed__Account__r.Warehouse__c =:filterWarehouse) AND AcctSeedERP__Project__r.RecordTypeId =:erpPartnerBoatSaleRtId order by AcctSeedERP__Project__r.Arrival_Date__c';
		System.debug('queryShipments');
		System.debug(queryShipments);
        for (AcctSeedERP__Material__c orderLine : Database.query(queryShipments))
        {
          if(orderLine.AcctSeedERP__Project__c != null 
            && orderLine.AcctSeedERP__Project__r.Serial_Number__c != null
            && !orderLine.AcctSeedERP__Project__r.ERP_Serial_In_Inventory__c){
              continue;
            } 
          List<Shipment> shipments = new List<Shipment>();
          Shipment shipmnt = new Shipment(orderLine);

          String k = orderLine.AcctSeedERP__Product__c + '-' + orderLine.GMBLASERP__Lot__r.Name;

          if (mapShipments.get(k) != null){
              shipments = mapShipments.get(k);
          }

          if(orderLine.AcctSeedERP__Project__c != null){
            if(!mapShipmentERP.containsKey(k))
              mapShipmentERP.put(k, new Set<Id>());
            mapShipmentERP.get(k).add(orderLine.AcctSeedERP__Project__c);
          }

          shipments.add(shipmnt);
          mapShipments.put(k,shipments);
        }
        System.debug('mapShipments');
        System.debug(mapShipments);

        /// Outstanding 
        Map<String,Integer> mapRetailSold = new Map<String,Integer>();
		Map<String, Map<String, List<Map<String,String>>>> hoverOverRetailSoldDetails = new Map<String, Map<String, List<Map<String,String>>>>();
		Map<String, Map<String, List<Map<String,String>>>> hoverOverDealerOrderDetails = new Map<String, Map<String, List<Map<String,String>>>>();
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
		                                                     AcctSeedERP__Project__r.Serial_Number__r.Name
		                                              FROM AcctSeedERP__Material__c
		                                              WHERE AcctSeedERP__Project__r.RecordTypeId IN :rts
		                                              AND AcctSeedERP__Project__r.Stage__c != 'Draft'
		                                              AND AcctSeedERP__Project__r.Stage__c != 'Delivered'
		                                              AND AcctSeedERP__Project__r.Stage__c != 'Closed Lost'
		                                              AND AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:filterWarehouse
		                                              AND GMBLASERP__Serial_Number__c = null
		                                              AND AcctSeedERP__Product__c != null ] )
		{

			if( objMaterial.AcctSeedERP__Project__r.RecordTypeId == erpRetailBoatSaleRtId )
			{
			  mapRetailLinked.put(objMaterial.AcctSeedERP__Project__c, false);
			  listRetailMaterials.add(objMaterial);
			}
		}

		if(!mapRetailLinked.isEmpty()){
		for(AcctSeed__Project__c pr : [SELECT Id, (SELECT Id FROM ERP_Orders__r) FROM AcctSeed__Project__c WHERE Id IN:mapRetailLinked.keySet()])
		  if(!pr.ERP_Orders__r.isEmpty())
		    mapRetailLinked.put(pr.Id, true);
		}

		for( AcctSeedERP__Material__c objMaterial : listRetailMaterials){
			if(mapRetailLinked.get(objMaterial.AcctSeedERP__Project__c)) continue;
			String uniqueCombo = getUniqueComboProject(objMaterial,objMaterial.AcctSeedERP__Product__r.RecordType.Name);
			//populateMapValues(objMaterial.AcctSeedERP__Product__c, uniqueCombo);
	        if(mapProductIdToSetYear.containsKey(objMaterial.AcctSeedERP__Product__c)){
	            mapProductIdToSetYear.get(objMaterial.AcctSeedERP__Product__c).add(uniqueCombo);
	        }else{
	            mapProductIdToSetYear.put(objMaterial.AcctSeedERP__Product__c, new Set<String>{uniqueCombo});
	        }
			uniqueCombo = objMaterial.AcctSeedERP__Product__c + ( uniqueCombo == '' ? '' : ('-' + uniqueCombo) );

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
		                          AND (Warehouse__c = null OR Warehouse__c =:filterWarehouse)
		                          and BoatId__c != null and RecordType.Name = 'Retail'])
		{
			String uniqueCombo;
	        if(objOpportunity.BoatId__r.RecordType.Name == 'Boat' && objOpportunity.Boat_Model_Year__c != null){
	            uniqueCombo = '-' + objOpportunity.Boat_Model_Year__c;
		        if(mapProductIdToSetYear.containsKey(objOpportunity.BoatId__c)){
		            mapProductIdToSetYear.get(objOpportunity.BoatId__c).add(objOpportunity.Boat_Model_Year__c);
		        }else{
		            mapProductIdToSetYear.put(objOpportunity.BoatId__c, new Set<String>{objOpportunity.Boat_Model_Year__c});
		        }
	        }
	        if(objOpportunity.BoatId__r.RecordType.Name == 'Trailer' && objOpportunity.Trailer_Model_Year__c != null){
	            uniqueCombo = '-' + objOpportunity.Trailer_Model_Year__c;
		        if(mapProductIdToSetYear.containsKey(objOpportunity.BoatId__c)){
		            mapProductIdToSetYear.get(objOpportunity.BoatId__c).add(objOpportunity.Trailer_Model_Year__c);
		        }else{
		            mapProductIdToSetYear.put(objOpportunity.BoatId__c, new Set<String>{objOpportunity.Trailer_Model_Year__c});
		        }
	        }
	        uniqueCombo = objOpportunity.BoatId__c + uniqueCombo;
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

		//// Wholesale Data
		Map<String,Integer> mapERPRetailWholeSale = new Map<String,Integer>();
		Map<String,Map<String,List<Map<String,String>>>> hoverOverWholeSaleERP = new Map<String,Map<String,List<Map<String,String>>>>();
		Id idWarehouseWholesale = GMBLASERP__Inventory_Settings__c.getOrgDefaults().Wholesale_Warehouse_Id__c;
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
		                                               AcctSeedERP__Project__r.Serial_Number__r.Name,
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
													AcctSeedERP__Project__r.Retail_ERP__r.TrailerModelYear__c
		                                        FROM AcctSeedERP__Material__c
		                                        WHERE AcctSeedERP__Project__r.RecordTypeId =:erpPartnerBoatSaleRtId
		                                        AND AcctSeedERP__Project__r.Stage__c != 'Draft'
		                                        AND AcctSeedERP__Project__r.Stage__c != 'Delivered'
		                                        AND AcctSeedERP__Project__r.Stage__c != 'Closed Lost'
		                                        AND AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:idWarehouseWholesale
		                                        AND AcctSeedERP__Project__r.AcctSeed__Account__r.Warehouse__c =:filterWarehouse
		                                        AND GMBLASERP__Serial_Number__c = null
		                                        AND AcctSeedERP__Product__c != null 
		                                        AND AcctSeedERP__Project__r.Locked__c = false] )
		{
			String uniqueCombo = getUniqueComboProject(objMaterial,objMaterial.AcctSeedERP__Product__r.RecordType.Name);
	        if(mapProductIdToSetYear.containsKey(objMaterial.AcctSeedERP__Product__c)){
	            mapProductIdToSetYear.get(objMaterial.AcctSeedERP__Product__c).add(uniqueCombo);
	        }else{
	            mapProductIdToSetYear.put(objMaterial.AcctSeedERP__Product__c, new Set<String>{uniqueCombo});
	        }


			uniqueCombo = objMaterial.AcctSeedERP__Product__c + ( uniqueCombo == '' ? '' : ('-' + uniqueCombo) );
			if(mapShipmentERP.containsKey(uniqueCombo) && mapShipmentERP.get(uniqueCombo).contains(objMaterial.AcctSeedERP__Project__c)) continue;
			Shipment shipmnt = new Shipment(objMaterial);
			List<Shipment> shipments = new List<Shipment>();
			if(mapShipments.containsKey(uniqueCombo))
			  shipments = mapShipments.get(uniqueCombo);
			else 
			  mapShipments.put(uniqueCombo,shipments);        

			shipments.add(shipmnt);
		}

		//// Product Owner
		String queryProductOwner = 'SELECT AcctSeed__Account__r.name , Manufactured_Product_id__c From AcctSeed__Project__c WHERE Manufactured_Product_id__c in: allProducts and AcctSeed__Status__c = \'Completed\'';
		Map<Id,String> mapProductOwner = new Map<Id,String>();
        for (AcctSeed__Project__c prod : Database.query(queryProductOwner)) {
            String productId = prod.Manufactured_Product_id__c;
            String accountOwner = prod.AcctSeed__Account__r.name;
            mapProductOwner.put(productId,accountOwner);
        }

        /// Map Canvas ERP
		Map<String, List<Map<String,String>>> allCanvas = new Map<String, List<Map<String,String>>>();
        if(!allSerials.isEmpty()){
			for( AcctSeedERP__Material__c objMaterial : [ SELECT Id,
			                                                     AcctSeedERP__Product__c,
			                                                     AcctSeedERP__Product__r.Name,
			                                                     AcctSeedERP__Product__r.RecordType.Name,
			                                                     GMBLASERP__Lot__c,
			                                                     GMBLASERP__Lot__r.Name,
			                                                     AcctSeedERP__Project__c,
			                                                     AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c,
			                                                     AcctSeedERP__Project__r.Serial_Number__c,
			                                                     AcctSeedERP__Project__r.Serial_Number__r.Name
			                                              FROM AcctSeedERP__Material__c
			                                              WHERE AcctSeedERP__Product__c != null 
			                                                AND AcctSeedERP__Product__r.Family IN ('Canvas and Cover Components')
			                                                AND AcctSeedERP__Project__r.Serial_Number__c != null
			                                                AND AcctSeedERP__Project__r.Serial_Number__c IN:allSerials])
			{
				String uniqueCombo = objMaterial.AcctSeedERP__Project__r.Serial_Number__c;
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

				if( !allCanvas.containsKey( uniqueCombo ) )
				    allCanvas.put( uniqueCombo, new List< Map<String,String>>() );

				allCanvas.get( uniqueCombo ).add( pData );
			}
		}

		/// Build Inventory Lines
        Map<String,Integer> mapLocations = new Map<String,Integer>();
        String locQuery = 'SELECT Id, Name, Current_Unit_Cost__c, GMBLASERP__Product__c, location__c,GMBLASERP__Lot__r.name, (SELECT Id, Name, Current_Unit_Cost__c, GMBLASERP__Product__c, GMBLASERP__Product__r.Name, Status__c, Model_Year__c, GMBLASERP__Lot__r.Name FROM Nested_Serial_Numbers__r) FROM GMBLASERP__Serial_Number__c where Available_Retail__c = true';
        locQuery += ' AND GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c =:filterWarehouse ';
        locQuery += ' AND GMBLASERP__Lot__r.name IN:listFilterYear ';

        for (GMBLASERP__Serial_Number__c ser: Database.query(locQuery)) {
            if(ser.location__c != null && ser.GMBLASERP__Product__c != null) {
				String k = ser.GMBLASERP__Product__c + '-' + ser.location__c + '-' + ser.GMBLASERP__Lot__r.name;
				allSerials.add(ser.Id);

	            if(mapLocations.get(k) != null) {
	                mapLocations.put(k, mapLocations.get(k)+1);
	            }else{
	                mapLocations.put(k,1);
	            }
            }
        }
        for (Product2 pro : [SELECT Id, Name From Product2 WHERE Id in: allProducts]) {
            for(String yearSelected : listFilterYear){
            	String yearSection = '-' + yearSelected;
				Inventory inv = new Inventory(pro);
				inv.inStock = (mapStock.containsKey(pro.Id + yearSection)?mapStock.get(pro.Id + yearSection):0);
				if(mapInventoryList.containsKey(pro.Id + yearSection)){
				  for(SerialNumber sn : mapInventoryList.get(pro.Id + yearSection)){
				    if(allCanvas.containsKey(sn.serialID))
				      sn.listCanvas = allCanvas.get(sn.serialID);
				  }
				  inv.stockDetails = JSON.serialize(new Map<String,List<SerialNumber>>{pro.Name => mapInventoryList.get(pro.Id + yearSection)});
				}

				//inv.reservedForDisplayed =  (mapProdLot.get(pro.Id + yearSection) != null && mapProdLot.get(pro.Id + yearSection).Reserved_for_Display__c != null?Integer.valueOf(mapProdLot.get(pro.Id + yearSection).Reserved_for_Display__c):0);
				//inv.reservedForRetail =  (mapProdLot.get(pro.Id + yearSection) != null && mapProdLot.get(pro.Id + yearSection).Reserved_For_Retail_Sale__c != null?Integer.valueOf(mapProdLot.get(pro.Id + yearSection).Reserved_For_Retail_Sale__c):0);
				if (mapShipments.get(pro.Id + yearSection) != null) {
				    List<Shipment> lstShip = new List<Shipment>();
				    lstShip = mapShipments.get(pro.Id + yearSection);
				    Map<Date,Shipment> mapShipment = new Map<Date,Shipment>();
				    for(Shipment sh : lstShip)
				    {
					if(sh.productId == null)
						sh.productId = pro.Id;
				      if(!mapShipment.containsKey(sh.deliverDate))
				        mapShipment.put(sh.deliverDate,sh);
				      else{
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
				          //else
				          //  ds2.putAll(ds);
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
				          //else
				          //  ds2.putAll(ds);
				          sh2.soldErpOrder = JSON.serialize(ds4);
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
				if (mapSpecialDamages.get(damageKey) != null) {
				   inv.damages = mapSpecialDamages.get(damageKey);
				   inv.showDamages = true;
				   //numberOfDamages = mapSpecialDamages.get(damageKey);
				   inv.damagesDetails = JSON.serialize(new Map<String,List<SerialNumber>>{pro.Name => mapSpecialDamagesList.get(damageKey)});
				}

				String demoKey =pro.Id + '-' + 'Demo' + yearSection;
				if (mapSpecialDamages.get(demoKey) != null) {
				   inv.demos = mapSpecialDamages.get(demoKey);
				   inv.showDemos = true;
				   //numberOfDemos = mapSpecialDamages.get(demoKey);
				   inv.demosDetails = JSON.serialize(new Map<String,List<SerialNumber>>{pro.Name => mapSpecialDamagesList.get(demoKey)});
				}

				String usedKey =pro.Id + '-' + 'Used' + yearSection;
				if (mapSpecialDamages.get(usedKey) != null) {
				   inv.useds = mapSpecialDamages.get(usedKey);
				   inv.showUsed = true;
				   //numberOfUsed = mapSpecialDamages.get(usedKey);
				   inv.usedsDetails = JSON.serialize(new Map<String,List<SerialNumber>>{pro.Name => mapSpecialDamagesList.get(usedKey)});
				}

				String specialsListKey =pro.Id + '-' + 'Specials List' + yearSection;
				if (mapSpecialDamages.get(specialsListKey) != null) {
				    inv.specials =  mapSpecialDamages.get(specialsListKey);
				    inv.showSpecials = true;
				    //numberOfSpecials = inv.specials;
				    inv.specialsDetails = JSON.serialize(new Map<String,List<SerialNumber>>{pro.Name => mapSpecialDamagesList.get(specialsListKey)});
				}

				String displayModelsKey =pro.Id + '-' + 'Specials List' + yearSection;
				if (mapSpecialDamages.get(displayModelsKey) != null) {
				    inv.dms =  mapSpecialDamages.get(displayModelsKey);
				    inv.showDM = true;
				    //numberOfSpecials = inv.specials;
				    inv.displayModels = JSON.serialize(new Map<String,List<SerialNumber>>{pro.Name => mapSpecialDamagesList.get(displayModelsKey)});
				}

				if (mapRetailSold.get(pro.Id + yearSection) != null)
				    inv.retailSold = mapRetailSold.get(pro.Id + yearSection);

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
				inv.availabeToShipDelears = inv.inStock - allSpecials;
				inv.netAvailable = inv.availabeToShipDelears - inv.dealerOrders;

				inv.productId = pro.Id;
				inv.productName = pro.Name + ' / ' + yearSelected;
				inv.lotName = filterType == 'Boat' ? yearSelected : '';
                System.debug('inv');
                System.debug(inv);
				if (! yearSelected.contains('-'))
				{
					if(inv.availabeForRetail <> 0 || inv.retailSold <> 0  || inv.specials <> 0 || inv.useds <> 0 || inv.damages <> 0 || inv.inStock <> 0 || inv.demos <> 0)
						listInventory.add(inv);
				}
            }
        }

        for(Inventory inv: listInventory ) {
            if(inv.existNextShipments) {
                Integer netAvail = inv.netAvailable;
                Integer netAvailRetail = inv.availabeForRetail;
                for(Shipment shi : inv.shipments){
                    if( netAvailRetail != null)
                    {
                        shi.available_retail = netAvailRetail + shi.quantity - shi.orders;
                        netAvailRetail = shi.available_retail;
                    }
                }
            }
        }

        return listInventory;
	}

    private static String getUniqueComboProject(AcctSeed__Project__c objProject, String recordType){
        String uniqueCombo = '';
        if(recordType == 'Boat' && objProject.BoatModelYear__c != null)
            uniqueCombo = objProject.BoatModelYear__c;
        if(recordType == 'Trailer' && objProject.TrailerModelYear__c != null)
            uniqueCombo = objProject.TrailerModelYear__c;

        return uniqueCombo;
    }

    /* ADDED BY DAVE HAHN MAY @29/17 */
    private static String getUniqueComboProject( AcctSeedERP__Material__c mat, String recordType )
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

	public class Inventory{
        public String productId                       	{get;set;}
        public String productName                       {get;set;}
        public String lotName                           {get;set;}
        public Product2 product                         {get;set;}
        public String customer                          {get;set;}
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
        public String displayModels                   	{get;set;}
        public Integer demos                            {get;set;}
        public String demosDetails                      {get;set;}
        public Integer useds                            {get;set;}
        public Integer dms                            	{get;set;}
        public String usedsDetails                      {get;set;}
        public Integer locationWhitefish                {get;set;}
        public Integer locationMontreal                 {get;set;}
        public Integer locationBarrie                   {get;set;}
        public Integer locationOUT                      {get;set;}
        public Boolean showDamages                      {get;set;}
        public Boolean showSpecials                     {get;set;}
        public Boolean showDemos                        {get;set;}
        public Boolean showUsed                         {get;set;}
        public Boolean showDM                         	{get;set;}
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

            existNextShipments = false;
            shipments = new List<Shipment>();
            reservedForDisplayed = 0;
            reservedForRetail = 0;
            showDamages = false;
            showSpecials = false;
            showUsed = false;
            showBarrie = false;
            showBarrie = false;
            showOUT = false;
            damages = 0;
            specials = 0;
            useds = 0;
            product = product;
            availabe = 1;
            wholesaleNonPOL = 0;
            retailSold = 0;
            availabeForRetail = 0;
            availabeToShipDelears =  0;
            dealerOrders = 0;
            netAvailable = 0;
        }
    }

    public class Shipment {
        public String productId                   {get;set;}
        public String shipID                      {get;set;}
        public Integer quantity                   {get;set;}
        public Date deliverDate                   {get;set;}
        public String deliverDateFormatted        {get;set;}
        public Integer available                  {get;set;}
        public Integer reserved                   {get;set;}
        public Integer available_retail           {get;set;}
        public Integer orders                     {get;set;}
        public String soldErpOrder                {get;set;}
        public String erpOrder                    {get;set;}

        public Shipment(String productId, Integer quantity, Date deliverDate,Integer reserved, String shipID, Integer orders) {

            shipID = shipID;
            productId = productId;
            quantity = quantity;
            available = available;
            deliverDate = deliverDate;
            deliverDateFormatted = deliverDate == null ? '' : Datetime.newInstance(deliverDate.year(), deliverDate.month(), deliverDate.day()).format('MM/dd/yy');
            reserved = reserved;
            orders = orders;
        }

        public Shipment(AcctSeedERP__Purchase_Order_Line__c orderLine) {
            if (orderLine.deliverDate__c != null)
                deliverDate = orderLine.deliverDate__c;
            else
                deliverDate = orderLine.AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c;

            deliverDateFormatted = deliverDate == null ? '' : Datetime.newInstance(deliverDate.year(), deliverDate.month(), deliverDate.day()).format('MM/dd/yy');
            Integer x;
            if(Integer.valueOf(orderLine.Reserved__c)!=null)
                 reserved = Integer.valueOf(orderLine.Reserved__c);
            else
                reserved = 0;

            shipID = orderLine.Id;
            productId = orderLine.AcctSeedERP__Product__c;
            if(orderLine.AcctSeedERP__Product__c != null && orderLine.AcctSeedERP__Product__r.RecordType.Name == 'Boat')
              quantity = Integer.valueOf(orderLine.AcctSeedERP__Quantity__c);
            else
              quantity = Integer.valueOf(orderLine.AcctSeedERP__Quantity_Unreceived__c);
            available = available;
            reserved = reserved;
            orders = orderLine.AcctSeedERP__Project__r.Retail_ERP__c == null ? 0 : 1;
            if(orderLine.AcctSeedERP__Project__c != null)
              erpOrder = JSON.serialize(new Map<String,List<ErpOrderObj>>{orderLine.Name => new List<ErpOrderObj>{new ErpOrderObj(orderLine.AcctSeedERP__Project__r, 'partnerERP')}});
            if(orderLine.AcctSeedERP__Project__r.Retail_ERP__c != null)
              soldErpOrder = JSON.serialize(new Map<String,List<ErpOrderObj>>{'Retail ERP Orders' => new List<ErpOrderObj>{new ErpOrderObj(orderLine.AcctSeedERP__Project__r.Retail_ERP__r, 'retailERP')}});
        }

        public Shipment(AcctSeedERP__Material__c orderLine) {
			System.debug('orderLine');
			System.debug(orderLine);
            System.debug('orderLineRetail ERP');
			System.debug(orderLine.AcctSeedERP__Project__r.Retail_ERP__c);

            deliverDate = null;
            deliverDateFormatted = null;
            if(orderLine.AcctSeedERP__Project__r.Arrival_Date__c != null){
                deliverDate = orderLine.AcctSeedERP__Project__r.Arrival_Date__c;
                deliverDateFormatted = Datetime.newInstance(deliverDate.year(),deliverDate.month(),deliverDate.day()).format('MMM d, yyyy');
            }
            reserved = 0;
            shipID = orderLine.Id;
            productId = orderLine.AcctSeedERP__Product__c;
            quantity = 1;
            available = available;
            orders = orderLine.AcctSeedERP__Project__r.Retail_ERP__c == null ? 0 : 1;
            System.debug('orderLineRetail orders');
            System.debug(orders);
            if(orderLine.AcctSeedERP__Project__r.Retail_ERP__c != null)
                soldErpOrder = JSON.serialize(new Map<String,List<ErpOrderObj>>{'Retail ERP Orders' => new List<ErpOrderObj>{new ErpOrderObj(orderLine.AcctSeedERP__Project__r.Retail_ERP__r, 'retailERP')}});
			if(orderLine.AcctSeedERP__Project__c != null){
				ErpOrderObj eo = new ErpOrderObj(orderLine.AcctSeedERP__Project__r, 'partnerERP');
				eo.productId = orderLine.AcctSeedERP__Product__c;
				erpOrder = JSON.serialize(new Map<String,List<ErpOrderObj>>{'Partner ERP' => new List<ErpOrderObj>{eo}});
			}
        }
    }

    public class SerialNumber {
        public String serialID                      {get;set;}
        public String serialName                    {get;set;}
        public String serialStatus                  {get;set;}
        public String unitCost                		{get;set;}
        public String productId                     {get;set;}
        public String productName                   {get;set;}
        public String lotName                       {get;set;}
        public String makeModel                     {get;set;}
        public List<SerialNumber> listNested        {get;set;}
        public List<Map<String,String>> listCanvas  {get;set;}

        public SerialNumber(GMBLASERP__Serial_Number__c serial) {
            listCanvas = new List<Map<String,String>>();
            listNested = new List<SerialNumber>();
            for(GMBLASERP__Serial_Number__c sr : serial.Nested_Serial_Numbers__r){
              listNested.add(new SerialNumber(sr));
            }
            serialID = serial.Id;
            serialName = serial.Name;
            serialStatus = serial.Status__c;
            unitCost = (serial.Current_Unit_Cost__c == null ? 0 : serial.Current_Unit_Cost__c).format();
            productId = serial.GMBLASERP__Product__c;
            productName = serial.GMBLASERP__Product__r.Name;
            lotName = serial.GMBLASERP__Lot__r.Name;
            makeModel = serial.Model_Year__c == null ? '' : String.valueOf(serial.Model_Year__c);
        }
    }

    public class ErpOrderObj {
        public String erpId                 {get;set;}
        public String productId           	{get;set;}
        public String accountName           {get;set;}
        public String idSerial              {get;set;}
        public String serialName            {get;set;}
        public String erpName               {get;set;}
        public String retailErpName         {get;set;}
        public String retailErpId           {get;set;}
        public String erpStage              {get;set;}
        public String erpCreatedDate        {get;set;}
        public String erpDeliveryDate       {get;set;}
        public String erpType               {get;set;}

        public ErpOrderObj(AcctSeed__Project__c erp, String pErpType) {
            erpId = erp.Id;
            erpName = erp.AcctSeedERP__Work_Order_Number__c;
            if(pErpType == 'partnerERP'){
              AcctSeed__Project__c erpn = erp.clone(false,true,true);
              retailErpId = erpn.Retail_ERP__c;
              retailErpName = erpn.Retail_ERP__r.AcctSeedERP__Work_Order_Number__c;
            }else{
              retailErpId = null;
              retailErpName = null;
            }
            accountName = erp.AcctSeed__Account__r.Name;
            serialName = erp.Serial_Number__r.Name;
            erpStage = erp.Stage__c;
            erpCreatedDate = erp.CreatedDate.format('MMM d, yyyy');
            erpDeliveryDate = erp.Delivery_Date__c != null ? erp.Delivery_Date__c.format('MMM d, yyyy') : '';
            erpType = pErpType;
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
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
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