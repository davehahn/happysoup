({
  fetchSubOptions: function( component )
  {
    var self = this,
        item = component.get('v.optionItem');
    self.subOptionsCallout( component )
      .then(
        $A.getCallback( function( response ) {
          component.set('v.subOptions', response);
          self.changeComplete( component );
        }),
        $A.getCallback( function( err ) {
          LightningUtils.errorToast( err );
        })
      );
  },

	subOptionsCallout: function(component)
  {
    var action = component.get("c.fetchSubOptions"), la;

    action.setParams({
      parentProductId: component.get('v.productId'),
      pricebookId: component.get('v.pricebookId')
    });

    la = new LightningApex( this, action );
    return la.fire();
  },

  fireOptionChangeEvent: function( component )
  {
    var optionChangeEvt = component.getEvent('optionChanged');
    var params = {
      pricebookEntryId: component.get('v.pricebookEntryId'),
      productId: component.get('v.productId'),
      parentProductId: component.get('v.parentProductId'),
      isSelected: component.get('v.isSelected'),
      lineId: component.get('v.lineId'),
      unitCost: component.get('v.unitCost'),
      quantitySelected: component.get('v.quantitySelected'),
      prepaid: component.get('v.isPrepaid')
    }
    optionChangeEvt.setParams(
      params
    );
    optionChangeEvt.fire();
  },

  changeComplete: function( component )
  {
    this.fireOptionChangeEvent( component );
  },

  // toggleSpinner: function( component, busy )
  // {
  //   var indEvt = $A.get('e.c:lgndP_BusyIndicator_Event');
  //   indEvt.setParams({isBusy: busy}).fire();
  // }
})