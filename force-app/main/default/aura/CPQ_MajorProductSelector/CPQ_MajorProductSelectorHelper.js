({
  selectFamily: function( component )
  {
    var self = this;
    return new Promise( function( resolve, reject ) {
      self.fetchProductOptions( component )
      .then(
        $A.getCallback( function( result ) {
          component.set('v.productSelectOptions', result);
          resolve();
        }),
        $A.getCallback( function( err ) {
          reject( err );
        })
      );
    })
  },

  fetchProductOptions : function( component )
  {
    var action = component.get('c.fetchMajorProductOptions');
    action.setParams({
      recordType: component.get('v.productRecordType'),
      family: component.get('v.productFamily'),
      activePricebookId: component.get('v.activePricebookId')
    });
    return new LightningApex( this, action ).fire();
  },

  fireValueChangeEvent: function( component )
  {
    var evt = component.getEvent("majorProductSelected");

    evt.setParams({
      family: component.get('v.productFamily'),
      recordTypeName: component.get('v.productRecordType'),
      productId: component.get('v.value')
    })
    .fire();
  }
})