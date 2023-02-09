({
  saleItemFromSelectedOption: function (component, event, helper) {
    var self = this,
      params = event.getParam("arguments"),
      option = params.option,
      isIncluded = params.isIncluded,
      saleItem = helper.buildSaleItem(option, isIncluded);
    if (
      option.selectedSubOptions !== undefined &&
      option.selectedSubOptions !== null &&
      option.selectedSubOptions.length > 0
    ) {
      for (let subOption of option.selectedSubOptions) {
        var newSaleItem = helper.buildSaleItem(subOption);
        if (subOption.standard > 0) {
          newSaleItem.salePrice = 0;
          newSaleItem.lineTotal = 0;
        }
        saleItem.subSaleItems.push(newSaleItem);
      }
    }
    return saleItem;
  },

  doCalculation: function (component, event, helper) {
    var self = this,
      prodTypes = ["theBoat", "theMotor", "theTrailer", "theTrollingMotor"],
      params = event.getParam("arguments"),
      cpq = params.cpq,
      deposit =
        isNaN(cpq.deposit) || cpq.deposit === null || cpq.deposit === undefined || cpq.deposit.length == 0
          ? 0
          : parseFloat(cpq.deposit),
      totals = {
        subTotal: 0,
        insuranceTotal: 0,
        savingsTotal: 0,
        taxableTotal: 0,
        retailOnlyTaxableTotal: 0,
        fedTax: 0,
        provTax: 0,
        retailTax: 0
      },
      calcFees = function (obj, ignoreTaxable) {
        var total = 0;
        if (obj.fees != null && Object.keys(obj).indexOf("fees") >= 0 && typeof obj.fees !== "undefined") {
          total = obj.fees.reduce(function (t, fee) {
            if (ignoreTaxable || (!ignoreTaxable && fee.taxable)) {
              t += parseFloat(fee.retailAmount);
            }
            return t;
          }, total);
        }
        return total;
      },
      calcSerialize = function (theProduct, totals) {
        if (Object.keys(cpq).indexOf(theProduct) >= 0 && cpq[theProduct] != null) {
          var cost = theProduct === "theBoat" ? cpq[theProduct].retailPrice : cpq[theProduct].retailUpgradeCost;
          totals.subTotal += cost;
          totals.subTotal += calcFees(cpq[theProduct], true);
          if (cpq[theProduct].taxable) {
            totals.taxableTotal += cost;
            totals.taxableTotal += calcFees(cpq[theProduct], false);
          }
        }
        return totals;
      };

    for (let theProduct of prodTypes) {
      totals = calcSerialize(theProduct, totals);
    }

    if (cpq.saleItems.length > 0) {
      for (let o of cpq.saleItems) {
        totals.subTotal += o.quantity * o.salePrice;
        if (o.taxable) {
          totals.taxableTotal += o.quantity * o.salePrice;
        }
        for (let sOpt of o.subSaleItems) {
          totals.subTotal += sOpt.quantity * sOpt.salePrice;
          if (sOpt.taxable) {
            totals.taxableTotal += sOpt.quantity * sOpt.salePrice;
          }
        }
      }
    }

    if (cpq.savings.length > 0) {
      totals.savingsTotal = cpq.savings.reduce(function (t, saving) {
        t += parseFloat(saving.amount);
        return t;
      }, totals.savingsTotal);
      totals.taxableTotal = cpq.savings.reduce(function (t, saving) {
        t += parseFloat(saving.amount);
        return t;
      }, totals.taxableTotal);
    }

    if (cpq.insuranceProducts.length > 0) {
      totals.insuranceTotal = cpq.insuranceProducts.reduce(function (t, insProd) {
        t += parseFloat(insProd.unitPrice);
        return t;
      }, totals.insuranceTotal);
      totals.retailOnlyTaxableTotal = cpq.insuranceProducts.reduce(function (t, insProd) {
        t += parseFloat(insProd.unitPrice);
        return t;
      }, totals.retailOnlyTaxableTotal);
    }

    if (cpq.warrantyOptions.length > 0) {
      cpq.warrantyOptions.forEach((item) => {
        const lineTotal = parseFloat(item.retailPrice * item.quantitySelected);
        totals.subTotal += lineTotal;
        if (item.taxable) {
          totals.taxableTotal += lineTotal;
        }
      });
    }

    if (cpq.maintenanceServicePlanOptions.length > 0) {
      cpq.maintenanceServicePlanOptions.forEach((item) => {
        const lineTotal = parseFloat(item.retailPrice * item.quantitySelected);
        totals.subTotal += lineTotal;
        if (item.taxable) {
          totals.taxableTotal += lineTotal;
        }
      });
    }

    if (cpq.additionalAccessories.length > 0) {
      totals.subTotal = cpq.additionalAccessories.reduce(function (t, aa) {
        t += parseFloat(aa.salePrice * aa.quantity);
        return t;
      }, totals.subTotal);
      totals.taxableTotal = cpq.additionalAccessories.reduce(function (t, aa) {
        if (aa.isTaxable) {
          t += parseFloat(aa.salePrice * aa.quantity);
        }
        return t;
      }, totals.taxableTotal);
    }

    if (cpq.customProducts.length > 0) {
      totals.subTotal = cpq.customProducts.reduce(function (t, cp) {
        t += parseFloat(cp.amount * cp.quantity);
        return t;
      }, totals.subTotal);
      totals.taxableTotal = cpq.customProducts.reduce(function (t, cp) {
        t += parseFloat(cp.amount * cp.quantity);
        return t;
      }, totals.taxableTotal);
    }

    if (cpq.tradeIn !== undefined && cpq.tradeIn !== null) {
      if (cpq.tradeIn.value !== undefined) {
        totals.taxableTotal -= cpq.tradeIn.value;
      }
    }
    totals.fedTax = cpq.isTaxExempt ? 0 : (totals.taxableTotal * cpq.taxZone.federalRate) / 100;
    totals.provTax = cpq.isTaxExempt ? 0 : (totals.taxableTotal * cpq.taxZone.provincialRate) / 100;
    totals.retailTax = cpq.isTaxExempt ? 0 : (totals.retailOnlyTaxableTotal * cpq.taxZone.provincialRate) / 100;
    totals.preTaxTotal =
      totals.subTotal + totals.insuranceTotal + totals.savingsTotal - deposit - (cpq.tradeIn.value - cpq.tradeIn.lien);

    totals.grandTotal =
      totals.subTotal +
      totals.insuranceTotal +
      totals.savingsTotal +
      totals.fedTax +
      totals.provTax +
      totals.retailTax -
      deposit -
      (cpq.tradeIn.value - cpq.tradeIn.lien);
    totals.preInsuranceTotal = totals.grandTotal - totals.insuranceTotal - totals.retailTax + deposit;
    return totals;
  }
});
