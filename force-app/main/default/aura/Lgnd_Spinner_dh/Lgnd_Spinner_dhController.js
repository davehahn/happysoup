({
	toggle : function(component, event, helper)
  {
    var isVisible = component.get('v.isVisible');
    component.set('v.isVisible', !isVisible );
	}
})