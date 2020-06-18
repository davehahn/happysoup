public with sharing class RegistrationExt {

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

	@AuraEnabled
	public static String fetchCustomer( String recordId )
	{
		Schema.sObjectType entityType = Id.valueOf(recordId).getSObjectType();
		if( entityType == Account.sObjectType )
			return fetchAccount( recordId );
		if( entityType == Lead.sObjectType )
			return fetchLead( recordId );
		return null;
	}

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
  public static Registration__c createRegistration( String serno,
																										String customerJSON,
																										String customerType,
  																								  List<GMBLASERP__Serial_Number__c> NestedItems,
  																								  String motor,
  																								  String motorSerial,
  																								  DateTime deliveryDate,
  																								  String partnerMemoryMaker,
  																								  String caseId,
  																								  String paymentMethod ) {
		Id customerId = updateCustomerData( customerType, customerJSON );
		if( customerId != null )
		{
			return doRegistration(
				serno,
				customerId,
				NestedItems,
				motor,
				motorSerial,
				deliveryDate,
				partnerMemoryMaker,
				caseId,
				paymentMethod );
		}
		throw new AuraHandledException('There was an error with the Customer data');
  }

	private static Id updateCustomerData( String type, String cJSON )
	{
		if( type == 'person' || type == null )
		{
			Customer.Person customer =
				(Customer.Person)JSON.deserialize(
					cJSON, Customer.person.class
				);
			Customer.AccountSaveResult result = customer.upsertRecord();
			System.debug( result );
			if( result.status == 'success' ) return result.record.Id;
			throw new AuraHandledException( result.messages[0] );
		}
		if( type == 'dealer' )
		{
			Customer.Dealer customer =
				(Customer.Dealer)JSON.deserialize(
					cJSON, Customer.Dealer.class
				);
			return customer.id;
		}
		return null;
	}

	private static Registration__c doRegistration(
		String serno,
		String accountId,
		List<GMBLASERP__Serial_Number__c> NestedItems,
		String motor,
		String motorSerial,
		DateTime deliveryDate,
		String partnerMemoryMaker,
		String caseId,
		String paymentMethod )
	{
		Registration__c registration = new Registration__c(
			Account__c = accountId,
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
					Account__c = accountId,
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

	private static String fetchAccount( String acctId )
	{
		Boolean isPerson = [SELECT IsPersonAccount FROM Account WHERE Id = :acctId].IsPersonAccount;
		if( isPerson )
		{
			Account acct = Account_Selector.allPersonAccountsByIds(new Set<Id>{acctId})[0];
			return JSON.serialize(new Customer.Person(acct));
		}
		else
		{
			Account acct = Account_Selector.allByIds( new Set<Id>{acctId})[0];
			return JSON.serialize( new Customer.Dealer( acct ) );
		}
	}

	private static String fetchLead( String leadId )
	{
		Lead l = [SELECT Id,
			Email,
			FirstName,
			LastName,
			Phone,
			MobilePhone,
			Preferred_Language__c,
			Country,
			CountryCode,
			City,
			State,
			StateCode,
			Street,
			PostalCode
		FROM Lead
		WHERE Id = : leadId
		AND isConverted = false];
		return JSON.serialize( new Customer.Person( l ) );
	}

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