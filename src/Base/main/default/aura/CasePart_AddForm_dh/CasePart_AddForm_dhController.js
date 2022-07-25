({
  doInit: function (component, event, helper) {
    console.log("doInit");
    //var partLookupComponent = component.find("partLookup");
    var partLookupQuantityComponent = component.find("partLookupQuantity");
    var partLookupOrderQuantityComponent = component.find("partLookupOrderQuantity");
    component.set("v.parts", []);
    component.set("v.partLookupValue", null);
    partLookupQuantityComponent.set("v.value", null);
    partLookupOrderQuantityComponent.set("v.value", null);
  },

  addPart: function (component, event, helper) {
    console.log("ADDPART");
    // validate part
    //var partLookupComponent = component.find("partLookup");
    //var partProductId = partLookupComponent.get("v.sobjectId");
    //partLookupComponent.set("v.error", null);
    var partProductId = component.get("v.partLookupValue");
    if (!partProductId) {
      //   if (!partLookupComponent.get("v.value")) {
      //     partLookupComponent.set("v.error", "Part is required");
      //   } else {
      //     partLookupComponent.set("v.error", "This part isn't valid");
      //   }
      //   return;
    }

    // validate quantity
    var partLookupQuantityComponent = component.find("partLookupQuantity");
    var quantity = partLookupQuantityComponent.get("v.value");
    partLookupQuantityComponent.set("v.errors", null);
    if (!quantity && quantity != 0) {
      partLookupQuantityComponent.set("v.errors", [{ message: "Quantity is required" }]);
      return;
    } else if (quantity <= 0) {
      partLookupQuantityComponent.set("v.errors", [{ message: "Quantity must be at least one" }]);
      return;
      // } else if (quantity % 1 != 0) {
      //   partLookupQuantityComponent.set("v.errors", [{ message: "Quantity must be a whole number" }]);
      //   return;
    }

    // validate quantity
    var partLookupOrderQuantityComponent = component.find("partLookupOrderQuantity");
    var orderQuantity = partLookupOrderQuantityComponent.get("v.value");
    partLookupOrderQuantityComponent.set("v.errors", null);
    if (!orderQuantity && orderQuantity != 0) {
      partLookupOrderQuantityComponent.set("v.errors", [{ message: "Order Quantity is required" }]);
      return;
    } else if (orderQuantity < 0) {
      partLookupOrderQuantityComponent.set("v.errors", [{ message: "Order Quantity must not be negative" }]);
      return;
    }
    if (orderQuantity > quantity) {
      partLookupOrderQuantityComponent.set("v.errors", [
        { message: "Order Quantity must be less or equal to claim quantity" }
      ]);
      return;
    }

    helper.getProduct(component, partProductId).then(
      $A.getCallback(function (product) {
        if (product) {
          helper.findPrice(component, product.Id).then(
            $A.getCallback(function (unitPrice) {
              // add product to our list of parts
              var parts = component.get("v.parts");
              parts.push({
                sobjectType: "Case_Part__c",
                Case__c: component.get("v.caseId"),
                Product__c: product.Id,
                Product__r: product,
                Quantity__c: quantity,
                Order_Quantity__c: orderQuantity,
                Unit_Price__c: unitPrice
              });
              component.set("v.parts", parts);
              // clear the part search and quantity fields
              component.set("v.partLookupValue", null);
              partLookupQuantityComponent.set("v.value", null);
            }),
            $A.getCallback(function (err) {
              helper.showToast("error", "An Error has Occured", err);
            })
          );
        }
      }),
      $A.getCallback(function (err) {
        helper.showToast("error", "An Error has Occured", err);
      })
    );
  },

  resetFrom: function (component) {
    console.log("RESET FORM");
    //var partLookupComponent = component.find("partLookup");
    var partLookupQuantityComponent = component.find("partLookupQuantity");
    var partLookupOrderQuantityComponent = component.find("partLookupOrderQuantity");
    component.set("v.parts", []);
    component.set("v.partLookupValue", null);
    //partLookupComponent.set("v.value", null);
    partLookupQuantityComponent.set("v.value", null);
    partLookupOrderQuantityComponent.set("v.value", null);
  },

  removePart: function (component, event, helper) {
    var parts = component.get("v.parts"),
      v = event.getSource().get("v.value");
    parts.splice(v, 1);
    component.set("v.parts", parts);
  }
});
