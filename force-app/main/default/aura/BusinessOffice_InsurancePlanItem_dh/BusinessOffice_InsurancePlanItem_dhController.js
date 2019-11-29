({
  doInit: function( component, event, helper )
  {
    component.set('v.termOutOfRange', false);
    var li = component.get('v.lineItem');
    if( li !== undefined && li !== null)
    {
      component.set('v.isSelected', true);
      component.set('v.coverageType', li.coverage);
      component.set('v.unitPrice', li.unitPrice);
    }
  },

	afterScripts : function(component, event, helper)
  {
    helper.fetchPlanItem( component )
    .then(
      $A.getCallback( function( result ) {
        component.set('v.planItem', result);
        component.set('v.rates', result.Insurance_Rates__r.records );
        component.set('v.type', result.Family);
        helper.findCurrentRate( component );
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    );
	},

  handleSelected: function( component, event, helper )
  {
    component.set('v.hasChanged', true);
    var evt = component.getEvent('planItemChanged');
    evt.fire();
  },

  coverageChanged: function( component, event, helper )
  {
    helper.findCurrentRate( component );
    component.set('v.hasChanged', true);
    var evt = component.getEvent('planItemChanged');
    evt.fire();
  },

  handleTermChange: function( component, event, helper )
  {
    helper.findCurrentRate( component );
  }
})