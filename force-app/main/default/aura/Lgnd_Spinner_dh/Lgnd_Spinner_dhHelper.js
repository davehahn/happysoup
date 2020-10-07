({
	setBusyMessage: function( component, params )
	{
    if( params && params.busyMessage )
      component.set('v.busyMessage', params.busyMessage );
    else
      component.set('v.busyMessage', '' );
	}
})