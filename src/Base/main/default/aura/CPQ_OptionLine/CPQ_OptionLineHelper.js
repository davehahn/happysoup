({
  fetchSubOptions: function( component )
  {
    var self = this;
    self.subOptionsCallout( component )
      .then(
        $A.getCallback( function( response ) {
          var item = component.get('v.optionItem'),
              saleItems = component.get('v.saleItems');
          item.subOptions = response;
          if( response !== undefined && response !== null && response.length > 0 )
          {
            for( let subOpt of response )
            {
              if( subOpt.isSelected )
              {
                item.selectedSubOptions.push( subOpt );
              }
            }
          }
          component.set('v.optionItem', item);
          self.changeComplete( component );
        }),
        $A.getCallback( function( err ) {
          LightningUtils.errorToast( err );
        })
      );
  },

  subOptionsCallout: function(component)
  {
    var action = component.get("c.fetchSubOptions1"),
        item = component.get('v.optionItem'), la;

    action.setParams({
      parentProductId: item.id,
      activePricebookId: component.get('v.pricebookId')
    });

    la = new LightningApex( this, action );
    return la.fire();
  },

  fireOptionChangeEvent: function( component )
  {
    console.log('firing option changed event');
    var optionChangeEvt = component.getEvent('optionChanged');
    var params = {
      optionItem: component.get('v.optionItem')
    };
    optionChangeEvt.setParams( params ).fire();
  },

  changeComplete: function( component )
  {
    var isLoaded = component.get('v.compLoaded');
    if( isLoaded )
      this.fireOptionChangeEvent( component );
    else
      component.set('v.compLoaded', true );
  }
})