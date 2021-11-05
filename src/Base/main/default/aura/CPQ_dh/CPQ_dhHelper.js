({
  doInit: function( component )
  {
    var self = this,
        spinner = component.find('spinner');
    spinner.toggle();
    self.initCPQ( component )
    .then(
      $A.getCallback( function( result ) {
        component.set('v.cpq', result );
        component.set('v.quoteName', result.quoteName );
        component.set('v.quoteExpireDate', result.quoteExpirationDate );
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
      spinner.toggle();
    }))
  },

  initCPQ: function( component )
  {
    var action = component.get('c.initCPQ');
    action.setParams({
      recordId: component.get('v.recordId'),
      opportunityId: component.get('v.opportunityId')
    })
    return new LightningApex( this, action ).fire();
  },

  handleScroll: function( component, scrollTrue )
  {
    var header = component.find('cpq-header').getElement(),
        content = component.find('cpq-content').getElement(),
        h;
    if( scrollTrue )
    {
      h = header.getBoundingClientRect().height
      content.style.paddingTop = h + "px";
      header.classList.add("sticky");
    }
    else
    {
      header.classList.remove("sticky");
      content.style.paddingTop = "0px";
    }
  },

  toggleCalc: function( component )
  {
    var calc = component.find('payment-calc'),
        mask = component.find('menu-mask');
    $A.util.toggleClass(calc, 'open');
    $A.util.toggleClass(mask, 'open');
  },

  doToggleCreateQuote: function( component )
  {
    var isQuoting = component.get('v.isQuoting'),
        cpq = component.get('v.cpq'),
        quoteName = '',
        opportunityId = component.get('v.opportunityId'),
        formContainer = component.find('customer-form');

    // if we have an opportunityId, we are createing a new quote
    // for an existing Opportunity
    if( opportunityId !== undefined &&
        opportunityId !== null &&
        opportunityId.length > 0 )
    {
      component.set('v.recordId', opportunityId);
      //set the quote name to default to BoatName / MotorName
      if( cpq.theBoat !== undefined && cpq.theBoat !== null )
        quoteName += cpq.theBoat.name;

      if( cpq.theMotor !== undefined && cpq.theMotor !== null )
        quoteName += ' / ' + cpq.theMotor.name;

      component.set('v.quoteName', quoteName );
      $A.util.toggleClass( component.find('quote-name-modal'), 'slds-hide');
    }
    else
    {
      component.set('v.isQuoting', !isQuoting );
      // if isQuoting == false then we where entering customer/buisness
      // info on the Retail_Sales_Tool_dh form - component and now we
      // want to go back to the Builder
      if( isQuoting )
      {
        formContainer.set('v.body', [] );
      }
      // if isQuoting == true then we are done building
      // and we want to load the customer/business form
      else
      {
        $A.createComponent(
          "c:Retail_Sales_Tool_dh",
          {
            fromCPQ: true,
            makeAccountTaxExempt: cpq.isTaxExempt
          },
          function(form, status, errorMessage)
          {
            if (status === "SUCCESS") {
              formContainer.set("v.body", form);
            }
            else if (status === "INCOMPLETE") {
                console.log("No response from server or client is offline.")
                // Show offline error
            }
            else if (status === "ERROR") {
                console.log("Error: " + errorMessage);
                // Show error message
            }
          }
        );
      }
    }
  },

  doUpdateQuote: function( component )
  {
    $A.util.toggleClass( component.find('quote-name-modal'), 'slds-hide');
  },

  createQuote: function( component )
  {
    var action = component.get('c.upsertQuote'),
        oppId = component.get('v.recordId'),
        cpq = component.get('v.cpq'),
        quoteName = component.get('v.quoteName'),
        expDate = component.get('v.quoteExpireDate'),
        params = {
          recordId: cpq.saveToRecordId === null ?
                      oppId : cpq.saveToRecordId,
          name: quoteName,
          expireDate: expDate,
          taxZoneJSON: JSON.stringify( cpq.taxZone )
        };
    action.setParams(params);

    return new LightningApex( this, action ).fire();
  },

  saveCPQ: function( component, quoteId )
  {
    var action = component.get('c.saveCPQ'),
        recordId = component.get('v.recordId'),
        cpq = component.get('v.cpq');
    if( quoteId !== undefined && quoteId !== null )
      cpq.saveToRecordId = quoteId;

    if( cpq.saveToRecordId === null ||
        cpq.saveToRecordId === undefined ||
        cpq.saveToRecordId.length === 0 )
    {
      cpq.saveToRecordId = recordId;
    }
    action.setParams({
      cpqJSON: JSON.stringify( cpq )
    });

    return new LightningApex( this, action ).fire();
  }

})