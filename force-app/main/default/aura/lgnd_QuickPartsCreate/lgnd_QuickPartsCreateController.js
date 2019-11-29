({
	doInit : function(component, event, helper) {
    helper.toggleIndicator( component );
    helper.getInitOptions( component )
    .then(
      $A.getCallback( function( result ) {
        helper.resetForm( component );
        component.set('v.suppliers', result.suppliers);
        component.set('v.unitsOfMeasurmentOptions', result.unitsOfMeasure);
        if( component.get('v.familyOptions') !== undefined && component.get('v.familyOptions') !== null )
          component.set('v.familySelectOptions', component.get('v.familyOptions').split(';') );
        if( result.familyOptions !== undefined && result.familyOptions !== null )
          component.set('v.familySelectOptions', result.familyOptions );
        if( result.dataWrapper !== undefined && result.dataWrapper !== null )
        {
          component.set('v.part', result.dataWrapper.part );
          component.set('v.retailPrice', result.dataWrapper.retailPrice );
          component.set('v.partnerPrice', result.dataWrapper.partnerPrice );
        }
      }),
      $A.getCallback( function( err ) {
        $A.get("e.force:closeQuickAction").fire();
        LightningUtils.errorToast(err);
      })
    )
    .finally( $A.getCallback( function() {
      helper.toggleIndicator( component );
    }) );
	},

  goToNextStep: function( component, event, helper )
  {
    var step = component.get('v.currentStep'),
        next = step + 1,
        idString = 'required-step'+step;
    if( helper.isValid( component.find(idString) ) )
      component.set('v.currentStep', next);
  },

  goToPrevStep: function( component, event, helper )
  {
    var step = component.get('v.currentStep'),
        prev = step - 1;
    component.set('v.currentStep', prev);
  },

  submitPart: function( component, event, helper )
  {
    if( helper.isValid( component.find('required-step3') ) )
    {
      helper.toggleIndicator( component );
      helper.submitPart( component )
      .then(
        $A.getCallback( function( result ) {
          helper.createComplete( component, result );
        }),
        $A.getCallback( function( err ) {
          helper.toastMessage(component, 'error', err);
        })
      )
      .finally( $A.getCallback( function() {
        helper.toggleIndicator( component );
      }));
    }
  }

})