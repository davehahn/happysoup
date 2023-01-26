({
  unSelectMajorProduct: function (component) {
    var cpq = component.get("v.cpq");
    if (cpq === undefined || cpq === null) {
      return false;
    }
    //Only clear the CPQ if we have not populated it from a Quote or Opp
    if (cpq.saveToRecordId == null || cpq.saveToRecordId == undefined || cpq.saveToRecordId == "") {
      cpq.boatId = null;
      cpq.motorId = null;
      cpq.trailerId = null;
      cpq.trollingMotorId = null;
      cpq.theBoat = null;
      cpq.theMotor = null;
      cpq.theTrailer = null;
      cpq.theTrollingMotor = null;
      cpq.selectedOptions = [];
      cpq.savings = [];
      cpq.customProducts = [];
      cpq.fees = [];
      cpq.saleItems = [];
      cpq.tradeIn = { value: 0, lien: 0, items: [] };
    }
    return cpq;
  },

  fetchMajorProductDetails: function (component, family, recordType, productId) {
    var self = this,
      action = component.get("c.fetchBoatDetails"),
      cpq = self.unSelectMajorProduct(component);

    cpq.baseProductRecordType_Name = recordType;
    cpq.baseProductFamily = family;

    // if( typeof(productId) !== 'string' )
    // {
    //   if( typeof( cpq.boatId ) === 'string' )
    //     self.unSelectMajorProduct( component );
    // }
    // else
    // {
    cpq.boatId = productId;
    component.set("v.cpq", cpq);
    action.setParams({
      cpqJSON: JSON.stringify(cpq)
    });
    this.updateCPQ(component, action);
    // }
  },

  updateCPQ: function (component, action) {
    var spinner = component.find("spinner");
    spinner.toggle();
    return new Promise(function (resolve, reject) {
      new LightningApex(this, action)
        .fire()
        .then(
          $A.getCallback(function (result) {
            component.set("v.cpq", result);
          }),
          $A.getCallback(function (err) {
            LightningUtils.errorToast(err);
          })
        )
        .finally(
          $A.getCallback(function () {
            spinner.toggle();
            resolve();
          })
        );
    });
  },

  updateSaleItems: function (component, option) {
    var cpq = component.get("v.cpq"),
      saleItems = cpq.saleItems,
      cpqUtils = component.find("CpqUtils"),
      removeItem = function (isExistingItem) {
        if (option.isSubOption) {
          var idx, subIdx;
          for (var i = 0; i < saleItems.length; i++) {
            if (saleItems[i].productId === option.parentProductId) {
              idx = i;
              for (var ii = 0; ii < saleItems[i].subSaleItems.length; ii++) {
                if (saleItems[i].subSaleItems[ii].productId == option.prod.Id) {
                  if (isExistingItem) {
                    if (saleItems[i].subSaleItems[ii].salePrice > 0) {
                      subIdx = ii;
                      break;
                    }
                  } else {
                    subIdx = ii;
                    break;
                  }
                }
              }
              if (idx !== null) break;
            }
          }
          if (idx !== undefined && subIdx !== undefined) {
            saleItems[idx].subSaleItems.splice(subIdx, 1);
          }
        } else {
          var idx;
          for (var i = 0; i < saleItems.length; i++) {
            if (saleItems[i].productId == option.prod.Id && saleItems[i].lineTotal > 0) {
              if (isExistingItem) {
                if (saleItems[i].salePrice > 0) {
                  idx = i;
                  break;
                }
              } else {
                idx = i;
                break;
              }
            }
          }
          if (idx !== undefined && idx !== null) {
            saleItems.splice(idx, 1);
          }
        }
      },
      addOrUpdateItem = function (isExistingItem) {
        if (option.isSubOption) {
          for (let saleItem of saleItems) {
            if (saleItem.productId == option.parentProductId) {
              doAddOrUpdate(saleItem.subSaleItems, isExistingItem);
            }
          }
        } else {
          doAddOrUpdate(saleItems, isExistingItem);
        }
      },
      doAddOrUpdate = function (items, isExistingItem) {
        var exists = false;
        for (let item of items) {
          if (item.productId == option.prod.Id) {
            if (isExistingItem) {
              if (item.salePrice > 0) {
                exists = true;
                item.quantity = option.quantitySelected - option.standard;
                item.lineTotal = item.quantity * option.retailPrice;
                break;
              }
            } else {
              exists = true;
              item.quantity = option.quantitySelected;
              item.lineTotal = option.quantitySelected * option.retailPrice;
              break;
            }
          }
        }
        if (!exists) {
          var item = cpqUtils.saleItemFromSelectedOption(option, false);
          if (isExistingItem) {
            item.quantity = option.quantitySelected - option.standard;
            item.lineTotal = item.quantity * option.retailPrice;
          }
          items.push(item);
        }
      };

    /*
      possibilities:
        option is non standard ( option.standard = 0 )
        option has standard quantity ( option.standard > 0 )
    */
    if (option.standard === 0) {
      if (parseInt(option.quantitySelected) === 0) {
        removeItem(false);
      } else {
        addOrUpdateItem(false);
      }
    } else {
      if (
        parseInt(option.standard) === parseInt(option.quantitySelected) &&
        parseInt(option.standard) !== parseInt(option.maximum)
      ) {
        removeItem(true);
      } else {
        addOrUpdateItem(true);
      }
    }

    cpq.saleItems = saleItems;
    component.set("v.cpq", cpq);
  }
});
