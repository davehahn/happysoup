({
	doInit : function(component, event, helper)
  {
    var val = component.get('v.value'),
        text = component.get('v.zeroLabel');
    if( parseFloat( val ) === 0 || isNaN( parseFloat( val ) ) )
    {
      component.set('v.isZero', true);
      component.set('v.displayValue', text);
    }
    else
    {
      component.set('v.displayValue', val);
    }
	}
})