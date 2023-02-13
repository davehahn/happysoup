({
  initialize: function (component) {
    component.set("v.loading", true);
    this.doInit(component).then(
      $A.getCallback(function (result) {
        component.set("v.loading", false);
        console.log(result);
        component.set("v.originalSelectedLineIds", result.selectedLineIds);
        component.set("v.warrantItems", result.warranty);
        component.set("v.serviceItems", result.service);
        component.set("v.isDeprecated", result.isDeprecated);
        component.set("v.changed", false);
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  doInit: function (component) {
    var action = component.get("c.initServiceAndWarranty"),
      la;

    action.setParams({
      recordId: component.get("v.recordId"),
      pbId: component.get("v.pricebookId")
    });

    la = new LightningApex(this, action);
    return la.fire();
  },

  doSave: function (component) {
    var action = component.get("c.saveWarrantyAndServiceLines"),
      options = component.find("cpq-option-cmp"),
      originalSelectedLineIds = component.get("v.originalSelectedLineIds"), //lineId when component was orig loaded
      currentLineIds = [],
      forSaving = [],
      item,
      la;

    if (options !== undefined && options !== null) {
      for (var i = 0; i < options.length; i++) {
        if (options[i].get("v.isSelected")) {
          item = {
            lineId: options[i].get("v.lineId"),
            productId: options[i].get("v.productId"),
            productName: options[i].get("v.productName"),
            pricebookEntryId: options[i].get("v.pricebookEntryId"),
            unitCost: options[i].get("v.unitCost"),
            parentProductId: options[i].get("v.parentProductId"),
            quantitySelected: options[i].get("v.quantitySelected"),
            isPrepaid: options[i].get("v.isPrepaid")
          };
          forSaving.push(item);

          //if there is a lineId, the item existed originally
          if (options[i].get("v.lineId") !== null) currentLineIds.push(options[i].get("v.lineId"));

          var subOpts = options[i].get("v.subOptions");
          if (subOpts !== undefined && subOpts !== null && subOpts.length > 0) {
            for (var ii = 0; ii < subOpts.length; ii++) {
              if (subOpts[ii].isSelected) {
                item = {
                  lineId: subOpts[ii].lineId,
                  productId: subOpts[ii].productId,
                  productName: subOpts[ii].productName,
                  pricebookEntryId: subOpts[ii].pricebookEntryId,
                  unitCost: subOpts[ii].unitCost,
                  parentProductId: subOpts[ii].parentProductId,
                  quantitySelected: subOpts[ii].quantitySelected
                };
                forSaving.push(item);

                if (subOpts[ii].lineId !== null) currentLineIds.push(subOpts[ii].lineId);
              }
            }
          }
        }
      }
      console.log("FORSAVING *****************************");
      console.log(forSaving);

      if (currentLineIds.length > 0) {
        for (let id of currentLineIds) {
          // if any of the currently selected line Ids exist in the original array,
          // remove them, and any ids left in the original array means these items
          // where de-selected and need to be deleted
          if (originalSelectedLineIds.indexOf(id) >= 0)
            originalSelectedLineIds.splice(originalSelectedLineIds.indexOf(id), 1);
        }
      }
      action.setParams({
        recordId: component.get("v.recordId"),
        items: JSON.stringify(forSaving),
        lineIdsToDelete: originalSelectedLineIds
      });

      la = new LightningApex(this, action);
      return la.fire();
    }
    return Promise.resolve();
  }
});
