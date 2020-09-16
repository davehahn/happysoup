({
  doInit: function( component, event, helper )
  {
    console.log('DOlines List init');
    helper.toggleSpinner( component, 'Retrieving Order Details');
    helper.doInit( component )
    .then(
      $A.getCallback( () => {}),
      $A.getCallback( () => {})
    )
    .finally( $A.getCallback( () => {
      console.log('DOlines List done');
      helper.toggleSpinner( component );
    }));
  },

  detailToggle: function( component, event, helper )
  {
    var moreDeets = component.get('v.moreDetails');
    component.set('v.moreDetails', !moreDeets );
  },

  handleAdd: function( component, event, helper )
  {
    var evt = component.getEvent('actionEvent');
    evt.setParams({
      action: 'add'
    })
    .fire();
  },

  handleSubmit: function( component, event, helper )
  {
    var confirmParams = {
      title: "Submit this order?",
      message: "Once this order is submitted it will be locked from further editing!"
    };
    helper.confirm( component, confirmParams )
    .then(
      $A.getCallback( function() {
        return helper.submitOrder( component );
      }),
      $A.getCallback( function() {
        return Promise.reject();
      })
    )
    .then(
      $A.getCallback( function(result) {
        $A.get('e.force:refreshView').fire();
        var toast = $A.get('e.force:showToast');
        toast.setParams({
          message: 'Your order was submitted successfully!',
          type: 'success'
        })
        .fire();
      }),
      $A.getCallback( function( err ) {
        if( err !== undefined )
          alert( err );
      })
    );
  },

  handleDelete: function( component, event, helper )
  {
    var params = event.getParams(),
        confirmParams = {
          title: "Are you sure?",
          message: "This will permenantly delete the record and can not be undone!"
        };
    helper.confirm( component, confirmParams )
    .then(
      $A.getCallback( function() {
        console.log('yes delete row')
        helper.deleteOrderRow( component, params.groupId, params.itemType );
      }),
      $A.getCallback( function() {
        return false;
      })
    );
  }

})