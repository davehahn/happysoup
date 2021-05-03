({
  initialize: function( component )
  {
    var recordId = component.get('v.recordId'),
        action = component.get('c.getAvailablePackages'), la;

    action.setParams({
      "recordId" : recordId
    });

    la = new LightningApex( this, action );
    la.fire()
    .then(
      $A.getCallback( function(result) {
        component.set('v.loading', false);
        component.set('v.originalSelectedLineIds', result.selectedLineIds );
        component.set('v.packages', result.packages);
        component.set('v.changed', false);
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    );
  }
})