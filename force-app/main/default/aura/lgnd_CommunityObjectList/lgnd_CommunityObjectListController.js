({
	doInit : function(component, event, helper)
  {
    console.log('community list doing init');
    var lists = component.get('v.listNames'),
        sObjectName = component.get('v.sObjectName'),
        fields = component.get('v.fields'),
        fieldDetailsMap,
        localConfig = JSON.parse( localStorage.getItem( component.get('v.title') ) ),
        opts,
        fieldDetails = [];
    component.set('v.shouldUseCache', false);
    if( !localConfig )
    {
      localConfig = {}
    }

    fieldDetailsMap = (fields === undefined || fields === null ) ?
      [] : fields.split(',');

    for( var i=0; i<fieldDetailsMap.length; i++ )
    {
      var d = {},
          r = fieldDetailsMap[i].split(':');
      d['name'] = r[0];
      d['apiName'] = r[1];
      d['type'] = r[2];
      fieldDetails.push(d);
    }
    component.set('v.fieldDetails', fieldDetails );

    //setup header
    if( lists !== undefined )
    {
      opts = lists.split(',');
      if( !localConfig.selectedList )
      {
        localConfig.selectedList = opts[0].split(':')[0];
        localConfig.listSelectorFilter = opts[0].split(':')[1];
      }
      if( !localConfig.sortDir )
        localConfig.sortDir = 'DESC';

      component.set('v.sortDir', localConfig.sortDir );
      component.set('v.selectedList', localConfig.selectedList );
      component.set('v.listSelectorFilter', localConfig.listSelectorFilter );
      component.set('v.availableLists', opts );

      if( localConfig.perPage )
        component.set('v.perPage', localConfig.perPage );
    }

    //setup table
    if( !localConfig.sortField )
      localConfig.sortField = fieldDetails[0].apiName;

    component.set('v.sortField', localConfig.sortField );

    if( !localConfig.sortedCol )
      localConfig.sortedCol = fieldDetails[0].name;

    component.set('v.sortedCol', localConfig.sortedCol );

    localStorage.setItem( component.get('v.title'), JSON.stringify( localConfig ) );
    component.find('listSelector--Cmp').doInit();
	},

	handleSearch: function( component, event, helper )
	{
	  let searchString = event.getSource().get('v.value'),
	      isLoading = component.get('v.isLoading');
	  if( ( searchString === null ||
	        searchString.length === 0 ||
	        searchString.length > 3 ) &&
	      !isLoading )
    {
      setTimeout( () => {
        if( component.get('v.searchInputString') === searchString )
          component.set('v.searchString', searchString );
      },500);
    }
  },

  doSearch: function( component, event, helper )
  {
    helper.fetchRecords( component );
  },

  navigateToNew: function( component )
  {
    var urlEvent = $A.get("e.force:navigateToURL"),
        url = component.get('v.newURL');
    urlEvent.setParams({
      "url": url
    });
    urlEvent.fire();
  },

  handleViewEvent: function( component, event, helper )
  {
    var recordId = event.getParam('recordId');
    helper.viewRow( component, recordId );
  },

  handleTableAction: function( component, event, helper )
  {
    var menuSelection = event.getParam("value").split(':'),
        action = menuSelection[0],
        recordId = menuSelection[1];
    //if( action == 'delete' )
      //helper.deleteOrderRow( component, groupId );
    if( action == 'edit' )
      helper.editRow( component, recordId );
    if( action == 'view' )
      helper.viewRow( component, recordId );
  },

  handleListChange: function( component, event, helper )
  {
    component.set('v.selectedList', event.getParam('listName') );
    component.set('v.listSelectorFilter', event.getParam('filterText') );
    helper.fetchRecords( component );
  },

  perPageChanged: function( component, event, helper )
  {
    component.set('v.pageNumber', 1);
    helper.fetchRecords( component );
  },

  pageNumChanged: function( component, event, helper )
  {
    helper.fetchRecords( component );
  },

  nextPage: function( component, event, helper )
  {
    var currentPage = component.get('v.pageNumber');
    currentPage++;
    component.set('v.pageNumber', currentPage );
    helper.fetchRecords( component );
  },

  prevPage: function( component, event, helper )
  {
    var currentPage = component.get('v.pageNumber');
    currentPage--;
    component.set('v.pageNumber', currentPage );
    helper.fetchRecords( component );
  },

  handleSort: function( component, event, helper )
  {
    var ele = event.currentTarget,
        workingField = ele.dataset.fieldName,
        currentField = component.get('v.sortedCol'),
        fieldDetails = component.get('v.fieldDetails'),
        dir = component.get('v.sortDir');

    if( workingField === currentField )
    {
      dir = dir === 'DESC' ? 'ASC' : 'DESC';
      component.set('v.sortDir', dir);
    }
    else
    {
      for( var i=0; i<fieldDetails.length; i++ )
      {
        if( workingField === fieldDetails[i].name )
        {
          component.set('v.sortedCol', fieldDetails[i].name);
          component.set('v.sortField', fieldDetails[i].apiName );
        }
      }
    }
    helper.fetchRecords( component );
  }
})