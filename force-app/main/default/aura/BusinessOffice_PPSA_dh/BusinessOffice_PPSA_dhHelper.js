({
  initialize: function( component )
  {
    this.initData( component )
    .then(
      $A.getCallback( function( result ) {
        console.log( result );
        component.set('v.loading', false);
        component.set('v.pricebookEntryId', result.pricebookEntryId );
        component.set('v.ppsa_id', result.ppsa_id );
        component.set('v.ppsa_value', result.ppsa_value );
      }),
      $A.getCallback( function( err ) {
        LightningUtils.showToast('error', 'An error has been encountered', err );
      })
    );
  },

	initData : function( component )
  {
    var action = component.get('c.ppsa_init'), la;
    action.setParams({
      recordId: component.get('v.recordId'),
      pricebookId: component.get('v.pricebookId')
    });

    la = new LightningApex( this, action );
    return la.fire();
	},

  savePPSA: function( component )
  {
    var action = component.get('c.savePPSALine'),
        params = {
          lineId: component.get('v.ppsa_id'),
          value: component.get('v.ppsa_value'),
          parentId: component.get('v.recordId'),
          pricebookEntryId: component.get('v.pricebookEntryId')
        }, la;

    console.log( params );
    action.setParams( params );

    la = new LightningApex( this, action );
    return la.fire();
  },

  showToast : function(state, title, message) {
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
        "title": title,
        "message": message,
        type: state
    });
    toastEvent.fire();
  }
})