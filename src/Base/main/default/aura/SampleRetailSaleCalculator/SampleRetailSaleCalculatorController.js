({
  doInit: function (component, event, helper) {
    console.log("DOINIT");
    helper.resetCustomProduct(component);
    component.set("v.promotions", []);
  },

  dataInit: function (component, event, helper) {
    console.log("doing dataInit");
    helper.fetchInitData(component).then(
      $A.getCallback(function (result) {
        if (result != null) {
          component.set("v.isInternalAccount", result.isInternalAccount);
          component.set("v.cpq", JSON.parse(result.cpq));
          if (result.legendVolumeDiscount != null) component.set("v.mercDiscount", result.legendVolumeDiscount / 100);
          if (result.legendCoopDiscount != null) component.set("v.coopDiscount", result.legendCoopDiscount / 100);
          if (result.legendVolumeDiscount != null) component.set("v.volumeDiscount", result.legendVolumeDiscount / 100);
        }
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  handleMobileMenuChange: function (component, event, helper) {
    var val = event.getParam("value");
    component.set("v.mobileMenuValue", event.getParam("value"));
  },

  handleMajorProductSelected: function (component, event, helper) {
    var params = event.getParams();
    component.set("v.customProducts", []);
    helper.resetCustomProduct(component);
    helper.fetchMajorProductDetails(component, params.family, params.recordTypeName, params.productId);
  },

  handlePromotionChange: function (component, event, helper) {
    var value = parseFloat(event.getParam("value"));
    if (isNaN(value)) value = 0;
    if (value > 0) {
      value = value * -1;
      event.getSource().set("v.value", value);
    }
    helper.calcTotals(component);
  },

  handleAddPromotion: function (component, event, helper) {
    var promos = component.get("v.promotions");

    promos.push({
      name: component.get("v.promotionName"),
      retail: component.get("v.retailPromotion"),
      partner: component.get("v.partnerPromotion")
    });
    component.set("v.promotions", promos);
    component.set("v.promotionName", "");
    component.set("v.retailPromotion", "");
    component.set("v.partnerPromotion", "");
  },

  handleRemovePromotion: function (component, event, helper) {
    var val = event.getSource().get("v.value");
    if (val === undefined) {
      component.set("v.retailPromotion", "");
      component.set("v.partnerPromotion", "");
      component.set("v.promotionName", "");
    } else {
      var promos = component.get("v.promotions");
      promos.splice(val, 1);
      component.set("v.promotions", promos);
    }
    helper.calcTotals(component);
  },

  validNegative: function (component, event, helper) {
    var value = parseFloat(event.getParam("value"));
    if (!isNaN(value) && value > 0) event.getSource().set("v.value", value * -1);

    helper.calcTotals(component);
  },

  // handleOptionChange: function( component, event, helper )
  // {
  //   var opt = event.getParams().optionItem,
  //       cpq = component.get('v.cpq'),
  //       selectedOpts = cpq.selectedOptions;

  //   if( opt.isSelected )
  //   {
  //     if( opt.isCheckbox )
  //       if( opt.parentProductId != null )
  //         helper.updateSelectedOptions.add.checkboxSubOption( selectedOpts, opt );
  //       else
  //         helper.updateSelectedOptions.add.checkboxOption( selectedOpts, opt );
  //     else
  //     {
  //       if( opt.parentProductId != null )
  //         helper.updateSelectedOptions.add.multipleSubOption( selectedOpts, opt );
  //       else
  //         helper.updateSelectedOptions.add.multipleOption( selectedOpts, opt );
  //     }
  //   }
  //   else
  //   {
  //     if( opt.parentProductId != null )
  //     {
  //       helper.updateSelectedOptions.remove.subOption( selectedOpts, opt );
  //     }
  //     else
  //       helper.updateSelectedOptions.remove.option( selectedOpts, opt );
  //   }
  //   cpq.selectedOptions = selectedOpts
  //   component.set('v.cpq', cpq);
  // },

  handleCPQ: function (component, event, helper) {
    if (event.getParam("oldValue") != null) {
      component.set("v.hasFees", helper.setHasFees(component));
      helper.calcTotals(component);
    }
  },

  calcTotals: function (component, event, helper) {
    helper.calcTotals(component);
  },

  addCustomProduct: function (component, event, helper) {
    var customProducts = component.get("v.customProducts");
    customProducts.push(component.get("v.customProduct"));
    component.set("v.customProducts", customProducts);
    helper.resetCustomProduct(component);
  },

  removeCustomProduct: function (component, event, helper) {
    var id = event.getSource().get("v.value"),
      customProducts = component.get("v.customProducts"),
      idx;
    for (var i = 0; i < customProducts.length; i++) {
      if (customProducts[i].id === id) idx = i;
    }
    if (!isNaN(idx)) customProducts.splice(idx, 1);
    component.set("v.customProducts", customProducts);
  }
});
