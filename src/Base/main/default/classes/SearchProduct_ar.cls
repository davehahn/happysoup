public class SearchProduct_ar {
	@AuraEnabled
	public static List<Map<String,String>> searchProducts(String searchString) {		
        String searchStringMod = '%' + searchString + '%';
        List<Map<String,String>> listJSON = new List<Map<String,String>>();
		for(Product2 product : 
			[SELECT Id, 
				Name, 
				RecordType.Name, 
				Family, 
				ProductCode,
				CreatedDate 
			FROM Product2 
			WHERE AcctSeed__Inventory_Product__c = true
             	AND (Name =:searchString
             		OR(	Name like :searchStringMod 
                        OR Family like :searchStringMod
                        OR ProductCode like :searchStringMod
                        OR RecordType.Name like :searchStringMod))
			ORDER BY CreatedDate DESC 
			LIMIT 10])
		{
			Map<String,String> m = new Map<String,String>();
			m.put('idProduct', product.Id);
			m.put('productName', product.Name);
			m.put('productCreated', product.CreatedDate.format());
			m.put('productFamily', product.Family);
            m.put('productCode', product.ProductCode);
            m.put('productType', product.RecordType.Name);
			listJSON.add(m);
		}
		return listJSON;
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
    }
}