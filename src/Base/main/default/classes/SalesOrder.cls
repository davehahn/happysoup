public without sharing class SalesOrder {
    
    public static Boolean disableTrigger{
		get{
			if(disableTrigger == null) return false;
			else return disableTrigger;
		}
		set{
			if(value == null) disableTrigger = false;
			else disableTrigger = value;
		}
	}
    
    public static void triggerHandler
		(map<Id,AcctSeedERP__Sales_Order__c> oldMap,
		 map<Id,AcctSeedERP__Sales_Order__c> newMap,
		 list<AcctSeedERP__Sales_Order__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(oldMap == NULL) oldMap = new map<Id,AcctSeedERP__Sales_Order__c>();
		if(newMap == NULL) newMap = new map<Id,AcctSeedERP__Sales_Order__c>();
		if(listNew == NULL) listNew = new list<AcctSeedERP__Sales_Order__c>();

		//updateAndValidate(oldMap,newMap,listNew,boolIsBefore,boolIsInsert,boolIsUpdate,boolIsDelete);

		if(boolIsBefore)
		{
			if(boolIsInsert)
			{
				//setDueDate( listNew );
			}
			if(boolIsUpdate)
			{
			}
			if(boolIsDelete)
			{
			}
		}
		else //i.e. trigger.isAfter
		{
			if(boolIsInsert)
			{
			//	handlePrePayables( listNew, oldMap );
			   // generateCashReceipt(listNew);
			}
			if(boolIsUpdate)
			{	List<AcctSeedERP__Sales_Order__c>lstSalesOrder = new List<AcctSeedERP__Sales_Order__c>();
                for(AcctSeedERP__Sales_Order__c so : listNew)
                {
                    AcctSeedERP__Sales_Order__c oldRec;
					oldRec = oldMap.get(so.Id);
                    if(so.Stage__c != oldRec.Stage__c && so.Stage__c == 'SHIPPED'){
                       lstSalesOrder.add(so); 
                    } 
                    
                }
             if(!lstSalesOrder.isEmpty()){
                 Billing(lstSalesOrder);
                 salesInventoryMovement(lstSalesOrder);
             }
				//handlePrePayables( listNew, oldMap );
			}
			if(boolIsDelete)
			{

			}
		}
	}
    
   public static List<AcctSeed__Billing__c> Billing(List<AcctSeedERP__Sales_Order__c>lstSalesOrder){
        List<AcctSeed__Billing__c> lstBilingToBeSaved = new List<AcctSeed__Billing__c>();
        List<AcctSeed__Billing_Line__c> lstBilingLineToBeSaved = new List<AcctSeed__Billing_Line__c>();
        List<BillingWrapper> lstBillingWrapper = new List<BillingWrapper>();
        List<AcctSeedERP__Sales_Order_Line__c> SalesOrderLineList = new List<AcctSeedERP__Sales_Order_Line__c>();
        BillingWrapper billingWrapper = new BillingWrapper();
        Map<id,List<AcctSeedERP__Sales_Order_Line__c>> SalesOrderToSOLineMap = getSalesOrder(lstSalesOrder);
        for(AcctSeedERP__Sales_Order__c so :lstSalesOrder){
            //AcctSeed__Billing__c billing = new AcctSeed__Billing__c();
           // billingWrapper.billing.AcctSeed__Billing_City__c =so.AcctSeedERP__Billing_City__c !=null?so.AcctSeedERP__Billing_City__c:null;
            //billingWrapper.billing.AcctSeed__Billing_Country__c = so.AcctSeedERP__Billing_Country__c!=null?so.AcctSeedERP__Billing_Country__c:null;
            billingWrapper.billing.AcctSeed__Customer__c = so.AcctSeedERP__Customer__c!=null ?so.AcctSeedERP__Customer__c:null;
            billingWrapper.billing.Lgnd_Due_Date__c = Date.today().addMonths(1);
         	//billing.GL_Account_Variable_3__c = ;
         	billingWrapper.billing.AcctSeed__Date__c = Date.today();
            billingWrapper.billing.AcctSeed__Billing_Format__c = 'a0e7h0000023LwkAAE';
            billingWrapper.billing.Tax_Override__c = true;
            billingWrapper.billing.AcctSeedERP__Sales_Order__c = so.Id;
            billingWrapper.billing.AcctSeed__Ledger__c = so.AcctSeedERP__Ledger__c; 
           // List<AcctSeedERP__Sales_Order_Line__c> listSalesOrderLine = so.AcctSeedERP__Sales_Order_Line__r;
            System.debug('@@ SalesOrderLineList= '+SalesOrderToSOLineMap.get(so.Id));
            for(AcctSeedERP__Sales_Order_Line__c sol :SalesOrderToSOLineMap.get(so.Id)){
            	AcctSeed__Billing_Line__c billingLine = new AcctSeed__Billing_Line__c();
                billingLine.AcctSeed__Comment__c=sol.AcctSeedERP__Comment__c;
                billingLine.AcctSeed__Date__c = Date.today();
                billingLine.AcctSeed__GL_Account_Variable_2__c=sol.AcctSeedERP__GL_Account_Variable_2__c;
                billingLine.AcctSeed__GL_Account_Variable_1__c=sol.AcctSeedERP__GL_Account_Variable_1__c;
                billingLine.AcctSeed__Product__c=sol.AcctSeedERP__Product__c;
                billingLine.AcctSeed__Product_Unit_Cost__c=sol.AcctSeedERP__Unit_Price__c;
                billingLine.AcctSeed__Hours_Units__c=sol.AcctSeedERP__Quantity_Ordered__c;
                billingLine.AcctSeedERP__Sales_Order_Line__c =sol.Id;
                billingLine.AcctSeed__GL_Account_Variable_3__c=sol.AcctSeedERP__GL_Account_Variable_3__c;
                billingLine.AcctSeed__Rate__c=sol.AcctSeedERP__Unit_Price__c;
                billingWrapper.lstBillingLine.add(billingLine);
               // billingLine.AcctSeed__Rate__c = ;
            }
           // lstBillingWrapper.add(new BillingWrapper(billing,lstBilingLineToBeSaved));
            lstBillingWrapper.add(billingWrapper);
        }
        

        
        System.debug('@@ lstBillingWrapper= '+lstBillingWrapper);
        for(BillingWrapper wrapper :lstBillingWrapper){
            lstBilingToBeSaved.add(wrapper.billing);
        }
        if(!lstBilingToBeSaved.isEmpty()){
            System.debug('@@# lstBilingToBeSaved= '+lstBilingToBeSaved);
            insert lstBilingToBeSaved;
            System.debug('@@# after insert');
        }
        
        for(BillingWrapper wrapper :lstBillingWrapper){
            for(AcctSeed__Billing_Line__c billingLine :wrapper.lstBillingLine){
            	billingLine.AcctSeed__Billing__c =  wrapper.billing.Id;	    
                lstBilingLineToBeSaved.add(billingLine);
            }  
        }
       System.debug('lstBilingLineToBeSaved= '+lstBilingLineToBeSaved);
        if(!lstBilingLineToBeSaved.isEmpty()){
            insert lstBilingLineToBeSaved; 
        }
        return lstBilingToBeSaved;
    } 
   public static void generateCashReceipt(List<AcctSeedERP__Sales_Order__c>lstSalesOrder){
        List<AcctSeed__Cash_Receipt__c> lstCashReceipt = new List<AcctSeed__Cash_Receipt__c>();
        Id idGlCashFloat = gcConstants.idGlCashFloat;
		Id idGlRBCCDN = gcConstants.idGlRBCCDN;
		Id idGlBank;
        //Currently payment method cash
        idGlBank = idGlCashFloat;
        Map<Id,AcctSeed__Cash_Receipt__c> mapBillReceipt = new Map<Id,AcctSeed__Cash_Receipt__c>();
        for(AcctSeedERP__Sales_Order__c so :lstSalesOrder){
            AcctSeed__Cash_Receipt__c newCR = new AcctSeed__Cash_Receipt__c(
                Sales_Order__c = so.id,
				AcctSeed__Account__c = so.AcctSeedERP__Customer__c!=null ?so.AcctSeedERP__Customer__c:null,
				//TODO : only total amount is assigning to cash receipt, no tax or no deduction is present
                AcctSeed__Amount__c = so.AcctSeedERP__Total__c,
				AcctSeed__Bank_Account__c = idGlBank,
				AcctSeed__Payment_Reference__c = so.Name + '_' + System.now().format(),
				Payment_Method__c = 'Cash',
				AcctSeed__Purpose__c = 'Customer Receipt'
                //AcctSeed__Receipt_Date__c = System.today()
			); 
            lstCashReceipt.add(newCR);
            
         }
         if(!lstCashReceipt.isEmpty()){
             insert lstCashReceipt;
         }
      
    }
   public static void salesInventoryMovement(List<AcctSeedERP__Sales_Order__c>lstSalesOrder){
       System.debug('in salesInventoryMovement');
       map<Id,map<Id,map<Id,Id>>> mapPWLB = new map<Id,map<Id,map<Id,Id>>>();
       Map<Id,Id> WarehouseToLocationMap = new Map<Id,Id>(); 
       Id idLocation;
        String pIdWarehouse ; 
        Set<Id> warehouseSet = new Set<Id>();
       for(AcctSeedERP__Sales_Order__c so :lstSalesOrder){
           warehouseSet.add(so.Warehouse__c);
       }
       
       
       for(AcctSeedERP__Location__c loc : [SELECT Id,AcctSeedERP__Warehouse__c FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c in :warehouseSet ORDER BY CreatedDate LIMIT 1]){
           WarehouseToLocationMap.put(loc.AcctSeedERP__Warehouse__c,loc.Id);
       }
        Map<id,List<AcctSeedERP__Sales_Order_Line__c>> SalesOrderToSOLineMap = getSalesOrder(lstSalesOrder);
		//	idLocation = loc.Id;
        for(AcctSeedERP__Sales_Order__c so :lstSalesOrder){
            List<AcctSeedERP__Sales_Order_Line__c> listSalesOrderLine = SalesOrderToSOLineMap.get(so.Id);
            for(AcctSeedERP__Sales_Order_Line__c sol :listSalesOrderLine){
               pIdWarehouse = String.valueOf(so.Warehouse__c);
               idLocation = WarehouseToLocationMap.get(so.Warehouse__c);
              // System.debug('@@ so.Warehouse__r.id = '+so.Warehouse__r.id);
              // System.debug('@@ so.Warehouse__c = '+so.Warehouse__c);
                
                if(!mapPWLB.containsKey(sol.AcctSeedERP__Product__c) && sol.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c){
            		mapPWLB.put(sol.AcctSeedERP__Product__c, new map<Id,map<Id,Id>>{pIdWarehouse => new map<Id,Id>{idLocation => null}});
			}
			
            }
        }
        System.debug('mapPWLB= '+mapPWLB);
        GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);
        List<AcctSeedERP__Sales_Order_Inventory_Movement__c> lstSOMovement = new List<AcctSeedERP__Sales_Order_Inventory_Movement__c>();
        for(AcctSeedERP__Sales_Order__c so :lstSalesOrder){
            List<AcctSeedERP__Sales_Order_Line__c> listSalesOrderLine = SalesOrderToSOLineMap.get(so.Id);
            for(AcctSeedERP__Sales_Order_Line__c sol :listSalesOrderLine){
                pIdWarehouse = String.valueOf(so.Warehouse__c);
                idLocation = WarehouseToLocationMap.get(so.Warehouse__c);
                if(sol.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c){
                    Id idBalance = mapPWLB.get(sol.AcctSeedERP__Product__c).get(pIdWarehouse).get(idLocation);
                    System.debug('idBalance= '+idBalance);
                    System.debug('sol.AcctSeedERP__Product__c= '+sol.AcctSeedERP__Product__c);
                    AcctSeedERP__Sales_Order_Inventory_Movement__c soMovement = new AcctSeedERP__Sales_Order_Inventory_Movement__c();
                    soMovement.GMBLASERP__Product__c = sol.AcctSeedERP__Product__c;
                    soMovement.AcctSeedERP__Inventory_Balance__c = idBalance;
                    soMovement.AcctSeedERP__Movement_Date__c = System.today();
                    soMovement.AcctSeedERP__Quantity__c = sol.AcctSeedERP__Quantity_Ordered__c; //sales order line
                    soMovement.AcctSeedERP__GL_Account_Variable_1__c = sol.AcctSeedERP__GL_Account_Variable_1__c;
                    soMovement.AcctSeedERP__GL_Account_Variable_2__c = sol.AcctSeedERP__GL_Account_Variable_2__c;
                    soMovement.AcctSeedERP__GL_Account_Variable_3__c = sol.AcctSeedERP__GL_Account_Variable_3__c;
                    soMovement.AcctSeedERP__Sales_Order_Line__c = sol.Id;
                    lstSOMovement.add(soMovement);
                 }
            }
        
        }
        if(!lstSOMovement.isEmpty())
        	insert lstSOMovement;
       
    }
   
    public static void updateAndValidate
		(map<Id,AcctSeedERP__Sales_Order__c> oldMap,
		 map<Id,AcctSeedERP__Sales_Order__c> newMap,
		 list<AcctSeedERP__Sales_Order__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(boolIsBefore && (boolIsUpdate || boolIsInsert))
		{
			refreshStatics(listNew);

			for(AcctSeedERP__Sales_Order__c b : listNew)
			{
				AcctSeedERP__Sales_Order__c oldRec;
				if(boolIsUpdate)
					oldRec = oldMap.get(b.Id);

				/*if(boolIsInsert && b.Internal_Billing__c && !allowBillingProjectForInternal)
					b.addError('An Internal Billing can only be created from an Internal ERP Order');
				if(boolIsUpdate
					&& b.GMBLASERP__Project__c != oldRec.GMBLASERP__Project__c
					&& !allowBillingProjectForInternal
					&& (b.Internal_Billing__c || oldRec.Internal_Billing__c))
					b.addError('The ERP Order of an Internal Billing Cannot be changed');
*/
				if(b.AcctSeedERP__Status__c == 'Posted')
				{
					if(boolIsUpdate)
					{
						if(b.GL_Account_Variable_3__c != oldRec.GL_Account_Variable_3__c ||
						   b.Tax_is_Harmonized__c != oldRec.Tax_is_Harmonized__c ||
						   b.Tax_Override__c != oldRec.Tax_Override__c ||
						   b.Tax_Rate_Federal__c != oldRec.Tax_Rate_Federal__c ||
						   b.Tax_Rate_Provincial__c != oldRec.Tax_Rate_Provincial__c ||
						   b.Tax_Rate_Retail__c != oldRec.Tax_Rate_Retail__c)
						{
							b.addError('The Sales Tax settings of a Billing may not be changed, if the billing is Posted.');
						}
					}
				}
				else
				{
					Account acct = mapAccount.get(b.AcctSeedERP__Customer__c);
					if(acct != null && acct.BillingState != null && mapGlv3ByName.containsKey(acct.BillingState)
						&& ((boolIsInsert && b.GL_Account_Variable_3__c == null) || (boolIsUpdate && b.AcctSeedERP__Customer__c != oldRec.AcctSeedERP__Customer__c)))
						b.GL_Account_Variable_3__c = mapGlv3ByName.get(acct.BillingState).Id;

					if(b.GL_Account_Variable_3__c == null)
					{
						//b.GL_Account_Variable_3__c = gcConstants.idGlv3Others; (Set in)
						b.Tax_Override__c = true;
						b.Tax_Rate_Federal__c = 0;
						b.Tax_Rate_Provincial__c = 0;
						b.Tax_Rate_Retail__c = 0;
					}

					if(!b.Tax_Override__c)
					{
						if(boolIsInsert ||
						  (boolIsUpdate &&
						   (b.GL_Account_Variable_3__c != oldRec.GL_Account_Variable_3__c ||
							b.Tax_is_Harmonized__c != oldRec.Tax_is_Harmonized__c ||
							b.Tax_Override__c != oldRec.Tax_Override__c ||
							b.Tax_Rate_Federal__c != oldRec.Tax_Rate_Federal__c ||
							b.Tax_Rate_Provincial__c != oldRec.Tax_Rate_Provincial__c ||
							b.Tax_Rate_Retail__c != oldRec.Tax_Rate_Retail__c)
						   )
						  )
						{
							b.Tax_Rate_Federal__c = 5;

							AcctSeed__Accounting_Variable__c glvTaxZone = mapGlv.get(b.GL_Account_Variable_3__c);
							if(glvTaxZone != null)
							{
								b.Tax_is_Harmonized__c = glvTaxZone.Tax_is_Harmonized__c;
								b.Tax_Rate_Provincial__c = glvTaxZone.Tax_Rate_Provincial__c;
								b.Tax_Rate_Retail__c = glvTaxZone.Tax_Rate_Retail__c;
							}
						}
					}
				}
			}
		}

		if(boolIsBefore && boolIsDelete){
			List<GMBLASERP__Serial_Number__c> listSerials = new List<GMBLASERP__Serial_Number__c>();
			List<ERP_document__c> listERPDocs = new List<ERP_document__c>();
			Set<Id> setIdDocuments = new Set<Id>();
			for(AcctSeed__Billing__c bill :
				[SELECT Id,
					(SELECT Id,
                     	Serial_Number_ERP_Order_Item__c,
                     	Serial_Number_Revenue__c,
                     	Serial_Revenue_Used__c,
                     	Serial_Revenue_Line__c
					FROM AcctSeed__Project_Billing_Lines__r
					WHERE Serial_Revenue_Used__c = true
					ORDER BY CreatedDate),
					(SELECT Id, DocumentID__c FROM ERP_documents__r)
			 	FROM AcctSeed__Billing__c
			 	WHERE Id IN :oldMap.keySet()])
			{
				for(AcctSeed__Billing_Line__c line : bill.AcctSeed__Project_Billing_Lines__r)
					listSerials.add(new GMBLASERP__Serial_Number__c(Id = line.Serial_Number_ERP_Order_Item__c, Billing_Revenue_Used__c = false));

				for(ERP_document__c erpDoc : bill.ERP_documents__r){
					listERPDocs.add(erpDoc);
					setIdDocuments.add(erpDoc.DocumentID__c);
				}
			}
			if(!setIdDocuments.isEmpty()){
				/// Deleting related billing documents
				delete [SELECT Id FROM Document WHERE Id IN:setIdDocuments];
				/// Deleting related ERP documents
				delete listERPDocs;
			}

			if(!listSerials.isEmpty()){
				Boolean oldVal = gcSerialNumber.disableTrigger;
				gcSerialNumber.disableTrigger = true;
				update listSerials;
				gcSerialNumber.disableTrigger = oldVal;
			}
		}

		if(!boolIsBefore && boolIsUpdate)
		{
			set<Id> setIdBillingApply = new set<Id>();
			set<Id> setIdBillingUpdateTax = new set<Id>();
			for( AcctSeedERP__Sales_Order__c  b : listNew)
			{
				 AcctSeedERP__Sales_Order__c  oldRec = oldMap.get(b.Id);

				if(b.AcctSeedERP__Status__c == 'Posted' && oldRec.AcctSeedERP__Status__c != 'Posted')
				{
					setIdBillingApply.add(b.Id);
				}

				if(b.GL_Account_Variable_3__c != oldRec.GL_Account_Variable_3__c ||
				   b.Tax_is_Harmonized__c != oldRec.Tax_is_Harmonized__c ||
				   b.Tax_Override__c != oldRec.Tax_Override__c ||
				   b.Tax_Rate_Federal__c != oldRec.Tax_Rate_Federal__c ||
				   b.Tax_Rate_Provincial__c != oldRec.Tax_Rate_Provincial__c ||
				   b.Tax_Rate_Retail__c != oldRec.Tax_Rate_Retail__c)
				{
					setIdBillingUpdateTax.add(b.Id);
				}
			}
			//if(!setIdBillingApply.isEmpty())
				//applyCash(setIdBillingApply);
			if(!setIdBillingUpdateTax.isEmpty())
				SalesOrderLine.updateSalesTax(setIdBillingUpdateTax);
		}
	}

	private static map<Id,Account> mapAccount;
	private static map<Id,AcctSeed__Accounting_Variable__c> mapGlv;
	private static map<String,AcctSeed__Accounting_Variable__c> mapGlv3ByName;
	//private static map<Id,Decimal> mapProjectBillings;

	private static void refreshStatics(list<AcctSeedERP__Sales_Order__c> listNew)
	{
		if(mapGlv == null)
		{
			mapAccount = new map<Id,Account>();
			mapGlv = new map<Id,AcctSeed__Accounting_Variable__c>();
			mapGlv3ByName = new map<String,AcctSeed__Accounting_Variable__c>();
		}

		set<Id> setIdAccount = new set<Id>();
		set<Id> setIdGlv = new set<Id>();
		set<String> setNameGlv = new set<String>();

		if(!mapGlv.containsKey(gcConstants.idGlv3Ontario))
			setIdGlv.add(gcConstants.idGlv3Ontario);

		for(AcctSeedERP__Sales_Order__c b : listNew)
		{
			if(b.GL_Account_Variable_3__c != null && !mapGlv.containsKey(b.GL_Account_Variable_3__c))
				setIdGlv.add(b.GL_Account_Variable_3__c);
			if(b.AcctSeedERP__Customer__c != null && !mapAccount.containsKey(b.AcctSeedERP__Customer__c))
				setIdAccount.add(b.AcctSeedERP__Customer__c);
		}

		if(!setIdAccount.isEmpty())
        for(Account a :
        	[SELECT Id,
        		BillingState
        	 FROM Account
        	 WHERE Id IN :setIdAccount])
        {
        	mapAccount.put(a.Id,a);
        	if(a.BillingState != null && !mapGlv3ByName.containsKey(a.BillingState))
        		setNameGlv.add(a.BillingState);
        }

		setIdGlv.remove(null);
		if(!setIdGlv.isEmpty() || !setNameGlv.isEmpty())
		{
			for(AcctSeed__Accounting_Variable__c glv :
				[SELECT Id,
						Name,
						Tax_is_Harmonized__c,
						Tax_Rate_Provincial__c,
						Tax_Rate_Retail__c,
						AcctSeed__Type__c
				 FROM AcctSeed__Accounting_Variable__c
				 WHERE Id IN :setIdGlv OR Name IN:setNameGlv])
			{
				mapGlv.put(glv.Id,glv);
	        	if(glv.AcctSeed__Type__c.equals('GL Account Variable 3'))
	        		mapGlv3ByName.put(glv.Name,glv);
			}
		}
	}
    
     class BillingWrapper{
        AcctSeed__Billing__c billing;
        List<AcctSeed__Billing_Line__c> lstBillingLine;
        
        BillingWrapper(){
            billing = new AcctSeed__Billing__c();
            lstBillingLine = new List<AcctSeed__Billing_Line__c>();
        }
        BillingWrapper(AcctSeed__Billing__c billing, List<AcctSeed__Billing_Line__c> lstBillingLine){
            this.billing = billing;
            this.lstBillingLine = lstBillingLine;
        }
        
        
    }
    private static Map<id,List<AcctSeedERP__Sales_Order_Line__c>> getSalesOrder(List<AcctSeedERP__Sales_Order__c> lstSalesOrder){
        Set<Id> SalesOrderIdSet = new Set<Id>();
        Map<id,List<AcctSeedERP__Sales_Order_Line__c>> SalesOrderToSOLineMap = new Map<id,List<AcctSeedERP__Sales_Order_Line__c>>();
        for(AcctSeedERP__Sales_Order__c so :lstSalesOrder){
        	SalesOrderIdSet.add(so.id);
        }
        List<AcctSeedERP__Sales_Order_Line__c>SalesOrderLineList = [select id,AcctSeedERP__Comment__c,AcctSeedERP__GL_Account_Variable_3__c,AcctSeedERP__GL_Account_Variable_2__c,AcctSeedERP__GL_Account_Variable_1__c,AcctSeedERP__Product__c,AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c
									 ,AcctSeedERP__Unit_Price__c,AcctSeedERP__Quantity_Ordered__c,AcctSeedERP__Sales_Order__c from AcctSeedERP__Sales_Order_Line__c where 	AcctSeedERP__Sales_Order__c in :SalesOrderIdSet];
        //List<Ecwid_Field_Mapping__mdt> lstFieldMapping = EcwidRestUtils.dynamicFielddMap.get('Billing Line');
       for(AcctSeedERP__Sales_Order_Line__c sol :SalesOrderLineList){
           if(SalesOrderToSOLineMap.containsKey(sol.AcctSeedERP__Sales_Order__c)){
               SalesOrderToSOLineMap.get(sol.AcctSeedERP__Sales_Order__c).add(sol);
           }else{
               SalesOrderToSOLineMap.put(sol.AcctSeedERP__Sales_Order__c,new List<AcctSeedERP__Sales_Order_Line__c>{sol});
           }
       } 
       return SalesOrderToSOLineMap; 
    }



}