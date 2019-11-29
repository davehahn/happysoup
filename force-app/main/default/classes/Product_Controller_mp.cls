public with sharing class Product_Controller_mp {

	private static final Id retailPbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
	private static final Id partnerPbId = Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c;
	private static final Set<Id> pricebooks = new Set<Id>{ retailPbId, partnerPbId };

	public class PricedProduct {
		public String Id { get; set; }
		public String Name { get; set; }
		public String Default_Image_Thumb { get; set; }
		public String ProductCode { get; set; }
		public String Description { get; set; }
		public Decimal retailPrice { get; set; }
		public Decimal partnerPrice { get; set; }

		public PricedProduct( Product2 p)
		{
			this.Id = p.Id;
			this.Name = p.Name;
			this.Default_Image_Thumb = p.Default_Image_Thumb__c;
			this.ProductCode = p.ProductCode;
			this.Description = p.Description;
		}
	}

	//@AuraEnabled
	//public static String findProducts(String query) {
	//	if (query.length() > 0) {
	//		query = '%' + query + '%';
	//	}

	//	List<Product2> products = [Select Id, Name, Default_Image_Thumb__c, ProductCode, Description FROM Product2 WHERE Name LIKE :query LIMIT 10];
	//	return JSON.serialize(products);
	//}

	@AuraEnabled
	public static String findProductsAndPrice(String query, String userType) {
		Set<String> validUserTypes = new Set<String>{'Standard', 'PowerPartner'};
		if( userType == null )
			userType = UserInfo.getUserType();
		if( !validUserTypes.contains(userType) )
			throw new AuraHandledException('Invalid user type specified during Product_Lookup_mp instantiation');

		String productsJSON;
		switch on userType
		{
			when 'Standard'
			{
				productsJSON = findForInternal( query );
			}
			when 'PowerPartner'
			{
				productsJSON = findForPartner( query );
			}
		}
		return productsJSON;
	}

	private static Map<Id, Product2> findProducts( String query )
	{
		if (query.length() > 0) {
			query = '%' + query + '%';
		}
		return new Map<Id, Product2>([SELECT Id,
																				 Name,
																				 Default_Image_Thumb__c,
																				 ProductCode,
																				 Description
																	FROM Product2
																	WHERE ( Name LIKE :query
																					OR ProductCode LIKE :query
																					OR Description LIKE :query )
																	AND isActive = true
																	LIMIT 100 ]);
	}

	private static Map<Id, Map<Id, Decimal>> findPrices( Set<Id> prodIds )
	{
		Map<Id, Map<Id, Decimal>> result = new Map<Id, Map<Id, Decimal>>();
		for( PricebookEntry pbe : [SELECT Id,
																			Pricebook2Id,
																			Product2Id,
																			UnitPrice
															 FROM PricebookEntry
															 WHERE Product2Id IN :prodIds
															 AND Pricebook2Id IN :pricebooks] )
		{
			if( !result.containsKey( pbe.Product2Id ) )
				result.put( pbe.Product2Id, new Map<Id, Decimal>() );
			result.get(pbe.Product2Id).put(pbe.Pricebook2Id, pbe.UnitPrice );
		}
		return result;
	}

	private static String findForInternal( String query )
	{
		Map<Id, Product2> prods = findProducts( query );
		Map<Id, Map<Id, Decimal>> prices = findPrices( prods.keySet() );
		PricedProduct[] result = new List<PricedProduct>();

		for( Id prodId : prods.keySet() )
		{
			if( prices.containsKey(prodId ) )
			{
				Map<Id, Decimal> priceMap = prices.get( prodId );
				if( priceMap.containsKey( retailPbId) )
				{
					PricedProduct pp = new PricedProduct( prods.get(prodId) );
					pp.retailPrice = priceMap.get( retailPbId );
					if( priceMap.containsKey( partnerPbId ) )
						pp.partnerPrice = priceMap.get( partnerPbId );
					result.add( pp );
				}
			}
		}
		return JSON.serialize( result );
	}

	private static String findForPartner( String query )
	{
		Map<Id, Product2> prods = findProducts( query );
		Map<Id, Map<Id, Decimal>> prices = findPrices( prods.keySet() );
		PricedProduct[] result = new List<PricedProduct>();

		for( Id prodId : prods.keySet() )
		{
			if( prices.containsKey(prodId ) )
			{
				Map<Id, Decimal> priceMap = prices.get( prodId );
				if( priceMap.containsKey( partnerPbId) )
				{
					PricedProduct pp = new PricedProduct( prods.get(prodId) );
					pp.partnerPrice = priceMap.get( partnerPbId );
					if( priceMap.containsKey( retailPbId ) )
						pp.retailPrice = priceMap.get( retailPbId );
					result.add( pp );
				}
			}
		}
		return JSON.serialize( result );
	}

	@AuraEnabled
	public static Product2 getProduct(Id productId) {
		Product2 product = [Select Id, Name FROM Product2 WHERE Id = :productId];

		return product;
	}
}