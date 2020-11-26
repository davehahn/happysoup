({
  addDummyRecordData: function( component, fields )
  {
    var recs = [], count = 0, rec = {}, blankRecord,
        addValueToObj = function(obj, base) {
          return Object.keys(obj)
              .reduce((clone, key) => {
                key.split('.').reduce((innerObj, innerKey, i, arr) =>
                  innerObj[innerKey] = (i+1 === arr.length) ? obj[key] : innerObj[innerKey] || {}, clone)
              return clone;
            }, Object.assign({}, base));
        }

    for( var i=0; i<fields.length; i++ )
    {
      rec[fields[i]] = '';
    }
    blankRecord = addValueToObj(rec, {});

    while( count < component.get('v.perPage') )
    {
      recs.push( blankRecord );
      count++;
    }
    component.set('v.records', recs);
  },

  fetchRecords: function( component )
  {
    var self = this,
        action = component.get('c.fetchRecords'),
        listFilter = component.get('v.listSelectorFilter'),
        globalFilter = component.get('v.globalFilter'),
        listName = component.get('v.selectedList'),
        fieldDetails = component.get('v.fieldDetails'),
        searchString = component.get('v.searchString'),
        orderField = component.get('v.sortField'),
        orderFieldName = component.get('v.sortedCol'),
        orderDir = component.get('v.sortDir'),
        perPage = component.get('v.perPage'),
        localConfig = JSON.parse( localStorage.getItem( component.get('v.title') ) ),
        useCache = component.get('v.shouldUseCache'),
        fieldNames = [],
        searchFields = [],
        params;

    self.showIndicator( component, true );

    for( var i=0; i<fieldDetails.length; i++ )
    {
      fieldNames.push( fieldDetails[i].apiName );
      if( fieldDetails[i].type === 'STRING' )
        searchFields.push( fieldDetails[i].apiName );
    }

    self.addDummyRecordData( component, fieldNames );

    params = {
      sObjectName: component.get('v.sObjectName'),
      fieldNames: fieldNames,
      accountField: component.get('v.accountIdentityField'),
      searchString: searchString,
      searchFields: searchFields,
      orderField: orderField,
      orderDir: orderDir,
      perPage: perPage,
      pageNum: component.get('v.pageNumber')
    };

    localConfig.selectedList = listName;
    localConfig.listSelectorFilter = listFilter;
    localConfig.sortField = orderField;
    localConfig.sortedCol = orderFieldName;
    localConfig.sortDir = orderDir;
    localConfig.perPage = perPage;

    params.listFilter = null;
    if( globalFilter !== undefined && globalFilter.length > 0 )
        params.listFilter = globalFilter;

    if( listFilter !== undefined && listFilter.length > 0 )
    {
      if( params.listFilter !== null )
        params.listFilter += (' AND ' + listFilter);
      else
        params.listFilter = listFilter;
    }

    if( useCache )
      action.setStorable();
    else
    {
      action.setStorable({ ignoreExisting: true } );
      component.set('v.shouldUseCache', true );
    }

    action.setParams( params );

    action.setCallback( this, function( response ) {
      var state = response.getState();
      if( state === 'SUCCESS' )
      {
        var result = JSON.parse( response.getReturnValue() ),
            pageOptions = [];

        component.set('v.records', result.records );
        component.set('v.recordCount', result.records.length );
        component.set('v.totalRecordCount', result.recordCount );
        component.set('v.totalPages', result.totalPages);
        for( var i=0; i<result.totalPages; i++ )
        {
          pageOptions.push(i+1);
        }
        component.set('v.pageOptions', pageOptions);
        localStorage.setItem( component.get('v.title'), JSON.stringify( localConfig ) );
        self.showIndicator( component, false );
        if( component.get('v.searchString') !== component.get('v.searchInputString') )
          component.set('v.searchString', component.get('v.searchInputString') );
      }
      if( state === 'INCOMPLETE' )
      {
        alert( 'incomplete' );
      }
      if( state === 'ERROR' )
      {
        var errors = response.getError();
        if (errors) {
            if (errors[0] && errors[0].message) {
                alert("Error message: " +
                         errors[0].message);
            }
        } else {
            alert("Unknown error");
        }
      }
    });

    $A.enqueueAction( action );
  },

  editRow: function( component, recordId )
  {
    var editURL = component.get('v.editURL'),
        action;
    if( editURL === undefined )
    {
      action = $A.get("e.force:editRecord");
      action.setParams({
        "recordId": recordId
      })
      .fire();
    }
    else
    {
      console.log(editURL);
    }
  },

  viewRow: function( component, recordId )
  {
    var viewURL = component.get('v.viewURL'),
        action;
    if( viewURL === undefined || viewURL.length === 0)
    {
      action = $A.get('e.force:navigateToSObject');
      action.setParams({
        "recordId": recordId
      })
      .fire();
    }
    else
    {
      alert(viewURL);
    }
  },

  showIndicator: function( component, state )
  {
    var tb = component.find('listTable'),
        pgn = component.find('paginationRow');
    component.set('v.isLoading', state);
    if( state )
    {
      $A.util.addClass( tb, 'loading');
      $A.util.addClass( pgn, 'loading');
    }
    else
    {
      $A.util.removeClass( tb, 'loading');
      $A.util.removeClass( pgn, 'loading');
    }

  }

})