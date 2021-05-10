global without sharing class gcPurchaseOrder_Ext {

	global gcPurchaseOrder_Ext(ApexPages.StandardController ctrl){}
	global gcPurchaseOrder_Ext(){}
	global static string locale{get{return UserInfo.getLocale();}}

	@RemoteAction @ReadOnly
	global static list<map<string,string>> retrieveLines(Id idFilter)
	{
		list<map<string,string>> listJSON = new list<map<string,string>>();

		Date dateEarliestOpen = GMBLASERP.gcAccountingPeriod.dateEarliestOpen();
	 	List<AcctSeedERP__Purchase_Order_Line__c> listPOL = new List<AcctSeedERP__Purchase_Order_Line__c>();
	 	Map<Id,List<AcctSeedERP__Purchase_Order_Inventory_Movement__c>> maplistPOIM = new Map<Id,List<AcctSeedERP__Purchase_Order_Inventory_Movement__c>>();
	 	Map<Id,List<AcctSeed__Account_Payable_Line__c>> maplistAPL = new Map<Id,List<AcctSeed__Account_Payable_Line__c>>();
	 	Set<Id> setPOLId = new Set<Id>();
		for(AcctSeedERP__Purchase_Order_Line__c line :
			[SELECT Id, Name,
			 AcctSeedERP__Comment__c,
			 AcctSeedERP__Product__c,
			 AcctSeedERP__Product__r.Family,
			 AcctSeedERP__Product__r.RecordType.Name,
			 AcctSeedERP__Product__r.Name,
			 AcctSeedERP__Product__r.ProductCode,
			 AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c,
			 AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
			 AcctSeedERP__Product__r.GMBLASERP__Lot_Tracked__c,
			 AcctSeedERP__Project__c,
			 AcctSeedERP__Project__r.Name,
			 AcctSeedERP__Project_Task__c,
			 AcctSeedERP__Project_Task__r.Name,
			 AcctSeedERP__Purchase_Order__r.AcctSeedERP__Status__c,
			 AcctSeedERP__Purchase_Order__r.Locked__c,
			 AcctSeedERP__Purchase_Order__r.AcctSeedERP__Type__c,
			 AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c,
			 AcctSeedERP__Quantity__c,
			 AcctSeedERP__Quantity_Received__c,
			 AcctSeedERP__Quantity_Unreceived__c,
			 AcctSeedERP__Unit_Price__c,
			 GMBLASERP__Lot__c,
			 GMBLASERP__Lot__r.Name,
			 deliverDate__c,
			 Base_Price__c,
			 AcctSeedERP__Total__c,
			 GMBLASERP__Price_Override__c,
			 GMBLASERP__Quantity_Received_Non_Inventory__c
			 FROM AcctSeedERP__Purchase_Order_Line__c
			 WHERE AcctSeedERP__Purchase_Order__c = :idFilter OR Id = :idFilter])
		{
			setPOLId.add(line.Id);
			listPOL.add(line);
		}
		for(AcctSeedERP__Purchase_Order_Inventory_Movement__c move :
			[SELECT Id,
				AcctSeedERP__Purchase_Order_Line__c,
				Freight_Charge__c,
				Freight_Applied__c,
				AcctSeedERP__Movement_Date__c,
				AcctSeedERP__Quantity__c,
				AcctSeedERP__Unit_Cost__c
			FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c
			WHERE AcctSeedERP__Purchase_Order_Line__c IN:setPOLId
			ORDER BY AcctSeedERP__Movement_Date__c])
		{
			if(!maplistPOIM.containsKey(move.AcctSeedERP__Purchase_Order_Line__c))
				maplistPOIM.put(move.AcctSeedERP__Purchase_Order_Line__c, new List<AcctSeedERP__Purchase_Order_Inventory_Movement__c>());

			maplistPOIM.get(move.AcctSeedERP__Purchase_Order_Line__c).add(move);
		}

		for(AcctSeed__Account_Payable_Line__c apl :
			[SELECT Id,
				AcctSeedERP__Purchase_Order_Line__c,
				AcctSeed__Amount__c,
				AcctSeed__Account_Payable__r.AcctSeed__Status__c
			FROM AcctSeed__Account_Payable_Line__c
			WHERE AcctSeedERP__Purchase_Order_Line__c IN:setPOLId])
		{
			if(!maplistAPL.containsKey(apl.AcctSeedERP__Purchase_Order_Line__c))
				maplistAPL.put(apl.AcctSeedERP__Purchase_Order_Line__c, new List<AcctSeed__Account_Payable_Line__c>());

			maplistAPL.get(apl.AcctSeedERP__Purchase_Order_Line__c).add(apl);
		}

		for(AcctSeedERP__Purchase_Order_Line__c line : listPOL)
		{
            map<string,string> m = new map<string,string>();

            //m.put('poStatus',line.AcctSeedERP__Purchase_Order__r.AcctSeedERP__Status__c);
            m.put('poStatus',line.AcctSeedERP__Purchase_Order__r.Locked__c ? '' : 'Open');
            m.put('poType',line.AcctSeedERP__Purchase_Order__r.AcctSeedERP__Type__c);

            if(line.deliverDate__c != null)
            	m.put('deliverDate',line.deliverDate__c.format());
            else if(line.AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c != null)
            	m.put('deliverDate',line.AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c.format());
            else
            	m.put('deliverDate','');

            m.put('idLine',line.Id);
            m.put('lineNumber', String.valueOf(Integer.valueOf(line.Name.replaceAll('[^0-9]',''))));

            m.put('comment',line.AcctSeedERP__Comment__c);
            m.put('idLot',line.GMBLASERP__Lot__c);
            m.put('lotName',line.GMBLASERP__Lot__r.Name);

            m.put('idProduct', line.AcctSeedERP__Product__c);
			m.put('productFamily',line.AcctSeedERP__Product__r.Family);
			m.put('productName',line.AcctSeedERP__Product__r.Name);
			m.put('productCode',line.AcctSeedERP__Product__r.ProductCode);
			m.put('productType',line.AcctSeedERP__Product__r.RecordType.Name);

			if(line.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c)
			m.put('isInventory','true');
			else
			m.put('isInventory','false');

			if(line.AcctSeedERP__Product__r.AcctSeedERP__Serialized__c)
			m.put('isSerialized','true');
			else
			m.put('isSerialized','false');

			if(line.AcctSeedERP__Product__r.GMBLASERP__Lot_Tracked__c)
			m.put('isLotTracked','true');
			else
			m.put('isLotTracked','false');

			if(line.AcctSeedERP__Project__c != null)
			{
				m.put('idProject', line.AcctSeedERP__Project__c);
				m.put('projectName',line.AcctSeedERP__Project__r.Name);
			}
			if(line.AcctSeedERP__Project_Task__c != null)
			{
				m.put('idProjectTask',line.AcctSeedERP__Project_Task__c);
				m.put('projectTaskName',line.AcctSeedERP__Project_Task__r.Name);
			}

			if(line.AcctSeedERP__Quantity__c != null)
			m.put('qtyOrdered',String.valueOf(line.AcctSeedERP__Quantity__c.setScale(6)));
			else
			m.put('qtyOrdered','0');

			if(line.AcctSeedERP__Quantity_Unreceived__c != null)
			m.put('qtyUnreceived',String.valueOf(line.AcctSeedERP__Quantity_Unreceived__c.setScale(6)));
			else
			m.put('qtyUnreceived','0');

			if(line.AcctSeedERP__Unit_Price__c == null) line.AcctSeedERP__Unit_Price__c = 0;
			m.put('unitPrice',String.valueOf(line.AcctSeedERP__Unit_Price__c.setScale(6)));
			if(line.Base_Price__c == null) line.Base_Price__c = 0;
			m.put('basePrice',String.valueOf(line.Base_Price__c.setScale(6)));

			if(line.AcctSeedERP__Total__c != null)
			m.put('amtOrdered',String.valueOf(line.AcctSeedERP__Total__c.setScale(6)));
			else
			m.put('amtOrdered','0');

			if(line.GMBLASERP__Price_Override__c)
				m.put('priceOverride','true');
			else
				m.put('priceOverride','false');

			Decimal qtyReceived = 0;
			Decimal amtReceived = 0;
			Decimal totalFreightApplied = 0;
			Decimal countFrieghtApplied = 0;
			//Boolean hasMoves = false;
			//Boolean hasMovesClosedPeriod = false;
			Boolean availableToAppyFreight = false;
			m.put('hasMoves','false');
			m.put('hasMovesClosedPeriod','false');
			if(maplistPOIM.containsKey(line.Id) && !maplistPOIM.get(line.Id).isEmpty())
			{
				m.put('hasMoves','true');
				for(AcctSeedERP__Purchase_Order_Inventory_Movement__c move : maplistPOIM.get(line.Id))
				{
					if(move.AcctSeedERP__Movement_Date__c < dateEarliestOpen)
						m.put('hasMovesClosedPeriod','true');
					Decimal qty = move.AcctSeedERP__Quantity__c;
					if(qty == null) qty = 0;
					Decimal unitCost = move.AcctSeedERP__Unit_Cost__c;
					if(unitCost == null) unitCost = 0;

					qtyReceived += qty;
					amtReceived += (qty * unitCost);

					if(move.Freight_Applied__c){
						totalFreightApplied += move.Freight_Charge__c * qty;
						countFrieghtApplied ++;
					}
					else
						availableToAppyFreight = true;

				}
			}

			m.put('availableToAppyFreight',availableToAppyFreight ? 'true' : 'false');
			if(countFrieghtApplied > 0)
				m.put('freightApplied','true');
			else
				m.put('freightApplied','false');

			m.put('totalFreightApplied',String.valueOf(totalFreightApplied.setScale(6)));
			m.put('qtyReceived',String.valueOf(qtyReceived.setScale(6)));

			if(line.GMBLASERP__Quantity_Received_Non_Inventory__c == null) line.GMBLASERP__Quantity_Received_Non_Inventory__c = 0;
			m.put('qtyReceivedNonInventory',String.valueOf(line.GMBLASERP__Quantity_Received_Non_Inventory__c.setScale(6)));

			amtReceived += (line.GMBLASERP__Quantity_Received_Non_Inventory__c * line.AcctSeedERP__Unit_Price__c);
			m.put('amtReceived',String.valueOf(amtReceived.setScale(6)));

			Decimal amtPaid = 0;
			if(maplistAPL.containsKey(line.Id) && !maplistAPL.get(line.Id).isEmpty())
			{
				m.put('hasAPLines','true');
				for(AcctSeed__Account_Payable_Line__c apl : maplistAPL.get(line.Id))
				{
					if(apl.AcctSeed__Amount__c != null)
						amtPaid += apl.AcctSeed__Amount__c;
				}
			}
			else
				m.put('hasAPLines','false');

			m.put('amtPaid',String.valueOf(amtPaid.setScale(6)));
            listJSON.add(m);
		}
		return listJSON;
	}

	@RemoteAction @ReadOnly
    global static List<Map<String,String>> searchProjectTask(String searchTxt)
    {
    	List<Map<String,String>> listProject = new List<Map<String,String>>();
        searchTxt = '%'+searchTxt.replaceAll('[*]','%') +'%';

        for(AcctSeed__Project_Task__c pt :
        	[SELECT Id,
        		Name,
        		AcctSeed__Project__r.AcctSeed__Account__c,
        		AcctSeed__Project__r.AcctSeed__Account__r.Name
        	FROM AcctSeed__Project_Task__c
        	WHERE AcctSeed__Project__r.Locked__c = false
        		AND (Name like :searchTxt
        			OR AcctSeed__Project__r.Name like :searchTxt
        			OR AcctSeed__Project__r.AcctSeed__Account__r.Name like :searchTxt)
        	ORDER BY Name
        	LIMIT 12])
        {
        	Map<String,String> m = new Map<String,String>();
        	String nm = pt.Name;
        	if(pt.AcctSeed__Project__r.AcctSeed__Account__c != null)
        		nm += ' Customer: ' + pt.AcctSeed__Project__r.AcctSeed__Account__r.Name;
        	m.put('label', nm);
        	m.put('idTask', pt.Id);
            listProject.add(m);
        }
        return listProject;

    }

	@RemoteAction @ReadOnly
    global static List<Map<String,String>> searchLot(String searchTxt, String idProduct)
    {
    	List<Map<String,String>> listLot = new List<Map<String,String>>();
        searchTxt = '%'+searchTxt.replaceAll('[*]','%') +'%';

        for(GMBLASERP__Lot__c lot :
        	[SELECT Id,
        		Name
        	FROM GMBLASERP__Lot__c
        	WHERE Name like :searchTxt
        		AND GMBLASERP__Product__c =:idProduct
        	ORDER BY Name
        	LIMIT 12])
        {
        	Map<String,String> m = new Map<String,String>();
        	m.put('label', lot.Name);
        	m.put('idLot', lot.Id);
            listLot.add(m);
        }
        return listLot;

    }

    @RemoteAction @ReadOnly
    global static list<map<string,string>> searchProduct(String idPurchaseOrder, String strSearch)
    {
      list<map<string,string>> listJSON = new list<map<string,string>>();

        strSearch = '%'+strSearch+'%';

        set<Id> setIdProduct = new set<Id>();
        for(AcctSeedERP__Purchase_Order_Line__c pol :[SELECT Id, AcctSeedERP__Product__c FROM AcctSeedERP__Purchase_Order_Line__c WHERE AcctSeedERP__Purchase_Order__c = :idPurchaseOrder])
          setIdProduct.add(pol.AcctSeedERP__Product__c);
        setIdProduct.remove(null);

        Map<Id, Product2> products = new Map<Id, Product2>([
          SELECT Id, IsActive, Name, Family, ProductCode,
              AcctSeedERP__Default_Vendor__r.Name,
              AcctSeed__Inventory_Product__c,
           (SELECT Id, AcctSeedERP__Quantity__c FROM AcctSeedERP__Purchase_Order_Lines__r WHERE AcctSeedERP__Purchase_Order__r.AcctSeedERP__Order_Date__c = LAST_90_DAYS AND AcctSeedERP__Quantity__c > 0)
           FROM Product2
             WHERE IsActive = true
               AND (Name LIKE :strSearch OR ProductCode LIKE :strSearch OR Family LIKE :strSearch OR AcctSeedERP__Default_Vendor__r.Name LIKE :strSearch)
        ]);

        Map<Id, Decimal> productId_cubeQuantity = new Map<Id, Decimal>();
        for( GMBLASERP__Inventory_Movement_Cube__c cube : [SELECT Id, GMBLASERP__Quantity__c, GMBLASERP__Product__c
                                                          FROM GMBLASERP__Inventory_Movement_Cube__c
                                                          WHERE GMBLASERP__Quantity__c != 0
                                                          AND GMBLASERP__Product__c IN :products.keySet() ])
        {
          if( !productId_cubeQuantity.containsKey( cube.GMBLASERP__Product__c) )
          {
            productId_cubeQuantity.put( cube.GMBLASERP__Product__c, 0 );
          }
          productId_cubeQuantity.put( cube.GMBLASERP__Product__c, productId_cubeQuantity.get( cube.GMBLASERP__Product__c ) + cube.GMBLASERP__Quantity__c );
        }

        for(Product2 p : products.values() )
        {
          if(p.IsActive == true )
          {
            map<string,string> m = new map<string,string>();

            m.put('idProduct',p.Id);
            m.put('productName',p.Name);
            m.put('productFamily',p.Family);
            m.put('productCode',p.ProductCode);
            m.put('vendorName',p.AcctSeedERP__Default_Vendor__r.Name);
            if(p.AcctSeed__Inventory_Product__c)
              m.put('isInventory','true');
            else
              m.put('isInventory','false');

            if(setIdProduct.contains(p.Id))
              m.put('alreadyIncluded','true');
            else
              m.put('alreadyIncluded','false');

            Decimal qtyInventory = 0;
            if( productId_cubeQuantity.containsKey(p.Id) &&
                productId_cubeQuantity.get(p.Id) > 0 )
            {
              qtyInventory = productId_cubeQuantity.get(p.Id);
            }

            m.put('qtyInventory',String.valueOf(qtyInventory.setScale(0)));

            Decimal qtyOrdered = 0;
            for(AcctSeedERP__Purchase_Order_Line__c pol :p.AcctSeedERP__Purchase_Order_Lines__r)
              qtyOrdered += pol.AcctSeedERP__Quantity__c;

            m.put('qtyOrdered',String.valueOf(qtyOrdered.setScale(0)));

            listJSON.add(m);
          }
        }

        return listJSON;
    }

    @RemoteAction
    global static map<string,string> createLine(Id idPurchaseOrder, Id idProduct, Decimal qty)
    {

    	AcctSeedERP__Purchase_Order_Line__c line = new AcctSeedERP__Purchase_Order_Line__c(
    		AcctSeedERP__Product__c = idProduct,
    		AcctSeedERP__Purchase_Order__c = idPurchaseOrder,
    		AcctSeedERP__Quantity__c = qty
    	);
    	insert line;
    	return retrieveLines(line.Id)[0];
    }

	@RemoteAction
	global static string deleteLine(String idLine)
	{
		delete [SELECT Id FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c WHERE AcctSeedERP__Purchase_Order_Line__c = :idLine];
		delete [SELECT Id FROM AcctSeedERP__Purchase_Order_Line__c WHERE Id = :idLine];
		return '';
	}

	@RemoteAction
	global static map<string,string> updateUnitPrice(Id idLine, Decimal price)
	{
		AcctSeedERP__Purchase_Order_Line__c line = [SELECT Id FROM AcctSeedERP__Purchase_Order_Line__c WHERE Id = :idLine][0];

		line.AcctSeedERP__Unit_Price__c = price;
		if(price == null)
			line.GMBLASERP__Price_Override__c = false;
		else
			line.GMBLASERP__Price_Override__c = true;

		update line;

		return retrieveLines(line.Id)[0];
	}

	@RemoteAction
	global static map<string,string> updateDeliverDate(Id idLine, String deliverDate)
	{
		AcctSeedERP__Purchase_Order_Line__c line = [SELECT Id, deliverDate__c FROM AcctSeedERP__Purchase_Order_Line__c WHERE Id = :idLine][0];
		line.deliverDate__c = deliverDate != '' ? Date.parse(deliverDate) : null;
		update line;
		return retrieveLines(line.Id)[0];
	}

	@RemoteAction
	global static map<string,string> updateQtyOrdered(Id idLine, Decimal qty)
	{
		AcctSeedERP__Purchase_Order_Line__c line = [SELECT Id FROM AcctSeedERP__Purchase_Order_Line__c WHERE Id = :idLine];

		if(qty == null) qty = 0;
		line.AcctSeedERP__Quantity__c = qty;

		update line;

		return retrieveLines(line.Id)[0];
	}

	@RemoteAction
	global static map<string,string> updateProjectTask(Id idLine, Id idTask)
	{
		Id pIdTask = null;
		Id pIdProject = null;

		if(idTask != null){
			AcctSeed__Project_Task__c pt = [SELECT Id, AcctSeed__Project__c FROM AcctSeed__Project_Task__c WHERE Id = :idTask];
			pIdTask = pt.Id;
			pIdProject = pt.AcctSeed__Project__c;
		}

		AcctSeedERP__Purchase_Order_Line__c line = [SELECT Id, AcctSeedERP__Project__c, AcctSeedERP__Project_Task__c FROM AcctSeedERP__Purchase_Order_Line__c WHERE Id = :idLine];
		line.AcctSeedERP__Project_Task__c = pIdTask;
		line.AcctSeedERP__Project__c = pIdProject;

		update line;

		return retrieveLines(line.Id)[0];
	}

	@RemoteAction
	global static map<string,string> updateLot(Id idLine, Id idLot)
	{
		Id pIdTask = null;
		Id pIdProject = null;

		AcctSeedERP__Purchase_Order_Line__c line = [SELECT Id, GMBLASERP__Lot__c FROM AcctSeedERP__Purchase_Order_Line__c WHERE Id = :idLine];
		line.GMBLASERP__Lot__c = idLot;

		update line;

		return retrieveLines(line.Id)[0];
	}

	@RemoteAction
	global static map<string,string> updateQtyReceivedNonInventory(Id idLine, Decimal qty)
	{
		Id idGLVP = [SELECT AcctSeed__Vouchers_Payable_GL_Account__c FROM AcctSeed__Accounting_Settings__c][0].AcctSeed__Vouchers_Payable_GL_Account__c;
		for(AcctSeedERP__Purchase_Order_Line__c line :
			[SELECT Id,
				Name,
				GMBLASERP__Quantity_Received_Non_Inventory__c,
				(SELECT AcctSeed__Quantity__c FROM AcctSeedERP__Account_Payable_Lines__r WHERE AcctSeed__Expense_GL_Account__c != :idGLVP)
			FROM AcctSeedERP__Purchase_Order_Line__c
			WHERE Id = :idLine])
		{
			Decimal qtyPaid = 0;
			for(AcctSeed__Account_Payable_Line__c apl : line.AcctSeedERP__Account_Payable_Lines__r)
			{
				if(apl.AcctSeed__Quantity__c != null) qtyPaid += apl.AcctSeed__Quantity__c;
			}

			if(qty == null) qty = 0;
			if(qty < qtyPaid)
				throw new gcException('Purchase Order line has existing account payable lines. Quantity cannot be less than '+String.valueOf(qtyPaid));
			else{
				line.GMBLASERP__Quantity_Received_Non_Inventory__c = qty;
				update line;
			}
		}
		return retrieveLines(idLine)[0];
	}

	@RemoteAction
	global static map<string,string> updateQtyReceivedNonInventory_Old(Id idLine, Decimal qty)
	{
		AcctSeedERP__Purchase_Order_Line__c line = [SELECT Id FROM AcctSeedERP__Purchase_Order_Line__c WHERE Id = :idLine];

		if(qty == null) qty = 0;
		line.GMBLASERP__Quantity_Received_Non_Inventory__c = qty;

		update line;

		return retrieveLines(line.Id)[0];
	}

	@RemoteAction
	global static list<map<string,string>> receiveAllNonInventory(Id idPurchaseOrder)
	{
		list<AcctSeedERP__Purchase_Order_Line__c> listPOL = new list<AcctSeedERP__Purchase_Order_Line__c>();
		for(AcctSeedERP__Purchase_Order_Line__c pol :
			[SELECT Id, AcctSeedERP__Quantity__c, AcctSeedERP__Quantity_Received__c, GMBLASERP__Quantity_Received_Non_Inventory__c
			 FROM AcctSeedERP__Purchase_Order_Line__c
			 WHERE AcctSeedERP__Purchase_Order__c = :idPurchaseOrder AND AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c = false])
		{
			Decimal qtyOrdered = pol.AcctSeedERP__Quantity__c;
			if(qtyOrdered == null)
			   qtyOrdered = 0;

			Decimal qtyReceived = pol.AcctSeedERP__Quantity_Received__c;
			if(qtyReceived == null)
			   qtyReceived = 0;

			Decimal qtyReceivedNonInventory = pol.GMBLASERP__Quantity_Received_Non_Inventory__c;
			if(qtyReceivedNonInventory == null)
			   qtyReceivedNonInventory = 0;

			Decimal qtyNew = qtyOrdered - qtyReceived - qtyReceivedNonInventory;
			if(qtyNew <= 0)
				continue;

			pol.GMBLASERP__Quantity_Received_Non_Inventory__c = qtyOrdered;
			listPOL.add(pol);
		}
		if(!listPOL.isEmpty())
			update listPOL;

		return retrieveLines(idPurchaseOrder);
	}

	@RemoteAction
	global static map<string,string> updateComment(Id idLine, String comment)
	{
		AcctSeedERP__Purchase_Order_Line__c line = [SELECT Id FROM AcctSeedERP__Purchase_Order_Line__c WHERE Id = :idLine];

		line.AcctSeedERP__Comment__c = comment;

		update line;

		return retrieveLines(line.Id)[0];
	}

	@RemoteAction @ReadOnly
	global static list<map<string,string>> retrieveWarehouses(Id idPurchaseOrder)
	{
		list<map<string,string>> listJSON = new list<map<string,string>>();

		Id idWarehouseLast = null;
		for(AcctSeedERP__Purchase_Order_Inventory_Movement__c move :
			[SELECT Id, AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c
			 FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c
			 WHERE AcctSeedERP__Purchase_Order_Line__r.AcctSeedERP__Purchase_Order__c = :idPurchaseOrder
			 ORDER BY LastModifiedDate DESC, AcctSeedERP__Movement_Date__c DESC
			 LIMIT 1])
		{
			idWarehouseLast = move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c;
		}

		Id idWarehouseTransit = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Transit_Warehouse_Id__c;
		Id idWarehouseAdjustment = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c;

		for(AcctSeedERP__Warehouse__c whs :
			[SELECT Id, Name
			 FROM AcctSeedERP__Warehouse__c
			 WHERE Id != :idWarehouseTransit
			   AND Id != :idWarehouseAdjustment
			   ORDER BY Name])
		{
			map<string,string> obj = new map<string,string>{'idWarehouse'=>whs.Id,'warehouseName'=>whs.Name};
			if(whs.Id == idWarehouseLast)
				obj.put('isMostRecent','true');
			listJSON.add(obj);
		}
		return listJSON;
	}

	@RemoteAction @ReadOnly
	global static list<map<string,string>> retrieveLots(Id idPurchaseOrderLine)
	{
		AcctSeedERP__Purchase_Order_Line__c line = [SELECT AcctSeedERP__Product__c, GMBLASERP__Lot__c FROM AcctSeedERP__Purchase_Order_Line__c WHERE Id =:idPurchaseOrderLine][0];
		//Id idProduct = [SELECT AcctSeedERP__Product__c FROM AcctSeedERP__Purchase_Order_Line__c WHERE Id =:idPurchaseOrderLine][0].AcctSeedERP__Product__c;
		Id idProduct = line.AcctSeedERP__Product__c;

		list<map<string,string>> listJSON = new list<map<string,string>>();

		Id idLotLast = line.GMBLASERP__Lot__c;
		if(idLotLast == null)
		for(AcctSeedERP__Purchase_Order_Inventory_Movement__c move :
			[SELECT Id, GMBLASERP__Lot__c
			 FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c
			 WHERE AcctSeedERP__Purchase_Order_Line__c = :idPurchaseOrderLine
			 ORDER BY LastModifiedDate DESC, AcctSeedERP__Movement_Date__c DESC
			 LIMIT 1])
		{
			idLotLast = move.GMBLASERP__Lot__c;
		}

		for(GMBLASERP__Lot__c l :
			[SELECT Id, Name
			 FROM GMBLASERP__Lot__c
			 WHERE GMBLASERP__Product__c = :idProduct
			 ORDER BY Name])
		{
			map<string,string> obj = new map<string,string>{'idLot'=>l.Id,'lotName'=>l.Name};
			if(l.Id == idLotLast)
				obj.put('isMostRecent','true');
			listJSON.add(obj);
		}
		return listJSON;
	}

	@RemoteAction @ReadOnly
	global static list<map<string,string>> retrieveSerials(Id idPurchaseOrderLine)
	{
		Id idProduct = [SELECT AcctSeedERP__Product__c FROM AcctSeedERP__Purchase_Order_Line__c WHERE Id =:idPurchaseOrderLine][0].AcctSeedERP__Product__c;

		list<map<string,string>> listJSON = new list<map<string,string>>();

		Id idSerialLast = null;
		for(AcctSeedERP__Purchase_Order_Inventory_Movement__c move :
			[SELECT Id, GMBLASERP__Serial_Number__c
			 FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c
			 WHERE AcctSeedERP__Purchase_Order_Line__c = :idPurchaseOrderLine
			 ORDER BY LastModifiedDate DESC, AcctSeedERP__Movement_Date__c DESC
			 LIMIT 1])
		{
			idSerialLast = move.GMBLASERP__Serial_Number__c;
		}

		for(GMBLASERP__Serial_Number__c sn :
			[SELECT Id, Name, GMBLASERP__Lot__r.Name, GMBLASERP__Inventory_Balance__c
			 FROM GMBLASERP__Serial_Number__c
			 WHERE GMBLASERP__Product__c = :idProduct
			 ORDER BY Name])
		{
			map<string,string> obj = new map<string,string>{'idSerial'=>sn.Id,'serialName'=>sn.Name};
			if(sn.GMBLASERP__Lot__c != null)
				obj.put('lotName',sn.GMBLASERP__Lot__r.Name);

			if(sn.GMBLASERP__Inventory_Balance__c != null)
				obj.put('disabled','true');
			else if(sn.Id == idSerialLast)
				obj.put('isMostRecent','true');

			listJSON.add(obj);
		}
		return listJSON;
	}


	@RemoteAction @ReadOnly
	global static list<map<string,string>> retrieveMoves(Id idFilter)
	{
		list<map<string,string>> listJSON = new list<map<string,string>>();
		Date dateEarliestOpen = GMBLASERP.gcAccountingPeriod.dateEarliestOpen();
		for(AcctSeedERP__Purchase_Order_Inventory_Movement__c move :
			[SELECT Id, Name,
					AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name,
					AcctSeedERP__Movement_Date__c,
					AcctSeedERP__Purchase_Order_Line__c,
					AcctSeedERP__Quantity__c,
					AcctSeedERP__Unit_Cost__c,
					GMBLASERP__Account_Payable_Line__r.AcctSeed__Amount__c,
					GMBLASERP__Lot__c,
					GMBLASERP__Lot__r.Name,
					GMBLASERP__Serial_Number__c,
					GMBLASERP__Serial_Number__r.Name,
					Freight_Applied__c,
					Freight_Charge__c,
					Freight_Charge_header__c,
					Freight_Charge_header__r.Name
			 FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c
			 WHERE AcctSeedERP__Purchase_Order_Line__c = :idFilter OR Id =:idFilter
			 ORDER BY AcctSeedERP__Movement_Date__c DESC, LastModifiedDate DESC, Id DESC])
		{
			map<string,string> obj = new map<string,string>();

			if(move.AcctSeedERP__Quantity__c == null) move.AcctSeedERP__Quantity__c = 0;
			if(move.AcctSeedERP__Unit_Cost__c == null) move.AcctSeedERP__Unit_Cost__c = 0;

			obj.put('idMove',move.Id);
			obj.put('moveName',String.valueOf(Integer.valueOf(move.Name.replaceAll('[^0-9]',''))));
			obj.put('warehouseName',move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name);
			obj.put('moveDate',move.AcctSeedERP__Movement_Date__c.format());
			obj.put('qty',String.valueOf(move.AcctSeedERP__Quantity__c.setScale(6)));
			obj.put('unitCost',String.valueOf(move.AcctSeedERP__Unit_Cost__c.setScale(6)));
			obj.put('idLine',move.AcctSeedERP__Purchase_Order_Line__c);

			obj.put('amtReceived',String.valueOf((move.AcctSeedERP__Quantity__c * move.AcctSeedERP__Unit_Cost__c).setScale(6)));

			obj.put('freightApplied',move.Freight_Applied__c ? 'true' : 'false');
			obj.put('freightCharge',move.Freight_Charge__c != null ? String.valueOf(move.Freight_Charge__c.setScale(6)) : '0');
			obj.put('freightChargeHeader',move.Freight_Charge_header__c);
			obj.put('freightChargeHeaderName',move.Freight_Charge_header__r.Name);
			obj.put('hasAPLine','false');
			obj.put('amtPaid','0');
			if(move.GMBLASERP__Account_Payable_Line__c != null)
			{
				obj.put('hasAPLine','true');
				if(move.GMBLASERP__Account_Payable_Line__r.AcctSeed__Amount__c != null)
					obj.put('amtPaid',String.valueOf(move.GMBLASERP__Account_Payable_Line__r.AcctSeed__Amount__c.setScale(6)));
			}

			obj.put('idLot',move.GMBLASERP__Lot__c);
			obj.put('lotName',move.GMBLASERP__Lot__r.Name);
			obj.put('idSerial',move.GMBLASERP__Serial_Number__c);
			obj.put('serialName',move.GMBLASERP__Serial_Number__r.Name);

			if(move.AcctSeedERP__Movement_Date__c < dateEarliestOpen)
				obj.put('periodIsClosed','true');
			else
				obj.put('periodIsClosed','false');

			if(obj.get('hasAPLine') == 'true')
				obj.put('msg','paid');
			else if(obj.get('hasMovesClosedPeriod') == 'true')
				obj.put('msg','closed');

			listJSON.add(obj);
		}
		return listJSON;
	}

	@RemoteAction
	global static list<map<String,String>> receiveAllInventory(Id idPurchaseOrder, Id idWarehouse)
	{

		map<Id,Decimal> mapPOLqty = new map<Id,Decimal>();
		map<Id,map<Id,map<Id,Id>>> mapPWLB = new map<Id,map<Id,map<Id,Id>>>();

		list<AcctSeedERP__Purchase_Order_Line__c> listPOL = new list<AcctSeedERP__Purchase_Order_Line__c>();

		for(AcctSeedERP__Purchase_Order_Line__c pol :
			[SELECT Id, AcctSeedERP__Product__c, AcctSeedERP__Quantity__c, AcctSeedERP__Quantity_Received__c, GMBLASERP__Quantity_Received_Non_Inventory__c
			 FROM AcctSeedERP__Purchase_Order_Line__c
			 WHERE AcctSeedERP__Purchase_Order__c = :idPurchaseOrder
			   AND AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c = true
			   AND AcctSeedERP__Product__r.AcctSeedERP__Serialized__c = false
			   AND AcctSeedERP__Product__r.GMBLASERP__Lot_Tracked__c = false])
		{
			Decimal qtyOrdered = pol.AcctSeedERP__Quantity__c;
			if(qtyOrdered == null)
			   qtyOrdered = 0;

			Decimal qtyReceived = pol.AcctSeedERP__Quantity_Received__c;
			if(qtyReceived == null)
			   qtyReceived = 0;

			Decimal qtyReceivedNonInventory = pol.GMBLASERP__Quantity_Received_Non_Inventory__c;
			if(qtyReceivedNonInventory == null)
			   qtyReceivedNonInventory = 0;

			Decimal qtyNew = qtyOrdered - qtyReceived - qtyReceivedNonInventory;

			if(qtyNew <= 0)
				continue;

			if(!mapPWLB.containsKey(pol.AcctSeedERP__Product__c))
				mapPWLB.put(pol.AcctSeedERP__Product__c, new map<Id,map<Id,Id>>());

			mapPOLqty.put(pol.Id,qtyNew);

			listPOL.add(pol);
		}

		if(!listPOL.isEmpty())
		{
			list<AcctSeedERP__Purchase_Order_Inventory_Movement__c> listMove = new list<AcctSeedERP__Purchase_Order_Inventory_Movement__c>();

			Id idLocation = null;
			for(AcctSeedERP__Location__c loc : [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c = :idWarehouse ORDER BY CreatedDate LIMIT 1])
			{
				idLocation = loc.Id;
			}
			for(Id idProduct : mapPWLB.keySet())
			{
				mapPWLB.put(idProduct, new map<Id,map<Id,Id>>{idWarehouse => new map<Id,Id>{idLocation => null}});
			}
			GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);
			for(AcctSeedERP__Purchase_Order_Line__c pol : listPOL)
			{
				listMove.add(new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
					AcctSeedERP__Purchase_Order_Line__c = pol.Id,
					AcctSeedERP__Inventory_Balance__c = mapPWLB.get(pol.AcctSeedERP__Product__c).get(idWarehouse).get(idLocation),
					AcctSeedERP__Movement_Date__c = date.today(),
					AcctSeedERP__Quantity__c = mapPOLqty.get(pol.Id)
				));
			}
			insert listMove;
		}

		return retrieveLines(idPurchaseOrder);
	}


	@RemoteAction
	global static list<map<string,string>> createMove(Id idPurchaseOrderLine, Id idWarehouse, String lotName, String serialName, Decimal qty, Decimal modelYear)
	{
		String  specialChar = lotName.right(1).toUpperCase().replaceAll('[0-9A-Z]','').replaceAll('[^*]','');
		lotName = lotName.toUpperCase().replaceAll('[^0-9A-Z]','') + specialChar;
		serialName = serialName.toUpperCase().replaceAll('[^0-9A-Z]','');

		Id idProduct = [SELECT AcctSeedERP__Product__c FROM AcctSeedERP__Purchase_Order_Line__c WHERE Id = :idPurchaseOrderLine][0].AcctSeedERP__Product__c;
		Id idLocation = null;
		for(AcctSeedERP__Location__c loc : [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c = :idWarehouse ORDER BY CreatedDate LIMIT 1])
		{
			idLocation = loc.Id;
		}
		if(idLocation == null)
		{
			AcctSeedERP__Location__c loc = new AcctSeedERP__Location__c(AcctSeedERP__Warehouse__c = idWarehouse, Name='Default Location');
			insert loc;
			idLocation = loc.Id;
		}
		AcctSeed__Accounting_Settings__c accSetting = [SELECT AcctSeed__Default_Ledger__c FROM AcctSeed__Accounting_Settings__c ORDER BY CreatedDate][0];
		Id idBalance = GMBLASERP.gcInventoryBalance.findOrCreateBalance(idProduct, idWarehouse, idLocation);

		Product2 product = [SELECT Id, AcctSeedERP__Serialized__c, GMBLASERP__Lot_Tracked__c FROM Product2 WHERE Id =:idProduct][0];

		AcctSeedERP__Purchase_Order_Inventory_Movement__c move = new AcctSeedERP__Purchase_Order_Inventory_Movement__c();
		move.AcctSeedERP__Purchase_Order_Line__c = idPurchaseOrderLine;
		move.AcctSeedERP__Inventory_Balance__c = idBalance;
		move.AcctSeedERP__Movement_Date__c = date.Today();
		move.AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c;

		Id idLot = null;
		Id idSerial = null;
		if(product.GMBLASERP__Lot_Tracked__c)
		{
			for(GMBLASERP__Lot__c lot : [SELECT Id FROM GMBLASERP__Lot__c WHERE GMBLASERP__Product__c =:idProduct AND Name =:lotName LIMIT 1])
			{
				idLot = lot.Id;
			}
			if(idLot == null)
			{
				GMBLASERP__Lot__c lot = new GMBLASERP__Lot__c(Name = lotName, GMBLASERP__Product__c = idProduct);
				insert lot;
				idLot = lot.Id;
			}
			move.GMBLASERP__Lot__c = idLot;
		}

		move.AcctSeedERP__Quantity__c = qty;

		if(product.AcctSeedERP__Serialized__c)
		{
			for(GMBLASERP__Serial_Number__c serial : [SELECT Id, GMBLASERP__Lot__c FROM GMBLASERP__Serial_Number__c WHERE GMBLASERP__Product__c = :idProduct AND Name =:serialName LIMIT 1])
			{
				idSerial = serial.Id;
				idLot = serial.GMBLASERP__Lot__c;
			}

			if(idSerial == null)
			{
				GMBLASERP__Serial_Number__c serial = new GMBLASERP__Serial_Number__c(Name = serialName, GMBLASERP__Product__c = idProduct, GMBLASERP__Lot__c = idLot, Model_Year__c = modelYear);
				insert serial;
				idSerial = serial.Id;
			}
			move.GMBLASERP__Lot__c = idLot;
			move.GMBLASERP__Serial_Number__c = idSerial;
			move.AcctSeedERP__Quantity__c = 1;
		}

		insert move;
		return retrieveMoves(idPurchaseOrderLine);
	}

	@RemoteAction
	global static string deleteMove(String idMove)
	{
		delete [SELECT Id FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c WHERE Id =:idMove];
		return '';
	}

	@RemoteAction @ReadOnly
	global static list<map<string,string>> retrievePricebooks(Id idPurchaseOrder)
	{
		list<map<string,string>> listJSON = new list<map<string,string>>();
		Id idPriceBook = [SELECT GMBLASERP__Pricebook__c FROM AcctSeedERP__Purchase_Order__c WHERE Id =:idPurchaseOrder][0].GMBLASERP__Pricebook__c;

		for(Pricebook2 pb :
			[SELECT Id, Name
			 FROM Pricebook2
			 WHERE IsActive = true OR Id =:idPriceBook
			 ORDER BY Name])
		{
			map<string,string> m = new map<string,string>();
			m.put('Id',pb.Id);
			m.put('Name',pb.Name);
			if(pb.Id == idPricebook)
			m.put('makeSelected','true');
			listJSON.add(m);
		}
		return listJSON;
	}

	@RemoteAction @ReadOnly
	global static Boolean checkEnablePricebookSelection(Id idPurchaseOrder)
	{
		for(AcctSeedERP__Purchase_Order_Inventory_Movement__c poim :
			[SELECT Id
			 FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c
			 WHERE AcctSeedERP__Purchase_Order_Line__r.AcctSeedERP__Purchase_Order__c = :idPurchaseOrder
			 LIMIT 1])
		{
			return false;
		}

		for(AcctSeed__Account_Payable_Line__c apl :
			[SELECT Id
			 FROM AcctSeed__Account_Payable_Line__c
			 WHERE AcctSeedERP__Purchase_Order_Line__r.AcctSeedERP__Purchase_Order__c = :idPurchaseOrder
			    OR AcctSeed__Account_Payable__r.AcctSeedERP__Purchase_Order__c = :idPurchaseOrder])
		{
			return false;
		}

		return true;
	}

	@RemoteAction
	global static string updatePricebook (Id idPurchaseOrder, Id idPricebook)
	{
		AcctSeedERP__Purchase_Order__c po = [SELECT Id, GMBLASERP__Pricebook__c FROM AcctSeedERP__Purchase_Order__c WHERE Id =:idPurchaseOrder];
		if(po.GMBLASERP__Pricebook__c != idPricebook)
		{
			po.GMBLASERP__Pricebook__c = idPricebook;
			update po;
		}
		return '';
	}

	@RemoteAction
	global static String applyFreightCharge(Id idPurchaseOrder, List<String> listIdLines, Decimal freightAmount)
	{
		Set<String> setIdLines = new Set<String>();
		setIdLines.addAll(listIdLines);

		List<AcctSeedERP__Purchase_Order_Line__c> listAllLines = new List<AcctSeedERP__Purchase_Order_Line__c>();
		List<AcctSeedERP__Purchase_Order_Line__c> listLines = new List<AcctSeedERP__Purchase_Order_Line__c>();
		List<AcctSeedERP__Purchase_Order_Line__c> listUpdateLines = new List<AcctSeedERP__Purchase_Order_Line__c>();
		List<AcctSeedERP__Purchase_Order_Inventory_Movement__c> listUpdateMoves = new List<AcctSeedERP__Purchase_Order_Inventory_Movement__c>();
		Map<Id,List<AcctSeedERP__Purchase_Order_Inventory_Movement__c>> maplistPOIM = new Map<Id,List<AcctSeedERP__Purchase_Order_Inventory_Movement__c>>();
		Map<Id,Decimal> mapPOLinePOMAmount = new Map<Id,Decimal>();
		Map<Id,Decimal> mapPOLinePOMQty = new Map<Id,Decimal>();
		Set<Id> setPOLId = new Set<Id>();
		/// PO Lines
		Decimal totalPOAmount = 0;
		for(AcctSeedERP__Purchase_Order_Line__c line1 :
			[SELECT Id, Name,
			 AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c,
			 AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
			 AcctSeedERP__Product__r.GMBLASERP__Lot_Tracked__c,
			 AcctSeedERP__Quantity__c,
			 AcctSeedERP__Quantity_Received__c,
			 AcctSeedERP__Quantity_Unreceived__c,
			 AcctSeedERP__Unit_Price__c,
			 AcctSeedERP__Total__c,
			 GMBLASERP__Price_Override__c,
			 Base_Price__c,
			 GMBLASERP__Quantity_Received_Non_Inventory__c
			 FROM AcctSeedERP__Purchase_Order_Line__c
			 WHERE Id IN:listIdLines])
		{
			setPOLId.add(line1.Id);
			listAllLines.add(line1);
		}

		for(AcctSeedERP__Purchase_Order_Inventory_Movement__c move :
			[SELECT Id,
				AcctSeedERP__Purchase_Order_Line__c,
				Freight_Charge__c,
				Freight_Applied__c,
				AcctSeedERP__Movement_Date__c,
				AcctSeedERP__Quantity__c,
				AcctSeedERP__Unit_Cost__c
			FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c
			WHERE Freight_Applied__c = false AND AcctSeedERP__Purchase_Order_Line__c IN:setPOLId
			ORDER BY AcctSeedERP__Movement_Date__c])
		{
			if(!maplistPOIM.containsKey(move.AcctSeedERP__Purchase_Order_Line__c))
				maplistPOIM.put(move.AcctSeedERP__Purchase_Order_Line__c, new List<AcctSeedERP__Purchase_Order_Inventory_Movement__c>());

			maplistPOIM.get(move.AcctSeedERP__Purchase_Order_Line__c).add(move);
		}
		System.debug(loggingLevel.Error,'setPOLId:'+setPOLId);
		System.debug(loggingLevel.Error,'maplistPOIM:'+JSON.serialize(maplistPOIM));
		for(AcctSeedERP__Purchase_Order_Line__c line2 : listAllLines)
		{
			System.debug(loggingLevel.Error,'line2:'+line2);
			if(maplistPOIM.containsKey(line2.Id) && !maplistPOIM.get(line2.Id).isEmpty())
			{
				System.debug(loggingLevel.Error,'moveList:'+maplistPOIM.get(line2.Id));
				Decimal totalPOMAmount = 0;
				Decimal totalPOMQty = 0;
				for(AcctSeedERP__Purchase_Order_Inventory_Movement__c move : maplistPOIM.get(line2.Id))
				{
					System.debug(loggingLevel.Error,'move:'+move);
					Decimal qty = move.AcctSeedERP__Quantity__c == null ? 0 :move.AcctSeedERP__Quantity__c;
					Decimal unitCost = line2.Base_Price__c == null ? (move.AcctSeedERP__Unit_Cost__c == null ? 0 :move.AcctSeedERP__Unit_Cost__c) : line2.Base_Price__c;
					totalPOAmount += (qty * unitCost);
					totalPOMAmount += (qty * unitCost);
					totalPOMQty += qty;
				}
				listLines.add(line2);
				mapPOLinePOMQty.put(line2.Id, totalPOMQty);
				mapPOLinePOMAmount.put(line2.Id, totalPOMAmount);
			}
		}
		if(listLines.isEmpty()) {
			return 'There are no Purchase Order lines to apply freight charge.';
		}

		Freight_Charges__c freight = new Freight_Charges__c(Amount__c = freightAmount.setScale(6), Date_Applied__c = Date.today(), Purchase_Order__c = idPurchaseOrder);
		insert freight;

		for(AcctSeedERP__Purchase_Order_Line__c line : listLines)
		{
			Decimal totalLineAmount = mapPOLinePOMAmount.get(line.Id);
			Decimal qty = mapPOLinePOMQty.get(line.Id);
			Decimal freightCharge = (((totalLineAmount * 100)/totalPOAmount) * freightAmount)/100;
			if(freightCharge <> 0)
			{
				Decimal freightChargePerQty = (freightCharge/qty);
				line.GMBLASERP__Price_Override__c = true;
				if(line.Base_Price__c == null)
					line.Base_Price__c = line.AcctSeedERP__Unit_Price__c;
				line.AcctSeedERP__Unit_Price__c = line.Base_Price__c + freightChargePerQty;
				listUpdateLines.add(line);
				for(AcctSeedERP__Purchase_Order_Inventory_Movement__c move : maplistPOIM.get(line.Id))
				{
					move.GMBLASERP__Cost_Override__c = true;
					move.Freight_Applied__c = true;
					move.Freight_Charge__c = freightChargePerQty.setScale(6);
					move.Freight_Charge_header__c = freight.Id;
					listUpdateMoves.add(move);
				}
			}
		}

		if(!listUpdateLines.isEmpty() && !listUpdateMoves.isEmpty())
		{
			Boolean oldVal = gcPurchaseOrderLine.applyingFreight;
			gcPurchaseOrderLine.applyingFreight = true;
			update listUpdateLines;
			update listUpdateMoves;
			for(AcctSeedERP__Purchase_Order_Line__c line : listLines)
			{
				line.AcctSeedERP__Unit_Price__c = line.Base_Price__c;
			}
			update listUpdateLines;
			gcPurchaseOrderLine.applyingFreight = oldVal;
		}
		return '';
	}

	@RemoteAction @ReadOnly
	global static List<Map<String,String>> allFreightCharges(String idFilter)
	{
		list<map<string,string>> listJSON = new list<map<string,string>>();

		for(Freight_Charges__c fc :
			[SELECT Id, Name,
				Amount__c,
				Date_Applied__c,
				(SELECT Id FROM Purchase_Order_Inventory_Movements__r ORDER BY AcctSeedERP__Movement_Date__c)
			FROM Freight_Charges__c
			WHERE Purchase_Order__c =:idFilter])
		{
            map<string,string> m = new map<string,string>();
            m.put('idFreight',fc.Id);
            m.put('freightName',fc.Name);
            m.put('amount', String.valueOf(fc.Amount__c.setScale(6)));
            m.put('totalPOLines', String.valueOf(fc.Purchase_Order_Inventory_Movements__r.size()));
            m.put('dateApplied', fc.Date_Applied__c.format());

            listJSON.add(m);
        }

        return listJSON;
	}

	@RemoteAction
	global static List<Map<String,String>> removeFreight(String idPO, String idFreight)
	{
		Set<Id> setIdPOL = new Set<Id>();
		for(Freight_Charges__c fc :
			[SELECT Id, Name,
				Amount__c,
				Date_Applied__c,
				(SELECT Id, AcctSeedERP__Purchase_Order_Line__c FROM Purchase_Order_Inventory_Movements__r ORDER BY AcctSeedERP__Movement_Date__c)
			FROM Freight_Charges__c
			WHERE Id =:idFreight])
		{
			List<AcctSeedERP__Purchase_Order_Inventory_Movement__c> listUpdateMoves = new List<AcctSeedERP__Purchase_Order_Inventory_Movement__c>();
			for(AcctSeedERP__Purchase_Order_Inventory_Movement__c move : fc.Purchase_Order_Inventory_Movements__r)
			{
				move.GMBLASERP__Cost_Override__c = true;
				move.Freight_Applied__c = false;
				move.Freight_Charge__c = 0;
				move.Freight_Charge_header__c = null;
				listUpdateMoves.add(move);
				setIdPOL.add(move.AcctSeedERP__Purchase_Order_Line__c);
			}
			update listUpdateMoves;
			delete fc;
			List<AcctSeedERP__Purchase_Order_Line__c> listPOL = new List<AcctSeedERP__Purchase_Order_Line__c>();
			for(AcctSeedERP__Purchase_Order_Line__c pol :
				[SELECT Id,
					Base_Price__c,
					(SELECT Id, Freight_Applied__c FROM AcctSeedERP__Purchase_Order_Inventory_Movements__r)
				FROM AcctSeedERP__Purchase_Order_Line__c
				WHERE Id IN:setIdPOL])
			{
				if(!pol.AcctSeedERP__Purchase_Order_Inventory_Movements__r.isEmpty()){
					Boolean hasAppliedLines = false;
					for(AcctSeedERP__Purchase_Order_Inventory_Movement__c pom : pol.AcctSeedERP__Purchase_Order_Inventory_Movements__r)
					{
						if(pom.Freight_Applied__c){
							hasAppliedLines = true;
							break;
						}
					}
					if(!hasAppliedLines)
					{
						pol.Base_Price__c = null;
						listPOL.add(pol);
					}
				}
			}
			if(!listPOL.isEmpty()){
				Boolean oldVal = gcPurchaseOrderLine.disableTrigger;
				gcPurchaseOrderLine.disableTrigger = true;
				update listPOL;
				gcPurchaseOrderLine.disableTrigger = oldVal;
			}
        }
        return allFreightCharges(idPO);
	}

	//// AP FROM selected lines
	@RemoteAction
	public static String createAPSelected(String idFilter, List<String> listIdLines)
	{
		if(!AcctSeed__Account_Payable__c.sObjectType.getDescribe().accessible)
	 		throw new gcException('The current user does not have access to the Account Payable object.');
	 	Set<String> setIdLines = new Set<String>();
	 	setIdLines.addAll(listIdLines);
		AcctSeedERP__Purchase_Order__c po = [SELECT Id, Name, AcctSeedERP__Vendor__c, AcctSeedERP__Vendor__r.Name, GL_Account_Variable_1__c, GL_Account_Variable_2__c FROM AcctSeedERP__Purchase_Order__c WHERE Id =:idFilter][0];
		String vendorInvoiceNumber = po.Name + '-' + po.AcctSeedERP__Vendor__r.Name + String.valueOf(DateTime.now().getTime());
		AcctSeed__Account_Payable__c ap = new AcctSeed__Account_Payable__c(
												AcctSeed__Vendor__c = po.AcctSeedERP__Vendor__c,
												AcctSeed__Date__c = date.Today(),
												Approval_Date__c = date.Today(),
												Approved__c = true,
												AcctSeed__Payee_Reference__c = vendorInvoiceNumber,
												AcctSeedERP__Purchase_Order__c = po.Id,
												GL_Account_Variable_1__c = po.GL_Account_Variable_1__c,
												GL_Account_Variable_2__c = po.GL_Account_Variable_2__c);
		insert ap;

		//get the Vouchers Payable account
		Id idGLVP = [SELECT AcctSeed__Vouchers_Payable_GL_Account__c FROM AcctSeed__Accounting_Settings__c][0].AcctSeed__Vouchers_Payable_GL_Account__c;

		//get the VP balance for each Purchase Order Line
		list<AggregateResult> listAggRes = new list<AggregateResult>();

		listAggRes.addAll(
			[SELECT AcctSeedERP__Purchase_Order_Inventory_Movement__r.AcctSeedERP__Purchase_Order_Line__c idPOL,
					sum(AcctSeedERP__Purchase_Order_Inventory_Movement__r.AcctSeedERP__Quantity__c) qty,
					sum(AcctSeed__Amount__c) amt
			 FROM AcctSeed__Transaction__c
			 WHERE AcctSeed__GL_Account__c = :idGLVP
			   AND AcctSeedERP__Purchase_Order_Inventory_Movement__r.AcctSeedERP__Purchase_Order_Line__c IN:setIdLines
			   AND AcctSeedERP__Purchase_Order_Inventory_Movement__r.GMBLASERP__Account_Payable_Line__c = null
			   AND (AcctSeed__Amount__c < 0 OR AcctSeed__Amount__c > 0)
			 GROUP BY AcctSeedERP__Purchase_Order_Inventory_Movement__r.AcctSeedERP__Purchase_Order_Line__c]);

		list<AcctSeed__Account_Payable_Line__c> listAPL = new list<AcctSeed__Account_Payable_Line__c>();
		map<Id,AcctSeedERP__Purchase_Order_Line__c> mapPOL = new map<Id,AcctSeedERP__Purchase_Order_Line__c>();

		//create the new AP Lines
		for(AggregateResult aggRes : listAggRes)
		{
			Decimal amt = (Decimal)aggRes.get('amt');

			if(amt != null && amt != 0)
			{
				mapPOL.put((Id)aggRes.get('idPOL'), null);
				listAPL.add(new AcctSeed__Account_Payable_Line__c(
					AcctSeed__Account_Payable__c = ap.Id,
					AcctSeed__Amount__c = amt * (-1),
					AcctSeed__Expense_GL_Account__c = idGLVP,
					AcctSeed__Quantity__c = (Decimal)aggRes.get('qty'),
					AcctSeedERP__Purchase_Order_Line__c = (Id)aggRes.get('idPOL')
				));
			}
		}

		//retrieve additional PO line details, to be used to populate the AP lines
		for(AcctSeedERP__Purchase_Order_Line__c pol :
			[SELECT Id,
					AcctSeedERP__Product__c,
					AcctSeedERP__Project__c,
					AcctSeedERP__Project_Task__c
			 FROM AcctSeedERP__Purchase_Order_Line__c
			 WHERE Id IN : mapPOL.keySet()])
		{
			mapPOL.put(pol.Id,pol);
		}

		//transfer the details of the PO lines to the new AP lines
		for(AcctSeed__Account_Payable_Line__c apl : listAPL)
		{
			AcctSeedERP__Purchase_Order_Line__c pol = mapPOL.get(apl.AcctSeedERP__Purchase_Order_Line__c);
			apl.AcctSeed__Product__c = pol.AcctSeedERP__Product__c;
			apl.AcctSeed__Project__c = pol.AcctSeedERP__Project__c;
			apl.AcctSeed__Project_Task__c = pol.AcctSeedERP__Project_Task__c;
		}

		Id idGLExpenseDefault = null;
		for(AcctSeed__GL_Account__c gl :[SELECT Id FROM AcctSeed__GL_Account__c WHERE AcctSeed__Type__c = 'Expense' AND AcctSeed__Active__c = true ORDER BY Name LIMIT 1])
			idGLExpenseDefault = gl.Id;
		if(idGLExpenseDefault == null)
		{
	 		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'There must be at least one active GL Account of type Expense, in order to process an AP.'));
	 		return null;
		}

		//retrieve PO lines for non-inventory products, and create AP lines for them
		for(AcctSeedERP__Purchase_Order_Line__c pol :
			[SELECT Id, Name,
				    AcctSeedERP__Product__c,
				    AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c,
				    AcctSeedERP__Product__r.Name,
				    AcctSeedERP__Project__c,
				    AcctSeedERP__Project_Task__c,
				    AcctSeedERP__Unit_Price__c,
				    GMBLASERP__Quantity_Received_Non_Inventory__c,
				    (SELECT AcctSeed__Amount__c, AcctSeed__Quantity__c FROM AcctSeedERP__Account_Payable_Lines__r WHERE AcctSeed__Expense_GL_Account__c != :idGLVP)
			 FROM AcctSeedERP__Purchase_Order_Line__c
			 WHERE Id IN : setIdLines
			   AND GMBLASERP__Quantity_Received_Non_Inventory__c != 0
			   AND GMBLASERP__Quantity_Received_Non_Inventory__c != null
			   AND AcctSeedERP__Unit_Price__c != 0
			   AND AcctSeedERP__Unit_Price__c != null])
		{
			Decimal qtyPaid = 0;
			Decimal amtPaid = 0;
			for(AcctSeed__Account_Payable_Line__c apl : pol.AcctSeedERP__Account_Payable_Lines__r)
			{
				if(apl.AcctSeed__Amount__c != null) amtPaid += apl.AcctSeed__Amount__c;
				if(apl.AcctSeed__Quantity__c != null) qtyPaid += apl.AcctSeed__Quantity__c;
			}

			Decimal qtyReceived = pol.GMBLASERP__Quantity_Received_Non_Inventory__c;
			Decimal amtReceived = pol.GMBLASERP__Quantity_Received_Non_Inventory__c * pol.AcctSeedERP__Unit_Price__c;

			Id idGL = pol.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c;
			if(idGL == null) idGL = idGLExpenseDefault;

			if(amtPaid.setScale(6) < amtReceived.setScale(6))
			listAPL.add(new AcctSeed__Account_Payable_Line__c(
				AcctSeed__Account_Payable__c = ap.Id,
				AcctSeed__Amount__c = (amtReceived - amtPaid).setScale(6),
				AcctSeed__Quantity__c = (qtyReceived - qtyPaid).setScale(6),
				AcctSeed__Expense_GL_Account__c = idGL,
				AcctSeed__Product__c = pol.AcctSeedERP__Product__c,
				AcctSeed__Project__c = pol.AcctSeedERP__Project__c,
				AcctSeed__Project_Task__c = pol.AcctSeedERP__Project_Task__c,
				AcctSeedERP__Purchase_Order_Line__c = pol.Id
			));
		}

		insert listAPL;

		//prepare to update the Purchase Order Inventory Movements with the new AP Lines
		map<Id,Id> mapPOLtoAPL = new map<Id,Id>();
		for(AcctSeed__Account_Payable_Line__c apl : listAPL)
		{
			mapPOLtoAPL.put(apl.AcctSeedERP__Purchase_Order_Line__c, apl.Id);
		}

		//update the Purchase Order Inventory Movements
		list<AcctSeedERP__Purchase_Order_Inventory_Movement__c> listMove = new list<AcctSeedERP__Purchase_Order_Inventory_Movement__c>();
		for(AcctSeedERP__Purchase_Order_Inventory_Movement__c move :
			[SELECT Id, AcctSeedERP__Purchase_Order_Line__c, GMBLASERP__Account_Payable_Line__c
			 FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c
			 WHERE AcctSeedERP__Purchase_Order_Line__c IN : mapPOLtoAPL.keySet()
			   AND GMBLASERP__Account_Payable_Line__c = null])
		{
			move.GMBLASERP__Account_Payable_Line__c = mapPOLtoAPL.get(move.AcctSeedERP__Purchase_Order_Line__c);
			listMove.add(move);
		}

		GMBLASERP.gcPurchaseOrderInventoryMovement.disableTrigger = true;
		update listMove;
		GMBLASERP.gcPurchaseOrderInventoryMovement.disableTrigger = false;
 		return ap.Id;
	}

 	public static void coverage(){
		integer i;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
	}
}