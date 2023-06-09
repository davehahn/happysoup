({
  calculate: function (component) {
    var amount = component.get("v.amount"),
      deposit = component.get("v.deposit"),
      interestRate = component.get("v.interestRate"),
      term = component.get("v.term"),
      insuranceTerm = component.get("v.insuranceTerm"),
      amort = component.get("v.amort"),
      compound_per_year = 12,
      compoundInterest,
      remaining,
      payment,
      m_payment,
      bw_payment,
      w_payment,
      fireEvent = !component.get("v.updateViaButton"),
      evt = $A.get("e.c:CPQ_PaymentCalculator_PaymentsChanged_Event");

    interestRate = interestRate === null ? 0 : interestRate;
    deposit = deposit === null ? 0 : deposit;
    const amountFinanced = amount;

    term = term === null ? 0 : term;
    amort = amort === null ? 0 : amort;
    if (parseFloat(interestRate) === 0) {
      payment = amountFinanced / amort;
      remaining = amountFinanced - payment * term;
    } else {
      (compoundInterest = interestRate / 100 / compound_per_year),
        (payment =
          (compoundInterest * amountFinanced) /
          (1 - Math.pow(1 + compoundInterest, -((amort * compound_per_year) / 12))));
      remaining =
        amountFinanced * Math.pow(1 + compoundInterest, (term * compound_per_year) / 12) -
        payment * ((Math.pow(1 + compoundInterest, (term * compound_per_year) / 12) - 1) / compoundInterest);
    }

    m_payment = payment / (12 / compound_per_year);
    bw_payment = payment / (26 / compound_per_year);
    w_payment = payment / (52 / compound_per_year);

    component.set("v.monthlyPayment", m_payment);
    component.set("v.biWeeklyPayment", bw_payment);
    component.set("v.weeklyPayment", w_payment);
    component.set("v.remaining", remaining);

    if (fireEvent) {
      const params = {
        monthlyPayment: m_payment,
        biWeeklyPayment: bw_payment,
        weeklyPayment: w_payment,
        term: term,
        insuranceTerm: insuranceTerm,
        interestRate: interestRate,
        amort: amort,
        deposit: deposit,
        recordId: component.get("v.recordId")
      }
      evt.setParams(params).fire();
    }
  },

  fetchTaxZones: function (component) {
    var taxZoneId = component.get("v.currentTaxZoneId"),
      taxZone = component.get("v.currentTaxZone"),
      action = component.get("c.fetchTaxZones");
    if (taxZoneId === undefined && taxZone !== undefined && taxZone !== null) {
      taxZoneId = taxZone.id;
    }
    if (taxZoneId === undefined) {
      return Promise.resolve();
    }
    return new LightningApex(this, action).fire();
  },

  setCurrentTaxZoneFromProv: function (component) {
    var prov = component.get("v.saleProvince");
    this.setCurrentTaxZone(component, prov, "name");
  },

  setCurrentTaxZone: function (component, matchValue, matchAttr) {
    var taxZones = component.get("v.taxZones");
    for (let tz of taxZones) {
      if (tz[matchAttr] === matchValue) {
        component.set("v.currentTaxZoneId", tz.id);
        component.set("v.currentTaxRate", (tz.provincialRate + tz.federalRate) / 100);
        component.set("v.currentTaxZone", tz);
        break;
      }
    }
    this.calculate(component);
  }
});
