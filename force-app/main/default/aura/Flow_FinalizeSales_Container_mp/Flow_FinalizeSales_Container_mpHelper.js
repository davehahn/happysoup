({
	getPricebooks : function(component)
	{
		console.log('getPricebooks');
		var self = this,
				action = component.get('c.getPricebooks'), la;
		return new Promise( function( resolve, reject )
			{
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						component.set('v.pricebooks', result);
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	},

	getErpPricebook : function(component)
	{
		console.log('getErp');
		var self = this,
				erpId = component.get('v.recordId'),
				action = component.get('c.getERP'), la;
		return new Promise( function( resolve, reject )
			{
				action.setParams({
					"erpId" : erpId
				});
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( erp ) {
						component.set('v.selectedPricebook', erp.GMBLASERP__Pricebook__c);
						resolve(erp);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	}
})