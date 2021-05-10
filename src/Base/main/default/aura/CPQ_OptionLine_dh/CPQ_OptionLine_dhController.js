({
  doInit: function( component, event, helper )
  {
    var isCheckbox = component.get('v.isCheckbox');
    if( !isCheckbox )
    {
      var max = component.get('v.maximum'),
          std = component.get('v.standard'),
          opts = [];
      for( var i=std; i<=max; i++ )
      {
        opts.push(i);
      }
      component.set('v.quantityOptions', opts);
    }
  },

  selectChanged: function( component, event, helper )
  {
    var qty = component.get('v.quantitySelected'),
        subOpts = component.get('v.subOptions'),
        parentProductId = component.get('v.parentProductId');

    component.set('v.isSelected', qty > 0 ) ;

    if( qty > 0 && parentProductId == null && (subOpts == null || subOpts.length === 0) )
      helper.fetchSubOptions( component );
    else
    {
      if( qty == 0 )
        component.set('v.subOptions', [] );
      helper.changeComplete( component );
    }

  },

	toggleSelected : function(component, event, helper)
  {
    var selected = component.get('v.isSelected'),
        parentProductId = component.get('v.parentProductId'),
        options;
    component.set('v.quantitySelected', selected ? 1 : 0 );
    if( selected == true  && parentProductId == null )
    {
      helper.fetchSubOptions( component );
      if (component.get('v.isPrepayable')) {
        component.set('v.isPrepaid', true);
      }
    }
    else
    {
      component.set('v.subOptions', []);
      helper.changeComplete( component );
      if (component.get('v.isPrepayable')) {
        component.set('v.isPrepaid', false);
      }
    }

  },

  prepaidChanged : function(component, event, helper)
  {
    helper.fireOptionChangeEvent(component);
  }
})