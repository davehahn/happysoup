({
  doInit: function( component, event, helper )
  {
    component.set('v.pricebook', {'sobjectType': 'Pricebook2'} );
  },

	afterScripts : function(component, event, helper)
  {
    component.set('v.scriptsLoaded', true);
	},

  openModal: function( component, event, helper )
  {
    helper.fetchPricebook( component )
    .then(
      $A.getCallback( function( result ) {
        console.log( result );
        component.set('v.origPricebookName', result.Name );
        component.set('v.modalOpen', true);
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    );
  },

  closeModal: function( component, event, helper )
  {
    helper.closeModal( component );
  },

  doClone: function( component, event, helper )
  {
    var spinner = component.find('spinner');
    spinner.toggle();
    helper.doClone( component )
    .then(
      $A.getCallback( function(result) {
        helper.successToastMessage( component );
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": result.Id
        });
        navEvt.fire();
        helper.closeModal( component );
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
      spinner.toggle();
    }));
  }
})