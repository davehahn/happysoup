({
	getRiggers : function(component) {
		console.log('helper.getRiggers');
		var self = this,
				warehouse = component.get('v.city'),
				team = component.get('v.team'),
				action = component.get('c.getRiggers');
		action.setParams({
			"warehouse": warehouse,
			"team": team
		});
		return new Promise(function(resolve, reject) {
			self.actionHandler(action, false).then(function(riggers) {
				console.log(riggers);
				component.set('v.riggers', riggers);
				resolve();
			});
		});
	},

  init : function(component) {
    var self = this;
    self.getRiggers(component).then(function() {
     self.refresh(component);
    });
  },

  refresh : function(component) {
    var self = this;
    self.getRiggers(component);
    // setTimeout(function() {
    //   self.refresh(component);
    // }, 25000);
  },

	actionHandler: function( action, deserialize ) {
		console.log('helper.actionHandler');
    var self = this;
    return new Promise( function( resolve, reject ) {
      action.setCallback(self, function(response) {
        var state = response.getState();
        console.log(state);
        if( state === 'SUCCESS' )
        {
          var result = response.getReturnValue();
          if( typeof result === 'string')
          {
            try {
              result = result.replace(/(\r|\n)/gm, "");
              result = JSON.parse( result );
            }
            catch(err) {
              console.log(err);
            }
          }
          resolve( result );
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
      });

      $A.enqueueAction( action );
    });
  }
})