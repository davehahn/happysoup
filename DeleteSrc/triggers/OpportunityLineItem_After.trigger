/* TODO: DELETE ME */
trigger OpportunityLineItem_After on OpportunityLineItem (after insert, after update, after delete) {
	if(Legend_Settings__c.getOrgDefaults().TriggerEnable_OpportunityLineItem_After__c)
	{

	  //Set<String> oppIds = new Set<String>();
	  //Map<String, String> boatMap = new Map<String,String>();// {[oppId, Product2(BoatId)]}
	  //Decimal tempVal;

	  //if(Trigger.isDelete){
	  //  for(OpportunityLineItem oli : Trigger.old) {
	  //      if( !oppIds.contains(oli.OpportunityId) ){
	  //          oppIds.add(oli.OpportunityId);
	  //      }
	  //    }
	  //}
	  //else {

	  //  for(OpportunityLineItem oli : Trigger.new) {
   //     if( !oppIds.contains(oli.OpportunityId) ){
   //         oppIds.add(oli.OpportunityId);
   //     }
	  //  }

	  //}

	  //  List<Opportunity> opps = [SELECT Id, TaxableTotal_LineItems__c,
	  //                            (SELECT Id,TotalPrice, isTaxable__c, isInsurance__c,
	  //                              PricebookEntry.Product2.Family, PricebookEntry.Product2Id, PricebookEntry.Product2.RecordType.Name
	  //                              FROM OpportunityLineItems)
	  //                            FROM Opportunity
	  //                            WHERE Id IN :oppIds ];
	  //  for( Opportunity o : opps ){
   //     tempVal = 0;
   //     if( boatMap.containsKey(o.Id) )
   //     {
   //     	o.BoatId__c = boatMap.get(o.Id);
   //     }
   //     for( OpportunityLineItem li : o.OpportunityLineItems)
   //     {
   //     	if( li.PricebookEntry.Product2.RecordType.Name == 'Boat')
   //     	{
   //     		o.BoatId__c = li.PricebookEntry.Product2Id;
   //     	}
   //       if(li.isTaxable__c == true  && !li.isInsurance__c){
   //         tempVal += li.TotalPrice;
   //       }
   //       if(li.PricebookEntry.Product2.Family == 'Discount'){
   //         tempVal += li.TotalPrice;
   //       }
   //     }
   //     o.TaxableTotal_LineItems__c = tempVal;
	  //  }

	  //  update opps;
	}

}