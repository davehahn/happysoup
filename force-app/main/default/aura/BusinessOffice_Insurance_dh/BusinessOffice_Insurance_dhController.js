({
  doInit : function(component, event, helper)
  {
    helper.initialize( component );
  },

  reInit: function( component, event, helper )
  {
    var initd = component.get('v.originalInitComplete');
    if( initd )
      helper.initialize( component );
  },

  reset: function( component, event, helper )
  {
    $A.get('e.force:refreshView').fire();
  },

  getPlanOptions: function( component, event, helper )
  {
    helper.fetchPlanOptions( component )
    .then(
      $A.getCallback( function( result ) {
        var selectedItems = component.get('v.selectedItems');
        if( selectedItems != null && Object.keys( selectedItems ).length > 0 )
        {
          for( let r in result )
          {
            for( let item in result[r].planItems )
            {
              if( selectedItems.hasOwnProperty( result[r].planItems[item].Id) )
              {
                result[r].planItems[item].lineItem = selectedItems[ result[r].planItems[item].Id ];
                result[r].planItems[item].lineItem.luigi = 'meh';
              }
            }
          }
        }
        component.set('v.planOptions', result );
        //component.set('v.loading', false);
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
        component.set('v.loading', false);
      })
    );
  },

  loadParamsChanged: function( component, event, helper )
  {
    component.set('v.hasResidualValue', event.getParam("finTerm") != event.getParam("finAmort") );
    component.set('v.term', event.getParam("insTerm") );
    component.set('v.finTerm', event.getParam("finTerm") );
    component.set('v.amort', event.getParam("finAmort") );
    component.set('v.intrestRate', event.getParam("intrestRate") );
    component.set('v.deposit', event.getParam("deposit") );
    component.set('v.staleData', true);
    helper.recalculate( component, true );
  },

  handleChange: function( component, event, helper )
  {
    helper.recalculate( component )
  },

  remoteUpdate: function( component, event, helper )
  {
    var hasChanges = component.get('v.hasChanges');
    return new Promise( function( resolve, reject ) {
      if( hasChanges )
      {
        helper.saveItems( component )
        .then(
          $A.getCallback( function() {
            resolve('Insurance Items updated');
          }),
          $A.getCallback( function( error ) {
            reject( error );
          })
        );
      }
      else
      {
        resolve('Insurance lines - nothing to save');
      }
    });
  },

  doSave: function( component, event, helper )
  {
    component.set('v.saving', true);
    helper.saveItems( component )
    .then(
      $A.getCallback( function( result ) {
        //helper.updateInsuranceItemAttr( result, 'v.lineItem', component);
        $A.get('e.force:refreshView').fire();
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    );
  }
})