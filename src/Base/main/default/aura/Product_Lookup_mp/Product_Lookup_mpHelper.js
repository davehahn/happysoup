({
	getProducts : function(component, event) {
		console.log('getProducts');
		var self = this,
				query = component.get('v.query'),
				combobox 	= component.find('name_combobox'),
				action = component.get('c.findProductsAndPrice'), la;
  console.log( 'USERTYPE = ' + component.get('v.actAsUserType') );
		action.setParams({
			"query" : query,
      "userType": component.get('v.actAsUserType')
		});
    if( query === undefined || query === null || query.length === 0 )
    {
      component.set('v.products', '');
      component.set('v.selectionId', null);
      self.toggle(combobox, 'close');
      return;
    }
		la = new LightningApex( this, action );
    la.fire()
    .then(
      $A.getCallback( function( data ) {
      	console.log(data);
      	console.log(data.length);
      	try {
					if (data.length > 0) {
						console.log(data);
						component.set("v.products", data);
						self.toggle(combobox, 'open');
					} else {
						console.log("error: no data");
						component.set("v.products", '');
						self.toggle(combobox, 'close');
					}
				} catch(e) {
					console.log("error:null");
					component.set("v.products", '');
					self.toggle(combobox, 'close');
				}
      }),
      $A.getCallback( function( err ) {
      	console.log('err');
        LightningUtils.errorToast( err );
      })
    );
	},

	toggle : function(element, action) {
		console.log('toggle');
		if (action == 'open') {
			$A.util.removeClass(element, 'slds-is-closed');
			$A.util.addClass(element, 'slds-is-open');
		} else if (action == 'close') {
			$A.util.removeClass(element, 'slds-is-open');
			$A.util.addClass(element, 'slds-is-closed');
		}
	}
})