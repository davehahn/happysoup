public class lgnd_serno_search {
	@AuraEnabled
	public static List<GMBLASERP__Serial_Number__c> findBySerialNumber(String serno, String context, String retrictToThisProduct) {
		String query = serno + '%';

    Id accountId;
    try {
      accountId = [SELECT AccountId FROM User WHERE Id = :Userinfo.getUserId()].AccountId;
    }
    catch( Exception e ){}

		List<GMBLASERP__Serial_Number__c> items;

		// Filter for context permissable serial numbers
		if (context == 'limited') {
			System.debug(context);
			List<GMBLASERP__Serial_Number__c> allowedItems = new List<GMBLASERP__Serial_Number__c>();

			String dbquery = 'SELECT Account__c,';
			dbquery += ' ErpOrder__c,';
			dbquery += ' Id,';
			dbquery += ' isCurrent__c,';
			dbquery += ' Name,';
			dbquery += ' ProductMake__c,';
			dbquery += ' SerialNumber__r.Id,';
			dbquery += ' SerialNumber__r.Name,';
			dbquery += ' SerialNumber__r.Product_Name__c,';
			dbquery += ' SerialNumber__r.Description__c,';
			dbquery += ' SerialNumber__r.Status__c,';
			dbquery += ' SerialNumber__r.GMBLASERP__Lot__c,';
			dbquery += ' SerialNumber__r.GMBLASERP__Lot__r.Name,';
			dbquery += ' SerialNumber__r.Product_Record_Type__c,';
			dbquery += ' SerialNumber__r.Location__c,';
			dbquery += ' SerialNumber__r.GMBLASERP__Product__c';
			dbquery += ' FROM Registration__c';
			dbquery += ' WHERE Account__c =  \'' + accountId +'\'';
			dbquery += ' AND SerialNumber__r.Name like \'' + query +'\'';
			dbquery += ' AND isCurrent__c = true';
			if (retrictToThisProduct != null) {
				dbquery += ' AND SerialNumber__r.GMBLASERP__Product__c = \'' + retrictToThisProduct +'\'';
			}
			System.debug( dbquery );
			Registration__c[] regs = Database.query( dbquery );
			for (Registration__c reg : regs) {

				System.debug(reg);

				if (reg.Account__c == accountId) {
					GMBLASERP__Serial_Number__c item = new GMBLASERP__Serial_Number__c(
																										Id 																			= reg.SerialNumber__r.Id,
																										Name 																		= reg.SerialNumber__r.Name,
																										Description__c 													= reg.SerialNumber__r.Description__c,
																										Status__c		 														= reg.SerialNumber__r.Status__c,
																										GMBLASERP__Lot__c 											= reg.SerialNumber__r.GMBLASERP__Lot__c,
																										GMBLASERP__Product__c 									= reg.SerialNumber__r.GMBLASERP__Product__c
																									);

					if (reg.SerialNumber__r.GMBLASERP__Lot__c != null && reg.SerialNumber__r.GMBLASERP__Lot__r.Name.length() == 4) {
						item.Description__c = reg.SerialNumber__r.GMBLASERP__Lot__r.Name + ' - ' + reg.SerialNumber__r.Product_Name__c;
					} else {
						item.Description__c = reg.SerialNumber__r.Product_Name__c;
					}

					allowedItems.add(item);
				}
			}
			items = allowedItems;
		} else {
			items = [	SELECT 	Id,
												Name,
												Product_Name__c,
												Description__c,
												Status__c,
												GMBLASERP__Lot__c,
												GMBLASERP__Lot__r.Name,
												Product_Record_Type__c,
												Location__c,
												GMBLASERP__Product__r.Can_be_Nest__c,
												GMBLASERP__Product__r.Can_be_Nested__c
								FROM GMBLASERP__Serial_Number__c
								WHERE Name like :query
								LIMIT 10];

			// Descriptions
			for (GMBLASERP__Serial_Number__c item: items) {
				if (!String.isBlank(item.Description__c)) {
					// Do nothing. Description__c has already been filled.
				} else if (item.GMBLASERP__Lot__c != null &&
									 item.GMBLASERP__Lot__r.Name.length() == 4) {
					item.Description__c = item.GMBLASERP__Lot__r.Name + ' - ' + item.Product_Name__c;
				} else {
					item.Description__c = item.Product_Name__c;
				}
			}
		}

		System.debug(items);

		return items;
	}

	@AuraEnabled
	public static List<GMBLASERP__Serial_Number__c> findBySerialId(String sernoId) {
		List<GMBLASERP__Serial_Number__c> item = [
							SELECT 	Id,
											Available__c,
											Name,
											Product_Name__c,
											Description__c,
											Status__c,
											GMBLASERP__Lot__c,
											GMBLASERP__Lot__r.Name,
											Product_Record_Type__c,
											Location__c,
											GMBLASERP__Product__r.Can_be_Nest__c,
											GMBLASERP__Product__r.Can_be_Nested__c,
											GMBLASERP__Product__r.Id,
											(SELECT Account__r.Name FROM Registrations__r WHERE isCurrent__c = true)
							FROM GMBLASERP__Serial_Number__c
							WHERE Id = :sernoId
							LIMIT 1];

		return item;
	}
}