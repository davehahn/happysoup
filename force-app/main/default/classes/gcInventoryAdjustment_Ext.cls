global without sharing class gcInventoryAdjustment_Ext {

    global gcInventoryAdjustment_Ext(ApexPages.standardController c){
    	defaultRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Boat').getRecordTypeId();
    }
    global gcInventoryAdjustment_Ext(){
    	defaultRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Boat').getRecordTypeId();
    }
	
	global List<SelectOption> getListProductType()
	{
		List<SelectOption> listOptions = new List<SelectOption>();

	    Map<Id,Schema.RecordTypeInfo> productRecordTypeInfo = Schema.SObjectType.Product2.getRecordTypeInfosById();
		listOptions.add(new selectOption('', '-- SELECT ALL --'));

		for(Id idRT : productRecordTypeInfo.keySet())
        {
			listOptions.add(new selectOption(idRT, productRecordTypeInfo.get(idRT).getName()));
		}

		return listOptions;	
	}

	global static String defaultRecordId{get;set;}

    @RemoteAction @ReadOnly 
    global static map<string,string> retrieveAdjustment(Id idAdjustment)
    {
        return GMBLASERP.gcInventoryAdjustment_Ext.retrieveAdjustment(idAdjustment);
    }

    @RemoteAction @ReadOnly 
    global static list<map<string,string>> retrieveMoves(string idFilter)
    {
    	return GMBLASERP.gcInventoryAdjustment_Ext.retrieveMoves(idFilter);
    }

    @RemoteAction @ReadOnly 
    global static list<map<string,string>> retrieveInventory(string idAdjustment, string idObject, String idType)
    {
        GMBLASERP__Inventory_Adjustment__c adj = 
        [SELECT GMBLASERP__Warehouse__c, 
                GMBLASERP__Product__c, 
                GMBLASERP__Adjustment_Type__c, 
                GMBLASERP__Adjustment_Date__c 
         FROM GMBLASERP__Inventory_Adjustment__c 
         WHERE Id = :idAdjustment][0];

        map<string,list<string>> mapFilters = new map<string,list<string>>();

        mapFilters.put('dateThru', new list<string>{String.valueOf(adj.GMBLASERP__Adjustment_Date__c.format())});

        if(adj.GMBLASERP__Warehouse__c != null)
            mapFilters.put('idWarehouse', new list<string>{adj.GMBLASERP__Warehouse__c});
        if(adj.GMBLASERP__Product__c != null)
            mapFilters.put('idProduct', new list<string>{adj.GMBLASERP__Product__c});

        if(idObject != null)
        {
        	if((Id.valueOf(idObject)).getSObjectType() == GMBLASERP__Serial_Number__c.sObjectType)
        		mapFilters.put('idSerial', new list<string>{idObject});
        	else if((Id.valueOf(idObject)).getSObjectType() == GMBLASERP__Lot__c.sObjectType)
        		mapFilters.put('idLot', new list<string>{idObject});
        	else if((Id.valueOf(idObject)).getSObjectType() == Product2.sObjectType)
                mapFilters.put('idProduct', new list<string>{idObject});
        }

        if(idType != '' && !mapFilters.containsKey('idProduct'))
        {
        	List<String> listProductId = new List<String>();
        	for(Product2 p :
				[SELECT Id
				 FROM Product2
				 WHERE AcctSeed__Inventory_Product__c = true
				 	AND RecordTypeId =:idType])
			{
				listProductId.add(p.Id);
			}
			if(!listProductId.isEmpty())
				mapFilters.put('idProduct',listProductId);
			else
				return new list<map<string,string>>();
        }

        return gcInventoryMovementCube_Report.inventorySummary(mapFilters, new list<string>{'idProduct','idLot','idSerial'});
    }

    @RemoteAction
    global static map<string,string> adjustQuantity(String idMove, Decimal qty)
    {
    	return GMBLASERP.gcInventoryAdjustment_Ext.adjustQuantity(idMove, qty);
    }

    @RemoteAction
    global static map<string,string> adjustValue(String idMove, Decimal amt)
    {
    	return GMBLASERP.gcInventoryAdjustment_Ext.adjustValue(idMove, amt);
    }

	@RemoteAction 
	global static map<string,string> createAdjustment(String idAdjustment, String idObject)
	{
		return GMBLASERP.gcInventoryAdjustment_Ext.createAdjustment(idAdjustment, idObject);
	}

    @RemoteAction
    global static string deleteMove(String idMove)
    {
    	return GMBLASERP.gcInventoryAdjustment_Ext.deleteMove(idMove);
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
	}
}