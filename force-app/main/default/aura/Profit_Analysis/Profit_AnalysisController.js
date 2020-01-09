/**
 * Created by dave on 2019-11-06.
 */

({
  doInit: function( component, event, helper )
  {
    var spinner = component.find('spinner');
    spinner.toggle();
    helper.fetchData( component )
    .then(
      $A.getCallback( function( result ) {
        if( result === 'denied' )
        {
          component.set('v.allowedToView', false);
          component.set('v.lineItems', null );
          component.set('v.saleItems', null );
          component.set('v.businessOfficeItems', null );
        }
        else
        {
          helper.setResultValues( component, result );
        }
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
      spinner.toggle();
    }));
  },

  handleIncludeChange: function( component, event, helper )
  {
    console.log( 'toggle checked' );
    helper.setTotals( component );
  },

  handlePbChange: function( component, event, helper )
  {
    var spinner = component.find('spinner'),
        pbId = event.getSource().get('v.value');
    spinner.toggle();
    helper.updateItems( component, pbId )
    .then(
      $A.getCallback( function( result )
      {
        helper.setResultValues( component, result );
      }),
      $A.getCallback( function( err ){
        LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
      spinner.toggle();
    }))
  }
});