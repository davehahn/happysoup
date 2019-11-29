({
  doInit : function(component, event, helper)
  {
    var steps = [
          'Select Account',
          'Account F.O.R.M.A.T',
          'WOW Notes',
          'Opportunity'
        ],
        customer = {
          isTaxExempt: component.get('v.makeAccountTaxExempt')
        };
    component.set('v.steps', steps);
    component.set('v.currentStep', steps[0] );
    component.set('v.customer', customer );
  },

  afterScripts: function( component, event, helper )
  {
    helper.getSelectOptions( component )
    .then(
      $A.getCallback( function( result ) {
        console.log( result );
        component.set('v.selectOptions', result );
        component.set('v.opp', result.opp );
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    );
  },

  handleNext: function( component, event, helper )
  {
    var steps = component.get('v.steps'),
        step = component.get('v.currentStep'),
        stepNum = steps.indexOf(step) + 1;

    if( stepNum === 1 && !component.get('v.showPersonForm') )
    {
      LightningUtils.errorToast("Please select or create a new account");
      return false;
    }

    if( helper.formValid( component, stepNum ) )
      component.set( 'v.currentStep', steps[ stepNum ] );
    else
      LightningUtils.errorToast("Please fix any errors on the form to continue");
  },

  handleBack: function( component )
  {
    var steps = component.get('v.steps'),
        step = component.get('v.currentStep'),
        stepNum = steps.indexOf(step);

    if( stepNum === 0 )
      component.set('v.saleType', '');
    else
      component.set( 'v.currentStep', steps[ steps.indexOf(step) - 1 ] );
  },

  handleAccountSelected: function( component, event, helper )
  {
    console.log('accountSelected');
    var objectId = event.getParams().accountId,
        spinner = component.find('spinner');
    spinner.toggle();
    helper.fetchCustomer( component, objectId )
    .then(
      $A.getCallback( function( result ) {
        console.log( result );
        component.set('v.customer', result );
        component.set('v.showPersonForm', true );
        spinner.toggle();
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
  },

  handleAccountSearchCleared: function( component )
  {
    console.log( 'handling account search cleared event ');
    var c = {
      id: '',
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      gender: '',
      mobilePhone: '',
      street: '',
      city: '',
      state: '',
      stateCode: '',
      country: '',
      postalCode: '',
      preferredLanguage: '',
      relationshipStatus: '',
      numberOfChildren: '',
      occupation: '',
      towVehicle: '',
      emotionalMotivation: [],
      hobbies: [],
      animals: [],
      teams: '',
      wowNotes: ''
    }
    component.set('v.customer', c );
    component.set('v.showPersonForm', false );
  },

  handleCreateAccount: function( component, event, helper )
  {
    component.set('v.showPersonForm', true );
  },

  handleContinue: function( component, event, helper )
  {
    var steps = component.get('v.steps'),
        step = component.get('v.currentStep'),
        stepNum = steps.indexOf(step) + 1,
        spinner = component.find('spinner');

    if( helper.formValid( component, stepNum ) )
    {
      spinner.toggle();
      helper.createSale( component )
      .then(
        $A.getCallback( function( result ) {
          component.set('v.opportunityId', result );
          var evt = $A.get("e.c:Retail_Sales_Tool_OppCreated_Event");
          evt.setParams({
            opportunityId: result
          })
          .fire();
        }),
        $A.getCallback( function( err ) {
          LightningUtils.errorToast( err );
        })
      )
      .finally( $A.getCallback( function() {
        spinner.toggle();
      }));
    }
    else
      LightningUtils.errorToast("Please fix any errors on the form to continue");
  }

})