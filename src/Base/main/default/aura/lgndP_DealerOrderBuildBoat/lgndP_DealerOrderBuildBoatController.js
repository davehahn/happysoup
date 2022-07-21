({
  doInit: function (component, event, helper) {
    var dealerOrder = component.get("v.dealerOrder");
    component.set("v.promotionMessage", null);
    if (
      dealerOrder.Account__r !== undefined &&
      dealerOrder.Account__r.BillingState !== undefined &&
      dealerOrder.Account__r.BillingState !== null &&
      dealerOrder.Account__r.BillingState.length > 0
    ) {
      component.set("v.province", dealerOrder.Account__r.BillingState);
    } else {
      component.set("v.province", "Others");
    }
    helper.setUserType(component).then(
      $A.getCallback(function () {
        component.find("lgnd_BoatTypeSelector--CMP").resetVars();
        helper.fireChangeEvent(component);
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  doInitForEdit: function (component, event, helper) {
    helper.functions.clearVars(component);
    var params = event.getParam("arguments"),
      result;

    helper
      .setUserType(component)
      .then(
        $A.getCallback(function () {
          component.set("v.orderGroupId", params.groupId);
          return helper.initForEdit(component, params.groupId);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      )
      .then(
        // initForEdit SUCCESS
        $A.getCallback(function (resp) {
          result = JSON.parse(resp);
          component.set("v.modelYear", result.modelYear);
          if (result.province !== undefined && result.province.length > 0) component.set("v.province", result.province);
          else component.set("v.province", "Others");

          return helper.selectTypeFunction(component, result.family, result.recordType);
        }),
        //initForEdit FAIL
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      )
      .then(
        // SelectTypeFunction SUCCESS Now Select the boat
        $A.getCallback(function () {
          /* set this here because helper.selectType sets to true
           by default
        */
          component.set("v.isMotorRequest", result.isMotorRequestOnly);
          return helper.selectBoatFunction(component, result.selectedBoat_Id, result.options);
        }),
        // SelectTypeFunction FAIL
        $A.getCallback(function (err) {
          console.log(err);
        })
      )
      .then(
        // SelectBoatFunction SUCCESS Now Select the trailer
        $A.getCallback(function () {
          return helper.handleTrailer(component, result.selectedTrailer_Id, result.trailerOptions);
        }),
        // SelectBoatFunction FAIL
        $A.getCallback(function (err) {
          console.log(err);
        })
      )
      .then(
        // Select Trailer SUCCESS Now Select the motor
        $A.getCallback(function (trailer) {
          component.set("v.trailer", trailer);
          if (
            result.motorRequest !== undefined &&
            result.motorRequest !== null &&
            Object.keys(result.motorRequest).length > 0
          ) {
            //add this back in as the JSON serialization/deserialation messes up the object
            result.motorRequest.sobjectType = result.motorRequest.attributes.type;
            delete result.motorRequest.attributes;
            component.set("v.motorRequest", result.motorRequest);

            return helper.handleMotor(component, result.motorRequest.Motor__c, result.motorOptions);
          } else {
            return helper.handleMotor(component, result.selectedMotor_Id, result.motorOptions);
          }
        }),
        // SelectBoatFunction FAIL
        $A.getCallback(function (err) {
          console.log(err);
        })
      )
      .then(
        // SelectMotor SUCCESS
        $A.getCallback(function (motor) {
          component.set("v.motor", motor);
          return helper.handleTrollingMotor(component, result.selectedTrollingMotor_Id, result.trollingMotorOptions);
        }),
        // SelectBoatFunction FAIL
        $A.getCallback(function (err) {
          console.log(err);
        })
      )
      .then(
        // SelectTrollingMotor SUCCESS
        $A.getCallback(function (trollingMotor) {
          component.set("v.trollingMotor", trollingMotor);
          component.set("v.quantity", parseInt(result.quantity));
          component.set("v.notes", result.notes);
          //component.set('v.optionsList', result.optionsList);
          //component.set('v.options', result.options);
          helper.fireChangeEvent(component);
        }),
        // SelectBoatFunction FAIL
        $A.getCallback(function (err) {
          console.log(err);
        })
      );
  },

  cancelOrder: function (component, event, helper) {
    var cancelEvt = component.getEvent("cancelOrderEvent");
    cancelEvt.fire();
  },

  handleAdd: function (component, event, helper) {
    const modelYear = component.get("v.modelYear");

    helper.functions.clearVars(component);
    component.set("v.modelYear", modelYear);
    component.find("lgnd_BoatTypeSelector--CMP").resetVars();
    helper.fireChangeEvent(component);
    helper.functions.toggleModal(component, "close");
  },

  navNext: function (component, event, helper) {
    var inOrderView = component.get("v.inOrderView"),
      nav;
    helper
      .saveDealerOrderLine(component)
      .then(
        $A.getCallback(function (response) {
          component.set("v.dealerOrder", response);
          if (inOrderView) {
            let evt = $A.get("e.c:lgndP_DealerOrderLineEditComplete_Event");
            evt
              .setParams({
                status: "complete"
              })
              .fire();
          } else {
            nav = $A.get("e.c:lgndP_DealerOrderNav_Event");
            nav
              .setParams({
                firedBy: 1,
                navigateTo: 2
              })
              .fire();
          }
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
          helper.functions.toggleSpinner(component, false);
        })
      )
      .finally(
        $A.getCallback(function () {
          if (!inOrderView) helper.functions.toggleSpinner(component, false);
        })
      );
  },

  navBack: function (component, event, helper) {
    var inOrderView = component.get("v.inOrderView"),
      nav;
    if (inOrderView) {
      let evt = $A.get("e.c:lgndP_DealerOrderLineEditComplete_Event");
      evt
        .setParams({
          status: "cancel"
        })
        .fire();
    } else {
      nav = $A.get("e.c:lgndP_DealerOrderNav_Event");
      nav.setParams({ firedBy: 1, navigateTo: 0 }).fire();
    }
  },

  cancelItem: function (component, event, helper) {
    var nav = $A.get("e.c:lgndP_DealerOrderNav_Event");
    nav.setParams({ firedBy: 1, navigateTo: 2 }).fire();
  },

  selectType: function (component, event, helper) {
    var params = event.getParams(),
      family = params.family,
      recordType = params.recordType;

    if (family !== "" && recordType !== "") {
      helper.selectTypeFunction(component, family, recordType);
    }
  },

  selectBoat: function (component, event, helper) {
    var boatId = component.get("v.selectedBoat_Id"),
      boat;

    if (typeof boatId === "undefined" || (typeof boatId !== "undefined" && boatId.length === 0) || boatId === null)
      return null;
    helper
      .selectBoatFunction(component, boatId)
      .then(
        //SelectBoatFunction SUCCESS
        $A.getCallback(function (result) {
          boat = result;
          return helper.handleTrailer(component, boat.standardTrailer_Id);
        }),
        //SelectBoatFunction FAIL
        $A.getCallback(function (err) {
          console.log("Select Boat ERROR");
          LightningUtils.errorToast(err, "sticky");
        })
      )
      .then(
        //HandleTrailer SUCCESS
        $A.getCallback(function (trailer) {
          component.set("v.trailer", trailer);
          return helper.handleMotor(component, boat.standardMotor_Id);
        }),
        //HandleTrailer FAIL
        $A.getCallback(function (err) {
          console.log("handle trailer fail");
          LightningUtils.errorToast(err, "sticky");
        })
      )
      .then(
        //HandleMotor SUCCESS
        $A.getCallback(function (motor) {
          component.set("v.motor", motor);
          return helper.handleTrollingMotor(component, boat.standardTrollingMotor_Id);
        }),
        //HandleMotor FAIL
        $A.getCallback(function (err) {
          console.log("handle motor fail");
          LightningUtils.errorToast(err, "sticky");
        })
      )
      .then(
        //HandleTrollingMotor SUCCESS
        $A.getCallback(function (trollingMotor) {
          component.set("v.trollingMotor", trollingMotor);
          helper.fireChangeEvent(component);
        }),
        //HandleTrollingMotor FAIL
        $A.getCallback(function (err) {
          console.log("handle trolling motor fail");
          LightningUtils.errorToast(err, "sticky");
        })
      );
  },

  selectTrailer: function (component, event, helper) {
    var trailerId = component.get("v.selectedTrailer_Id");
    helper.handleTrailer(component, trailerId).then(
      $A.getCallback(function (trailer) {
        component.set("v.trailer", trailer);
        helper.fireChangeEvent(component);
      }),

      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  selectMotor: function (component, event, helper) {
    var motorId = component.get("v.selectedMotor_Id");
    helper.handleMotor(component, motorId).then(
      $A.getCallback(function (motor) {
        component.set("v.motor", motor);
        helper.fireChangeEvent(component);
      }),

      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  selectTrollingMotor: function (component, event, helper) {
    var t_motorId = component.get("v.selectedTrollingMotor_Id");
    helper.handleTrollingMotor(component, t_motorId).then(
      $A.getCallback(function (trollingMotor) {
        component.set("v.trollingMotor", trollingMotor);
        helper.fireChangeEvent(component);
      }),

      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  handleOptionChange: function (component, event, helper) {
    var params = event.getParams(),
      changeData = {
        whatChanged: "options",
        changeData: params
      };
    helper.handleConfigChange(component, changeData).then(
      $A.getCallback(function () {
        helper.fireChangeEvent(component);
      })
    );
  },

  handlePackageAndSave: function (component, event, helper) {
    var isMotorRequest = component.get("v.isMotorRequest"),
      motor = component.get("v.motor");
    if (isMotorRequest) {
      var changeData = {
        whatChanged: "motor"
      };
      if (helper.motorIsPackageAndSave(component)) {
        motor.cost_description = "Package and Save";
        motor.cost = null;
        changeData.changeData = motor;
      } else {
        var toastContent = {
          type: "warning",
          title: "Motor was removed!",
          message: motor.name + " is not available for Package and Save Promotion"
        };
        component.set("v.toastContent", toastContent);
      }
      helper.handleConfigChange(component, changeData).then(
        $A.getCallback(function () {
          helper.fireChangeEvent(component);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
    } else {
      helper.handleMotor(component, motor.id).then(
        $A.getCallback(function () {
          helper.fireChangeEvent(component);
        }),

        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
    }
  }
});
