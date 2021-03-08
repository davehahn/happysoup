({
  doInit: function( component )
  {
    var steps = [
      'Select Parts',
      'Add Notes'
    ];
    component.set('v.steps', steps);
    component.set('v.currentStep', steps[0]);
  },

	afterScripts : function(component, event, helper)
  {
    helper.getInitData(component)
    .then(
      $A.getCallback( function(result) {
        console.log( JSON.parse(JSON.stringify(result)));
        if( Object.keys(result).indexOf('erp') >= 0 )
        {
          component.set('v.stage', JSON.parse(result.erp).Stage__c );
        }
        if( Object.keys(result).indexOf('canCreate') >= 0 )
        {
          component.set('v.canCreate', result.canCreate === 'true' );
        }
        if( Object.keys(result).indexOf('cases') >= 0 )
        {
          var cases = JSON.parse( result.cases );
          console.log( cases );
          component.set('v.caseWrappers', cases );
          component.set('v.hasCases', true );
          component.set('v.hasMultipleCases', cases.length > 1 );
        }
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    );
	},

  openModel: function(component, event, helper )
  {
    var spinner = component.find('spinner');
    spinner.toggle();
    helper.getMaterials( component )
    .then(
      $A.getCallback( function( result ) {
        console.log( result );
        component.set('v.materials', result );
        component.set('v.modalOpen', true);
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
      spinner.toggle();
    }));

  },

  closeModal: function( component )
  {
    component.set('v.modalOpen', false );
  },

  handleStepBack: function( component )
  {
    var steps = component.get('v.steps'),
        cStep = component.get('v.currentStep'),
        stepIdx = steps.indexOf(cStep);
        console.log('back currentStep = ' + cStep);
        console.log('back stepIdx = ' + stepIdx);
    if( stepIdx > 0 )
      component.set('v.currentStep', steps[stepIdx - 1] );

  },

  handleStepNext: function( component )
  {
    var steps = component.get('v.steps'),
        cStep = component.get('v.currentStep'),
        stepIdx = steps.indexOf(cStep);
    console.log('next currentStep = ' + cStep);
    console.log('next stepIdx = ' + stepIdx);
    if( stepIdx !== ( steps.length - 1 ) )
      component.set('v.currentStep', steps[stepIdx + 1] );

  },

  submitRequest: function( component, event, helper )
  {
    var spinner = component.find('spinner');
    spinner.toggle();
    helper.createCase( component )
    .then(
      $A.getCallback( function( result ) {
        LightningUtils.showToast('success', 'Success', 'Parts Request #' + result + ' was created.');
        component.set('v.modalOpen', false);
        $A.get('e.force:refreshView').fire();
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