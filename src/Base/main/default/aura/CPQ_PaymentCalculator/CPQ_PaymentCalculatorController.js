({
  scriptsLoaded: function (component, event, helper) {
    helper.fetchTaxZones(component).then(
      $A.getCallback(function (result) {
        if (result !== undefined) {
          component.set("v.taxZones", result);
          helper.setCurrentTaxZone(component, component.get("v.currentTaxZone").id, "id");
        }
        helper.calculate(component);
        component.set("v.isLoaded", true);
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  calculate: function (component, event, helper) {
    helper.calculate(component);
  },

  handleTaxZoneChange: function (component, event, helper) {
    var taxZoneId = component.get("v.currentTaxZoneId");
    helper.setCurrentTaxZone(component, taxZoneId, "id");
  },

  termChange: function (component, event, helper) {
    var term = component.get("v.term"),
      amort = component.get("v.amort");
    if (parseInt(term) > parseInt(amort)) {
      amort = term;
      component.set("v.amort", amort);
    }
    helper.calculate(component);
  },

  insuranceTermChange: function (component, event, helper) {
    helper.calculate(component);
  },

  amortChange: function (component, event, helper) {
    var term = component.get("v.term"),
      amort = component.get("v.amort");
    if (parseInt(amort) < parseInt(term)) {
      term = amort;
      component.set("v.term", term);
    }
    helper.calculate(component);
  },

  rate_deposit_change: function (component, event, helper) {
    var deposit = component.get("v.deposit"),
      interestRate = component.get("v.interestRate");

    if (interestRate < 0) LightningUtils.errorToast("Interest Rate must be greater than or equal to zero");
    else if (deposit < 0) LightningUtils.errorToast("Deposit can not be less than zero");
    else {
      helper.calculate(component);
    }
  },

  handleUpdate: function (component, event, helper) {
    var evt = $A.get("e.c:CPQ_PaymentCalculator_PaymentsChanged_Event");
    evt
      .setParams({
        monthlyPayment: component.get("v.monthlyPayment"),
        biWeeklyPayment: component.get("v.biWeeklyPayment"),
        weeklyPayment: component.get("v.weeklyPayment"),
        term: component.get("v.term"),
        insuranceTerm: component.get('v.insuranceTerm'),
        interestRate: component.get("v.interestRate"),
        amort: component.get("v.amort"),
        deposit: component.get("v.deposit"),
        recordId: component.get("v.recordId")
      })
      .fire();
  }
});
