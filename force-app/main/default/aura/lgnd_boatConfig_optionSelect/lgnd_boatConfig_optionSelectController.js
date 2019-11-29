({
	toggleSelected : function(component, event, helper)
  {
    console.log('toggleSelected');
    var selected = component.get('v.isSelected'),
        hasOptions = component.get('v.hasOptions'),
        parentProductId = component.get('v.parent_id'),
        options;
    //component.set('v.isSelected', !selected);
    console.log( 'option is selected ? = ' + selected);
    console.log( 'option has subOptions? = ' + hasOptions );
    console.log( 'option parent_id = ' + parentProductId );
    if( selected == true &&
        hasOptions == true  )
    {
      helper.fetchsubOptions( component )
      .then(
        $A.getCallback( function( response ) {
          console.log('sub options');
          console.log( response)
          component.set('v.subOptions', response);
          helper.changeComplete( component );
        }),
        $A.getCallback( function( err ) {
          alert(err);
        })
      );
    }
    else
    {
      component.set('v.subOptions', []);
      helper.changeComplete( component );
    }

	}

})