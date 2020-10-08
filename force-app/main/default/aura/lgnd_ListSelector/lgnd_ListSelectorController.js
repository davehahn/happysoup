({
  doInit: function( component, event, helper )
  {
    var listOptions = component.get('v.listOptions'),
        currentVal = component.get('v.value'),
        filterMap = {},
        listNames = [];
     console.log('List Options');
     console.log(listOptions);
    for( var i=0; i<listOptions.length; i++ )
    {
      var split = listOptions[i].split(':');
      listNames.push( split[0] );
      filterMap[ split[0] ] = split[1];
    }
    console.log(listNames);
    component.set('v.listNames', listNames);
    component.set('v.filterMap', filterMap);
    helper.fireSelectEvent( component );
  },

	toggleMenu : function(component, event, helper)
  {
    helper.toggleMenu( component );
	},

  selectList: function( component, event, helper )
  {
    event.preventDefault();
    var ele = event.currentTarget,
        eleData = ele.dataset;

    component.set('v.value', eleData.listName );
    helper.fireSelectEvent( component );
    helper.toggleMenu( component );
  }
})