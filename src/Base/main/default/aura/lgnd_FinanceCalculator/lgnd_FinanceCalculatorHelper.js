({
  initComponent: function (component) {
    var indicator = component.find("busy-indicator"),
      self = this;
    $A.util.removeClass(indicator, "toggle");
    self.fetchRecord(component).then(
      $A.getCallback(function (result) {
        component.set("v.insuranceLines", result.insuranceLines);
        component.set("v.insuranceTaxRate", result.insuranceTaxRate);
        component.set("v.preInsuranceAmount", result.preInsuranceAmount);
        component.set("v.finTerm", result.finTerm);
        component.set("v.finAmort", result.finAmort);
        component.set("v.insTerm", result.insTerm);
        component.set("v.intrestRate", result.intrestRate);
        component.set("v.deposit", result.deposit);
        component.set("v.originalInitComplete", true);
        component.set("v.hasChanged", false);
        self.calculatePayments(component);
        $A.util.addClass(indicator, "toggle");
      }),

      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  calculateInsuranceTotal: function (component) {
    var insuranceItems = component.get("v.insuranceLines"),
      taxRate = component.get("v.insuranceTaxRate") / 100,
      total = 0;
    component.set("v.termError", false);
    if (insuranceItems !== undefined && insuranceItems !== null) {
      for (var i = 0; i < insuranceItems.length; i++) {
        if (insuranceItems[i].termError) component.set("v.termError", true);
        total += insuranceItems[i].unitPrice * (1 + taxRate);
      }
    }
    return total;
  },

  fetchRecord: function (component) {
    var action = component.get("c.fetchRecord"),
      la;

    action.setParams({
      recordId: component.get("v.recordId")
    });

    la = new LightningApex(this, action);
    return la.fire();
  },

  doRecordSave: function (component) {
    var action = component.get("c.updateRecord"),
      data = {
        deposit: component.get("v.deposit"),
        intrestRate: component.get("v.intrestRate"),
        finTerm: component.get("v.finTerm"),
        finAmort: component.get("v.finAmort"),
        insTerm: component.get("v.insTerm")
      },
      la;

    action.setParams({
      financeDataJSON: JSON.stringify(data),
      recordId: component.get("v.recordId")
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  calculatePayments: function (component, hasChanged) {
    hasChanged = hasChanged === undefined ? false : hasChanged;
    component.set("v.hasChanged", hasChanged);

    var preInsuranceAmount = component.get("v.preInsuranceAmount"),
      insuranceTotal = this.calculateInsuranceTotal(component),
      deposit = component.get("v.deposit"),
      intrestRate = component.get("v.intrestRate"),
      finTerm = component.get("v.finTerm"),
      finAmort = component.get("v.finAmort"),
      insTerm = component.get("v.insTerm"),
      compound_per_year = 12,
      amountFinanced = preInsuranceAmount + insuranceTotal - deposit,
      compoundIntrest = intrestRate / 100 / compound_per_year,
      remaining,
      payment;

    deposit = deposit === null ? 0 : deposit;
    intrestRate = intrestRate === null ? 0 : parseFloat(intrestRate);
    finTerm = finTerm === null ? 0 : finTerm;
    finAmort = finAmort === null ? 0 : finAmort;
    insTerm = insTerm === null ? 0 : insTerm;

    if (intrestRate === 0) {
      payment = amountFinanced / finAmort;
      remaining = amountFinanced - payment * finTerm;
    } else {
      payment =
        (compoundIntrest * amountFinanced) /
        (1 - Math.pow(1 + compoundIntrest, -((finAmort * compound_per_year) / 12)));
      remaining =
        amountFinanced * Math.pow(1 + compoundIntrest, (finTerm * compound_per_year) / 12) -
        payment * ((Math.pow(1 + compoundIntrest, (finTerm * compound_per_year) / 12) - 1) / compoundIntrest);
    }

    component.set("v.monthlyPayment", payment / (12 / compound_per_year));
    component.set("v.biWeeklyPayment", payment / (26 / compound_per_year));
    component.set("v.weeklyPayment", payment / (52 / compound_per_year));
    component.set("v.remaining", remaining);
  }
});
