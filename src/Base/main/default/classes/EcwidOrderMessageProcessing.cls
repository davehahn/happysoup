public without sharing class EcwidOrderMessageProcessing {
    
    public EcwidOrderWrapper order_wrapper = new EcwidOrderWrapper();
    Account account=new Account();
    
    public EcwidOrderMessageProcessing(){}
    
    public EcwidOrderMessageProcessing(String jsonResponse) {
        this.order_wrapper = EcwidOrderWrapper.parse(jsonResponse);
    }
    
  	/*
  	 * Build Query based on the field stored in custome meta data 
 	*/
    private String buildQuery(String queryFor,Account account){
        System.debug('queryFor= '+queryFor);
        System.debug('dynamicQueryMap= '+EcwidRestUtils.dynamicQueryMap);
       	String query = EcwidRestUtils.dynamicQueryMap.get(queryFor);
        System.debug('query= '+query);
       	List<Ecwid_Query_Field_Mapping__mdt> lstField = EcwidRestUtils.dynamicQueryFieldMap.get(queryFor);
        
        for(Ecwid_Query_Field_Mapping__mdt field :lstField){
            if(query.indexOf(field.MasterLabel) != -1){
                System.debug('field.MasterLabel= '+field.MasterLabel);
                System.debug('@@= '+String.valueOf(account.get(field.Field_Name__c)));
                if(account.get(field.Field_Name__c) != null)
                	query = query.replace(field.MasterLabel,String.valueOf(account.get(field.Field_Name__c)));
                //System.debug('query after replace= '+query);
            }
        }
        System.debug('###query= '+query);
        System.debug('return from querybuilder');
        return query;
    }
  	
    /*
  	 * Find the matchnig account with the given criteria
 	*/  
    public  List<sObject> findDuplicateAccount(){
        String query = buildQuery('Duplicate Account',this.account);
        try{
        	return Database.query(query);
        }catch(Exception e){
            System.debug('Exception = '+e);
        }
        return null;
    }
    
    /*
  	 * Check the order status coming from Ecwid
 	 */ 
    public Boolean checkOrderStatus(){
        if('DELIVERED'.equalsIgnoreCase(this.order_wrapper.fulfillmentStatus)){
           return false; 
        }
        return true;
    }
    
    /*
  	 * Prepare SObject for internal code purpose
 	 */
    public  void prepareAccountObject(){
        this.account.PersonEmail = this.order_wrapper.email;
    }
    
    /*
  	 * Update account information if account is present. Information are obtain from Ecwid Response
 	 */
    public void updateAccount(Account account){
        try{
            account.PersonEmail = this.order_wrapper.email;
            if(this.order_wrapper.billingPerson != null){
                account.BillingStreet = this.order_wrapper.billingPerson.street;
                account.BillingCity = this.order_wrapper.billingPerson.city;
                account.BillingState = this.order_wrapper.billingPerson.stateOrProvinceName;
                account.BillingCountry = this.order_wrapper.billingPerson.countryName;
                account.BillingCountryCode = this.order_wrapper.billingPerson.countryCode;
                account.BillingStateCode = this.order_wrapper.billingPerson.stateOrProvinceCode;
                account.BillingPostalCode = this.order_wrapper.billingPerson.postalCode;
                account.Phone = this.order_wrapper.billingPerson.phone;
            }
            if(this.order_wrapper.shippingPerson != null){
                account.shippingStreet = this.order_wrapper.shippingPerson.street;
                account.shippingCity = this.order_wrapper.shippingPerson.city;
                account.shippingState = this.order_wrapper.shippingPerson.stateOrProvinceName;
                account.shippingCountry = this.order_wrapper.shippingPerson.countryName;
                account.shippingCountryCode = this.order_wrapper.shippingPerson.countryCode;
                account.shippingStateCode = this.order_wrapper.shippingPerson.stateOrProvinceCode;
                account.shippingPostalCode = this.order_wrapper.shippingPerson.postalCode;
                account.Phone = this.order_wrapper.billingPerson.phone;
            }
            update account;
        }catch(Exception e){
            System.debug('Exception in updateAccount: '+e.getMessage());
        }
    }
    
    /*
  	* Create Lead
 	*/
    public Lead ceateLead(){
        Lead lead = new Lead();
        try{
            lead.email = this.order_wrapper.email;
            
            if(null != this.order_wrapper.billingPerson){
                lead.LastName = this.order_wrapper.billingPerson.name != null ? this.order_wrapper.billingPerson.name:this.order_wrapper.email;
                lead.City = this.order_wrapper.billingPerson.city != null ? this.order_wrapper.billingPerson.city:'';
                lead.Street = this.order_wrapper.billingPerson.street != null ? this.order_wrapper.billingPerson.street:'';
                lead.State = this.order_wrapper.billingPerson.stateOrProvinceName != null ? this.order_wrapper.billingPerson.stateOrProvinceName:'';
                lead.Country = this.order_wrapper.billingPerson.countryName != null ? this.order_wrapper.billingPerson.countryName:'';
                lead.CountryCode = this.order_wrapper.billingPerson.countryCode != null ? this.order_wrapper.billingPerson.countryCode:'';
                lead.StateCode = this.order_wrapper.billingPerson.stateOrProvinceCode != null ? this.order_wrapper.billingPerson.stateOrProvinceCode:'';
                lead.PostalCode = this.order_wrapper.billingPerson.postalCode != null ? this.order_wrapper.billingPerson.postalCode:'';
                lead.Company = this.order_wrapper.billingPerson.companyName != null ? this.order_wrapper.billingPerson.companyName:'';
                lead.Phone = this.order_wrapper.billingPerson.phone != null ? this.order_wrapper.billingPerson.phone:'';
            }else{
                lead.LastName = this.order_wrapper.email;
            }
            insert lead;
        }catch(Exception e){
            System.debug('Exception in updateAccount: '+e.getMessage());
        }
        return lead;
   }
    
    /*
  	* This function checks whether sales order exists based on the id received from Ecwid
 	*/
    public List <AcctSeedERP__Sales_Order__c>  checkExistingSalesOrder(){
       List <AcctSeedERP__Sales_Order__c> lstSalesOrder = [Select 
                                                                id,
                                                                Ecwid_Order_Id__c,
                                                                AcctSeedERP__Customer__c,
                                                                (Select 
                                                                    id,
                                                                    AcctSeedERP__Product__c,
                                                                    AcctSeedERP__Quantity_Ordered__c,
                                                                    AcctSeedERP__Unit_Price__c,
                                                                    GMBLASERP__Price_Override__c,
                                                                    AcctSeedERP__GL_Account_Variable_3__c
                                                                 from 
                                                                    AcctSeedERP__Sales_Order_Line__r
                                                                ) 
                                                           from 
                                                             	AcctSeedERP__Sales_Order__c  
                                                           WHERE 
                                                             	Ecwid_Order_Id__c = :this.order_wrapper.id 
                                                         ];
    	return lstSalesOrder;
    }
    
    public Id getGLV3(Account acc){
        acc.billingstate = 'Ontario';
        System.debug('in the getGLV3 ');
        String query = buildQuery('SL GLV3',acc);
        System.debug('after build query');
        String glv3Id = null;
        System.debug('@@ query = '+query);
        List<sObject> sobject_list;
        try{
        	sobject_list = Database.query(query);
        }catch(Exception e){
            System.debug('Exception = '+e);
        }
        System.debug('@@ sobject_list = '+sobject_list);
        if(sobject_list != null && !sobject_list.isEmpty()){
            for(Sobject obj :sobject_list){
                if(obj.get('Name') == 'Others'){
                    glv3Id = obj.Id;	     
                }
                if(obj.get('Name') == acc.billingstate){
                    return obj.Id;	        
                }
            }
        }
        return glv3Id;    
    }
    
    public AcctSeedERP__Sales_Order__c createSalesOrder(Account acc, AcctSeedERP__Sales_Order__c salesOrder){
     
        //acc.BillingState = 'Ontario';
        salesOrder.AcctSeedERP__Customer__c = acc.id;
		salesOrder.Ecwid_Order_Id__c = this.order_wrapper.id;  
        System.debug('this.order_wrapper.fulfillmentStatus= '+this.order_wrapper.fulfillmentStatus);
        salesOrder.Stage__c = this.order_wrapper.fulfillmentStatus;
        if(this.order_wrapper.billingPerson != null){
                salesOrder.AcctSeedERP__Billing_Street__c = this.order_wrapper.billingPerson.street;
                salesOrder.AcctSeedERP__Billing_City__c = this.order_wrapper.billingPerson.city;
                salesOrder.AcctSeedERP__Billing_State__c = this.order_wrapper.billingPerson.stateOrProvinceName;
                salesOrder.AcctSeedERP__Billing_Country__c = this.order_wrapper.billingPerson.countryName;
                //salesOrder.shippingCountryCode = this.order_wrapper.shippingPerson.countryCode;
               // salesOrder.shippingStateCode = this.order_wrapper.shippingPerson.stateOrProvinceCode;
                salesOrder.AcctSeedERP__Billing_PostalCode__c = this.order_wrapper.billingPerson.postalCode;
            
                //salesOrder. = this.order_wrapper.billingPerson.phone;
            }
        
        if(this.order_wrapper.shippingPerson != null){
                salesOrder.AcctSeedERP__Shipping_Street__c = this.order_wrapper.shippingPerson.street;
                salesOrder.AcctSeedERP__Shipping_City__c = this.order_wrapper.shippingPerson.city;
                salesOrder.AcctSeedERP__Shipping_State__c = this.order_wrapper.shippingPerson.stateOrProvinceName;
                salesOrder.AcctSeedERP__Shipping_Country__c = this.order_wrapper.shippingPerson.countryName;
                //salesOrder.shippingCountryCode = this.order_wrapper.shippingPerson.countryCode;
               // salesOrder.shippingStateCode = this.order_wrapper.shippingPerson.stateOrProvinceCode;
                salesOrder.AcctSeedERP__Shipping_PostalCode__c = this.order_wrapper.shippingPerson.postalCode;
                //salesOrder. = this.order_wrapper.billingPerson.phone;
            }
        
       /* List<Ecwid_Field_Mapping__mdt> lstFieldMapping = EcwidRestUtils.dynamicFielddMap.get('Sales Order');
        
        for(Ecwid_Field_Mapping__mdt fieldMapping :lstFieldMapping){
            System.debug('fieldMapping= '+fieldMapping);
            if(fieldMapping.Data_Type__c.equalsIgnoreCase('Query')){
                System.debug('fieldMapping.Default_Value__c= '+fieldMapping.Default_Value__c);
                List<SObject> lstObject = Database.query(fieldMapping.Default_Value__c);
                salesOrder.put(fieldMapping.SF_Field_API_Name__c,lstObject[0].get(fieldMapping.Source_Field__c));
            }
            else{
                System.debug('fieldMapping.SF_Field_API_Name__c= '+fieldMapping.SF_Field_API_Name__c);
                System.debug('fieldMapping.Default_Value__c= '+fieldMapping.Default_Value__c);
                salesOrder.put(fieldMapping.SF_Field_API_Name__c,fieldMapping.Default_Value__c);
            }
        }
        */
        if(!String.isEmpty(account.AcctSeed__GL_Account_Variable_3__c )){
            salesOrder.GL_Account_Variable_3__c = account.AcctSeed__GL_Account_Variable_3__c;
        }else{
            salesOrder.GL_Account_Variable_3__c = getGLV3(account);
        }
        //EcwidRestUtils.setting.Store_Id__c
        salesOrder.Warehouse__c  = EcwidRestUtils.wareHouseId;
        salesOrder.GL_Account_Variable_1__c = EcwidRestUtils.glv1Id;
        salesOrder.GL_Account_Variable_2__c = EcwidRestUtils.glv2Id;
        System.debug('this.order_wrapper.paymentStatus= '+this.order_wrapper.paymentStatus);
        salesOrder.Payment_Status__c = this.order_wrapper.paymentStatus;
        salesOrder.Ecwid_Store_Id__c = EcwidRestUtils.storeId;
        
        System.debug('salesOrder.AcctSeedERP__Ledger__c= '+salesOrder.AcctSeedERP__Ledger__c);
        AcctSeed__Ledger__c led = [Select id,AcctSeed__Type__c from AcctSeed__Ledger__c WHERE AcctSeed__Type__c = 'Transactional' limit 1]; 
        System.debug('@@led= '+led);
        salesOrder.AcctSeedERP__Ledger__c = led.id;
        Id isOnlineOrderRT =  Schema.SObjectType.AcctSeedERP__Sales_Order__c.getRecordTypeInfosByDeveloperName().get('Online_Orders').getRecordTypeId();
        salesOrder.RecordTypeId = isOnlineOrderRT;
        Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
		Id retailPbId = settings.Default_Retail_Pricebook__c;
        salesOrder.Pricebook__c = retailPbId;
        upsert salesOrder;
        System.debug('Sales Order created id= '+salesOrder.Id);
        System.debug('this.order_wrapper.items= '+this.order_wrapper.items);
        createSalesOrderLineItem(this.order_wrapper.items, salesOrder, acc,salesOrder.AcctSeedERP__Sales_Order_Line__r);
        return salesOrder;
    }
    public EcwidOrderWrapper.cls_items addSalesLineItemForShippingCharge(){
        EcwidOrderWrapper.cls_items ShippingChargeItem= new EcwidOrderWrapper.cls_items();
        ShippingChargeItem.sku = EcwidRestUtils.setting.Freight_Purolator_SKU__c;
        ShippingChargeItem.price = this.order_wrapper.shippingOption != null ?this.order_wrapper.shippingOption.shippingRate:'0';
        ShippingChargeItem.quantity = '1';
        return ShippingChargeItem;
        
    }
    
    /*
  	* This function create / update the Sales Order Line item
 	*/
    public void createSalesOrderLineItem(List<EcwidOrderWrapper.cls_items> lstSalesOrderLineItemFromEcwid,  AcctSeedERP__Sales_Order__c salesOrder, Account account, List<AcctSeedERP__Sales_Order_Line__c> lstExistingSalesOrderLine){
        Map<Id,AcctSeedERP__Sales_Order_Line__c> mapExistingLineItem = new Map<Id,AcctSeedERP__Sales_Order_Line__c>();
        List<AcctSeedERP__Sales_Order_Line__c> lstOrderLineItemToSave = new List<AcctSeedERP__Sales_Order_Line__c>();
        Map<String,	Product2> mapProduct = new Map<String,Product2>();
        Map<String,EcwidOrderWrapper.cls_items> mapEcwidProductItem = new Map<String,EcwidOrderWrapper.cls_items>();
        List<String> lstProductSku =new List<String>();
        Boolean isCreated;
        try{   
            //map for the existing line items
            if(!lstExistingSalesOrderLine.isEmpty()){
                for(AcctSeedERP__Sales_Order_Line__c existingLineItem : lstExistingSalesOrderLine){
                    mapExistingLineItem.put(existingLineItem.AcctSeedERP__Product__c,existingLineItem); 
                }
            }
            System.debug('lstSalesOrderLineItemFromEcwid= '+lstSalesOrderLineItemFromEcwid);
            for(EcwidOrderWrapper.cls_items item : lstSalesOrderLineItemFromEcwid){
                System.debug('@@ item.sku= '+item.sku);
                lstProductSku.add(item.sku);
                mapEcwidProductItem.put(item.sku,item);
            } 
            
            //add a shipping charge line item, this is not an inventory product
            EcwidOrderWrapper.cls_items ShippingChargeItem = addSalesLineItemForShippingCharge();
            lstProductSku.add(ShippingChargeItem.sku);
            mapEcwidProductItem.put(ShippingChargeItem.sku,ShippingChargeItem);
            
            if(!lstProductSku.isEmpty()){
                List<Product2> lstProduct = getProductData(lstProductSku);
                Map<Id,Decimal> mapProductPrice = getPriceFromPriceBook(lstProduct);
                
                for(Product2 product :lstProduct){
                    isCreated=false;
                    if(mapEcwidProductItem.containsKey(product.Unique_Product_Code__c)){
                        EcwidOrderWrapper.cls_items itemFromEcwid = mapEcwidProductItem.get(product.Unique_Product_Code__c);
                        AcctSeedERP__Sales_Order_Line__c OrderLineItem;
                        
                        if(mapExistingLineItem != null && mapExistingLineItem.containsKey(product.Id)){
                            //exising line item
                            OrderLineItem = mapExistingLineItem.get(product.Id);
                            mapExistingLineItem.remove(product.Id);
                        }else{
                            //new line item
                            OrderLineItem = new AcctSeedERP__Sales_Order_Line__c();
                            isCreated = true;
                        }
                        OrderLineItem.AcctSeedERP__Product__c = product.Id;
                        OrderLineItem.AcctSeedERP__Quantity_Ordered__c = Integer.valueOf(itemFromEcwid.quantity);
                        OrderLineItem.AcctSeedERP__Unit_Price__c = Double.valueOf(itemFromEcwid.price);
                        OrderLineItem.AcctSeedERP__Comment__c = '';
                        OrderLineItem.Review_Price__c = false;
                        OrderLineItem.GMBLASERP__Price_Override__c = true;
                        OrderLineItem.AcctSeedERP__GL_Account_Variable_2__c = salesOrder.GL_Account_Variable_2__c;
                        OrderLineItem.AcctSeedERP__GL_Account_Variable_1__c = salesOrder.GL_Account_Variable_1__c;
                        OrderLineItem.AcctSeedERP__GL_Account_Variable_3__c = salesOrder.GL_Account_Variable_3__c;
                        
                        if(!mapProductPrice.isEmpty() && mapProductPrice.containsKey(product.Id)&& mapProductPrice.get(Product.Id) <> OrderLineItem.AcctSeedERP__Unit_Price__c){
                            OrderLineItem.Review_Price__c = true;
                        }
                        if(isCreated){
                            OrderLineItem.AcctSeedERP__Sales_Order__c = salesOrder.id;
                        }
                        
                          
                        /*List<Ecwid_Field_Mapping__mdt> lstFieldMapping = EcwidRestUtils.dynamicFielddMap.get('Sales Order Line Items');
                        for(Ecwid_Field_Mapping__mdt fieldMapping :lstFieldMapping){
                            if(fieldMapping.Data_Type__c.equalsIgnoreCase('Query')){
                                System.debug('@@fieldMapping.Default_Value__c ='+fieldMapping.Default_Value__c );
                                List<SObject> lstObject = Database.query(fieldMapping.Default_Value__c);
                                OrderLineItem.put(fieldMapping.SF_Field_API_Name__c,
                                                  lstObject[0].get(fieldMapping.Source_Field__c)!= null ?lstObject[0].get(fieldMapping.Source_Field__c):null);
                            }
                        }*/
                        lstOrderLineItemToSave.add(OrderLineItem);
                    }  
                }
            }
            
            List<AcctSeedERP__Sales_Order_Line__c> lstOrderLineItemTobeRemoved = new List<AcctSeedERP__Sales_Order_Line__c>();
            if(!mapExistingLineItem.isEmpty()){
                lstOrderLineItemTobeRemoved = mapExistingLineItem.Values();
            }
            System.debug('lstOrderLineItemTobeRemoved = '+lstOrderLineItemTobeRemoved);        
            System.debug('lstOrderLineItemToSave= '+lstOrderLineItemToSave);
            
            if(!lstOrderLineItemToSave.isEmpty()){
                upsert lstOrderLineItemToSave;
                //Notification incase product price is difer from the PriceBook 
                //NotificationForPriceReview(lstOrderLineItemToSave);
            }
            //If any ilne item deleted from the sales Order
            if(!lstOrderLineItemTobeRemoved.isEmpty()){
                delete lstOrderLineItemTobeRemoved;
            }
        }catch(Exception e){
         	System.debug('Exception in updateAccount: '+e.getMessage());   
        }
    }
  /*  
    public List<AcctSeed__Billing__c> Billing(List<AcctSeedERP__Sales_Order__c>lstSalesOrder){
        List<AcctSeed__Billing__c> lstBilingToBeSaved = new List<AcctSeed__Billing__c>();
        List<AcctSeed__Billing_Line__c> lstBilingLineToBeSaved = new List<AcctSeed__Billing_Line__c>();
        List<BillingWrapper> lstBillingWrapper = new List<BillingWrapper>();
        BillingWrapper billingWrapper = new BillingWrapper();
        
        List<Ecwid_Field_Mapping__mdt> lstFieldMapping = EcwidRestUtils.dynamicFielddMap.get('Billing Line');
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
            List<AcctSeedERP__Sales_Order_Line__c> listSalesOrderLine = so.AcctSeedERP__Sales_Order_Line__r;
            
            for(AcctSeedERP__Sales_Order_Line__c sol :listSalesOrderLine){
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
        if(!lstBilingLineToBeSaved.isEmpty()){
            insert lstBilingLineToBeSaved; 
        }
        return lstBilingToBeSaved;
    }
    
    
    public void billingCashReceipt(List<AcctSeed__Billing__c> lstBiling){
        
        Id idGlCashFloat = gcConstants.idGlCashFloat;
		Id idGlRBCCDN = gcConstants.idGlRBCCDN;
		Id idGlBank;
        //Currently payment method cash
        idGlBank = idGlCashFloat;
        Map<Id,AcctSeed__Cash_Receipt__c> mapBillReceipt = new Map<Id,AcctSeed__Cash_Receipt__c>();
        for(AcctSeed__Billing__c bill : [SELECT Id, Name,AcctSeed__Customer__c,AcctSeed__Balance__c	FROM AcctSeed__Billing__c WHERE Id IN :lstBiling]){
           AcctSeed__Cash_Receipt__c newCR = new AcctSeed__Cash_Receipt__c(
				AcctSeed__Account__c = bill.AcctSeed__Customer__c,
				AcctSeed__Amount__c = bill.AcctSeed__Balance__c,
				AcctSeed__Bank_Account__c = idGlBank,
				AcctSeed__Payment_Reference__c = bill.Name + '_' + System.now().format(),
				Payment_Method__c = 'Cash',
				AcctSeed__Purpose__c = 'Customer Receipt'
			);
 			mapBillReceipt.put(bill.Id, newCR);
        }
        if(!mapBillReceipt.isEmpty()){
			/// Create a new Receipt
			List<AcctSeed__Billing_Cash_Receipt__c> listBCM = new List<AcctSeed__Billing_Cash_Receipt__c>();
			try{
				insert mapBillReceipt.values();
				AcctSeed__Accounting_Period__c currPeriod = GMBLASERP.gcAccountingPeriod.periodCurr();
				for(Id idBill : mapBillReceipt.keySet())
				{
					AcctSeed__Cash_Receipt__c newCR = mapBillReceipt.get(idBill);
					/// Apply Cash Receipt on the new Bill
					AcctSeed__Billing_Cash_Receipt__c bcm = new AcctSeed__Billing_Cash_Receipt__c(
						//AcctSeed__Accounting_Period__c = currPeriod.Id,
						AcctSeed__Applied_Amount__c = newCR.AcctSeed__Amount__c,
						AcctSeed__Billing__c = idBill,
						AcctSeed__Cash_Receipt__c = newCR.Id
					);
					listBCM.add(bcm);
				}
				insert listBCM;
			}catch(Exception e){
				
				System.debug(e.getMessage());
			}
			
		}
		
    }
    
    public void salesInventoryMovement(List<AcctSeedERP__Sales_Order__c>lstSalesOrder){
        map<Id,map<Id,map<Id,Id>>> mapPWLB = new map<Id,map<Id,map<Id,Id>>>();
        Id idLocation;
        String pIdWarehouse ; 
        List<Ecwid_Field_Mapping__mdt> lstFieldMapping = EcwidRestUtils.dynamicFielddMap.get('Sales Order');
        for(Ecwid_Field_Mapping__mdt fieldMapping :lstFieldMapping){
            System.debug('fieldMapping= '+fieldMapping);
            if(fieldMapping.Data_Type__c.equalsIgnoreCase('Query') && fieldMapping.Default_Value__c.contains('')){
                List<SObject> lstObject = Database.query(fieldMapping.Default_Value__c);
                pIdWarehouse = String.valueOf(lstObject[0].get(fieldMapping.Source_Field__c));
                //salesOrder.put(fieldMapping.SF_Field_API_Name__c,lstObject[0].get(fieldMapping.Source_Field__c));
            }}
		for(AcctSeedERP__Location__c loc : [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c = :pIdWarehouse ORDER BY CreatedDate LIMIT 1])
			idLocation = loc.Id;
        for(AcctSeedERP__Sales_Order__c so :lstSalesOrder){
            List<AcctSeedERP__Sales_Order_Line__c> listSalesOrderLine = so.AcctSeedERP__Sales_Order_Line__r;
            for(AcctSeedERP__Sales_Order_Line__c sol :listSalesOrderLine){
               
                if(!mapPWLB.containsKey(sol.AcctSeedERP__Product__c) && sol.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c){
            		mapPWLB.put(sol.AcctSeedERP__Product__c, new map<Id,map<Id,Id>>{pIdWarehouse => new map<Id,Id>{idLocation => null}});
			}
			
            }
        }
        System.debug('mapPWLB= '+mapPWLB);
        GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);
        List<AcctSeedERP__Sales_Order_Inventory_Movement__c> lstSOMovement = new List<AcctSeedERP__Sales_Order_Inventory_Movement__c>();
        for(AcctSeedERP__Sales_Order__c so :lstSalesOrder){
            List<AcctSeedERP__Sales_Order_Line__c> listSalesOrderLine = so.AcctSeedERP__Sales_Order_Line__r;
            for(AcctSeedERP__Sales_Order_Line__c sol :listSalesOrderLine){
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
    
    public void NotificationForPriceReview(List<AcctSeedERP__Sales_Order_Line__c> lstOrderLineItem){
        List<AcctSeedERP__Sales_Order_Line__c> lstSendPriceReviewNotification = new List<AcctSeedERP__Sales_Order_Line__c>();
        for(AcctSeedERP__Sales_Order_Line__c sol: lstOrderLineItem){
            if(sol.Review_Price__c){
                lstSendPriceReviewNotification.add(sol);
            }
        }
        System.debug('lstSendPriceReviewNotification= '+lstSendPriceReviewNotification);
        if(!lstSendPriceReviewNotification.isEmpty()){
            //call Queueable job
            Map<String, List<AcctSeedERP__Sales_Order_Line__c>> input_map = new Map<String, List<AcctSeedERP__Sales_Order_Line__c>>();
            input_map.put('salesorderitems', lstSendPriceReviewNotification);
            EcwidReviewSalesOrderLinePriceAsync  chatter_job = new EcwidReviewSalesOrderLinePriceAsync(input_map);
            Id job_id = System.enqueueJob(chatter_job);
        }
    }
    */
    public List<Product2> getProductData(List<String> lstProductSku){
        List<Product2> lstProduct = [
                                        SELECT 
                                            Id,
                                            Unique_Product_Code__c 
                                        FROM 
                                        	Product2 
                                        where 
                                        	Unique_Product_Code__c in :lstProductSku
                                    ];
        return lstProduct;
    }
    
    public Map<Id,Decimal> getPriceFromPriceBook( List<Product2> lstProduct){
    	List<PricebookEntry> lstPriceFromPriceBook = [Select UnitPrice, Product2Id From PricebookEntry Where Product2Id IN: lstProduct ANd Pricebook2Id = '01si0000000KoRPAA0'];
        Map<Id,Decimal> mapProductPrice = new Map<Id,Decimal>();
        for(PricebookEntry price :lstPriceFromPriceBook){
            mapProductPrice.put(price.Product2Id,price.UnitPrice);
        } 
        return mapProductPrice;
    }
   /* class BillingWrapper{
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
*/
}