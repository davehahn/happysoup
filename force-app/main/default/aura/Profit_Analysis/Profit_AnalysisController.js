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
        console.log( JSON.parse( JSON.stringify( result ) ) );
        if( result === 'denied' )
        {
          component.set('v.allowedToView', false);
          component.set('v.lineItems', null );
          component.set('v.saleItems', null );
          component.set('v.businessOfficeItems', null );
          component.set('v.salesItemsTotal', null );
          component.set('v.businessOfficeItemsTotal', null );
        }
        else
        {
          component.set('v.lineItems', result.items);
          component.set('v.saleItems', result.saleItems );
          component.set('v.businessOfficeItems', result.businessOfficeItems );
          component.set('v.selectedPbId', result.pbId );
          component.set('v.pbOptions', result.pbOptions );
          component.set('v.salesItemsTotal', result.saleItemsTotal );
          component.set('v.businessOfficeItemsTotal', result.businessOfficeTotal );
          helper.setTotals( component );
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
        component.set('v.lineItems', result );
        helper.setTotals( component );
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