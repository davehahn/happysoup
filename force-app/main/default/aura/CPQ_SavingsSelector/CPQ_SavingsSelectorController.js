({
	doInit: function(component, event, helper)
  {
    helper.initNewSavings( component );
	},

  openForm: function( component, event, helper )
  {
    component.set('v.showForm', true);
  },

  closeForm: function( component, event, helper )
  {
    component.set('v.showForm', false);
  },

  validNegative: function( component, event, helper )
  {
    var value = parseFloat( event.getParam('value') );
    if( !isNaN(value) && value > 0 )
      event.getSource().set('v.value', value * -1 );
  },

  addSavings: function( component, event, helper )
  {
    var cpq = component.get('v.cpq'),
        newSavings = component.get('v.newSavings');
    cpq.savings.push( newSavings );
    component.set('v.cpq', cpq);
    helper.initNewSavings( component );
    component.set('v.showForm', false);
  },

  removeSavings: function( component, event, helper )
  {
    var cpq = component.get('v.cpq'),
        savings = cpq.savings,
        sId = event.getSource().get('v.value');

    savings.reduce( function( list, sp, index ) {
      if( sp.id === sId ) list.push(index);
      return list;
    }, []).reverse().forEach( function( index ) {
      savings.splice( index, 1 );
    });
    cpq.savings = savings;
    component.set('v.cpq', cpq );
  }

})