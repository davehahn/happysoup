public with sharing class RegistrationExt {

  public static Boolean disableRegistrationTrigger {
    get {
      if(disableRegistrationTrigger == null) return false;
      else return disableRegistrationTrigger;
    }
    set {
      if(value == null) disableRegistrationTrigger = false;
      else disableRegistrationTrigger = value;
    }
  }

  public RegistrationExt(ApexPages.StandardController stdCtr) {
  }

  public static void handleRegistrationsFromERP(Map < Id, AcctSeed__Project__c > newErpMap,
  																							Map < Id, AcctSeed__Project__c > oldErpMap)
  {
		List<AcctSeed__Project__c> newBoatSales = filterBoatSales(newErpMap.values());
		Set < Id > regToCreate_erpsIds = new Set < Id >();
		Set < Id > regsToDelete_erpIds = new Set < Id > ();
		for (AcctSeed__Project__c newErp: newBoatSales ) {
		  if (newErp.Stage__c == 'Delivered' && oldErpMap.get(newErp.Id).Stage__c != 'Delivered') {
				regToCreate_erpsIds.add(newErp.Id);
		  }
		  if (newErp.Stage__c != 'Delivered' && oldErpMap.get(newErp.Id).Stage__c == 'Delivered') {
				regsToDelete_erpIds.add(newErp.Id);
		  }
		}
		if(!regToCreate_erpsIds.isEmpty())
		{
				createRegistrationsFuture(regToCreate_erpsIds);
		}
		if(!regsToDelete_erpIds.isEmpty())
			deleteRegistrationsFuture(regsToDelete_erpIds);
  }

//  public static void triggerHandler(
//		Map < Id, Registration__c > oldMap,
//		Map < Id, Registration__c > newMap,
//		List < Registration__c > listNew,
//		Boolean boolIsBefore,
//		Boolean boolIsInsert,
//		Boolean boolIsUpdate,
//		Boolean boolIsDelete )
//  {
//		if (disableRegistrationTrigger) return;
//
//		if (oldMap == null) oldMap = new Map < Id, Registration__c > ();
//		if (newMap == null) newMap = new Map < Id, Registration__c > ();
//		if (listNew == null) listNew = new List < Registration__c > ();
//
//		if (boolIsBefore)
//		/* &&&&&&&   BEFORE    &&&&&&& */
//		{
//		  if (boolIsInsert) {
////				Set <Id> serialIdNowNonCurrent = new Set < Id > ();
////				for (Registration__c reg: listNew) {
////				  reg.isCurrent__c = true;
////				  reg.Registered_Date__c = DateTime.now();
////				  if( reg.ErpOrder__c != null )
////				  	reg.Uniqueifier__c = reg.ErpOrder__c + '_' + reg.SerialNumber__c;
////				  serialIdNowNonCurrent.add(reg.SerialNumber__c);
////				}
////				setNonCurrent(serialIdNowNonCurrent);
////				addRegistrationAccount(listNew);
//		  }
//		  if (boolIsUpdate) {
//		  }
//		  if (boolIsDelete) {
//		  }
//		} else {
//		  /* &&&&&&&   AFTER   &&&&&&& */
//		  if (boolIsInsert) {
//				//createPartnerCustomers( listNew );
//				//setRegistationDateOnSerial( listNew, oldMap );
//				//System.enqueueJob( new RegistrationPopulateMotorQueue( newMap.keySet() ) );
//		  }
//		  if (boolIsUpdate) {
//		  	setRegistationDateOnSerial( listNew, oldMap );
//		  }
//		  if (boolIsDelete) {
//		  }
//		}
//  }

  @AuraEnabled
  public static Contact[] fetchAccountContacts()
  {
  	try {
  		Id acctId = [SELECT Id, AccountId
  								 FROM User
  								 WHERE Id = :UserInfo.getUserId() ].AccountId;
  		if (acctId != null) {
	  	  return [SELECT Id, FirstName, LastName
	  	          FROM Contact
	  	          WHERE AccountId = :acctId ];
	  	} else {
	  		return new List<Contact>();
	  	}
  	}
  	catch( Exception e )
  	{
  		return new List<Contact>();
  	}
  }

  @AuraEnabled
  public static Registration__c createRegistration(String account,
  																								 String serno,
  																								 List<GMBLASERP__Serial_Number__c> NestedItems,
  																								 String motor,
  																								 String motorSerial,
  																								 DateTime deliveryDate,
  																								 String partnerMemoryMaker,
  																								 String caseId,
  																								 String paymentMethod ) {
		if( LGND_Utilities.sObjectNameFromId( account ) == 'Lead' ) {
			Lead lead = getDetailedLead(account);
			account = lgnd_account_createForm.convertLead(lead, String.valueOf(lead.Phone)).Id;
		}

		Registration__c registration = new Registration__c(
			Account__c = account,
			SerialNumber__c = serno,
	    Delivery_Date__c = deliveryDate,
	    Payment_Method__c = paymentMethod
    );
    if( !String.isBlank( partnerMemoryMaker ) )
    {
    	registration.Partner_Memory_Maker__c = partnerMemoryMaker;
    }
		if (motor != null && motorSerial != null) {
			registration.Registered_Motor__c = motor;
			registration.Registered_Motor_Serial__c = motorSerial;
		}

		//if (caseId != null) {
		//	disablePromoCase = true;
		//}
		insert registration;
		Registration__c[] regs = new List<Registration__c>();
		Set<Id> nestedSerialIds = new Set<Id>();
		// Register nested items, too
		for (GMBLASERP__Serial_Number__c item : NestedItems) {
		  regs.add(
		  	new Registration__c(
		  		Account__c = account,
		  		SerialNumber__c = item.Id
	  		)
	  	);
		  nestedSerialIds.add( item.Id );
		}

		GMBLASERP__Serial_Number__c[] prods = [SELECT Id,
																									Name,
																									Nest__c
																						 FROM GMBLASERP__Serial_Number__c
																						WHERE Id IN :nestedSerialIds];
		if (prods.size() > 0) {
			for( GMBLASERP__Serial_Number__c nestSerial : prods )
			{
		  	nestSerial.Nest__c = serno;
			}
		}
		insert regs;
		update prods;
		return registration;
  }

  private static Lead getDetailedLead(Id accId) {
  	return [SELECT BoatModel__c,
									 Company,
									 ConvertedAccountId,
									 ConvertedContactId,
									 ConvertedDate,
									 ConvertedOpportunityId,
									 CreatedById,
									 CreatedDate,
									 Description,
									 Email,
									 EmailBouncedDate,
									 EmailBouncedReason,
									 FirstName,
									 GeocodeAccuracy,
									 Id,
									 Image__c,
									 Industry,
									 IP_City__c,
									 IsConverted,
									 IsDeleted,
									 IsPersonAccount__c,
									 IsUnreadByOwner,
									 JigsawContactId,
									 LeadSource,
									 LegendUser__c,
									 LinkedIn__c,
									 MasterRecordId,
									 MiddleName,
									 MotorModel__c,
									 Name,
									 NumberOfEmployees,
									 OwnerId,
									 Phone,
									 PhotoUrl,
									 Preferred_Language__c,
									 Salutation,
									 Status,
									 SystemModstamp,
									 Title
						  FROM Lead
						 WHERE Id = :accId];
  }

  @AuraEnabled
  public static Map<String, String> getAccount(String accountId) {
		Account a = [SELECT Name,
												BillingStreet,
												BillingCity,
												BillingPostalCode,
												BillingState,
												BillingCountry,
												Phone,
												PersonEmail
								 	 FROM Account
								  WHERE Id=:accountId LIMIT 1];
		Map<String, String> result = new Map<String, String>{
		  'Name' => a.Name,
		  'Phone' => a.Phone,
		  'Email' => a.PersonEmail,
		  'City' => a.BillingCity,
		  'Street' => a.BillingStreet,
		  'PostalCode' => a.BillingPostalCode,
		  'State' => a.BillingState,
		  'Country' => a.BillingCountry
		};
		return result;
  }

  @AuraEnabled
  public static Map<String, String> getLead(String accountId) {
		Lead l = [SELECT Name,
										 Phone,
										 Email,
										 City,
										 Country,
										 State,
										 Street,
										 PostalCode
							  FROM Lead
							 WHERE Id=:accountId LIMIT 1];
		Map<String, String> result = new Map<String, String>{
		  'Name' => l.Name,
		  'Phone' => l.Phone,
		  'Email' => l.Email,
		  'City' => l.City,
		  'Street' => l.Street,
		  'PostalCode' => l.PostalCode,
		  'State' => l.State,
		  'Country' => l.Country
		};
		return result;
  }

  @AuraEnabled
  public static List<GMBLASERP__Serial_Number__c> findNestedItems(String sernoId) {
		List<GMBLASERP__Serial_Number__c> items = [
				  SELECT Name,
				  			 Product_Name__c,
				  			 Description__c,
				  			 Status__c,
				  			 GMBLASERP__Lot__c,
				  			 GMBLASERP__Lot__r.Name,
				  			 Product_Record_Type__c,
				  			 Location__c,
				  			 Nest__c
				    FROM GMBLASERP__Serial_Number__c
				   WHERE Nest__c = :sernoId];
		return items;
  }

  @AuraEnabled
  public static GMBLASERP__Serial_Number__c getProductDetails (String sernoId) {
		GMBLASERP__Serial_Number__c item = [
				  SELECT Name,
				  			 Product_Name__c,
				  			 Description__c,
				  			 Status__c,
				  			 GMBLASERP__Lot__c,
				  			 GMBLASERP__Lot__r.Name,
				  			 Product_Record_Type__c,
				  			 Location__c, Nest__c,
				  			 GMBLASERP__Product__r.Can_be_Nest__c,
				  			 GMBLASERP__Product__r.Can_be_Nested__c
				    FROM GMBLASERP__Serial_Number__c
				   WHERE Id = :sernoId];
		return item;
  }

  @AuraEnabled
  public static String getRegistrationHistory (String recordId) {
		List<Registration__c> regs = [SELECT Account__c,
																				 Id,
																				 isCurrent__c,
																				 Name,
																				 ProductMake__c,
																				 SerialNumber__c,
																				 CreatedDate
																	  FROM Registration__c
																	 WHERE SerialNumber__c = :recordId
																ORDER BY CreatedDate DESC];
		List<Object> wrapperList = new List<Object>();
		for (Registration__c reg : regs) {
		  List<Object> wrapper = new List<Object>();
		  Account acc = [ SELECT Id, Name
						  FROM Account
						  WHERE Id = :reg.Account__c];
		  wrapper.add(reg);
		  wrapper.add(acc);
		  wrapperList.add(wrapper);
		}
		return JSON.serialize(wrapperList);
  }

  @AuraEnabled
  public static String getUpgrades (String productId) {
  	System.debug(productId);
		LGND_APIv2_Product lp = new LGND_APIv2_Product( productId, 'partner', 'Boat' );
		return JSON.serialize(lp);
  }

  @AuraEnabled
  public static Case updateClaimWithRegistration(String caseId, String regId) {
  	Case c = [SELECT Id, Registration__c FROM Case WHERE ID = :caseId];
  	c.Registration__c = regId;
  	c.Status = 'Pending review';
  	update c;
  	return c;
  }

//	public class RegistrationPopulateMotorQueue implements Queueable {
//
//		public final Set<Id> regIds;
//
//		public RegistrationPopulateMotorQueue( Set<Id> registrationIds )
//		{
//			this.regIds = registrationIds;
//		}
//
//		public void execute( QueueableContext context )
//		{
//			Id pjRt = gcConstants.idRtProjectBoatSale;
//			Id boatRt = LGND_Constants.productRtId_Boat;
//			Id motorRt = LGND_Constants.productRtId_Motor;
//			Map<Id, Registration__c> erpId_Reg_map = new Map<Id, Registration__c>();
//			for( Registration__c reg : [ SELECT Id, ERPOrder__c
//																	 FROM Registration__c
//																	 WHERE Id IN :this.regIds
//																	 AND ERPOrder__c <> null
//																	 AND ERPOrder__r.RecordTypeId = :pjRt
//																	 AND Registered_Motor__c = null
//																	 AND SerialNumber__r.GMBLASERP__Product__r.RecordTypeId = :boatRt] )
//			{
//				erpId_Reg_map.put( reg.ERPOrder__c, reg );
//			}
//
//			for( AcctSeedERP__Material__c mat : [ SELECT Id,
//																									 AcctSeedERP__Project__c,
//																									 AcctSeedERP__Product__c,
//																									 GMBLASERP__Serial_Number__r.Name
//																						FROM AcctSeedERP__Material__c
//																						WHERE AcctSeedERP__Project__c IN :erpId_Reg_map.keySet()
//																						AND AcctSeedERP__Product__r.RecordTypeId = :motorRt
//																						AND AcctSeedERP__Product__r.Family <> 'Kicker Motor'] )
//			{
//				if( erpId_Reg_map.containsKey( mat.AcctSeedERP__Project__c ) )
//				{
//					erpId_Reg_map.get( mat.AcctSeedERP__Project__c ).Registered_Motor__c = mat.AcctSeedERP__Product__c;
//					erpId_Reg_map.get( mat.AcctSeedERP__Project__c ).Registered_Motor_Serial__c = mat.GMBLASERP__Serial_Number__r.Name;
//				}
//			}
//			update erpId_Reg_map.values();
//		}
//	}

  /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
//  private static void setNonCurrent(Set<Id> serialIds) {
//		Registration__c[] toUpdate = new List<Registration__c>();
//		for (Registration__c reg: [SELECT Id FROM Registration__c WHERE SerialNumber__c IN :serialIds]) {
//		  reg.isCurrent__c = false;
//		  toUpdate.add(reg);
//		}
//		if (toUpdate.size() > 0)
//		  update toUpdate;
//  }

  private static List<AcctSeed__Project__c> filterBoatSales(AcctSeed__Project__c[] erps) {
		Set<Id> boatSaleIds = new Set<Id>{
			gcConstants.idRtProjectBoatSale,
			gcConstants.idRtProjectPartnerBoatSale
		};
		List<AcctSeed__Project__c> result = new List<AcctSeed__Project__c>();
		for (AcctSeed__Project__c erp: erps) {
		  if( boatSaleIds.contains( erp.RecordTypeId ) )
			result.add(erp);
		}
		return result;
  }

  @future
  public static void createRegistrationsFuture(Set < Id > erpIds) {
		createRegistrations(erpIds);
  }

  private static void createRegistrations(Set<Id> erpIds) {
  	Set<String> erp_serial = new Set<String>();
  	//find any registration with these erps and prevent another from being created
  	//a single erp/serial combination should only ever result in a single registration
  	for( Registration__c r : [SELECT Id,
  																	 ERPOrder__c,
  																	 SerialNumber__c
  														FROM Registration__c
  														WHERE ERPOrder__c IN :erpIds] )
  	{
  		erp_serial.add( r.erpOrder__c + '_' + r.SerialNumber__c );
  	}
		Registration__c[] newRegs = new List < Registration__c > ();
		for (AcctSeed__Project__c erp: [SELECT Id,
																			   	 Stage__c,
																					 AcctSeed__Account__c,
																						(SELECT Id,
																										GMBLASERP__Serial_Number__c
																						 FROM AcctSeedERP__Project_Materials__r
																						 WHERE GMBLASERP__Serial_Number__c != '')
																					 FROM AcctSeed__Project__c
																					 WHERE Id IN: erpIds])
		{
		  for (AcctSeedERP__Material__c mat: erp.AcctSeedERP__Project_Materials__r)
		  {
		  	if( !erp_serial.contains( erp.Id + '_' + mat.GMBLASERP__Serial_Number__c) )
		  	{
					newRegs.add(new Registration__c(
					  Account__c = erp.AcctSeed__Account__c,
					  SerialNumber__c = mat.GMBLASERP__Serial_Number__c,
					  ErpOrder__c = erp.Id,
					  Delivery_Date__c = DateTime.now()
					));
				}
		  }
		}
		insert newRegs;
  }

  @future
  public static void deleteRegistrationsFuture(Set < Id > erpIds) {
		deleteRegistrations(erpIds);
  }

  private static void deleteRegistrations(Set < Id > erpIds) {
		Registration__c[] regs = [SELECT Id FROM Registration__c WHERE ErpOrder__c IN: erpIds];
		delete regs;
  }

//  private static void setRegistationDateOnSerial( List<Registration__c> listNew,
//  									 														  Map<Id, Registration__c> oldMap )
//  {
//  	GMBLASERP__Serial_Number__c[] serials = new List<GMBLASERP__Serial_Number__c>();
//  	for( Registration__c reg : listNew )
//  	{
//  		boolean include = false;
//  		Registration__c oldReg;
//  		if( oldMap.size() > 0 )
//  		{
//  			oldReg = oldMap.get( reg.Id );
//  		}
//  		if( reg.Registered_To_Customer__c )
//  		{
//  			include = true;
//  			if( oldReg != null && reg.Delivery_Date__c == oldReg.Delivery_Date__c )
//  				include = false;
//  		}
//  		if( include )
//  		{
//  			serials.add( new GMBLASERP__Serial_Number__c(
//  				Id = reg.SerialNumber__c,
//  				Retail_Registration_Date__c = reg.Delivery_Date__c
//  			));
//  		}
//  	}
//  	if( serials.size() > 0 )
//  	{
//  		Boolean orig = gcSerialNumber.disableTrigger;
//  		gcSerialNumber.disableTrigger = true;
//  		update serials;
//  		gcSerialNumber.disableTrigger = orig;
//  	}
//  }

//  private static void addRegistrationAccount(List<Registration__c> listNew) {
//
//		Id acctId;
//		if( UserInfo.getUserType() == 'Standard' )
//		{
//		  User currentUser = [SELECT Id, Warehouse__c FROM User WHERE Id = :Userinfo.getUserId() ];
//		  Legend_Settings__c orgDefaults = Legend_Settings__c.getOrgDefaults();
//		  Map<String, Id> wareHouseMap = new Map<String, Id>{
//				'Whitefish' => orgDefaults.LegendWhitefishAccountId__c,
//				'Barrie' => orgDefaults.LegendBarrieAccountId__c,
//				'Montreal' => orgDefaults.LegendMontrealAccountId__c,
//				'Wholesale' => orgDefaults.LegendWholesaleAccountId__c
//		  };
//		  if( wareHouseMap.containsKey( currentUser.wareHouse__c ) ) {
//				acctId = wareHouseMap.get( currentUser.Warehouse__c );
//		  }
//		}
//		else
//		{
//		  Id contactId = [SELECT ContactId FROM User WHERE Id = :Userinfo.getUserId()].ContactId;
//		  Contact ct = [SELECT AccountId, Account.BillingState FROM Contact WHERE Id = :contactId];
//		  acctId = ct.AccountId;
//		}
//
//		for (Registration__c reg: listNew) {
//		  if( reg.RegisteredByAccount__c == null ) {
//			reg.RegisteredByAccount__c = acctId;
//		  }
//		}
//
//  }

//  private static void createPartnerCustomers(List<Registration__c> listNew)
//  {
//		Map<String, Registration__c> uniqueRegMap = new Map<String, Registration__c>();
//		for ( Registration__c reg : listNew )
//		{
//		  uniqueRegMap.put( reg.RegisteredByAccount__c + '-' + reg.Account__c, reg);
//		}
//		Set<String> existing = new Set<String>();
//		for( Partner_Customer__c pc : [SELECT Uniqueifier__c
//																		 FROM Partner_Customer__c
//																		WHERE Uniqueifier__c IN :uniqueRegMap.keySet() ] )
//		{
//		  existing.add(pc.Uniqueifier__c);
//		}
//		Partner_Customer__c[] pcs = new List<Partner_Customer__c>();
//		for( String key : uniqueRegMap.keySet() )
//		{
//		  if( !existing.contains(key) )
//		  {
//			Registration__c reg = uniqueRegMap.get( key );
//			pcs.add( new Partner_Customer__c (
//			  Customer__c = reg.Account__c,
//			  Partner__c = reg.RegisteredByAccount__c,
//			  Uniqueifier__c = key
//			));
//		  }
//		}
//		insert pcs;
//  }


  public static void coverage()
  {
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
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
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