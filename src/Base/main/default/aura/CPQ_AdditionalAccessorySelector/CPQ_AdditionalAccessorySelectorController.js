/**
 * Created by dave on 2022-10-26.
 */

({
  doInit: function (component, event, helper) {
    const returnFields = ["Id", "Product2Id", "Product_Name__c", "ProductCode", "Product_Description__c", "UnitPrice", "IsProductTaxable__c"];
    const displayFields = ["ProductCode", "Product_Description__c"];
    const filterFields = ["Product_Name__c", "ProductCode"];
    const cpq = component.get("v.cpq");
    const whereClause =
      "Product2.RecordType.Name = 'Part' AND IsActive = True AND Product2.isActive = True AND Pricebook2Id = '" +
      cpq.activePricebookId +
      "'";
    component.set("v.returnFields", returnFields);
    component.set("v.displayFields", displayFields);
    component.set("v.filterOnFields", filterFields);
    component.set('v.whereClause', whereClause);

    console.log(JSON.parse(JSON.stringify(cpq)));
  },
  afterScripts: function (component, event, helper) {},
  openForm: function (component, event, helper) {
    component.set("v.showForm", true);
  },
  handleProductSelect: function (component, event, helper) {
    console.log("handleProductSelect");
    const result = event.getParam("value");
    console.log(JSON.parse(JSON.stringify(result)));
    helper
      .initAdditionalAccessory(component, result)
      .then(
        $A.getCallback((additionalAcc) => {
          component.set("v.newProduct", additionalAcc);
        })
      )
      .catch(
        $A.getCallback((error) => {
          console.log("Additional Accessory Error");
          console.log(JSON.parse(JSON.stringify(error)));
        })
      )
      .finally(
        $A.getCallback(() => {
          console.log("additional accessory finally");
        })
      );
  },
  handleCancel: function(component, event, helper){
    helper.closeForm(component);
  },
  addProduct: function (component, event, helper) {
    let isValid = component.find("required-input").reduce((validSoFar, inputCmp) => {
      if (inputCmp.checkValidity() === undefined) {
        return validSoFar;
      }
      inputCmp.reportValidity();
      return validSoFar && inputCmp.checkValidity();
    }, true);
    if (!isValid) {
      return;
    }
    console.log("valid and continue to add product");
    helper.addProductToCPQ(component);
  },
  removeProduct: function (component, event, helper) {
    let aaIndex = event.getSource().get("v.value");
    let cpq = component.get("v.cpq");
    cpq.additionalAccessories.splice(aaIndex, 1);
    component.set("v.cpq", cpq);
    console.log(aaIndex);
  }
});
