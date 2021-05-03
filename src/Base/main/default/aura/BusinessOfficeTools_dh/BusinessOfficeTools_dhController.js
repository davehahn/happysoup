({
	doInit :function(component, event, helper)
  {
    helper.doInit( component )
    .then(
      $A.getCallback( function( result ) {
        console.log( result );
        component.set('v.pricebookId', result.Id);
        component.set('v.pricebookName', result.Name);
        component.set('v.sObjectType', result.sObjectType );
        component.set('v.canViewInsuranceDocs', result.documentsAccessible);
        component.set('v.loading', false);
      }),
      $A.getCallback( function( err ) {
        LightningUtils.showToast('error', 'We have encountered an error', err);
      })
    );
	},

  reInitInsurance: function( component, event, helper )
  {
    var fiCmp = component.find('fi_CMP');
    fiCmp.reInit();
  },

  reInitInsuranceDocs: function( component, event, helper )
  {
    var insDocsCmp = component.find('insurDocs_CMP');
    insDocsCmp.reInit();
  }
})