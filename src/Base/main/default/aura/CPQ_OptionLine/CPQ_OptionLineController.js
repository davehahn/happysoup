({
  doInit: function (component, event, helper) {
    var item = component.get("v.optionItem"),
      saleItems = component.get("v.saleItems");
      console.log( JSON.parse( JSON.stringify( item ) ) );
    if (!item.isCheckbox) {
      var opts = [];
      for (var i = item.standard; i <= item.maximum; i++) {
        opts.push(i);
      }
      component.set("v.quantityOptions", opts);
    }
    var qtySelected;
    //do subOption first
    if (item.isSubOption) {
      for (let saleItem of saleItems) {
        if (saleItem.productId == item.parentProductId) {
          qtySelected = 0;
          for (let subSaleItem of saleItem.subSaleItems) {
            if (subSaleItem.productId == item.id) {
              qtySelected += subSaleItem.quantity;
            }
          }
          if (qtySelected > 0) {
            item.isSelected = true;
            item.quantitySelected = qtySelected;
            component.set("v.optionItem", item);
          }
        }
      }
      component.set("v.compLoaded", true);
    } else {
      qtySelected = 0;
      for (let saleItem of saleItems) {
        if (saleItem.productId == item.id) {
          qtySelected += saleItem.quantity;
        }
      }
      if (qtySelected > 0) {
        item.quantitySelected = qtySelected;
        item.isSelected = true;
        component.set("v.optionItem", item);
        helper.fetchSubOptions(component);
      } else {
        component.set("v.compLoaded", true);
      }
    }
  },

  selectChanged: function (component, event, helper) {
    var item = component.get("v.optionItem"),
      qty = item.quantitySelected,
      subOpts = item.subOptions,
      parentProductId = item.parentProductId;

    item.isSelected = qty > 0;
    if (qty === 0) {
      item.selectedSubOptions = [];
    }
    component.set("v.optionItem", item);
    if (qty > 0 && parentProductId == null && (subOpts == null || subOpts.length === 0))
      helper.fetchSubOptions(component);
    else {
      if (qty == 0) {
        component.set("v.subOptions", []);
      }
      helper.changeComplete(component);
    }
  },

  toggleSelected: function (component, event, helper) {
    var item = component.get("v.optionItem"),
      selected = item.isSelected,
      parentProductId = item.parentProductId,
      options;
    item.quantitySelected = selected ? 1 : 0;
    if (selected == true && !item.isSubOption) {
      component.set("v.optionItem", item);
      helper.fetchSubOptions(component);
    } else {
      item.subOptions = [];
      item.selectedSubOptions = [];
      component.set("v.optionItem", item);
      helper.changeComplete(component);
    }
  }
});
