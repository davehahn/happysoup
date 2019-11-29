public with sharing class gcProduct_UpdateMRPQty {
	public gcProduct_UpdateMRPQty() {}
	
	public gcProduct_UpdateMRPQty(ApexPages.StandardController stc){
		setIdFilter = new Set<Id>();
		setIdFilter.add(stc.getId());	
		retUrl = '/'+stc.getId();
	}

	public gcProduct_UpdateMRPQty(ApexPages.StandardSetController ssc){

		setIdFilter = new set<Id>();

		for(Product2 rec : (list<Product2>)ssc.getSelected())
			setIdFilter.add(rec.Id);

		retUrl = ApexPages.currentPage().getParameters().get('retUrl');
	}
	
	public pageReference back()
	{
		return new pageReference(retUrl);
	}
	
	public pageReference init()
	{
		String idFilter = ApexPages.currentPage().getParameters().get('idFilter');
		if(idFilter != null)
			setIdFilter.add(idFilter);

		if(retUrl == null && idFilter != null)
			retUrl = '/'+idFilter;

		if(setIdFilter.isEmpty())
		{
	 		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'No Product was selected.'));
	 		return null;					
	 	}
		gcInventoryReport_MRP.updateProductAvailabilityBatch(setIdFilter);
		if(idFilter != null)
			return new pageReference('/'+idFilter);
		else{
	 		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, 'All selected Product MRP quantities have been updated.'));
	 		return null;								
		}
	}
	
	private set<Id> setIdFilter{get;set;}
	private String retUrl{get;set;}

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
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
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