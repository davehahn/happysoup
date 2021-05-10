({
	doInit: function(component, event, helper)
  {
    var cpq = component.get('v.cpq');
    component.set('v.tradeValue', cpq.tradeIn.value );
    component.set('v.lien', cpq.tradeIn.lien);
    helper.resetNewItem( component );
	},

  openForm: function( component, event, helper )
  {
    component.set('v.showForm', true);
  },

  closeForm: function( component, event, helper )
  {
    component.set('v.showForm', false);
  },

  handleTradeValueChange: function( component )
  {
    component.set('v.valuesChanged', true);
  },

  updateTradeValues: function( component )
  {
    var cpq = component.get('v.cpq');
    cpq.tradeIn.value = component.get('v.tradeValue');
    cpq.tradeIn.lien = component.get('v.lien');
    component.set('v.cpq', cpq)
    component.set('v.valuesChanged', false);
  },

  addItem: function( component, event, helper )
  {
    var cpq = component.get('v.cpq'),
        newItem = component.get('v.newItem');

    cpq.tradeIn.items.push( newItem );
    component.set('v.cpq', cpq);
    helper.resetNewItem( component );
    component.set('v.showForm', false);
  },

  removeItem: function( component, event, helper )
  {
    var cpq = component.get('v.cpq'),
        items = cpq.tradeIn.items,
        removeId = event.getSource().get('v.value');

    items.reduce( function( list, item, index ) {
      if( item.id === removeId ) list.push(index);
      return list;
    }, []).reverse().forEach( function( index ) {
      items.splice( index, 1 );
    });
    cpq.tradeIn.items = items;
    component.set('v.cpq', cpq );
  }
})