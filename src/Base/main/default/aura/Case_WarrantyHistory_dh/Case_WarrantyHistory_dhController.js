({
	doInit : function(component, event, helper) {
    helper.fetchHistory( component )
    .then(
      $A.getCallback( function(result) {
        console.log( result );
        if( result )
          component.set('v.historyRecords', result);
      }),
      $A.getCallback( function( err ) {
        alert( err );
      })
    );
	},

  viewCase: function(component, event, helper )
  {
    var recordId = event.currentTarget.dataset.recordId,
        nav = $A.get("e.force:navigateToSObject");
    nav.setParams({
      recordId: recordId
    })
    .fire();
  }
})