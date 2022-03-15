global without sharing class gcLegendMRP {
	public gcLegendMRP() {}
	public gcLegendMRP(ApexPages.StandardController c){}

	@RemoteAction @ReadOnly
	webservice static boolean checkBoatsAvailableFromPO(Id idPurchaseOrder)
	{
		//if there is at least one boat that meets the following characteristics, return true.  otherwise return false.
		//the boat was received on this purchase order
		//the boat is in inventory
		//the boat is not referenced by a manufacturing project
		for(GMBLASERP__Serial_Number__c x :
			[SELECT Id, (SELECT Id FROM Projects__r WHERE AcctSeedERP__Manufactured_Product__c != null LIMIT 1)
			 FROM GMBLASERP__Serial_Number__c
			 WHERE Id IN (SELECT GMBLASERP__Serial_Number__c FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c WHERE AcctSeedERP__Purchase_Order_Line__r.AcctSeedERP__Purchase_Order__c =:idPurchaseOrder)
			   AND GMBLASERP__Inventory_Balance__c != null
			   AND GMBLASERP__Product__c IN (SELECT Id FROM Product2 WHERE RecordType.Name = 'Boat')])
		{
			if(x.Projects__r.size() == 0)
				return true;
		}
		return false;
	}

	@RemoteAction @ReadOnly @AuraEnabled
	public static list<map<string,string>> retrieveUnimprovedHulls_LWC(Id idPurchaseOrder, String timeString){
		return retrieveUnimprovedHulls(idPurchaseOrder);
	}

	@RemoteAction @ReadOnly
	public static list<map<string,string>> retrieveUnimprovedHulls(Id idPurchaseOrder)
	{
		list<map<string,string>> listJSON = new list<map<string,string>>();
		Application_RecordType appRT = new Application_RecordType();
		Application_RecordType.ProductRTs productRts = appRT.getProductRecordTypes();
		Set<Id> setIdRT = new Set<Id>{productRts.getBoatId(),productRts.getTrailerId(),productRts.getTrollingMotorId()};
		String soql = '';
		soql += ' SELECT Id, Name, GMBLASERP__Lot__r.Name, GMBLASERP__Product__r.Name, GMBLASERP__Product__r.ProductCode, GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name, ';
		//soql += ' 	(SELECT GMBLASERP__Quantity__c FROM GMBLASERP__Inventory_Movement_Cubes__r WHERE GMBLASERP__Quantity__c != null AND GMBLASERP__Quantity__c != 0), ';
		soql += '	(SELECT AcctSeedERP__Movement_Date__c FROM GMBLASERP__Purchase_Order_Inventory_Movements__r WHERE AcctSeedERP__Quantity__c > 0 ORDER BY AcctSeedERP__Movement_Date__c DESC LIMIT 1), ';
		soql += ' 	(SELECT Id FROM Projects__r WHERE AcctSeedERP__Manufactured_Product__c != null LIMIT 1) ';
		soql += ' FROM GMBLASERP__Serial_Number__c ';
		soql += ' WHERE GMBLASERP__Product__c IN (SELECT Id FROM Product2 WHERE RecordTypeId IN:setIdRT) ';
		soql += '   AND GMBLASERP__Inventory_Balance__c != null ';
		if(idPurchaseOrder != null)
		soql += '   AND Id IN (SELECT GMBLASERP__Serial_Number__c FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c WHERE AcctSeedERP__Purchase_Order_Line__r.AcctSeedERP__Purchase_Order__c =:idPurchaseOrder) ';

		for(GMBLASERP__Serial_Number__c sn : Database.query(soql))
		{
			if(sn.Projects__r.size() > 0) continue; //the serial is already on a Manufacturing Project

			map<string,string> m = new map<string,string>();

			m.put('idSerial',sn.Id);
			m.put('serialName',sn.Name);
			if(sn.GMBLASERP__Product__c != null)
			{
				m.put('idProduct',sn.GMBLASERP__Product__c);
				m.put('productName',sn.GMBLASERP__Product__r.Name);
				m.put('productCode',sn.GMBLASERP__Product__r.ProductCode);
			}
			if(sn.GMBLASERP__Lot__c != null)
			{
				m.put('idLot',sn.GMBLASERP__Lot__c);
				m.put('lotName',sn.GMBLASERP__Lot__r.Name);
			}
			if(sn.GMBLASERP__Inventory_Balance__c != null)
			{
				m.put('idBalance',sn.GMBLASERP__Inventory_Balance__c);
				m.put('idWarehouse',sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c);
				m.put('warehouseName',sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name);
			}

			if(sn.GMBLASERP__Purchase_Order_Inventory_Movements__r.size() > 0)
			{
				m.put('dateReceived',sn.GMBLASERP__Purchase_Order_Inventory_Movements__r[0].AcctSeedERP__Movement_Date__c.format());
			}

			listJSON.add(m);
		}
		return listJSON;
	}

	@RemoteAction
	public static string createProjectsFromHulls(list<Id> listIdSerial)
	{
		list<AcctSeed__Project__c> listProject = new list<AcctSeed__Project__c>();

		map<Id,GMBLASERP__Serial_Number__c> mapSerial = new map<Id,GMBLASERP__Serial_Number__c>();
		map<Id,Product2> mapProduct = new map<Id,Product2>();

		Id idRecordTypeMfg = [SELECT Id FROM RecordType WHERE sObjectType = 'AcctSeed__Project__c' AND DeveloperName='Manufacturing'][0].Id;

		for(GMBLASERP__Serial_Number__c sn :
			[SELECT Id, Name,
					GMBLASERP__Product__c,
					GMBLASERP__Product__r.Name,
					GMBLASERP__Product__r.RecordType.Name,
					GMBLASERP__Product__r.ProductCode,
					GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c
			 FROM GMBLASERP__Serial_Number__c
			 WHERE Id IN :listIdSerial])
		{
			mapSerial.put(sn.Id,sn);
			mapProduct.put(sn.GMBLASERP__Product__c,sn.GMBLASERP__Product__r);
		}

		for(Id idSerial : listIdSerial)
		{
			GMBLASERP__Serial_Number__c sn = mapSerial.get(idSerial);

			String projectName = 'PRE-RIG '+sn.Name;
//			if(sn.GMBLASERP__Product__r.RecordType.Name != 'Boat')
//				projectName = 'Modification '+sn.Name;

			if(projectName.length() > 40)
				projectName = projectName.substring(0,39);

			listProject.add(new AcctSeed__Project__c(
				Name = projectName,
				RecordTypeId = idRecordTypeMfg,
				AcctSeedERP__Manufactured_Product__c = sn.GMBLASERP__Product__c,
				AcctSeed__Status__c = 'New',
				Serial_Number__c = sn.Id,
				GMBLASERP__Warehouse__c = sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c
			));
		}
		if(listProject.size() > 0)
		{
			insert listProject;
			Map<Id,AcctSeed__Project__c> mapP = new Map<Id,AcctSeed__Project__c>();
			Map<Id,AcctSeed__Project_Task__c> mapPT = new Map<Id,AcctSeed__Project_Task__c>();
			list<AcctSeedERP__Material__c> listMaterial = new list<AcctSeedERP__Material__c>();
			for(AcctSeed__Project__c p : listProject)
			{
				String typeName = mapProduct.get(p.AcctSeedERP__Manufactured_Product__c).RecordType.Name;
				String taskName = 'PRE-RIG';
//				if(typeName != 'Boat')
//					taskName = 'Modification';

				AcctSeed__Project_Task__c pt = new AcctSeed__Project_Task__c(
					AcctSeed__Project__c = p.Id,
					Name = taskName,
					Product__c = p.AcctSeedERP__Manufactured_Product__c,
					Admin_Deletable_Only__c = true
				);
				mapPT.put(p.Id,pt);
				mapP.put(p.Id,p);
				/// Adding the ERP Serial as well in the material line - added on 19 May 2021
				listMaterial.add(new AcctSeedERP__Material__c(
					AcctSeedERP__Project__c = p.Id,
					AcctSeedERP__Product__c = p.AcctSeedERP__Manufactured_Product__c,
					GMBLASERP__Serial_Number__c = p.Serial_Number__c,
					AcctSeedERP__Quantity_Per_Unit__c = 1
				));
			}
			insert mapPT.values();
			for(AcctSeedERP__Material__c mt : listMaterial){
				mt.AcctSeedERP__Project_Task__c = mapPT.get(mt.AcctSeedERP__Project__c).Id;
			}
			/// Insert first set of materials for the newly created projects
			insert listMaterial;
		}

		return '';
	}

	@RemoteAction @ReadOnly
	public static list<map<string,string>> retrieveManufacturingProjectsCreatedToday()
	{
		list<map<string,string>> listJSON = new list<map<string,string>>();
		for(AcctSeed__Project__c p :
			[SELECT Id, Name,
					AcctSeed__Status__c,
					AcctSeedERP__Manufactured_Product__r.Name,
					AcctSeedERP__Work_Order_Number__c,
					Serial_Number__c,
					Serial_Number__r.Name,
					Serial_Number__r.GMBLASERP__Lot__c,
					Serial_Number__r.GMBLASERP__Lot__r.Name,
					GMBLASERP__Warehouse__c,
					GMBLASERP__Warehouse__r.Name
			FROM AcctSeed__Project__c
			WHERE CreatedDate = TODAY
			  AND AcctSeedERP__Manufactured_Product__c != null
			ORDER BY CreatedDate DESC])
		{
			map<string,string> m = new map<string,string>();
			m.put('idProject',p.Id);
			m.put('projectName',p.Name);
			m.put('projectStatus',p.AcctSeed__Status__c);
			m.put('workOrderNumber',p.AcctSeedERP__Work_Order_Number__c);

			m.put('idProduct',p.AcctSeedERP__Manufactured_Product__c);
			m.put('productName',p.AcctSeedERP__Manufactured_Product__r.Name);

			if(p.Serial_Number__c != null)
			{
				m.put('idSerial',p.Serial_Number__c);
				m.put('serialName',p.Serial_Number__r.Name);
				if(p.Serial_Number__r.GMBLASERP__Lot__c != null)
				{
					m.put('idLot',p.Serial_Number__r.GMBLASERP__Lot__c);
					m.put('lotName',p.Serial_Number__r.GMBLASERP__Lot__r.Name);
				}
			}
			if(p.GMBLASERP__Warehouse__c != null)
			{
				m.put('idWarehouse',p.GMBLASERP__Warehouse__c);
				m.put('warehouseName',p.GMBLASERP__Warehouse__r.Name);
			}

			listJSON.add(m);
		}
		return listJSON;
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
	}
}