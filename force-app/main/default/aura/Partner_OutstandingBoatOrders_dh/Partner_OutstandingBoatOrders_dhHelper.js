({
  checkPermission: function( component )
  {
    var action = component.get('c.checkPermission'), la;
    la = new LightningApex( this, action );
    return la.fire();
  },

	fetchNumbers : function( component )
  {
    var hasPerm = component.get('v.hasPermission');
    if( hasPerm === 'false' )
      return Promise.resolve(null);

    var action = component.get('c.fetchOutstandingNumbers'), la;
    la = new LightningApex( this, action );
    return la.fire();
	},

  loadDetailsModal: function( component, orderType )
  {
    var modalContainer = component.find('detailsModalContainer');
    modalContainer.set("v.body", []);
    $A.createComponent(
      "c:Partner_OutstandingOrdersDetails_dh",
      {
        orderType: orderType
      },
      function( modal, status, message)
      {
        if (status === "SUCCESS") {
          var body = modalContainer.get('v.body');
          body.push(modal);
          modalContainer.set("v.body", body);
        }
        else if (status === "INCOMPLETE") {
          LightningUtils.errorToast("No response from server or client is offline.")
        }
        else if (status === "ERROR") {
          LightningUtils.errorToast("Error: " + message);
        }
      }
    );
  }
})