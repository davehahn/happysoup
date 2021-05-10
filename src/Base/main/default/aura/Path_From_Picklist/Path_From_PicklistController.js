({
  handleSelect :function(component, event, helper)
  {
    var fieldName = component.get('v.pickListField'),
        fieldValue = event.getParam('detail').value,
        spinner = component.find('spinner'),
        simpleRecord = component.get('v.simpleRecord'),
        readOnly = component.get('v.readOnly');

    if( readOnly )
    {
      event.preventDefault();
      return;
    }
    simpleRecord[fieldName] = fieldValue;
    component.set('v.simpleRecord', simpleRecord );
    $A.util.toggleClass(spinner, "slds-hide");

    component.find('recordHandler').saveRecord(
      $A.getCallback( function(saveResult) {
        console.log( JSON.parse( JSON.stringify(saveResult)));
        if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT")
        {
          $A.get("e.force:refreshView").fire();
          $A.util.toggleClass(spinner, "slds-hide");
        }
        else if (saveResult.state === "INCOMPLETE")
        {
          LightningUtils.errorToast("User is offline, device doesn't support drafts.");
        }
        else if (saveResult.state === "ERROR")
        {
          LightningUtils.errorToast('Problem saving record, error: ' + JSON.stringify(saveResult.error));
        }
        else
        {
          LightningUtils.errorToast('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
        }
      })
    );
  },

  reloadRecord: function( component, event, helper )
  {
    component.find('recordHandler').reloadRecord(true)
  }
})