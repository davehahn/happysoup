({
	doInit :function(component, event, helper)
  {
    helper.initialize( component );
	},

  handleOptionChange: function( component, event, helper )
  {
    component.set('v.changed', true);
  },

  doSave: function( component, event, helper )
  {
    component.set('v.loading', true);
    helper.doSave( component )
    .then(
      $A.getCallback( function() {
        $A.get('e.force:refreshView').fire();
      }),
      $A.getCallback( function( err ) {
        component.set('v.loading', false);
        LightningUtils.errorToast( err );
      })
    )
  }
})