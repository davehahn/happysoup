({
  doInit: function (component, event, helper) {
    var lines = component.get("v.lines");
    helper.getInitialData(component);
    helper.synchronize(component);
  },

  handleWhoChange: function (component, event, helper) {
    //helper.getNames(component);
  },

  addLineItem: function (component, event, helper) {
    console.log("addLineItem");
    var debit_lines = component.get("v.debit_lines"),
      credit_lines = component.get("v.credit_lines");
    debit_lines.push([0, "", 0.0]);
    component.set("v.debit_lines", debit_lines);
    credit_lines.push([0, "", 0.0]);
    component.set("v.credit_lines", credit_lines);
  },

  balanceAddedLines: function (component, event, helper) {
    console.log("balanceAddedLines");
    var debit_lines = component.get("v.debit_lines"),
      credit_lines = component.get("v.credit_lines"),
      sum_debit = 0.0,
      sum_credit = 0.0,
      isBalanced = false;
    console.table(debit_lines);
    for (var i = 0; i < debit_lines.length; i++) {
      console.table(debit_lines[i]);
      sum_debit += parseFloat(debit_lines[i][2]);
    }
    for (var i = 0; i < credit_lines.length; i++) {
      sum_credit += parseFloat(credit_lines[i][2]);
    }
    isBalanced = sum_debit == sum_credit;
    console.log(sum_debit);
    console.log(sum_credit);
    console.log(isBalanced);
    component.set("v.addedLinesBalance", isBalanced);
  },

  createEntries: function (component, event, helper) {
    console.log("createEntries");
    var self = this,
      spinner = component.find("spinner");
    spinner.toggle();
    helper.validateLines(component).then(
      $A.getCallback(function (result) {
        console.log(result);
        if (result == false) {
          console.log("createEntries: not balanced");
          spinner.toggle();
          LightningUtils.errorToast("All debits and credits must be balanced.");
        } else {
          console.log("createEntries: balanced, proceed.");
          var entries = result;
          console.log(entries);
          helper.createJournalEntry(component, entries).then(
            $A.getCallback(function (result) {
              component.set("v.journalEntryMade", true);
              LightningUtils.showToast("success", "Success", "Journal entry created.");
              spinner.toggle();
            }),
            $A.getCallback(function (err) {
              LightningUtils.errorToast(err);
              spinner.toggle();
            })
          );
        }
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
        spinner.toggle();
      })
    );
  },

  sync: function (component, event, helper) {
    helper.synchronize(component);
  },

  toggleWarrantyTable: function (component, event, helper) {
    var table = component.find("warrantyTable");
    if ($A.util.hasClass(table, "slds-hide")) {
      $A.util.removeClass(table, "slds-hide");
    } else {
      $A.util.addClass(table, "slds-hide");
    }
  }
});
