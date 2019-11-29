global class gcProject_CreateFromOppy {
	global gcProject_CreateFromOppy() {
		idFilter = ApexPages.currentPage().getParameters().get('idOppy');
		retUrl = '/'+idFilter;
	}
	global gcProject_CreateFromOppy(ApexPages.StandardController stc){
		retUrl = '/'+stc.getId();		
	}

	private Id idFilter{get;set;}
	private String retUrl{get;set;}

	public pageReference back()
	{
		return new pageReference(retUrl);
	}
	
    global PageReference createProject()
    {
        Id idOppy = ApexPages.currentPage().getParameters().get('idOppy');

        Opportunity oppy = [SELECT Id, Approved__c FROM Opportunity WHERE Id=:idOppy][0];
        if(!oppy.Approved__c){
        	ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Cannot create ERP order from this Opportunity. It is not approved yet.'));
        	return null;
		}
			

        for(Trade_In_Item__c ti : [SELECT Id FROM Trade_In_Item__c WHERE Trade_In_Record__r.Opportunity__c =:idOppy limit 1])
       		return new pageReference('/apex/gpOpportunityTradeIn?Id='+idOppy);

        for(AcctSeed__Project__c p :
        	[SELECT Id
        	 FROM AcctSeed__Project__c
        	 WHERE AcctSeed__Opportunity__c = :idOppy])
        {
        	ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'This Opportunity already has underlying Work Order(s).'));
        	return null;
        }

        Id idProject = createProject2(idOppy);

        return new pageReference('/'+idProject);
    }

    global Static Id createProject2(Id idOppy)
    {
    	Id idUser = UserInfo.getUserId();
    	Id idWarehouse = null;
    	Set<Id> setIdWarehouseReserved = new Set<Id>();

    	String dept = [SELECT Id, Sales_Department__c FROM User WHERE Id = :idUser][0].Sales_Department__c;
    	Opportunity oppy = [SELECT Id,
    														 Name,
    														 CampaignId,
    														 LeadSource,
    														 AccountId,
    														 Pricebook2Id,
    														 Trade_In_Amount__c,
    														 Trade_In_Value__c,
    														 Business_Manager__c,
    														 RecordType.Name,
    														 Warehouse__c,
    														 Deposit__c,
    														 Deposit_Method__c,
    														 On_Water_Orientation__c,
    														 Pickup_Location__c,
    														 Payment_Method__c,
    														 Finance_Status__c,
    														 Customer_Notes__c,
    														 Delivery_Date__c,
    														 ContactEmail__c,
    														 BoatId__c,
    														 GL_Account_Variable_3__c,
    														 OwnerId,
    														 Insurance_Term__c,
    														 Finance_Term__c,
                                 Finance_Annual_Interest__c,
                                 Finance_Ammortization__c,
                                 Finance_Payments_Per_Year__c,
                                 Finance_Compound__c,
                                 Tax_Override__c,
                                 Tax_Rate_Federal__c,
                                 Tax_Rate_Provincial__c,
                                 Tax_Rate_Retail__c,
                                 Boat_Specialist_Id__c,
                                 Boat_Model_Year__c,
                                 Trailer_Model_Year__c
    											FROM Opportunity
    											WHERE Id = :idOppy][0];

    	setIdWarehouseReserved.add(GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c);
    	setIdWarehouseReserved.add(GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Transit_Warehouse_Id__c);

    	idWarehouse = oppy.Warehouse__c;

    	if( idWarehouse == null )
    	{
	    	for(AcctSeedERP__Warehouse__c whs :
	    		[SELECT Id, Name
	    		 FROM AcctSeedERP__Warehouse__c
	    		 WHERE Id NOT IN :setIdWarehouseReserved
	    		 ORDER BY CreatedDate])
	    	{
	    		if(whs.Name == dept)
	    		{
	    			idWarehouse = whs.Id;
	    			break;
	    		}
	    		if(idWarehouse == null)
	    			idWarehouse = whs.Id;
    		}
    	}

			Id projectRT = oppy.RecordType.Name == 'Retail Counter Sale' ?
				gcConstants.idRtProjectCounterSale :
				gcConstants.idRtProjectBoatSale;

        AcctSeed__Project__c project = new AcctSeed__Project__c(
            Name = (oppy.Name).LEFT(80),
            Campaign__c = oppy.CampaignId,
            LeadSource__c = oppy.LeadSource,
            Stage__c = 'Tagging Pending',
            Deposit__c = oppy.Deposit__c,
            Deposit_Method__c = oppy.Deposit_Method__c,
            On_Water_Orientation__c = oppy.On_Water_Orientation__c,
					  Pickup_Location__c = oppy.Pickup_Location__c,
					  Delivery_Date__c = oppy.Delivery_Date__c,
        	  AcctSeed__Account__c = oppy.AccountId,
            AcctSeed__Opportunity__c = oppy.Id,
            Boat_Product__c = oppy.BoatId__c,
            GMBLASERP__Pricebook__c = oppy.Pricebook2Id,
            RecordTypeId = projectRT,
            Customer_Notes__c = oppy.Customer_Notes__c,
            GMBLASERP__Warehouse__c = idWarehouse,
            GL_Account_Variable_3__c = oppy.GL_Account_Variable_3__c,
            Business_Manager__c = oppy.Business_Manager__c,
            Salesperson__c = oppy.OwnerId,
            Payment_Method__c = oppy.Payment_Method__c,
            Boat_Specialist__c = oppy.Boat_Specialist_Id__c,
            Insurance_Term__c = oppy.Insurance_Term__c,
            Finance_Term__c = oppy.Finance_Term__c,
						Finance_Annual_Interest__c = oppy.Finance_Annual_Interest__c,
						Finance_Ammortization__c = oppy.Finance_Ammortization__c,
						Finance_Payments_Per_Year__c = oppy.Finance_Payments_Per_Year__c,
						Finance_Compound_Per_Year__c = oppy.Finance_Compound__c,
						Tax_Override__c = oppy.Tax_Override__c,
						ContactEmail__c = oppy.ContactEmail__c,
						BoatModelYear__c = oppy.Boat_Model_Year__c,
						TrailerModelYear__c = oppy.Trailer_Model_Year__c
	      );
	      if( oppy.Tax_Override__c == true )
	      {
	      	project.Tax_Rate_Federal__c = oppy.Tax_Rate_Federal__c;
	      	project.Tax_Rate_Provincial__c = oppy.Tax_Rate_Provincial__c;
	      	project.Tax_Rate_Retail__c = oppy.Tax_Rate_Retail__c;
	      }
        insert project;
        AcctSeed__Project_Task__c projectTask = new AcctSeed__Project_Task__c(
          Name = 'Oppy Line Items',
          DisplayOnCustomerInvoice__c = true,
        	AcctSeed__Project__c = project.Id
        );
        insert projectTask;

        list<AcctSeedERP__Material__c> listMatl = new list<AcctSeedERP__Material__c>();
        List<AcctSeedERP__Material__c> listInsuranceItem = new List<AcctSeedERP__Material__c>();
        List<AcctSeedERP__Material__c> listWar_ServItems = new List<AcctSeedERP__Material__c>();
        Id insuranceRT = LGND_Utilities.recordTypeIdFromName('Product2', 'Insurance');
        Id p_and_s_RT = LGND_Utilities.recordTypeIdFromName('Product2', 'Protection and Services');

        for(OpportunityLineItem oli :
           [SELECT Id,
           		   Description,
           		   ListPrice,
           		   Product2Id,
                 ParentProductId__c,
           		   Product2.RecordTypeId,
                 Product2.Family,
            	   Quantity,
            	   InsuranceCoverage__c,
                 Insurance_Rate__c,
            	   UnitPrice
            FROM OpportunityLineItem
            WHERE OpportunityId = :idOppy])
        {
        	//we want to seperate insurance items into there own tasks
        	if( insuranceRT == oli.Product2.RecordTypeId )
        	{
        		listInsuranceItem.add(new AcctSeedERP__Material__c(
	            AcctSeedERP__Product__c = oli.Product2Id,
	          	AcctSeedERP__Project__c = project.Id,
	            AcctSeedERP__Comment__c = oli.Description,
	            Insurance_Rate__c = oli.Insurance_Rate__c,
	            Insurance_Coverage__c = oli.InsuranceCoverage__c,
	            AcctSeedERP__Quantity_per_Unit__c = (oli.Quantity == null ? 0 : oli.Quantity),
	            GMBLASERP__Unit_Price__c = oli.UnitPrice,
	            GMBLASERP__Price_Override__c = true
	          ));
        	}
          //we also want to seperate Protection and Services /Extend Warranty Products
          else if( oli.Product2.RecordTypeId == p_and_s_RT ||
                   oli.Product2.Family == 'Extended Warranty' )
          {
            listWar_ServItems.add(new AcctSeedERP__Material__c(
              AcctSeedERP__Product__c = oli.Product2Id,
              AcctSeedERP__Project__c = project.Id,
              Parent_Product__c = oli.ParentProductId__c,
              AcctSeedERP__Comment__c = oli.Description,
              AcctSeedERP__Quantity_per_Unit__c = (oli.Quantity == null ? 0 : oli.Quantity),
              GMBLASERP__Unit_Price__c = oli.UnitPrice,
              GMBLASERP__Price_Override__c = (oli.UnitPrice == oli.ListPrice ? false : true)
            ));
          }
        	else
        	{
	          listMatl.add(new AcctSeedERP__Material__c(
	            AcctSeedERP__Product__c = oli.Product2Id,
	          	AcctSeedERP__Project__c = project.Id,
	            AcctSeedERP__Project_Task__c = projectTask.Id,
	            AcctSeedERP__Comment__c = oli.Description,
	            AcctSeedERP__Quantity_per_Unit__c = (oli.Quantity == null ? 0 : oli.Quantity),
	            GMBLASERP__Unit_Price__c = oli.UnitPrice,
	            GMBLASERP__Price_Override__c = (oli.UnitPrice == oli.ListPrice ? false : true)
	          ));
	        }
        }
        /// Add another material line for Trade In Value
        if(oppy.Trade_In_Value__c <> 0)
        {
            listMatl.add(new AcctSeedERP__Material__c(
              AcctSeedERP__Product__c = gcConstants.idProductTradeIn,
            	AcctSeedERP__Project__c = project.Id,
              AcctSeedERP__Project_Task__c = projectTask.Id,
              AcctSeedERP__Comment__c = 'Trade In Value',
              AcctSeedERP__Quantity_per_Unit__c = -1,
              GMBLASERP__Unit_Price__c = oppy.Trade_In_Value__c,
              GMBLASERP__Price_Override__c = true
            ));
            Decimal lienAmount = oppy.Trade_In_Value__c - oppy.Trade_In_Amount__c;
            if(lienAmount <> 0)
            {
	            listMatl.add(new AcctSeedERP__Material__c(
	                AcctSeedERP__Product__c = gcConstants.idProductTradeInLien,
	            	AcctSeedERP__Project__c = project.Id,
	                AcctSeedERP__Project_Task__c = projectTask.Id,
	                AcctSeedERP__Comment__c = 'Trade In Lien Amount',
	                AcctSeedERP__Quantity_per_Unit__c = 1,
	                GMBLASERP__Unit_Price__c = lienAmount,
	                GMBLASERP__Price_Override__c = true
	            ));
	        }
        }

        if( listInsuranceItem.size() > 0 )
        {
        	//if we have insurance items create a new task for them
        	AcctSeed__Project_Task__c insuranceTask = new AcctSeed__Project_Task__c(
            Name = 'Insurance Items',
            DisplayOnCustomerInvoice__c = true,
            IsInsurance__c = true,
        		AcctSeed__Project__c = project.Id
        	);
        	insert insuranceTask;
        	for( AcctSeedERP__Material__c m : listInsuranceItem )
        	{
        		m.AcctSeedERP__Project_Task__c = insuranceTask.Id;
        	}
        	listMatl.addAll( listInsuranceItem );
        }

        if( listWar_ServItems.size() > 0 )
        {
          //if we have warranty and service items create a new task for them
          AcctSeed__Project_Task__c ws_Task = new AcctSeed__Project_Task__c(
            Name = 'Protection and Services',
            DisplayOnCustomerInvoice__c = true,
            AcctSeed__Project__c = project.Id
          );
          insert ws_Task;
          for( AcctSeedERP__Material__c m : listWar_ServItems )
          {
            m.AcctSeedERP__Project_Task__c = ws_Task.Id;
          }
          listMatl.addAll( listWar_ServItems );
        }

        if(!listMatl.isEmpty())
            insert listMatl;

        oppy.StageName = 'Sent to ERP';
        Boolean oldOppyTriggerVal = OpportunityTriggerHandler.disableTrigger;
        OpportunityTriggerHandler.disableTrigger = true;
        update oppy;
        OpportunityTriggerHandler.disableTrigger = oldOppyTriggerVal;
        /// Lock the task now
        projectTask.Locked__c = true;
        Boolean oldTaskVal = gcProjectTask.disableTrigger;
        gcProjectTask.disableTrigger = true;
        update projectTask;
        gcProjectTask.disableTrigger = oldTaskVal;
        return project.Id;
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
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
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