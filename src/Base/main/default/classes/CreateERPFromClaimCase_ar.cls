public without sharing class CreateERPFromClaimCase_ar {

	@future
	public static void createProjectFromCaseFuture(Set<Id> setIdCase){
		/// We are getting an error from Rigger Schedule which is also a future method. So we cannot call it from another future
		createProjectFromCase(setIdCase);
	}

	public static void createProjectFromCase(Set<Id> setIdCase)
    {
    	List<Case_Part__c> listCP = new List<Case_Part__c>();
    	for(Case_Part__c cp : 
    			[SELECT Id,
    			   			Case__c,
                   Material__c, 
                   Name, 
                   Product__c,
                   Product__r.Name, 
                   Product_Code__c,
                   Unit_Price__c,
                   Order_Quantity__c, 
                   Quantity__c
              FROM Case_Part__c
             WHERE Case__c IN:setIdCase
              AND Product__r.Family != 'Labour'])
    	{
    		if(cp.Order_Quantity__c != null && cp.Order_Quantity__c <> 0)
    			listCP.add(cp);
    	}
    	if(listCP.isEmpty()) return;
    	List<Case> listCaseToUpdate = new List<Case>();
    	Map<Id,Case> mapIdCase = new Map<Id,Case>();
    	Map<Id,AcctSeed__Project__c> mapIdERP = new Map<Id,AcctSeed__Project__c>();
    	Map<Id,AcctSeed__Project_Task__c> mapIdERPTask = new Map<Id,AcctSeed__Project_Task__c>();
    	for(Case ca : [SELECT Id, AccountId, Account.Name, OwnerId, CaseNumber, Partner_Reference__c FROM Case WHERE Id IN:setIdCase])
			{
    		mapIdCase.put(ca.Id, ca);
	    	AcctSeed__Project__c partsOrderERP = new AcctSeed__Project__c (
					Name = ca.Account.Name + ' (W)',
					RecordTypeId = gcConstants.idRtPartnerPartsOrder,
					AcctSeed__Account__c = ca.AccountId,
					Salesperson__c = ca.OwnerId,
					OwnerId = ca.OwnerId,
					Warranty_Case__c = ca.Id,
					Customer_Notes__c = 'Warranty Case # ' + ca.CaseNumber,
					Partner_External_PO_Number__c = ca.Partner_Reference__c
		    );
		    mapIdERP.put(ca.Id, partsOrderERP);
    	}

	    insert mapIdERP.values();

	    for(Id idCase : mapIdERP.keySet()){
	    	Id idProject = mapIdERP.get(idCase).Id;
		    AcctSeed__Project_Task__c pt = new AcctSeed__Project_Task__c(
		        AcctSeed__Project__c = idProject,
		        DisplayOnCustomerInvoice__c = true,
		        Name = 'Parts Order Task'
		    );
		    mapIdERPTask.put(idCase, pt);
		    System.debug(loggingLevel.error,'idProject:'+idProject);
		    System.debug(loggingLevel.error,'mapIdERPTask:'+mapIdERPTask);
		   	listCaseToUpdate.add(new Case(Id = idCase, Parts_Order_ERP__c = idProject));
	    }
	    insert mapIdERPTask.values();

	    AcctSeedERP__Material__c[] materials = new List<AcctSeedERP__Material__c>();
	    for(Case_Part__c cp : listCP)
	    {
	    	Id idProject = mapIdERP.get(cp.Case__c).Id;
	    	Id idProjectTask = mapIdERPTask.get(cp.Case__c).Id;
			materials.add( new AcctSeedERP__Material__c(
				AcctSeedERP__Product__c = cp.Product__c,
				AcctSeedERP__Quantity_Per_Unit__c = cp.Order_Quantity__c,
				AcctSeedERP__Project__c = idProject,
				AcctSeedERP__Project_Task__c = idProjectTask
			));
	    }
	    if(!materials.isEmpty())
	    	insert materials;

	    if(!listCaseToUpdate.isEmpty())
			{
	    	TriggerBase.bypass('Case');
	    	update listCaseToUpdate;
				TriggerBase.clearBypass('Case');
	    }
    }
}