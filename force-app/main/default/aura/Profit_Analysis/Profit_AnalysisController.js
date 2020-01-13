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
        helper.defaultCustomItem( component );
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

  handleTabChange: function( component, event, helper )
  {
    component.set('v.currentTab', event.getSource().get('v.id') );
  },

  handleIncludeChange: function( component, event, helper )
  {
    helper.setTotals( component );
  },

  handleConfigChange: function( component, event, helper )
  {
    var spinner = component.find('spinner'),
        pbId = component.get('v.selectedPbId'),
        prov = component.get('v.selectedProvince') ;

    spinner.toggle();
    helper.fetchData( component, pbId, prov )
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
  },

  addCustomItem: function( component, event, helper )
  {
    var item = component.get('v.customItem'),
        type = component.get('v.currentTab'),
        varString;
    if( !helper.isFormValid( component) )
    {
      return;
    }
    for( let field of ['saleTotal', 'factoryPbTotal', 'riggingCost'] )
    {
      if( typeof( item[field] ) === 'undefined' ||
          item[field] == null ||
          item[field] === '' )
      {
        item[field] = 0;
      }
    }
    if( type === 'sales' )
    {
      varString = 'v.saleItems';
    }
    if( type === 'business_office' )
    {
      varString = 'v.businessOfficeItems';
    }

    var items = component.get(varString);
    items.push( item );
    component.set(varString, items );

    helper.setTotals( component );
    helper.defaultCustomItem( component );
  },

  handleRemoveCustomItem: function( component, event, helper )
  {
    let id = event.getSource().get('v.value'),
        type = component.get('v.currentTab'),
        varString, items, filtered;

    if( type === 'sales' )
    {
      varString = 'v.saleItems';
    }
    if( type === 'business_office' )
    {
      varString = 'v.businessOfficeItems';
    }

    items = component.get(varString);
    filtered = items.filter( function( value, index, arr )
    {
      return value.id !== id;
    });
    component.set(varString, filtered );
    helper.setTotals( component );
  }
});