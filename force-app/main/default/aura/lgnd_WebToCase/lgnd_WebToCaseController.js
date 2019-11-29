({
	doInit : function(component, event, helper)
  {
    console.log( 'web to case init' );
    var action = component.get('c.initData');
    action.setCallback( this, function( response ) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var result = JSON.parse( response.getReturnValue() );
        console.log( result );
        component.set('v.userName', result.userName );
        component.set('v.userEmail', result.userEmail );
        component.set('v.typeOptions', result.typeOptions);
        component.set('v.reasonOptions', result.reasonOptions );
        component.set('v.priorityOptions', result.priorityOptions );
        component.set('v.contactId', result.userId );
      }
      //else if (cmp.isValid() && state === "INCOMPLETE") {
      else if (state === "INCOMPLETE") {
        // do something
        console.log( 'incomplete' );
      }
      //else if (cmp.isValid() && state === "ERROR") {
      else if (state === "ERROR") {
        var errors = response.getError();
        if (errors) {
            if (errors[0] && errors[0].message) {
                console.log("Error message: " +
                         errors[0].message);
            }
        } else {
            console.log("Unknown error");
        }
      }
    });
    $A.enqueueAction(action);
	},

  checkValidity: function( component, event, helper )
  {
    component.set('v.formValid', helper.isFormValid( component ) );
  },

  submitCase: function( component, event, helper )
  {
    var data = {
                  'url': component.get('v.url'),
                  'orgid': component.get('v.orgId'),
                  'contactId': component.get('v.contactId'),
                  'name': component.get('v.userName'),
                  'email': component.get('v.userEmail'),
                  'caseType': component.get('v.type'),
                  'reason': component.get('v.reason'),
                  'priority': component.get('v.priority'),
                  'subject': component.get('v.subject'),
                  'description': component.get('v.description')
                },
        action = component.get('c.saveTheCase'),
        indicator = component.find('busy-indicator');

    $A.util.toggleClass( indicator, 'hidden' );

    action.setParams({
      jsonData: JSON.stringify( data )
    });

    action.setCallback( this, function( response ) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var result = JSON.parse( response.getReturnValue() );
        console.log( result );
        //if( component.get('v.fileList').length > 0 )
        //{
          component.set('v.caseId', result.Id);
          helper.uploadFiles( component )
          .then(
            $A.getCallback( function() {
              helper.caseCreateComplete( component );
            }),
            $A.getCallback( function( err ) {
              console.log('controller line 106');
              console.log( err );
              alert(err);
            })
          );
        // }
        // else
        //   helper.caseCreateComplete( component );
      }
      //else if (cmp.isValid() && state === "INCOMPLETE") {
      else if (state === "INCOMPLETE") {
        // do something
        console.log( 'incomplete' );
        component.set('v.toastContent', {'type': 'error', 'message': 'Incomplete'});
        $A.util.toggleClass( indicator, 'hidden' );
      }
      //else if (cmp.isValid() && state === "ERROR") {
      else if (state === "ERROR") {
        var errors = response.getError();
        if (errors) {
            if (errors[0] && errors[0].message) {
                console.log("Error message: " +
                         errors[0].message);
            }
        } else {
            console.log("Unknown error");
            component.set('v.toastContent', {'type': 'error', 'message': 'Error encountered'});
            $A.util.toggleClass( indicator, 'hidden' );
        }
      }
    });
    $A.enqueueAction(action);
  },

  attachmentsActive: function( component, event, helper )
  {
    component.set('v.fileUploadInitd', true);
  }

})