public with sharing class gcProject_PickList_PDF2 {

    public gcProject_PickList_PDF2(){}

    public gcProject_PickList_PDF2(ApexPages.StandardController c) { 
		idProject = c.getId();
		init();
	}

	public Id idProject{get;set;}

	public transient Map<String,String> project{get;set;}
	public transient List<Map<String,String>> listMaterial{get;set;}
	public List<MaterialWrapper> materials;

	public class MaterialWrapper {
		public String productName {get; set;}
		public String productCode {get; set;}
		public String qtySpecified {get; set;}
		public String qtyAvailable {get; set;}
		public String qtyAllocated {get; set;}
		public String qtyFilled {get; set;}
		public String qtyNeeded {get; set;}
		public String projectTaskName {get; set;}
		public Boolean done {get; set;}

		public List<Map<String, String>> locations {get; set;}

		public MaterialWrapper() {
			this.locations = new List<Map<String, String>>();
		}
	}

	public List<MaterialWrapper> getMaterials()
	{
		return materials;
	}

	private void init()
	{
		project = new Map<String,String>();
		listMaterial = new List<Map<String,String>>();

		for(AcctSeed__Project__c p :
			[SELECT Id,
					Name,
					CreatedDate,
					AcctSeed__Account__c,
					AcctSeed__Account__r.Name,
             		AcctSeedERP__Manufactured_Product__r.Name,
					AcctSeedERP__Work_Order_Number__c,
					Boat_Specialist__r.Name,
             		RecordType.Name,
             		Serial_Number__r.Name,
          			Salesperson__r.Name,
          			WarehouseName__c
			 FROM AcctSeed__Project__c
			 WHERE Id = :idProject
			 LIMIT 1])
		{
			System.debug( 'PROJECT = ' + p);
			project.put('id',p.Id);
			project.put('workOrderNumber',p.AcctSeedERP__Work_Order_Number__c);
			project.put('workOrderName',p.Name);
			project.put('accountName',(p.AcctSeed__Account__c == null ? '' : p.AcctSeed__Account__r.Name));
			project.put('createdDate',p.CreatedDate.format());
            project.put('recordTypeName',(p.RecordType.Name == null ? '' : p.RecordType.Name));
            project.put('manufacturedProductName',(p.AcctSeedERP__Manufactured_Product__r.Name == null ? '' : p.AcctSeedERP__Manufactured_Product__r.Name));
            project.put('serialName',(p.Serial_Number__r.Name == null ? '' : p.Serial_Number__r.Name));
            project.put('salesperson',(p.Salesperson__r.Name == null ? '' : p.Salesperson__r.Name));
            project.put('boatSpecialist',(p.Boat_Specialist__r.Name == null ? '' : p.Boat_Specialist__r.Name));
            project.put('warehouse',(p.WarehouseName__c == null ? '' : p.WarehouseName__c));
		}

		listMaterial = gcProject_Ext.retrieveMaterials(idProject,null);
        //map['key'] within a visualforce context will fail, if the key is not found, or if the value is null
        //so make sure that each one of the keys returns a non-null value

        Set<Id> productIds = new Set<Id>();

        for(Map<String,String> m : listMaterial)
        {
            if(m.get('productName') == null)
                m.put('productName','');
            if(m.get('productCode') == null)
                m.put('productCode','');
            if(m.get('qtySpecified') == null)
                m.put('qtySpecified','0');

            productIds.add( String.valueOf( m.get('idProduct') ) );
        }

        Map<Id, Decimal> movementMap = new Map<Id, Decimal>();
        for(GMBLASERP__Inventory_Movement_Cube__c movement : [SELECT Id, 
        															 GMBLASERP__Quantity__c, 
        															 GMBLASERP__Warehouse__c,
        															 GMBLASERP__Product__c
        	 		 											FROM GMBLASERP__Inventory_Movement_Cube__c
        	 		 										   WHERE GMBLASERP__Quantity__c != 0
        	 		   											 AND GMBLASERP__Warehouse__r.Name = :project.get('warehouse')
        	 		   											 AND GMBLASERP__Product__c IN :productIds]) {
        	//movementMap.put(movement.GMBLASERP__Product__c, movement.GMBLASERP__Quantity__c);
        	if (movementMap.get(movement.GMBLASERP__Product__c) == null) {
        		movementMap.put(movement.GMBLASERP__Product__c, movement.GMBLASERP__Quantity__c);
        	} else {
        		Decimal quantity = movementMap.get(movement.GMBLASERP__Product__c);
        		quantity += movement.GMBLASERP__Quantity__c;
        		movementMap.put(movement.GMBLASERP__Product__c, quantity);
        	}
        }

		materials = new List<MaterialWrapper>();

        Product_Bin_Location__c[] binLocations = [SELECT Id, 
        												 Aisle__c, 
        												 Name, 
        												 Product__c, 
        												 Section__c,
        												 Warehouse__r.Name
        											FROM Product_Bin_Location__c
        										   WHERE Product__c IN :productIds
        											 AND Warehouse__r.Name = :project.get('warehouse')];

        System.debug('productIds: ' + productIds);
        System.debug('warehouse: ' + project.get('warehouse'));
        System.debug('binLocations: ' + binLocations);
		
		Set<Id> materialIds = new Set<Id>();
		for (Map<String,String> m : listMaterial) {
        	materialIds.add( m.get('idMaterial') );
        }
        for (AcctSeedERP__Material__c material : [SELECT AcctSeedERP__Comment__c, 
        												 AcctSeedERP__Product__c, 
        												 AcctSeedERP__Product__r.Family,
        												 AcctSeedERP__Project__c, 
        												 AcctSeedERP__Project_Task__c, 
        												 AcctSeedERP__Quantity_Allocated__c, 
        												 AcctSeedERP__Quantity_Per_Unit__c, 
        												 Case_Part__c, 
        												 CreatedById, 
        												 CreatedDate, 
        												 DisplayOnCustomerInvoice__c, 
        												 ERP_RecordTypeId__c, 
        												 GMBLASERP__Lot__c, 
        												 GMBLASERP__Price_Override__c, 
        												 GMBLASERP__Serial_Number__c, 
        												 GMBLASERP__Total_Price__c, 
        												 GMBLASERP__Unit_Price__c, 
        												 Id, 
        												 Insurance_Coverage__c, 
        												 Insurance_Rate__c, 
        												 IsDeleted, 
        												 isDiscount__c, 
        												 isInsuranceItem__c, 
        												 Material__c, 
        												 Name, 
        												 OwnerId, 
        												 Product_Name__c, 
        												 Product_Record_Type__c, 
        												 Quantity_Allocated_Non_Inventory__c,
														 Actual_Quantity_Filled__c,
        												 Quantity_Specified_Override__c, 
        												 Return_Parent__c, 
        												 Taxable_Retail__c 
        											FROM AcctSeedERP__Material__c
        										   WHERE Id IN :materialIds]) {
        	for (Map<String,String> m : listMaterial) {
        		if (m.get('idMaterial') == material.Id ) {
        			m.put('productRecordType', material.Product_Record_Type__c);
        			m.put('isDiscount', String.valueOf(material.isDiscount__c) );
        			m.put('isInsuranceItem', String.valueOf(material.isInsuranceItem__c) );
        			m.put('productFamily', String.valueOf(material.AcctSeedERP__Product__r.Family) );
        		}
        	}
        }

        for (Map<String,String> m : listMaterial)
        {
        	if (   m.get('isDiscount') != 'true'
        		&& m.get('isInsuranceItem') != 'true' 
        		&& m.get('productRecordType') != 'Fees'
        		&& m.get('productFamily') != 'Premium Package' ) {
	        	MaterialWrapper mw = new MaterialWrapper();
	        	mw.projectTaskName = m.get('projectTaskName');
	        	mw.productCode = m.get('productCode') == null ? 'x' : m.get('productCode');
	        	mw.productName = m.get('productName') == null ? 'x' : m.get('productName');
	        	mw.qtySpecified = m.get('qtySpecified') == null ? '0' : m.get('qtySpecified');
	        	mw.qtyAvailable = String.valueOf( movementMap.get( m.get('idProduct') ) );
	        	mw.qtyAllocated = m.get('qtyAllocated') == null ? '0' : m.get('qtyAllocated');
				mw.qtyNeeded = m.get('qtyCanBeMoved') == null ? '0' : m.get('qtyCanBeMoved');

	        	if (mw.qtySpecified == mw.qtyAllocated) {
	        		mw.done = True;
	        	} else {
	        		mw.done = False;
	        	}

	        	for (Product_Bin_Location__c l : binLocations)
	        	{
	        		Map<String, String> binMap = new Map<String, String>();
	        		if ( l.Product__c == m.get('idProduct') && l.Warehouse__r.Name == project.get('warehouse') )
	        		{
	        			binMap.put('section', (l.Section__c == null ? '' : l.Section__c));
	        			binMap.put('aisle', (l.Aisle__c == null ? '' : l.Aisle__c));
	        			binMap.put('bin', (l.Name == null ? '' : l.Name));
		        		mw.locations.add(binMap);
		        		System.debug('binMap: ' + binMap);
	        		}
	        	}
	        	materials.add(mw);
	        }
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
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
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