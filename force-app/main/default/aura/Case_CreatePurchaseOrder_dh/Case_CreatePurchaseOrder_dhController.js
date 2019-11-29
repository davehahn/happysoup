({
  doInit: function( component, event, helper )
  {
    component.set('v.modalOpen', false);
    component.set('v.currentStep', 1);
    component.set('v.vendorEmpty', false);
  },

  afterScripts: function( component, event, helper )
  {
    helper.checkForPartsRequiringOrdering( component )
    .then(
      $A.getCallback( function( result ) {
        if( result > 0 )
          component.set('v.cmpLoaded', true );
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    );
  },

  handleStepChange: function( component, event, helper )
  {
    var step = component.get('v.currentStep');
    if( step === 1 )
    {
      component.set('v.title', helper.titles.stepOne);
      component.set('v.vendorPartsSelection', null );
    }
    if( step === 2 )
    {
      component.set('v.title', helper.titles.stepTwo);
    }
  },

  handleInitializePo: function( component, event, helper )
  {
    helper.initNewPO( component)
    .then(
      $A.getCallback( function( result ){
        console.log( result );
        if( Object.keys( result ).indexOf('vendors') >= 0 )
        {
          console.log( JSON.parse(result.vendors) )
          component.set('v.vendorParts', JSON.parse(result.vendors) );
        }
        if( Object.keys( result ).indexOf('userWarehouse') >= 0 )
          component.set('v.userWarehouse', result.userWarehouse );

        component.set('v.modalOpen', true);
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    );
  },

  handleVendorPartsSelected: function( component, event, helper )
  {
    var params = event.getParams();
    console.log( JSON.parse( JSON.stringify(params) ) );
    component.set('v.vendorPartsSelection', params );
    if( params.vendorId === null )
      component.set('v.vendorEmpty', true);
    component.set('v.currentStep', 2);
  },

  handleBack: function( component )
  {
    component.set('v.currentStep', 1);
  },

  handleSubmit: function( component )
  {
    component.find('spinner').toggle();
    component.find('po-form').submit();
  },

	handlePO_Success: function( component, event, helper )
  {
    console.log( JSON.parse( JSON.stringify( event.getParams() ) ) );
    var response = event.getParam('response');

    helper.shouldSetDefaultVendor( component )
    .then(
      $A.getCallback( function(result ) {
        return helper.createPOlinesAndUpdateCase( component, response.id, result )
      })
    )
    .then(
      $A.getCallback( function( result ) {
        helper.poSuccessHandler( component );
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
      component.find('spinner').toggle();
    }))
	},

  openModal: function(component, event, helper)
  {
    component.set('v.modalOpen', true);
  },

  closeModal: function(component, event, helper)
  {
    $A.get('e.force:refreshView').fire();
  }
})