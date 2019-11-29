({
	doInit: function(component, event, helper)
  {
    helper.initNewCustomProduct( component );
  },

  openForm: function( component, event, helper )
  {
    component.set('v.showForm', true);
  },

  closeForm: function( component, event, helper )
  {
    component.set('v.showForm', false);
  },

  addCustomProduct: function( component, event, helper )
  {
    var cpq = component.get('v.cpq'),
        newCustomProduct = component.get('v.newCustomProduct');
    cpq.customProducts.push( newCustomProduct );
    component.set('v.cpq', cpq);
    helper.initNewCustomProduct( component );
    component.set('v.showForm', false);
  },

  removeCustomProduct: function( component, event, helper )
  {
    var cpq = component.get('v.cpq'),
        prods = cpq.customProducts,
        cp_id = event.getSource().get('v.value');

    prods.reduce( function( list, cp, index ) {
      if( cp.id === cp_id ) list.push(index);
      return list;
    }, []).reverse().forEach( function( index ) {
      prods.splice( index, 1 );
    });
    cpq.customProducts = prods;
    component.set('v.cpq', cpq );
  }
})