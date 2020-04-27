({
  getSelectOptions: function( component )
  {
    var action = component.get('c.buildSelectOptions'), la;
    la = new LightningApex( this, action );
    return la.fire();
  },

  fetchCustomer : function( component, objectId )
  {
    console.log( 'helper.fetchCustomer with ID of ' + objectId);
    var action = component.get('c.fetchCustomer'), la;
    action.setParams({
      objectId: objectId
    });
    la = new LightningApex( this, action );
    return la.fire();
  },

  formValid: function( component, stepNum )
  {
    var requiredFields = component.find('required-form-'+stepNum);
    if( requiredFields === null || requiredFields == undefined )
      requiredFields = [];
    // if we have a single field ( this will be an object not an array )
    if( requiredFields.length === undefined )
      requiredFields = [requiredFields];

    return requiredFields.reduce(function (validSoFar, inputCmp) {
      try {
        inputCmp.showHelpMessageIfInvalid();
      }
      catch(err){}
      if( inputCmp.isInstanceOf("ui:inputDate") )
      {
        if( inputCmp.get('v.value') == null )
        {
          inputCmp.set('v.errors', [{message: "Close Date is required"}]);
          return false;
        }
        else
        {
          inputCmp.set('v.errors', null);
          return true;
        }
      }
      else
        return validSoFar && inputCmp.get('v.validity').valid;
    }, true);
  },

  createSale: function( component )
  {
    var oppId = component.get('v.opportunityId');
    if( oppId === undefined )
    {
      var action = component.get('c.createSale'), la;
      console.log( JSON.parse( JSON.stringify( component.get('v.customer') ) ) );
      action.setParams({
        customerJSON: JSON.stringify(component.get('v.customer') ),
        oppJSON: JSON.stringify(component.get('v.opp') )
      });
      la = new LightningApex( this, action );
      return la.fire();
    }
    else
    {
      return Promise.resolve(oppId);
    }
  },

  checkDuplicate: function( component )
  {
    var action = component.get('c.checkDuplicate'), la;
    action.setParams({
      customerJSON: JSON.stringify(component.get('v.customer') )
    });
    la = new LightningApex( this, action );
    return la.fire();
  },

  handleDuplicate: function( component, event, helper )
  {
    var steps = component.get('v.steps'),
        step = component.get('v.currentStep'),
        stepNum = steps.indexOf(step),
        spinner = component.find('spinner');

      spinner.toggle();
      helper.checkDuplicate(component)
      .then(
        $A.getCallback( function( result ) {
          //if(result != undefined || result != null)
          //  result = JSON.parse(result);
          component.set("v.showPop", true);
          component.set('v.listData', result );
          console.log(result);
        })
      )
      .finally( $A.getCallback( function() {
        spinner.toggle();
      }));
  },
  closeModel: function(component, event, helper) {
    component.set("v.showPop", false);
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
          var cont = this;
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
              var duplicateMessage = err;//'DUPLICATES_DETECTED';
                          console.log(err);
                if(duplicateMessage.includes('DUPLICATES_DETECTED') || duplicateMessage.includes('Duplicate Alert')){
                    console.log('DUPLICATES_DETECTED');
                  console.log(duplicateMessage);
                  helper.handleDuplicate(component, event, helper);
                }else{
                  LightningUtils.errorToast( err );
                }
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