({
	fetchsubOptions: function(component)
  {
    var self = this,
        action = component.get("c.fetchSubOptions");

    action.setParams({
      parentProductId: component.get('v.product_id'),
      pricebookId: component.get('v.pricebookId')
    });

    self.toggleSpinner( component, true );
    return new Promise( function(resolve, reject) {

      action.setCallback(self, function(response) {
        var state = response.getState();
        if( state === 'SUCCESS' )
        {
          var options = JSON.parse( response.getReturnValue() );
          resolve( options );
        }
        if( state === 'INCOMPLETE' )
        {
          reject( 'incomplete' );
        }
        if( state === 'ERROR' )
        {
          var errors = response.getError();
          if (errors) {
              if (errors[0] && errors[0].message) {
                  reject("Error message: " +
                           errors[0].message);
              }
          } else {
              reject("Unknown error");
          }
        }
        self.toggleSpinner( component, false );
      });

      $A.enqueueAction( action );
    });

    //return this.actionHandler.call( this, component, action );
	},

  fireOptionChangeEvent: function( component )
  {
    var optionChangeEvt = $A.get('e.c:lgnd_BoatConfig_optionChanged_Event');
    console.log(' optionSelect change event params')
    var params = {
      id: component.get('v.product_id'),
      name: component.get('v.product_name'),
      cost: component.get('v.cost'),
      parent_id: component.get('v.parent_id'),
      isSelected: component.get('v.isSelected')
    }
    console.log( params );
    optionChangeEvt.setParams(
      params
    );

    optionChangeEvt.fire();
  },

  actionHandler: function( component, action )
  {
    var self = this;
    self.toggleSpinner( component, true );
    return new Promise( function(resolve, reject) {

      action.setCallback(self, function(response) {
        var state = response.getState();
        if( state === 'SUCCESS' )
        {
          resolve( response.getReturnValue() );
        }
        if( state === 'INCOMPLETE' )
        {
          reject( 'incomplete' );
        }
        if( state === 'ERROR' )
        {
          var errors = response.getError();
          if (errors) {
              if (errors[0] && errors[0].message) {
                  reject("Error message: " +
                           errors[0].message);
              }
          } else {
              reject("Unknown error");
          }
        }
        self.toggleSpinner( component, false );
      });

      $A.enqueueAction( action );
    });
  },

  changeComplete: function( component )
  {
    this.fireOptionChangeEvent( component );
  },

  toggleSpinner: function( component, busy )
  {
    var indEvt = $A.get('e.c:lgndP_BusyIndicator_Event');
    indEvt.setParams({isBusy: busy}).fire();
  }
})