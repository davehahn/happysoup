({
	afterScripts: function(component, event, helper)
  {
    helper.initialize( component );
	},

  savePPSA: function( component, event, helper )
  {
    component.set('v.loading', true );
    helper.savePPSA( component )
    .then(
      $A.getCallback( function( result ) {
        component.set('v.ppsa_id', result.ppsa_id );
        component.set('v.ppsa_value', result.ppsa_value );
        component.set('v.loading', false );
        LightningUtils.showToast('success', 'success', 'PPSA has been updated');
        $A.get('e.force:refreshView').fire();
      }),
      $A.getCallback( function( err ) {
        LightningUtils.showToast('error', 'An error has been encountered', err );
        helper.initialize( component );
      })
    );
  }
})