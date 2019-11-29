/**
 * Created by dave on 2019-10-21.
 */

({
  doInit: function( component, event, helper )
  {
    var spinner = component.find('spinner');
    //spinner.toggle();
    helper.fetchSerial( component )
    .then(
      $A.getCallback( function(result)
      {
        console.log('SERIAL NUMBER');
        console.log( JSON.parse( JSON.stringify( result ) ) );
        component.set('v.serialNumber', result);
        return helper.fetchRegistration( component );
      }),
      $A.getCallback( function( err )
      {
        LightningUtils.errorToast( err );
      })
    )
    .then(
      $A.getCallback( function( result )
      {
        console.log('REGISTRATION');
        console.log( JSON.parse( JSON.stringify( result ) ) );
        component.set( 'v.registration', result );
      }),
      $A.getCallback( function( err )
      {
        LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
      //spinner.toggle();
      component.set('v.loaded', true );
    }));
  },

  doRegistration: function( component, event, helper )
  {
    var spinner = component.find('spinner');
    spinner.toggle();
    helper.doRegistration( component )
    .then(
      $A.getCallback( function( result ) {
        LightningUtils.showToast('success', 'Success', 'Serial number was registered');
        $A.get('e.force:closeQuickAction').fire();
        $A.get('e.force:refreshView').fire();
      }),
      $A.getCallback( function( err ){
        LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
      spinner.toggle();
    }));
  }
});