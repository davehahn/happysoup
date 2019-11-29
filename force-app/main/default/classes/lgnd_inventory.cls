public with sharing class lgnd_inventory {

	/* ------------
		 	Wrappers
	------------ */

	public List<wrapProduct> wrapProductList {get; set;}
	public List<Registration__c> selectedRegistrations {get; set;}

	public class wrapProduct implements Comparable {
    public Registration__c reg {get; set;}
    public String orderField {get; set;}
    public String orderDir {get; set;}
    public Integer pageCount {get; set;}
    public Integer recordCount {get; set;}
    public List<wrapProduct> nestedItems {get; set;}

    public wrapProduct(Registration__c r, String o, String d, List<wrapProduct> n) {
    	reg = r;
    	orderField = o;
    	orderDir = d;
    	nestedItems = n;
    }

    public Integer compareTo(Object compareTo) {
    	wrapProduct wrapProduct = (wrapProduct)compareTo;
    	Integer returnValue = 0;

    	if (orderField == 'SerialNumber__c') {
    		if (reg.SerialNumber__r.Name > wrapProduct.reg.SerialNumber__r.Name) {
	    		returnValue = (orderDir == 'ASC') ? 1 : -1 ;
	    	} else if (reg.SerialNumber__r.Name < wrapProduct.reg.SerialNumber__r.Name) {
	    		returnValue = (orderDir == 'ASC') ? -1 : 1 ;
	    	}
    	}

    	if (orderField == 'Product_Record_Type__c') {
    		if (reg.SerialNumber__r.Product_Record_Type__c > wrapProduct.reg.SerialNumber__r.Product_Record_Type__c) {
	    		returnValue = (orderDir == 'ASC') ? 1 : -1 ;
	    	} else if (reg.SerialNumber__r.Product_Record_Type__c < wrapProduct.reg.SerialNumber__r.Product_Record_Type__c) {
	    		returnValue = (orderDir == 'ASC') ? -1 : 1 ;
	    	}
    	}

    	if (orderField == 'Product_Name__c') {
    		if (reg.SerialNumber__r.Product_Name__c > wrapProduct.reg.SerialNumber__r.Product_Name__c) {
	    		returnValue = (orderDir == 'ASC') ? 1 : -1 ;
	    	} else if (reg.SerialNumber__r.Product_Name__c < wrapProduct.reg.SerialNumber__r.Product_Name__c) {
	    		returnValue = (orderDir == 'ASC') ? -1 : 1 ;
	    	}
    	}

    	if (orderField == 'Location__c') {
    		if (reg.SerialNumber__r.Location__c > wrapProduct.reg.SerialNumber__r.Location__c) {
	    		returnValue = (orderDir == 'ASC') ? 1 : -1 ;
	    	} else if (reg.SerialNumber__r.Location__c < wrapProduct.reg.SerialNumber__r.Location__c) {
	    		returnValue = (orderDir == 'ASC') ? -1 : 1 ;
	    	}
    	}

    	return returnValue;
    }
  }

	/* -----------------
			Registrations
	----------------- */

	@AuraEnabled
	public static String getDetailedRegistrations(String orderField,
                                                String orderDir,
                                                Integer perPage,
                                                Integer pageNum,
                                                String filter,
                                                String sernoFilter) {

		List<wrapProduct> Nests = new List<wrapProduct>();
		List<wrapProduct> AllProducts = new List<wrapProduct>();

    Id accountId;

    Integer startingPoint = (Integer.valueOf(pageNum) - 1) * (Integer.valueOf(perPage));
		Integer endingPoint = startingPoint + (Integer.valueOf(perPage));

    try {
      accountId = [SELECT AccountId FROM User WHERE Id = :Userinfo.getUserId()].AccountId;
    }
    catch( Exception e ){
    	System.debug(e);
    }

    if (sernoFilter == null) {
    	sernoFilter = '%';
  	} else {
    	sernoFilter = '%' + sernoFilter + '%';
    }

    System.debug(sernoFilter);

		for (Registration__c reg : [SELECT Account__r.Name, 
																			 Account__r.Id, 
																			 Account__r.Type,
																			 ErpOrder__c,
																			 Id,
																			 isCurrent__c,
																			 Name,
																			 ProductMake__c,
																			 CreatedDate,
																			 SerialNumber__r.Id,
																			 SerialNumber__r.Name,
																			 SerialNumber__r.Product_Name__c,
																			 SerialNumber__r.Description__c,
																			 SerialNumber__r.Status__c,
																			 SerialNumber__r.GMBLASERP__Lot__c,
																			 SerialNumber__r.GMBLASERP__Lot__r.Name,
																			 SerialNumber__r.Product_Record_Type__c,
																			 SerialNumber__r.Location__c,
																			 SerialNumber__r.OwnerId,
																			 SerialNumber__r.GMBLASERP__Product__c,
																			 SerialNumber__r.GMBLASERP__Product__r.Name,
																			 SerialNumber__r.GMBLASERP__Product__r.Can_be_Nest__c,
																			 SerialNumber__r.GMBLASERP__Product__r.Can_be_Nested__c,
																			 SerialNumber__r.GMBLASERP__Product__r.Id,
																			 SerialNumber__r.Nest__c,
																			 SerialNumber__r.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name
																FROM Registration__c
																WHERE Account__c = :accountId
																And isCurrent__c = true
																And (SerialNumber__r.Name LIKE :sernoFilter OR SerialNumber__r.Product_Name__c LIKE :sernoFilter) 
																]) {

			String serno = String.valueOf(reg.get('SerialNumber__c'));

			List<wrapProduct> nestedItems;

			if (filter == 'All' || filter == reg.SerialNumber__r.Product_Record_Type__c) {
				AllProducts.add(new wrapProduct(reg, orderField, orderDir, nestedItems));
				if (reg.SerialNumber__r.Nest__c == null) {
					Nests.add(new wrapProduct(reg, orderField, orderDir, nestedItems));
				}
			}
		}

		Nests.sort();
		AllProducts.sort();

		// Nesting
		for (wrapProduct nest : Nests) {
			nest.nestedItems = new List<wrapProduct>();
			for (wrapProduct item : AllProducts) {
				if (nest.reg.SerialNumber__r.Id == item.reg.SerialNumber__r.Nest__c) {
					nest.nestedItems.add(item);
				}
			}
		}

		if (Nests.size() < Integer.valueOf(endingPoint)) {
			endingPoint = Integer.valueOf(Nests.size());
		}

		List<wrapProduct> ProductListSubset = new List<wrapProduct>();

		for (Integer i = startingPoint; i < endingPoint; i++) {
			ProductListSubset.add(Nests[i]);
		}

		Integer aa = Integer.valueOf( Nests.size() );
    Integer bb = Integer.valueOf( perPage );
    Integer pageCount = aa / bb;
    if( Math.mod( aa, bb) > 0 )
      pageCount++;

		ProductListSubset[0].pageCount = pageCount;

		ProductListSubset[0].recordCount = Nests.size();

		return JSON.serialize(ProductListSubset);
	}

	@AuraEnabled
  public static String getAccountRegistrations (String recordId) {
    List<wrapProduct> ProductList = new List<wrapProduct>();

    List<wrapProduct> nestedItems;

		for (Registration__c reg : [SELECT 	Account__c,
																				ErpOrder__c,
																				Id,
																				isCurrent__c,
																				Name,
																				ProductMake__c,
																				SerialNumber__c,
																				SerialNumber__r.Id,
																				SerialNumber__r.Name,
																				SerialNumber__r.Product_Name__c,
																				SerialNumber__r.Description__c,
																				SerialNumber__r.Status__c,
																				SerialNumber__r.GMBLASERP__Lot__c,
																				SerialNumber__r.GMBLASERP__Lot__r.Name,
																				SerialNumber__r.Product_Record_Type__c,
																				SerialNumber__r.Location__c,
																				SerialNumber__r.OwnerId,
																				SerialNumber__r.GMBLASERP__Product__c,
																				SerialNumber__r.Nest__c,
																				CreatedDate
																FROM Registration__c
																WHERE Account__c = :recordId And isCurrent__c = true]) {

			String serno = String.valueOf(reg.get('SerialNumber__c'));

			ProductList.add(new wrapProduct(reg, 'SerialNumber__c', 'ASC', nestedItems));
		}

		return JSON.serialize(ProductList);
  }

	/* -----------------
			User Info
	----------------- */

	@AuraEnabled
	public static String getUserId() {
		return userinfo.getUserId();
	}

}