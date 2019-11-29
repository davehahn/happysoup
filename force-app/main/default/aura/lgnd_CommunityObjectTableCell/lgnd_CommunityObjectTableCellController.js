({
	doInit : function(component, event, helper)
  {
    var record = component.get('v.record');
    var fieldName = component.get('v.field');
    var findValue = function( fName ) {
          return fName.split('.').reduce( function( v, subName ) {
            if( v === undefined )
              return '';
            return v[subName];
          }, record );
        };

    if( fieldName !== undefined || fieldName !== null )
    {
      var fieldValue = findValue(fieldName); //fieldName.split('.').reduce((o,i)=>o[i], record);
      // var fieldValue = fieldName.split('.').reduce( function(o,i) {
      //   console.log( i );
      //   console.log( o );
      //   o[i];
      // }, record);
      component.set('v.fieldValue', fieldValue );
    }
    //component.set('v.fieldType', fieldTypeMap[fieldName] );
	},

  viewRecord: function( component )
  {
    var viewURL = component.get('v.viewURL'),
        record = component.get('v.record'),
        action,
        recordId = component.get('v.viewRecordId');
    if( viewURL === undefined )
    {
      if (recordId == null) {
        recordId = record.Id
      }
      action = $A.get('e.force:navigateToSObject');
      action.setParams({
        "recordId": recordId
      })
      .fire();
    }
    else
    {
      console.log(viewURL);
    }
  }
})