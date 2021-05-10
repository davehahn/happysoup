(function( window, document, undefined ) {

  class LightningApex {

    constructor( helper, action) {
      this.helper = helper;
      this.action = action;
    }

    fire() {
      var self = this;
      return new Promise( function( resolve, reject ) {
        self.action.setCallback(self.helper, function(response) {
          var state = response.getState();
          if( state === 'SUCCESS' )
          {
            var result = response.getReturnValue();
            if( typeof result === 'string')
            {
              try {
                result = JSON.parse( result );
              }
              catch(err) {}
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
            console.log( errors );
            if (errors) {
              if (errors[0] && errors[0].message)
                  reject(errors[0].message);

              if( errors[0] &&
                  errors[0].pageErrors &&
                  errors[0].pageErrors.length > 0 )
              {
                reject( errors[0].pageErrors[0].message );
              }

              if( errors[0] &&
                  errors[0].fieldErrors &&
                  Object.keys( errors[0].fieldErrors ).length > 0 )
              {
                var msg = '';
                for( var field in errors[0].fieldErrors )
                {
                  msg += field + ' - ' + errors[0].fieldErrors[field][0].message + '\r\n';
                }
                reject( msg );
              }

            } else {
                reject("Unknown error");
            }
          }
        });

        $A.enqueueAction( self.action );
      });
    }

  }

  window.LightningApex = LightningApex;

})( window, document );