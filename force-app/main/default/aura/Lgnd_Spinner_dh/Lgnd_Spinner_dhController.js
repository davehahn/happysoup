({
	toggle : function(component, event, helper)
  {
    let isVisible = component.get('v.isVisible'),
        params = event.getParam('arguments');

    if( params && params.busyMessage )
      component.set('v.busyMessage', params.busyMessage );
    else
      component.set('v.busyMessage', '' );

    component.set('v.isVisible', !isVisible );
	}
})