({
	setSelected : function( component )
  {
    var options = component.get('v.selectOptions'),
        value = component.get('v.value');

    if( value === undefined || value === null )
      value = [];

    for( let o of options )
    {
      if( value.indexOf( o.value ) >= 0 )
        o.selected = true;
      else
        o.selected = false;
    }
    component.set('v.selectOptions', options );
	}
})