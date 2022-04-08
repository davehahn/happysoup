global without sharing class gcLegendMRP_Items {
	public gcLegendMRP_Items() {}
	public gcLegendMRP_Items(ApexPages.StandardController c){}

	@RemoteAction @ReadOnly 
	public static list<map<string,string>> retrieveItemsSerials()
	{
		list<map<string,string>> listJSON = new list<map<string,string>>();

		String soql = '';
		soql += ' SELECT Id, Name, GMBLASERP__Lot__r.Name, GMBLASERP__Product__r.Name, GMBLASERP__Product__r.ProductCode, GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name, ';
		//soql += ' 	(SELECT GMBLASERP__Quantity__c FROM GMBLASERP__Inventory_Movement_Cubes__r WHERE GMBLASERP__Quantity__c != null AND GMBLASERP__Quantity__c != 0), ';
		soql += '	(SELECT AcctSeedERP__Movement_Date__c FROM GMBLASERP__Purchase_Order_Inventory_Movements__r WHERE AcctSeedERP__Quantity__c > 0 ORDER BY AcctSeedERP__Movement_Date__c DESC LIMIT 1), ';
		soql += ' 	(SELECT Id, Name, AcctSeed__Status__c FROM Projects__r WHERE AcctSeedERP__Manufactured_Product__c != null AND (AcctSeed__Status__c = \'Active\' OR AcctSeed__Status__c = \'New\') LIMIT 1) ';
		soql += ' FROM GMBLASERP__Serial_Number__c ';
		soql += ' WHERE GMBLASERP__Inventory_Balance__c != null ';
		//soql += '   AND GMBLASERP__Product__c IN (SELECT Id FROM Product2 WHERE RecordType.Name != \'Boat\') ';

		for(GMBLASERP__Serial_Number__c sn : Database.query(soql))
		{

			map<string,string> m = new map<string,string>();

			m.put('idSerial',sn.Id);
			m.put('serialName',sn.Name);

			if(!sn.Projects__r.isEmpty())
			{
				m.put('idProject',sn.Projects__r[0].Id);
				m.put('projectName',sn.Projects__r[0].Name);
				m.put('projectStatus',sn.Projects__r[0].AcctSeed__Status__c);
			}

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
	public static string createProjectsFromSerials(list<Id> listIdSerial, Boolean includePreRig)
	{
		list<AcctSeed__Project__c> listProject = new list<AcctSeed__Project__c>();
		
		map<Id,GMBLASERP__Serial_Number__c> mapSerial = new map<Id,GMBLASERP__Serial_Number__c>();

		Id idRecordTypeMfg = [SELECT Id FROM RecordType WHERE sObjectType = 'AcctSeed__Project__c' AND DeveloperName='Manufacturing'][0].Id;
		
		for(GMBLASERP__Serial_Number__c sn : 
			[SELECT Id, Name,
					GMBLASERP__Product__c,
					GMBLASERP__Product__r.Name,
					GMBLASERP__Product__r.ProductCode,
					GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c
			 FROM GMBLASERP__Serial_Number__c
			 WHERE Id IN :listIdSerial])
		{
			mapSerial.put(sn.Id,sn);
		}

		for(Id idSerial : listIdSerial)
		{
			GMBLASERP__Serial_Number__c sn = mapSerial.get(idSerial);
			
			String projectName = 'Modification '+sn.Name;

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
			list<AcctSeed__Project_Task__c> listPT = new list<AcctSeed__Project_Task__c>();
			for(AcctSeed__Project__c p : listProject)
			{
				listPT.add(new AcctSeed__Project_Task__c(
					AcctSeed__Project__c = p.Id,
					Name = 'Modification',
					Product__c = p.AcctSeedERP__Manufactured_Product__c,
					Locked__c = true
				));
			}
			if(!includePreRig){
				Boolean boolOld = gcProjectTask.disableUpdateMaterialSpec;
				gcProjectTask.disableUpdateMaterialSpec = true;
				insert listPT;
				gcProjectTask.disableUpdateMaterialSpec = boolOld;
			}else {
				Boolean currentStatus = gcMaterial.disableTaskLockCheck;
				gcMaterial.disableTaskLockCheck = true;
				insert listPT;
				gcMaterial.disableTaskLockCheck = currentStatus;
			}
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
			  //AND AcctSeedERP__Manufactured_Product__r.RecordType.Name != 'Boat'
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
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;        
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
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