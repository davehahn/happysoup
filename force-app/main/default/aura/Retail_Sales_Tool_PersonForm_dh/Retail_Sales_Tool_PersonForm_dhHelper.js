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
  }

})