/**
 * Created by dave on 2021-04-05.
 */

({
  doNextPromise: function (component, step) {
    let cmp = component.find("backOrderCreator");
    switch (step) {
      case 0:
        return cmp.stageTransferredMaterials();
      case 1:
        return cmp.findPartsRequestCases();
      case 2:
        return cmp.buildNewERP();
      case 3:
        return cmp.initializeChangesToOriginalOrder();
      case 4:
        return cmp.saveAllChanges();
      default:
        return Promise.resolve();
    }
  }
});
