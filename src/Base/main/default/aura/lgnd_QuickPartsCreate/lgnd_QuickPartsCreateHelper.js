({
  resetForm: function (component) {
    var part = {
      Name: "",
      Name_FR__c: "",
      Family: "",
      Description: "",
      Description_FR__c: "",
      ProductCode: "",
      AcctSeed__Unit_Cost__c: "",
      AcctSeedERP__Default_Vendor__c: "",
      AcctSeed__Inventory_Product__c: true,
      Unit_of_Measurement__c: "Each",
      Taxable__c: true
    };
    component.set("v.part", part);
    component.set("v.currentStep", 1);
  },

  isValid: function (fields) {
    var inputs = [];
    if (fields.length === undefined) inputs.push(fields);
    else inputs = fields;

    return inputs.reduce(function (validSoFar, inputCmp) {
      inputCmp.showHelpMessageIfInvalid();
      return validSoFar && inputCmp.get("v.validity").valid;
    }, true);
  },

  getInitOptions: function (component) {
    var action = component.get("c.fetchInitOptions"),
      context = component.get("v.componentContext"),
      recId,
      la;

    if (context !== "utilityBar") recId = component.get("v.recordId");

    action.setParams({
      externalProductId: recId
    });

    la = new LightningApex(this, action);
    return la.fire();
  },

  submitPart: function (component) {
    var data = {},
      part = JSON.parse(JSON.stringify(component.get("v.part"))),
      action = component.get("c.createPart"),
      la;

    data.part = part;
    data.retailPrice = component.get("v.retailPrice");
    data.partnerPrice = component.get("v.partnerPrice");
    data.externalReferenceId = component.get("v.recordId");

    action.setParams({
      jsonData: JSON.stringify(data)
    });

    la = new LightningApex(this, action);
    return la.fire();
  },

  createComplete: function (component, part) {
    this.resetForm(component);
    LightningUtils.showToast("success", "Success", "Part was created");

    var context = component.get("v.componentContext"),
      createdEvent = component.getEvent("partCreatedEvent");

    createdEvent
      .setParams({
        productId: part.Id,
        productCode: part.ProductCode
      })
      .fire();

    if (context == "quickAction") {
      $A.get("e.force:closeQuickAction").fire();
      $A.get("e.force:refreshView").fire();
    }

    if (context === "utilityBar") {
      var ubAPI = component.find("utilitybar");
      ubAPI.minimizeUtility();
    }

    if (context == "modal") {
    }
  },

  toastMessage: function (component, type, message) {
    component.set("v.toastContent", { type: type, message: message });
  },

  toggleIndicator: function (component) {
    var spinner = component.find("spinner");
    if (spinner !== undefined && spinner !== null) spinner.toggle();
  }
});
