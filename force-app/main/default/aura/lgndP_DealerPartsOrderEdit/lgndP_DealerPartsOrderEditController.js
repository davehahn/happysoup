({
	doInit : function(component, event, helper)
  {
    var sPageURL = decodeURIComponent(window.location.search.substring(1)),
        sURLVariables = sPageURL.split('&');

    console.log( sPageURL );
    console.log( sURLVariables );

    for( var i=0; i<sURLVariables.length; i++ )
    {
      var param = sURLVariables[i].split('=');
      if( param.length === 2 && param[0] === 'recordId' )
      {
        component.set('v.recordId', param[1] );
        break;
      }
    }
	}
})