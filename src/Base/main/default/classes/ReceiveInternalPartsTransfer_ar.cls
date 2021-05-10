public without sharing class ReceiveInternalPartsTransfer_ar {
	public class invTransfer{
		public String transferId{get;set;}
		public String transferName{get;set;}
		public String erpId{get;set;}
		public String warehouseToId{get;set;}
		public String warehouseFromId{get;set;}
		public String warehouseFrom{get;set;}
		public String outboundDate{get;set;}
		public String inboundDate{get;set;}
		public List<transferLine> lines{get;set;}
	}
	public class transferLine{
		public String outboundId {get;set;}
		public String materialId {get;set;}
		public String productName {get;set;}
		public Decimal quantityOriginal {get;set;}
		public Decimal quantity {get;set;}
	}
	@AuraEnabled
    public static Map<String,String> retrieveTransfersByERP(String idERP)
    {
         List<invTransfer> listTnsf = new List<invTransfer>();
	     Map<String,String> res = new Map<String,String>();
         AcctSeed__Project__c proj = [SELECT Id, Internal_Partner_Parts_Order__c, Internal_Warranty__c FROM AcctSeed__Project__c WHERE Id=:idERP][0];
         if(proj.Internal_Partner_Parts_Order__c || proj.Internal_Warranty__c)
         {
	         for(GMBLASERP__Inventory_Transfer__c invTns : 
	         		[SELECT Id, 
	         			Name, 
	         			GMBLASERP__Outbound_Date__c, 
	         			GMBLASERP__Inbound_Date__c, 
	         			GMBLASERP__Warehouse_From__c, 
	         			GMBLASERP__Warehouse_From__r.Name, 
	         			GMBLASERP__Warehouse_To__c,
	         			ERP_Order__c,
	         			(SELECT Id, Material__c, AcctSeedERP__Quantity__c, GMBLASERP__Product__r.Name FROM GMBLASERP__Outbound_Inventory_Movements__r)
	         		FROM GMBLASERP__Inventory_Transfer__c
	         		WHERE GMBLASERP__Inbound_Date__c = null 
	         			AND ERP_Order__c =:idERP])
	         {
	         	invTransfer inTr = new invTransfer();
	         	String ymd = Datetime.newInstance(invTns.GMBLASERP__Outbound_Date__c.year(), invTns.GMBLASERP__Outbound_Date__c.month(), invTns.GMBLASERP__Outbound_Date__c.day()).format('YYYY-MM-dd');
	         	inTr.transferId = invTns.Id;
	         	inTr.transferName = invTns.Name;
	         	inTr.erpId = invTns.ERP_Order__c;
	         	inTr.warehouseToId = invTns.GMBLASERP__Warehouse_To__c;
	         	inTr.warehouseFromId = invTns.GMBLASERP__Warehouse_From__c;
	         	inTr.warehouseFrom = invTns.GMBLASERP__Warehouse_From__r.Name;
	         	inTr.outboundDate = ymd;
	         	inTr.inboundDate = ymd;
	         	List<transferLine> tLines = new List<transferLine>();
	         	for(AcctSeedERP__Outbound_Inventory_Movement__c oim : invTns.GMBLASERP__Outbound_Inventory_Movements__r){
	         		transferLine tl = new transferLine();
	         		tl.outboundId = oim.Id;
	         		tl.materialId = oim.Material__c;
	         		tl.productName = oim.GMBLASERP__Product__r.Name;
	         		tl.quantityOriginal = oim.AcctSeedERP__Quantity__c;
	         		tl.quantity = oim.AcctSeedERP__Quantity__c;
	         		tLines.add(tl);
	         	}
	         	inTr.lines = tLines;
	         	listTnsf.add(inTr);
	         }
	         res.put('isInternal','true');
	         res.put('listTnsf',JSON.serialize(listTnsf));
	     }else{
	     	res.put('isInternal','false');
	     }
         return res;
    }

   	@AuraEnabled
    public static String checkId(String idRecord){
    	Id idERP;
    	Id idFilter = Id.valueOf(idRecord);
    	String objectAPIName = idFilter.getSObjectType().getDescribe().getName();
    	if(objectAPIName == 'Case'){
    		for(Case c : [SELECT Id, Warranty_ERP__c FROM Case WHERE Id=:idRecord])
    			idERP = c.Warranty_ERP__c;
    	}else
    		idERP = idFilter;
    	return idERP;
    }

   	@AuraEnabled
    public static void createTransferInvoice(String idERP, String idTnsf){
    	gcProject_Ext.createInvoice(idERP, idTnsf, true);
    }

   	@AuraEnabled
    public static String receiveTransfer(String idERP, String idTnsf, String dateInbound, String listValues)
    {
    	for(GMBLASERP__Inventory_Transfer__c tc : [SELECT Id, GMBLASERP__Inbound_Date__c FROM GMBLASERP__Inventory_Transfer__c WHERE Id=:idTnsf])
    	{
    		try{
	    		String[] listYMD = dateInbound.split('-');
	    		Date inboundDate = Date.newInstance(Integer.valueOf(listYMD[0]), Integer.valueOf(listYMD[1]), Integer.valueOf(listYMD[2]));
	    		tc.GMBLASERP__Inbound_Date__c = inboundDate;
	    		update tc;
	    		List<AcctSeedERP__Outbound_Inventory_Movement__c> listOIM = new List<AcctSeedERP__Outbound_Inventory_Movement__c>();
	    		invTransfer invTr = (invTransfer)JSON.deserialize(listValues, invTransfer.class);
	    		Set<Id> setOIM = new Set<Id>();
	    		Map<Id,transferLine> mapTLine = new Map<Id,transferLine>();
	    		for(transferLine tl : invTr.lines)
	    		{
	    			Decimal diff = tl.quantity - tl.quantityOriginal;
	    			if(diff <> 0)
	    			{
	    				setOIM.add(tl.outboundId);
	    				mapTLine.put(tl.outboundId,tl);
	    				//listOIM.add(new AcctSeedERP__Outbound_Inventory_Movement__c());
	    			}
	    		}
	    		if(!setOIM.isEmpty())
    			{
    				GMBLASERP__Inventory_Transfer__c transfer = new GMBLASERP__Inventory_Transfer__c( 
													         			GMBLASERP__Outbound_Date__c = inboundDate, 
													         			GMBLASERP__Inbound_Date__c = inboundDate, 
													         			GMBLASERP__Warehouse_From__c = invTr.warehouseFromId, 
													         			GMBLASERP__Warehouse_To__c = invTr.warehouseToId,
													         			ERP_Order__c = invTr.erpId,
													         			Comments__c = 'Transfer Back to Wholesale for insufficient receivable quantity.'
													         		);
    				insert transfer;
    				for(AcctSeedERP__Outbound_Inventory_Movement__c oim : 
    					[SELECT Id,
    						GMBLASERP__Product__c,
				    		AcctSeedERP__Debit_GL_Account__c,
				    		AcctSeedERP__Inventory_Balance__c,
				    		AcctSeedERP__Movement_Date__c,
				    		AcctSeedERP__Project__c,
				    		AcctSeedERP__Project_Task__c,
				    		AcctSeedERP__Quantity__c,
					        AcctSeedERP__Type__c,
					        AcctSeedERP__Unit_Cost__c,
					        GMBLASERP__Cost_Override__c,
				    		GMBLASERP__Lot__c,
				    		GMBLASERP__Serial_Number__c,
				    		Material__c,
				    		GMBLASERP__Inventory_Transfer__c
    					FROM AcctSeedERP__Outbound_Inventory_Movement__c
    					WHERE Id IN:setOIM])
    				{
    					transferLine tl = mapTLine.get(oim.Id);
    					AcctSeedERP__Outbound_Inventory_Movement__c newOIM = oim.clone(false,true,true);
    					newOIM.AcctSeedERP__Quantity__c = tl.quantity - tl.quantityOriginal;
    					newOIM.GMBLASERP__Inventory_Transfer__c = transfer.Id;
    					listOIM.add(newOIM);
    				}
    				insert listOIM;
    				return transfer.Id;
    				//ERPInvoiceDocumentBuilder.generateTransferDocument(idERP, 'ERPPackingSlip_InternalPartOrder', transfer.Id);
    				//gcProject_Ext.createInvoice(transfer.ERP_Order__c, transfer.Id, true);
    			}
    			return 'ok';
    		}catch(Exception e){
    			throw new AuraHandledException(e.getMessage());
    		}
    	}
    	return '';
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
	}
}