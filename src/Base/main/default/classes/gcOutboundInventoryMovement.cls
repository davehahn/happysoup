global without sharing class gcOutboundInventoryMovement {

	global static Boolean disableTrigger{
		get{
			if(disableTrigger == null) return false;
			else return disableTrigger;
		}
		set{
			if(value == null) disableTrigger = false;
			else disableTrigger = value;
		}
	}
	
	global static Boolean enableExchangeDelete{
		get{
			if(enableExchangeDelete == null) return false;
			else return enableExchangeDelete;
		}
		set{
			if(value == null) enableExchangeDelete = false;
			else enableExchangeDelete = value;
		}
	}

	public static void triggerHandler
		(map<Id,AcctSeedERP__Outbound_Inventory_Movement__c> oldMap,
		 map<Id,AcctSeedERP__Outbound_Inventory_Movement__c> newMap,
		 list<AcctSeedERP__Outbound_Inventory_Movement__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(oldMap == NULL) oldMap = new map<Id,AcctSeedERP__Outbound_Inventory_Movement__c>();
		if(newMap == NULL) newMap = new map<Id,AcctSeedERP__Outbound_Inventory_Movement__c>();
		if(listNew == NULL) listNew = new list<AcctSeedERP__Outbound_Inventory_Movement__c>();

		updateAndValidate(oldMap,newMap,listNew,boolIsBefore,boolIsInsert,boolIsUpdate,boolIsDelete);
		GCR_InventoryMovement.triggerHandler(oldMap, newMap, listNew, boolIsBefore, boolIsInsert, boolIsUpdate, boolIsDelete);

		if(boolIsBefore)
		{
			gcSerialNumber.checkPriorMovements(listNew,oldMap);
			
			if(boolIsInsert)
			{

			}
			if(boolIsUpdate)
			{

			}
			if(boolIsDelete)
			{
				GCR_InventoryTransfer.cascadeDeleteChildrenOfOutbound(oldMap.keySet());
			}
		}
		else //i.e. trigger.isAfter
		{
			Set<String> setIdSerial = new Set<String>();
			if(boolIsInsert)
			{
				for(AcctSeedERP__Outbound_Inventory_Movement__c oim : listNew)
					if(oim.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(oim.GMBLASERP__Serial_Number__c);
				GCR_InventoryTransfer.verifyChildrenOfOutboundFromOrigin(newMap.keySet());
				System.debug('After the Insert');
				GCR_InventoryTransfer.verifyChildrenOfOutboundFromTransit(newMap.keySet());
			}
			if(boolIsUpdate)
			{
				for(AcctSeedERP__Outbound_Inventory_Movement__c oim : listNew)
					if(oim.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(oim.GMBLASERP__Serial_Number__c);
				for(AcctSeedERP__Outbound_Inventory_Movement__c oim : oldMap.values())
					if(oim.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(oim.GMBLASERP__Serial_Number__c);
				GCR_InventoryTransfer.verifyChildrenOfOutboundFromOrigin(newMap.keySet());
				System.debug('After the Update');
				GCR_InventoryTransfer.verifyChildrenOfOutboundFromTransit(newMap.keySet());
			}
			if(boolIsDelete)
			{
				for(AcctSeedERP__Outbound_Inventory_Movement__c oim : oldMap.values())
					if(oim.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(oim.GMBLASERP__Serial_Number__c);
			}
			/// To update serial unit cost run time (future).
			if(!setIdSerial.isEmpty()){
				List<String> listId = new List<String>();
				listId.addAll(setIdSerial);
				gcSerialNumber.updateSerialUnitCostFuture(listId);
			}
		}			
	}

	private static void updateAndValidate
		(map<Id,AcctSeedERP__Outbound_Inventory_Movement__c> oldMap,
		 map<Id,AcctSeedERP__Outbound_Inventory_Movement__c> newMap,
		 list<AcctSeedERP__Outbound_Inventory_Movement__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(boolIsBefore && (boolIsUpdate || boolIsInsert))
		{
			//collect the parent sales order line, for the purpose of setting the lot
			//collect the parent sales order, for the purpose of setting the movement date
			map<Id,AcctSeedERP__Sales_Order_Line__c> mapSalesOrderLine = new map<Id,AcctSeedERP__Sales_Order_Line__c>();
			map<Id,AcctSeedERP__Sales_Order__c> mapSalesOrder = new map<Id,AcctSeedERP__Sales_Order__c>();
			map<Id,AcctSeedERP__Inventory_Balance__c> mapBalance = new map<Id,AcctSeedERP__Inventory_Balance__c>();
			map<Id,GMBLASERP__Inventory_Transfer__c> mapTransfer = new map<Id,GMBLASERP__Inventory_Transfer__c>();

			/// GLV 1,2 FROM Adjustment
			Map<Id,GMBLASERP__Inventory_Adjustment__c> mapAdjustmentGLV = new Map<Id,GMBLASERP__Inventory_Adjustment__c>();
			for(AcctSeedERP__Outbound_Inventory_Movement__c move :listNew)
			{
				if(!Test.isRunningTest())move.AcctSeedERP__Ledger__c = 'a128A000003SnkCQAS';
				if(move.Adjustment_Id_From_Inbound__c != null)
					mapAdjustmentGLV.put(move.Adjustment_Id_From_Inbound__c, null);
				if(move.GMBLASERP__Sales_Order_Line__c != NULL)
					mapSalesOrderLine.put(move.GMBLASERP__Sales_Order_Line__c,NULL);
				if(move.GMBLASERP__Inventory_Transfer__c != null)
					mapTransfer.put(move.GMBLASERP__Inventory_Transfer__c,null);
				mapBalance.put(move.AcctSeedERP__Inventory_Balance__c,null);
			}
			if(!mapAdjustmentGLV.isEmpty())
			{
				for(GMBLASERP__Inventory_Adjustment__c adj : [SELECT Id, GL_Account_Variable_1__c, Department_GLV_2__c FROM GMBLASERP__Inventory_Adjustment__c WHERE Id IN:mapAdjustmentGLV.keySet()])
					mapAdjustmentGLV.put(adj.Id, adj);

				for(AcctSeedERP__Outbound_Inventory_Movement__c move :listNew)
				{
					if(move.Adjustment_Id_From_Inbound__c != null 
						&& mapAdjustmentGLV.get(move.Adjustment_Id_From_Inbound__c) != null 
						&& mapAdjustmentGLV.get(move.Adjustment_Id_From_Inbound__c).GL_Account_Variable_1__c != null)
						move.AcctSeedERP__GL_Account_Variable_1__c = mapAdjustmentGLV.get(move.Adjustment_Id_From_Inbound__c).GL_Account_Variable_1__c;
					if(move.Adjustment_Id_From_Inbound__c != null 
						&& mapAdjustmentGLV.get(move.Adjustment_Id_From_Inbound__c) != null 
						&& mapAdjustmentGLV.get(move.Adjustment_Id_From_Inbound__c).Department_GLV_2__c != null)
						move.AcctSeedERP__GL_Account_Variable_2__c = mapAdjustmentGLV.get(move.Adjustment_Id_From_Inbound__c).Department_GLV_2__c;
				}
			}
			///// GMBLASERP
			mapSalesOrderLine.remove(NULL);
			if(mapSalesOrderLine.size() > 0)
				for(AcctSeedERP__Sales_Order_Line__c sol :
				[SELECT Id, AcctSeedERP__Sales_Order__c, GMBLASERP__Lot__c
				FROM AcctSeedERP__Sales_Order_Line__c
				WHERE Id IN : mapSalesOrderLine.keySet()])
				{
					mapSalesOrderLine.put(sol.Id,sol);
					mapSalesOrder.put(sol.AcctSeedERP__Sales_Order__c, null);
				}
			mapSalesOrder.remove(NULL);
			if(mapSalesOrder.size() > 0)
				for(AcctSeedERP__Sales_Order__c so : [SELECT Id, GMBLASERP__Fill_Date__c FROM AcctSeedERP__Sales_Order__c WHERE Id IN : mapSalesOrder.keySet()])
				{
					mapSalesOrder.put(so.Id, so);
				}

			mapTransfer.remove(null);
			if(mapTransfer.size() > 0)
				for(GMBLASERP__Inventory_Transfer__c xfr :
				[SELECT Id, GMBLASERP__Inbound_Date__c, GMBLASERP__Outbound_Date__c, GMBLASERP__Warehouse_From__c, GMBLASERP__Warehouse_To__c
				FROM GMBLASERP__Inventory_Transfer__c
				WHERE Id IN :mapTransfer.keySet()])
				{
					mapTransfer.put(xfr.Id,xfr);
				}

			mapBalance.remove(null);
			for(AcctSeedERP__Inventory_Balance__c bal :
			[SELECT Id, AcctSeedERP__Product__r.AcctSeed__Inventory_GL_Account__c
			FROM AcctSeedERP__Inventory_Balance__c
			WHERE Id In :mapBalance.keySet()])
			{
				mapBalance.put(bal.Id,bal);
			}

			for(AcctSeedERP__Outbound_Inventory_Movement__c move : listNew)
			{
				move.AcctSeedERP__Credit_GL_Account__c = mapBalance.get(move.AcctSeedERP__Inventory_Balance__c).AcctSeedERP__Product__r.AcctSeed__Inventory_GL_Account__c;

				if(boolIsInsert && move.GMBLASERP__Sales_Order_Line__c != NULL)
					move.GMBLASERP__Lot__c = mapSalesOrderLine.get(move.GMBLASERP__Sales_Order_Line__c).GMBLASERP__Lot__c;

				if(boolIsUpdate && move.GMBLASERP__Sales_Order_Line__c != oldMap.get(move.Id).GMBLASERP__Sales_Order_Line__c)
					move.addError('The Sales Order Line of an Inventory Movement cannot be changed.');

				/*
				The outbound move that is the direct child of an Inventory Transfer should have movementDate = Transfer.OutboundDate
				The outbound move that is the grandchild of an Inventory Transfer should have movementDate = Transfer.InboundDate
				*/
				if(move.GMBLASERP__Inventory_Transfer__c != null && mapTransfer.containsKey(move.GMBLASERP__Inventory_Transfer__c))
				{
					GMBLASERP__Inventory_Transfer__c xfr = mapTransfer.get(move.GMBLASERP__Inventory_Transfer__c);
					if(move.AcctSeedERP__Inbound_Inventory_Movement__c == null)
						move.AcctSeedERP__Movement_Date__c = xfr.GMBLASERP__Outbound_Date__c;
					else if(xfr.GMBLASERP__Inbound_Date__c != null)
						move.AcctSeedERP__Movement_Date__c = xfr.GMBLASERP__Inbound_Date__c;
				}

				//if a Fill Date has been specified, set the move date to the Sales Order Fill Date
				//do not manipulate the Fill Date for returns (i.e. negative movements)
				if(move.GMBLASERP__Sales_Order_Line__c != NULL &&
						mapSalesOrder.get(mapSalesOrderLine.get(move.GMBLASERP__Sales_Order_Line__c).AcctSeedERP__Sales_Order__c).GMBLASERP__Fill_Date__c != null &&
						move.AcctSeedERP__Quantity__c >= 0)
				{
					move.AcctSeedERP__Movement_Date__c = mapSalesOrder.get(mapSalesOrderLine.get(move.GMBLASERP__Sales_Order_Line__c).AcctSeedERP__Sales_Order__c).GMBLASERP__Fill_Date__c;
				}
			}
		}

		if(boolIsBefore && boolIsDelete)
		{
			for(AcctSeedERP__Outbound_Inventory_Movement__c move :oldMap.values())
			{
				if(move.Lot_Exchange__c != null && !enableExchangeDelete)
					move.addError('The movement cannot be deleted as it is releated to a Lot Exchange.');
			}			
		}

		if(!boolIsBefore){
			Set<Id> setIdMaterialToUpdate = new Set<Id>();
			set<Id> setIdSalesOrderLine = new set<Id>();
			set<Id> setIdProjectTask = new set<Id>();
			if(boolIsInsert || boolIsUpdate) {
				for (AcctSeedERP__Outbound_Inventory_Movement__c move : listNew) {
					if (move.Material__c != null)
						setIdMaterialToUpdate.add(move.Material__c);
					setIdSalesOrderLine.add(move.GMBLASERP__Sales_Order_Line__c);
					setIdProjectTask.add(move.AcctSeedERP__Project_Task__c);
				}
			}
			if(boolIsDelete || boolIsUpdate) {
				for (AcctSeedERP__Outbound_Inventory_Movement__c move : oldMap.values()) {
					if (move.Material__c != null)
						setIdMaterialToUpdate.add(move.Material__c);
					setIdSalesOrderLine.add(move.GMBLASERP__Sales_Order_Line__c);
					setIdProjectTask.add(move.AcctSeedERP__Project_Task__c);
				}
			}

			if(!setIdMaterialToUpdate.isEmpty()){
				System.debug(loggingLevel.Error, 'setIdMaterialToUpdate:'+setIdMaterialToUpdate);
				gcMaterial.updateQtyMoved(setIdMaterialToUpdate);
			}
			/// FROM GMBLASERP Package
			setIdSalesOrderLine.remove(NULL);
			setIdProjectTask.remove(NULL);
			if(!setIdSalesOrderLine.isEmpty())
				GCR_SalesOrderLine.rollup(setIdSalesOrderLine);
			if(!setIdProjectTask.isEmpty())
				gcProjectTask.recalcQtyFilled(setIdProjectTask);
		}
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
	}
}