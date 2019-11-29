({
	doInit : function(component, event, helper) {
    console.log('schedulable init');
    component.set('v.scriptsLoaded', true);
    helper.loadSchedulable( component );
	},

  refresh: function( component, event, helper )
  {
    console.log('schedulable refresh');
    helper.loadSchedulable( component );
  },

  onRender: function( component , event, helper )
  {
    console.log( 'schedulable render' );
    var scriptsLoaded = component.get('v.scriptsLoaded'),
        allowRetail = component.get('v.allowRetail'),
        allowService = component.get('v.allowService');

    if( scriptsLoaded )
    {
      var items = $(".schedulable");
      if( items.length > 0  )
      {
        items.draggable({
          revert:true,
          revertDuration: 0,
          appendTo: '.cal-container',
          helper: 'clone',
          opacity: 0.75,
          addClasses: false,
          zIndex: 10000
        });
      }

    }

  },

  searchChanged: function( component, event, helper )
  {
    var searchValue = component.get('v.searchValue');
    if( searchValue == null || searchValue.length === 0 )
      helper.applyCalenderFilter( component );
    else
      helper.applySearch( component, searchValue );
  },

  clearSearch: function( component )
  {
    component.set('v.searchValue', '');
  }
})