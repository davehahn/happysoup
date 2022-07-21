({
  fetchsubOptions: function (component) {
    var self = this,
      option = component.get("v.option"),
      action = component.get("c.fetchSubOptions");

    action.setParams({
      parentProductId: option.id,
      pricebookId: component.get("v.pricebookId")
    });

    self.toggleSpinner(component, true);

    let apex = new LightningApex(this, action);
    apex
      .fire()
      .then(
        $A.getCallback((response) => {
          console.log("sub options");
          console.log(response);
          option.subOptions = response;
          component.set("v.option", option);
          self.changeComplete(component);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      )
      .finally(
        $A.getCallback(() => {
          this.toggleSpinner(component, false);
        })
      );

    //    return new Promise( function(resolve, reject) {
    //
    //      action.setCallback(self, function(response) {
    //        var state = response.getState();
    //        if( state === 'SUCCESS' )
    //        {
    //          var options = JSON.parse( response.getReturnValue() );
    //          resolve( options );
    //        }
    //        if( state === 'INCOMPLETE' )
    //        {
    //          reject( 'incomplete' );
    //        }
    //        if( state === 'ERROR' )
    //        {
    //          var errors = response.getError();
    //          if (errors) {
    //              if (errors[0] && errors[0].message) {
    //                  reject("Error message: " +
    //                           errors[0].message);
    //              }
    //          } else {
    //              reject("Unknown error");
    //          }
    //        }
    //        self.toggleSpinner( component, false );
    //      });
    //
    //      $A.enqueueAction( action );
    //    });
  },

  fireOptionChangeEvent: function (component) {
    var optionChangeEvt = $A.get("e.c:lgnd_BoatConfig_optionChanged_Event"),
      option = component.get("v.option");
    //        params = {
    //          id: option.id,
    //          name: option.name,
    //          cost: option.cost,
    //          parent_id:option.parent_id,
    //          isSelected: option.isSelected,
    //          object: option
    //        }

    optionChangeEvt.setParams(option);

    optionChangeEvt.fire();
  },

  //  actionHandler: function( component, action )
  //  {
  //    var self = this;
  //    self.toggleSpinner( component, true );
  //    return new Promise( function(resolve, reject) {
  //
  //      action.setCallback(self, function(response) {
  //        var state = response.getState();
  //        if( state === 'SUCCESS' )
  //        {
  //          resolve( response.getReturnValue() );
  //        }
  //        if( state === 'INCOMPLETE' )
  //        {
  //          reject( 'incomplete' );
  //        }
  //        if( state === 'ERROR' )
  //        {
  //          var errors = response.getError();
  //          if (errors) {
  //              if (errors[0] && errors[0].message) {
  //                  reject("Error message: " +
  //                           errors[0].message);
  //              }
  //          } else {
  //              reject("Unknown error");
  //          }
  //        }
  //        self.toggleSpinner( component, false );
  //      });
  //
  //      $A.enqueueAction( action );
  //    });
  //  },

  changeComplete: function (component) {
    this.fireOptionChangeEvent(component);
  },

  toggleSpinner: function (component, busy) {
    var indEvt = $A.get("e.c:lgndP_BusyIndicator_Event");
    indEvt.setParams({ isBusy: busy }).fire();
  }
});
