({
	afterScripts : function(component, event, helper)
  {
    helper.fetchRecords( component )
    .then(
      $A.getCallback( function( result ) {
        console.log( result );
        component.set('v.tasks', result );
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    );
	}
})