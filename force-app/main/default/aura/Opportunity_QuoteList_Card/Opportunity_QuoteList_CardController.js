({
	handleView: function( component, event, helper )
  {
    var v = event.getSource().get('v.value');
    component.set('v.selectedQuoteId', v);
  },

  handleShowDetails: function( component )
  {
    var bool = component.get('v.showDetails');
    component.set('v.showDetails', !bool );
  }

})