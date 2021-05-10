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
      component.set('v.columns', [
        {label: 'Name', fieldName: 'Name', type: 'text'},
        {label: 'Email', fieldName: 'PersonEmail', type: 'text'},
        {label: 'Phone', fieldName: 'Phone', type: 'phone'}
      ]);
    },

    afterScripts: function( component, event, helper )
    {
      helper.getSelectOptions( component )
      .then(
        $A.getCallback( function( result ) {
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
      var objectId = event.getParams().accountId,
          spinner = component.find('spinner');
      spinner.toggle();
      helper.fetchCustomer( component, objectId )
      .then(
        $A.getCallback( function( result ) {
          console.log( result );
          if( Object.keys( result ).indexOf('leadSource') >= 0 &&
              result.leadSource !== null )
          {
            let opp = component.get('v.opp');
            opp.leadSource = result.leadSource;
            component.set('v.opp', opp);
          }
          if( Object.keys( result ).indexOf('leadCampaignInfluences') >= 0 &&
              result.leadCampaignInfluences !== null &&
              result.leadCampaignInfluences.length > 0 )
          {
            let options = component.get('v.selectOptions');
            let influences = {
              groupName: 'Lead Influences',
              options: result.leadCampaignInfluences
            };
            options.campaigns.unshift( influences );
            component.set('v.selectOptions', options );
          }
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

    handleAccountSelection: function( component, event, helper )
    {
      var selectedValue = event.getSource().get("v.title");

      if(selectedValue == undefined || selectedValue == null){
        LightningUtils.errorToast("Please select an account.");
      }else{
        var cus = component.get('v.customer');
        cus.id = selectedValue;
        helper.handleContinue(component, event, helper);
      }
    },
    handleSaveAfterAccountSelection: function( component, event, helper )
    {
      var _self = this;
      var dataTable = component.find('otherDataTable');
      var table;
      if(dataTable != undefined && dataTable.length > 1){
        table = dataTable[1];
      }
      else
          table = dataTable;
      var AccIds = [];
      for( var acc of table.getSelectedRows() )
        AccIds.push( acc.Id );

      if(AccIds.length > 1){
        LightningUtils.errorToast("Please select only one account.");
      }else{
        var cus = component.get('v.customer');
        cus.id = AccIds[0];
        helper.handleContinue(component, event, helper);
      }
    },

    handleContinue: function( component, event, helper )
    {
      helper.handleContinue(component, event, helper);
    },
    rowSelected: function( component )
    {
        var dataTable = component.find('otherDataTable');
        var table;
        if(dataTable != undefined && dataTable.length > 1){
          for(var i = dataTable.length; i == 1; i--)
            dataTable[i].destroy();

          table = dataTable[1];
        }
        else
            table = dataTable;
        if(table != undefined){
            var selections = table.getSelectedRows();
            component.set('v.hasSelections', selections.length > 0 );
        }else
            component.set('v.hasSelections', false);
    },
     closeModel: function(component, event, helper) {
       component.set("v.showPop", false);
       component.set('v.hasSelections', false);
     }
  })