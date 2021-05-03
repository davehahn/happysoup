({
	toggleSelected : function(component, event, helper)
  {
    console.log('toggleSelected');
    var option = component.get('v.option');

    if( option.isSelected == true &&
        option.hasOptions == true  )
    {
      helper.fetchsubOptions( component );
    }
    else
    {
      option.subOptions = [];
      component.set('v.option', option);
      helper.changeComplete( component );
    }

	},

	selectChanged: function( component, event, helper )
	{
	  let option = component.get('v.option');

	  if( option.hasOptions &&
	      option.quantitySelected > 0 )
	  {
	    helper.fetchsubOptions( component );
    }
    else
    {
      component.set('v.subOptions', []);
      helper.changeComplete( component );
    }
  }

})