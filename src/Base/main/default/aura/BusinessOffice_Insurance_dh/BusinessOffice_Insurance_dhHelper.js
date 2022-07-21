({
  initialize: function (component) {
    component.set("v.loading", true);
    component.set("v.saving", false);
    component.set("v.planId", null);
    component.set("v.planSelectDisabled", false);
    this.fetchInitial(component).then(
      $A.getCallback(function (result) {
        console.log(JSON.parse(JSON.stringify(result)));
        var deposit = result.deposit === null ? 0 : result.deposit,
          selectedItems = result.selectedItems;
        // if there are already selected insurance items
        // disable the plan select
        if (selectedItems !== undefined && selectedItems !== null && Object.keys(selectedItems).length > 0) {
          component.set("v.planSelectDisabled", true);
        }
        component.set("v.hasResidualValue", result.finTerm !== result.amort);
        component.set("v.isFromQuebec", result.isFromQuebec);
        component.set("v.originalInitComplete", true);
        component.set("v.hasChanges", false);
        component.set("v.staleData", false);
        component.set("v.planOptions", {});
        component.set("v.plans", result.plans);
        component.set("v.planId", result.planId);
        component.set("v.amort", result.amort);
        component.set("v.intrestRate", result.intrestRate);
        component.set("v.preInsuranceAmount", result.preInsuranceAmount);
        component.set("v.deposit", deposit);
        component.set("v.term", result.term);
        component.set("v.finTerm", result.finTerm);
        component.set("v.taxZoneId", result.taxZoneId);
        component.set("v.insuranceTaxRate", result.insuranceTaxRate);
        component.set("v.selectedItems", selectedItems);
        component.set("v.loading", false);
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  fetchInitial: function (component) {
    var action = component.get("c.insurance_init"),
      la;
    action.setParams({
      recordId: component.get("v.recordId")
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  fetchPlanOptions: function (component) {
    var action = component.get("c.fetchInsurancePlanOptions"),
      params = {
        planId: component.get("v.planId"),
        pricebookId: component.get("v.pricebookId")
      },
      la;

    action.setParams(params);

    la = new LightningApex(this, action);
    return la.fire();
  },

  saveItems: function (component) {
    var itemsToUpdate,
      recordId = component.get("v.recordId"),
      action = component.get("c.saveInsuranceItems"),
      la;

    itemsToUpdate = this.buildItemsToSend(component);

    action.setParams({
      parentRecordId: recordId,
      items: JSON.stringify(itemsToUpdate.itemsForSaving),
      deleteRecordIds: itemsToUpdate.idsToDelete
    });

    la = new LightningApex(this, action);
    return la.fire();
  },

  buildItemsToSend: function (component) {
    var result = {
        itemsForSaving: [],
        idsToDelete: []
      },
      selected = component.get("v.selectedItems"),
      selectedProductIds = [],
      items = component.find("insurance-item");

    if (items !== undefined && items.length > 0) {
      for (var i = 0; i < items.length; i++) {
        var r = {},
          lineItem = items[i].get("v.lineItem");
        if (items[i].get("v.isSelected")) {
          selectedProductIds.push(items[i].get("v.productId"));
          r.productId = items[i].get("v.productId");
          r.pricebookEntryId = items[i].get("v.pricebookEntryId");
          r.insuranceRate = items[i].get("v.insuranceRate");
          r.isResidual = items[i].get("v.isResidual") === "true";
          r.coverage = items[i].get("v.coverageType");
          r.unitPrice = items[i].get("v.unitPrice");
          r.termError = items[i].get("v.termOutOfRange");
          r.productFamily = items[i].get("v.type");
          if (
            lineItem !== undefined &&
            lineItem !== null &&
            lineItem.recordId !== undefined &&
            lineItem.recordId !== null
          ) {
            r.recordId = lineItem.recordId;
          }
          result.itemsForSaving.push(r);
        } else {
          if (
            lineItem !== undefined &&
            lineItem !== null &&
            lineItem.recordId !== undefined &&
            lineItem.recordId !== null
          ) {
            result.idsToDelete.push(lineItem.recordId);
          }
        }
      }
    }
    if (Object.keys(selected).length > 0) {
      for (let i of Object.keys(selected)) {
        if (selectedProductIds.indexOf(i) < 0) {
          if (result.idsToDelete.indexOf(selected[i].recordId) < 0) result.idsToDelete.push(selected[i].recordId);
        }
      }
    }
    return result;
  },

  recalculate: function (component, sendChangeEvent) {
    sendChangeEvent = sendChangeEvent === undefined ? true : sendChangeEvent;
    var self = this,
      newChangedItems,
      changeEvt;
    self
      .getSelectedItems(component)
      .then(
        $A.getCallback(function (selected) {
          component.set("v.planSelectDisabled", selected.length > 0);
          return self.calculateCost(selected, component);
        })
      )
      .then(
        $A.getCallback(function (items) {
          var result = {};

          for (var i = 0; i < items.length; i++) {
            result[items[i].productId] = items[i].unitPrice;
          }
          self.updateInsuranceItemAttr(result, "v.unitPrice", component);
          if (sendChangeEvent) {
            newChangedItems = self.buildItemsToSend(component);
            changeEvt = $A.get("e.c:BusinessOffice_Insurance_ChangedEvent_dh");
            changeEvt
              .setParams({
                insuranceItems: newChangedItems.itemsForSaving
              })
              .fire();
          }
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
  },

  getSelectedItems: function (component) {
    return new Promise(function (resolve, reject) {
      var items = component.find("insurance-item"),
        result = [];
      if (items !== undefined) {
        for (var i = 0; i < items.length; i++) {
          if (items[i].get("v.isSelected") && !items[i].get("v.termOutOfRange")) {
            var r = {},
              lineItem = items[i].get("v.lineItem");
            r.productId = items[i].get("v.productId");
            r.pricebookEntryId = items[i].get("v.pricebookEntryId");
            r.insuranceRate = items[i].get("v.insuranceRate");
            r.isResidual = items[i].get("v.isResidual");
            r.coverage = items[i].get("v.coverageType");
            r.type = items[i].get("v.type");
            r.productFamily = items[i].get("v.type");
            if (
              lineItem !== undefined &&
              lineItem !== null &&
              lineItem.recordId !== undefined &&
              lineItem.recordId !== null
            ) {
              r.recordId = lineItem.recordId;
            }
            result.push(r);
          }
        }
      } else {
        console.log("_Insurance: helper.getSelectedItems ITEMS UNDEFINED");
      }
      resolve(result);
    });
  },

  calculateCost: function (selected, component) {
    var isFromQuebec = component.get("v.isFromQuebec"),
      self = this,
      preInsuranceAmount = component.get("v.preInsuranceAmount"),
      deposit = component.get("v.deposit"),
      term = component.get("v.term"),
      amort = component.get("v.amort"),
      intrestRate = component.get("v.intrestRate"),
      insuranceTaxRate = component.get("v.insuranceTaxRate"),
      calculationMethod = "Recursive";

    if (isFromQuebec) {
      calculationMethod = "Simple";
    }

    return LightningUtils.doInsuranceCostCalculations(
      selected,
      preInsuranceAmount,
      deposit,
      term,
      amort,
      intrestRate,
      insuranceTaxRate,
      calculationMethod
    );
  },

  updateInsuranceItemAttr: function (data, attr, component) {
    var items = component.find("insurance-item");

    if (items !== undefined && items.length > 0) {
      for (var i = 0; i < items.length; i++) {
        var prodId = items[i].get("v.productId");
        if (data.hasOwnProperty(prodId)) items[i].set(attr, data[prodId]);
      }
    }
  }
});
