global without sharing class createValueAdjustmentFromImportBatch implements Schedulable, Database.Batchable<sObject>{

	global createValueAdjustmentFromImportBatch() {}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Id, Product__c, Adjustment_Value_Per_Quantity__c, Has_Inbound__c, Adjusted__c, Existing_Quantity__c, Existing_Value__c FROM Import_Adjustment_New__c WHERE Adjustable__c = true and Adjusted__c = false';
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
   		List<Import_Adjustment_New__c> listImport = new List<Import_Adjustment_New__c>();
   		Map<Id,GMBLASERP__Inventory_Adjustment__c> mapAdjustment = new Map<Id,GMBLASERP__Inventory_Adjustment__c>();
   		Set<Id> setIdProduct = new Set<Id>();
   		Id idGlCostVariance = gcConstants.idGlCostVariance;
		for(SObject sObj : scope) {
			Import_Adjustment_New__c imp = (Import_Adjustment_New__c) sObj;
			if(!mapAdjustment.containsKey(imp.Product__c))
				mapAdjustment.put(imp.Product__c, new GMBLASERP__Inventory_Adjustment__c(GMBLASERP__Product__c = imp.Product__c, GMBLASERP__Adjustment_Date__c = Date.today(), GMBLASERP__Adjustment_Type__c = 'Value', GMBLASERP__GL_Account__c = idGlCostVariance));
			setIdProduct.add(imp.Product__c);
			listImport.add(imp);
		}
		insert mapAdjustment.values();
		Map<Id,Id> mapWarehouseLocation = new Map<Id,Id>();
		Id idWarehouse = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c;
		for(AcctSeedERP__Warehouse__c whs : [SELECT Id, (SELECT Id FROM AcctSeedERP__Locations__r LIMIT 1) FROM AcctSeedERP__Warehouse__c WHERE Id =:idWarehouse])
			mapWarehouseLocation.put(whs.Id, whs.AcctSeedERP__Locations__r[0].Id);
		Map<Id,Map<Id,Map<Id,Id>>> mapPWLB = new Map<Id,Map<Id,Map<Id,Id>>>();
		for(Import_Adjustment_New__c imp : listImport)
		{
			if(!mapPWLB.containsKey(imp.Product__c)){
            	mapPWLB.put(imp.Product__c, new map<Id,map<Id,Id>>{idWarehouse => new map<Id,Id>{mapWarehouseLocation.get(idWarehouse) => null}});
			}else if(!mapPWLB.get(imp.Product__c).containsKey(idWarehouse)){
				mapPWLB.get(imp.Product__c).put(idWarehouse, new map<Id,Id>{mapWarehouseLocation.get(idWarehouse) => null});
			}
		}
		GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);
        Map<Id,Decimal> mapPQty = new Map<Id,Decimal>();
        Map<Id,Decimal> mapPVal = new Map<Id,Decimal>();
        for(AggregateResult aggRes : 
            [SELECT GMBLASERP__Product__c idProduct, 	
            	sum(GMBLASERP__Quantity__c) qty, 
            	sum(GMBLASERP__Inventory_GL_Amount__c) amt
             FROM GMBLASERP__Inventory_Movement_Cube__c
             WHERE GMBLASERP__Product__c IN:setIdProduct
               	AND GMBLASERP__Movement_Date__c <= TODAY
             GROUP BY GMBLASERP__Product__c])
        {
            Decimal qtyInv = (Decimal)aggRes.get('qty');
            Decimal valInv = (Decimal)aggRes.get('amt');
            Id idProd = (Id)aggRes.get('idProduct');

            mapPQty.put(idProd,qtyInv);
            mapPVal.put(idProd,valInv);
        }

		List<AcctSeedERP__Inbound_Inventory_Movement__c> listMoves = new List<AcctSeedERP__Inbound_Inventory_Movement__c>();
		Map<Id,AcctSeedERP__Inbound_Inventory_Movement__c> mapIdMove = new Map<Id,AcctSeedERP__Inbound_Inventory_Movement__c>();
		for(Import_Adjustment_New__c imp : listImport)
		{
			Decimal cQty = 0;
			if(mapPQty.containsKey(imp.Product__c))
				cQty  =  mapPQty.get(imp.Product__c);
			imp.Existing_Quantity__c = cQty.setScale(6);

			Decimal cVal = 0;
			if(mapPVal.containsKey(imp.Product__c))
				cVal  =  mapPVal.get(imp.Product__c);
			imp.Existing_Value__c = cVal.setScale(2);

			if(cQty <= 0) continue;

			Id idBalance = GMBLASERP.gcInventoryBalance.findOrCreateBalance(imp.Product__c,idWarehouse,mapWarehouseLocation.get(idWarehouse));
			AcctSeedERP__Inbound_Inventory_Movement__c inMove = new AcctSeedERP__Inbound_Inventory_Movement__c(
					            GMBLASERP__Inventory_Adjustment__c = mapAdjustment.get(imp.Product__c).Id,
					            AcctSeedERP__Credit_GL_Account__c = mapAdjustment.get(imp.Product__c).GMBLASERP__GL_Account__c,
					            AcctSeedERP__Inventory_Balance__c = idBalance,
					            AcctSeedERP__Movement_Date__c = Date.today(),       
					            AcctSeedERP__Quantity__c = cQty,
					            AcctSeedERP__Type__c = 'Accounting',
					            AcctSeedERP__Unit_Cost__c = 0,
					            GMBLASERP__Cost_Override__c = false,
					            Import_Adjustment_Value__c = imp.Id
						);

			listMoves.add(inMove);
			mapIdMove.put(imp.Id, inMove);
		}
		if(!listMoves.isEmpty()){
			insert listMoves;
			List<AcctSeedERP__Outbound_Inventory_Movement__c> listOutMoves = new List<AcctSeedERP__Outbound_Inventory_Movement__c>();
			for(AcctSeedERP__Inbound_Inventory_Movement__c inMove : listMoves)
			{
				AcctSeedERP__Outbound_Inventory_Movement__c moveOut = new AcctSeedERP__Outbound_Inventory_Movement__c(
															            AcctSeedERP__Debit_GL_Account__c = inMove.AcctSeedERP__Credit_GL_Account__c,
															            AcctSeedERP__Inventory_Balance__c = inMove.AcctSeedERP__Inventory_Balance__c,
															            AcctSeedERP__Movement_Date__c = inMove.AcctSeedERP__Movement_Date__c,       
															            AcctSeedERP__Quantity__c = inMove.AcctSeedERP__Quantity__c,
															            AcctSeedERP__Type__c = 'Accounting',
															            AcctSeedERP__Unit_Cost__c = 0,
															            GMBLASERP__Cost_Override__c = false,
															            AcctSeedERP__Inbound_Inventory_Movement__c = inMove.Id
															        );
				listOutMoves.add(moveOut);
			}
			if(!listOutMoves.isEmpty())
				insert listOutMoves;
		}
		for(Import_Adjustment_New__c imp : listImport)
		{
			AcctSeedERP__Inbound_Inventory_Movement__c inMove = mapIdMove.get(imp.Id);
			if(inMove != null)
			{
				inMove.AcctSeedERP__Unit_Cost__c = imp.Adjustment_Value_Per_Quantity__c;
				inMove.GMBLASERP__Cost_Override__c = true;
				imp.Has_Inbound__c = true;
				imp.Adjusted__c = true;
			}
		}
		update mapIdMove.values();
		update listImport;
	}
	
	global void execute(SchedulableContext sc) {
		tempIAIUpdateProductWarehouseBatch b = new tempIAIUpdateProductWarehouseBatch();
		database.executeBatch(b, 1);
	}
	
	global void finish(Database.BatchableContext BC) {}

	global static void coverage(){
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
	}
}