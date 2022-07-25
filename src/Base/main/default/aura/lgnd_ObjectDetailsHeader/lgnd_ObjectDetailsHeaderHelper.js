({
  validFormats: ["STRING", "DATETIME", "CURRENCY"],
  initialize: function (component) {
    var self = this;
    component.set("v.displayAlwaysEditForm", false);
    self.fetchRecord(component).then(
      $A.getCallback(function (result) {
        if (result !== null && Object.keys(result).length > 0) {
          var nameField = component.get("v.nameField");
          component.set("v.record", result);
          component.set("v.recordName", result[nameField]);
          self.setEditability(component);
          self.setDisplayFields(component);
        }
      }),
      $A.getCallback(function (err) {
        alert(err);
      })
    );
  },

  fetchRecord: function (component) {
    var self = this,
      action = component.get("c.fetchRecordDetails"),
      sObjectName = component.get("v.sObjectName"),
      recordId = component.get("v.recordId"),
      canEditFormula = component.get("v.canEditFormula"),
      displayFields = component.get("v.displayFields"),
      //canEditCriteria,
      fields = new Set();

    fields.add(component.get("v.nameField"));

    if (canEditFormula !== undefined && canEditFormula !== null && canEditFormula.length > 0) {
      var canEditCriteria = canEditFormula.split(",");
      fields = canEditCriteria.reduce(function (fset, criteria) {
        return fset.add(criteria.split(":")[0]);
      }, fields);
    }

    if (!$A.util.isEmpty(displayFields)) {
      var displayFieldsArray = displayFields.split(",");
      fields = displayFieldsArray.reduce(function (fset, displayField) {
        if (displayField.length > 1) {
          return fset.add(displayField.split(":")[1]);
        }
      }, fields);
    }

    action.setParams({
      sObjectName: sObjectName,
      recordId: recordId,
      fields: Array.from(fields)
    });

    return new Promise(function (resolve, reject) {
      action.setCallback(self, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          resolve(JSON.parse(response.getReturnValue()));
        }
        if (state === "INCOMPLETE") {
          reject("incomplete");
        }
        if (state === "ERROR") {
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              reject("Error message: " + errors[0].message);
            }
          } else {
            reject("Unknown error");
          }
        }
      });

      $A.enqueueAction(action);
    });
  },

  setEditability: function (component) {
    var self = this,
      alwaysEditFields_List = component.get("v.alwaysEditFields_List"),
      criteriaResult = self.evaluateEditCriteria(component),
      result = false;

    if (alwaysEditFields_List !== undefined && alwaysEditFields_List.length > 0) result = true;
    else result = criteriaResult;

    component.set("v.canEdit", result);
    component.set("v.canDelete", criteriaResult);
  },

  evaluateEditCriteria: function (component) {
    var record = component.get("v.record"),
      canEditFormula = component.get("v.canEditFormula"),
      criteria = [],
      result = false;

    if (canEditFormula !== undefined && canEditFormula !== null && canEditFormula.length > 0) {
      criteria = canEditFormula.split(",");
    }

    for (var i = 0; i < criteria.length; i++) {
      var criteriaArray = criteria[i].split(":");
      if (criteriaArray.length === 3) {
        var fieldName = criteriaArray[0],
          oper = criteriaArray[1],
          matchValue = criteriaArray[2],
          recordValue = record[fieldName];

        switch (oper) {
          case "EQUALS":
            if (recordValue === matchValue) result = true;
            break;

          case "NOTEQUALS":
            if (recordValue !== matchValue) result = true;
            break;

          case "CONTAINS":
            if (recordValue.includes(matchValue)) result = true;
            break;
        }
      }
    }
    return result;
  },

  setDisplayFields: function (component) {
    var self = this,
      record = component.get("v.record"),
      displayFieldsString = component.get("v.displayFields"),
      fields = [],
      findValue = function (fName) {
        return fName.split(".").reduce(function (v, subName) {
          return v[subName];
        }, record);
      };

    if (!$A.util.isEmpty(displayFieldsString)) {
      fields = displayFieldsString.split(",").reduce(function (flds, fieldString) {
        var field = fieldString.split(":");
        if (field.length > 1) {
          var format = field[2] === undefined || self.validFormats.indexOf(field[2]) < 0 ? "STRING" : field[2];
          flds.push({
            label: field[0],
            value: findValue(field[1]),
            name: field[1],
            format: format
          });
        }
        return flds;
      }, fields);
    }
    component.set("v.displayFieldData", fields);
  },

  returnToList: function (component) {
    var listURL = component.get("v.listViewURL"),
      evt = $A.get("e.force:navigateToURL");
    evt
      .setParams({
        url: listURL,
        isredirect: true
      })
      .fire();
  },

  confirm: function (component, confirmParams) {
    var confirmCmp = component.find("lgnd-confirm");

    return new Promise(function (resolve, reject) {
      component.addEventHandler("c:lgnd_Confirm_Response_Event", function (auraEvent) {
        auraEvent.getParam("theResponse") ? resolve() : reject();
      });
      confirmCmp.showConfirm(confirmParams);
    });
  },

  deleteRecord: function (component) {
    var self = this,
      recordId = component.get("v.recordId"),
      action = component.get("c.deleteRecord");

    action.setParams({
      recordId: recordId
    });

    return new LightningApex(this, action).fire();

    //    return new Promise( function( resolve, reject ) {
    //      action.setCallback( self, function( response ) {
    //        var state = response.getState();
    //        if( state === 'SUCCESS' )
    //        {
    //          resolve();
    //        }
    //        if( state === 'INCOMPLETE' )
    //        {
    //          reject( 'incomplete' );
    //        }
    //        if( state === 'ERROR' )
    //        {
    //          var errors = response.getError();
    //          if (errors) {
    //              if (errors[0] && errors[0].message) {
    //                  reject("Error message: " +
    //                           errors[0].message);
    //              }
    //          } else {
    //              reject("Unknown error");
    //          }
    //        }
    //      });
    //      $A.enqueueAction(action);
    //    });
  }
});
