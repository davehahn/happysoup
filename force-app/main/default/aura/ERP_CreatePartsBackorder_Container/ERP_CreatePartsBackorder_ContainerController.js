/**
 * Created by dave on 2021-03-29.
 */

({
  doInit: function( component, event, helper )
  {
    let steps = [
      {buttonLabel: 'Next', title: 'Select Parts to Back Order', value: 0 },
      {buttonLabel: 'Next', title: 'What is the Reason for the Back Order', value: 1 },
      {buttonLabel: 'Next', title: "Verify Back Order ERP", value: 2 },
      {buttonLabel: 'Finish', title: "Verify Changes to Retail", value: 3 }
    ];
    component.set('v.steps', steps);
    component.set('v.currentStep', steps[0] );

  },

  handleCancel: function( component, event )
  {
    $A.get('e.force:closeQuickAction').fire();
  },

  handleNext: function( component )
  {
    let currentStep = component.get('v.currentStep');
    if( currentStep.value === 3 ) return;
    const steps = component.get('v.steps');

    let cmp = component.find('backOrderCreator');
    switch( currentStep.value )
    {
      case 0:
        cmp.stepOne();
        break;
      case 1:
        cmp.buildNewERP();
        break;
      case 2:
        cmp.createBackOrderRecords()
        .then( () => {
          return;
        })
        .catch( error => {
          console.log( JSON.parse(JSON.stringify(error)) );
        });
    }
    component.set( 'v.currentStep', steps[ currentStep.value + 1 ] );
  },

  handleBack: function( component )
  {
    let currentStep = component.get('v.currentStep');
    if( currentStep.value === 0 ) return;
    const steps = component.get('v.steps');
    component.set( 'v.currentStep', steps[ currentStep.value - 1 ] );
  }
});