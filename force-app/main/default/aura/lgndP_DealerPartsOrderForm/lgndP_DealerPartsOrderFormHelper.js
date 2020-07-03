({
  inConsole: function( component )
  {
    var workspaceAPI = component.find('workspace');
    return new Promise( (resolve, reject ) => {
      workspaceAPI.isConsoleNavigation().then(function(response) {
       resolve(response);
      })
      .catch(function(error) {
        reject(error);
      });
    })
  },

	doInit: function(component)
	{
		var erpOrderId = component.get("v.erpOrderId"),
				action = component.get("c.getProductFamily"),
				la;

		action.setParams({
			"erpOrderId": erpOrderId,
			"saleType": component.get("v.saleType")
		});

		la = new LightningApex( this, action );
		return la.fire();
	},

	searchKeyChangeHelper : function(component) {
		var spinner = component.find('spinner');
		this.doSearch( component )
		.then(
			$A.getCallback( function( results ) {
				component.set("v.products", results);
				console.log( results );
				if(results.length == 0) {
						component.set("v.noFoundMessage", "No products found to your search criteria.");
						component.set("v.isFound", false);
				} else {
						component.set("v.noFoundMessage", "");
						component.set("v.isFound", true);
				}
			}),
			$A.getCallback( function( err ) {
				LightningUtils.errorToast( err );
			})
		)
		.finally( $A.getCallback( function() {
			spinner.toggle();
		}));
	},

	doSearch: function( component )
	{
		var searchKey = component.get("v.searchKey"),
				spinner = component.find('spinner'),
				action = component.get("c.getProductswithFamily"),
				params,
				la;

		if(searchKey.length < 2) {
			searchKey = "";
		}

		params = {
			"searchKey": searchKey.trim(),
			"pFamily": JSON.stringify(component.get("v.lstProdFamily")),
			"selectedIds": this.buildPdtIdString(component),
			"selectedBoatModel": component.get("v.selectedBoatModel"),
			"activePriceBookId": component.get('v.activePriceBookId'),
			"isInternalRetail": component.get('v.saleType') === 'Retail'
		};

		action.setParams( params );
		spinner.toggle();
		la = new LightningApex( this, action );
		return la.fire();
	},

	closeProductModal: function( component )
  {
    var modal = component.find("product-create-modal"),
        form = component.find("product-form");
    $A.util.addClass( modal, 'slds-hide');
    form.set('v.body', []);
  },

	multiplyQuanPdtsHelper : function(component, event) {
		var index = event.currentTarget.dataset.recordid;
		var className = ".inputNumber" + index;
		var quantity = document.querySelector(className).value;
		var tmpMaterialList = component.get("v.materials");
		tmpMaterialList[index].totalPrice = (quantity*tmpMaterialList[index].pricePerQuantity).toFixed(2);
		tmpMaterialList[index].matQuantity = quantity;
		component.set("v.materials", tmpMaterialList);
		this.calOrderTotal(component, tmpMaterialList);
	},

	addProductHelper : function(component,event,helper){
		var pdindex = component.get("v.listIndex");
		var tmpProductList = component.get("v.products");
		var tmpProduct = tmpProductList[pdindex];
		var index;
		var tmpMaterialList = component.get("v.materials");

		for(var i = 0; i < tmpMaterialList.length; i++) {
				if(tmpProduct.Id == tmpMaterialList[i].pdtId) {
						index = i;
						break;
				}
		}
		var quantity = tmpMaterialList[index].matQuantity + 1 ;
		tmpMaterialList[index].totalPrice = (quantity*tmpMaterialList[index].pricePerQuantity).toFixed(2);
		tmpMaterialList[index].matQuantity = quantity;
		component.set("v.materials", tmpMaterialList);
		this.calOrderTotal(component);
		$A.util.addClass(component.find("MyModalSec"),"HideModelBox") ;
	},

	calOrderTotal : function(component) {
			var orderTotal = 0.0,
			    materialList = component.get('v.materials');
			for(var i = 0; i < materialList.length; i++) {
					orderTotal += parseFloat(materialList[i].totalPrice);
			}
			component.set("v.grandTotal", orderTotal.toFixed(2));
	},

	buildPdtIdString : function(component) {
			var materialsList = component.get("v.materials");
			var pdtIds = "";
			for(var i = 0; i < materialsList.length; i++) {
					pdtIds += ((pdtIds.length == 0) ? '' : ':');
					pdtIds += materialsList[i].pdtId;
			}
			return pdtIds;
	},

	fetchNewlyCreatedProduct: function( component, prodId )
	{
		var action = component.get("c.fetchProductDetails"), la;
		action.setParams({
			prodId: prodId,
			pricebookId: component.get('v.activePriceBookId')
		});
		la = new LightningApex( this, action );
		return la.fire();
	},

	addToListHelper : function(component, event) {
		var index = event.currentTarget.dataset.recordid,
		    				tmpProductList = component.get("v.products"),
								tmpProduct = tmpProductList[index],
								self = this;

		if(!this.isAlreadyAdded(component.get("v.materials"), tmpProduct.Id))
		{
			self.addItemToCartList( component, tmpProduct);
		} else {
			component.set("v.listIndex",index);
			$A.util.removeClass(component.find("MyModalSec"),"HideModelBox") ;
		}
	},

	addItemToCartList: function( component, item )
	{
		var spinner = component.find('spinner');
		var _self = this;
		_self.searchInvQty( component, item )
		.then(
			$A.getCallback( function( results ) {
				var items = component.get("v.materials"),
					newWrapper = {};
				newWrapper.pdtId = item.Id;
				newWrapper.pdtName = item.Name;
				newWrapper.matQuantity = 1.0;
				newWrapper.pdtcode = item.ProductCode;
				newWrapper.pricePerQuantity = item.UnitPrice;
				newWrapper.matImgUrl = item.ImageURL;
				newWrapper.totalPrice = newWrapper.matQuantity*item.UnitPrice;
				newWrapper.AvailableQuantitySelf = results.qty;
				newWrapper.warehouseName = results.warehouseName;
				items.push(newWrapper);
				component.set("v.materials", items);
				_self.calOrderTotal( component );
			}),
			$A.getCallback( function( err ) {
				LightningUtils.errorToast( err );
			})
		)
		.finally( $A.getCallback( function() {
			spinner.toggle();
		}));		
	},

	searchInvQty: function( component, item )
	{
		var spinner = component.find('spinner'),
			action = component.get("c.getProductQuantity"),
			params,
			la;

		params = {
			"idProduct": item.Id
		};

		action.setParams( params );
		spinner.toggle();
		la = new LightningApex( this, action );
		return la.fire();
	},

	isAlreadyAdded : function(addedMaterialList, pdtId) {
			var isAdded = false;
			for(var i = 0; i < addedMaterialList.length; i++) {
					if(pdtId == addedMaterialList[i].pdtId) {
							isAdded = true;
							break;
					}
			}
			return isAdded;
	},

	returnToList: function()
	{
			var evt = $A.get("e.force:navigateToURL");
			evt.setParams({
					url: "/parts-orders",
					isredirect: true
			})
			.fire();
	},

	returnToDetails: function( component, erpId )
	{
	  let self = this;
	  if( component.get('v.inConsoleView') )
	  {
	    let focusedTabId;
	    const workspaceAPI = component.find("workspace");
	    workspaceAPI.getFocusedTabInfo()
      .then( (response) => {
        focusedTabId = response.tabId;
        return workspaceAPI.openTab({
          pageReference: {
            type: 'standard__recordPage',
            attributes: {
              recordId: erpId,
              actionName: 'view'
            },
            state: {}
          },
          focus: true
        });
      })
      .then( (response) => {
        workspaceAPI.refreshTab({tabId: focusedTabId});
      })
      .catch(function(error) {
          console.log(error);
      });
    }
    else
    {
      var navEvt = $A.get("e.force:navigateToSObject");
      navEvt.setParams({
        "recordId": erpId
      });
      navEvt.fire();
    }
	},

	submitRetail: function( component, accountId )
	{
		var action = component.get('c.saveRetailCounterSaleERP'),
				campaignSource = component.get('v.campaign'),
				lead = component.get('v.lead'),
				la;

		action.setParams({
			"materialsJSON" : JSON.stringify(component.get("v.materials")),
			"accountId": accountId,
			"campaignSource": campaignSource,
			"lead": lead
		});

		la = new LightningApex( this, action );
		return la.fire();
	},

	submitHelper : function(component, isSaveLater) {
			var self = this,
					params,
					action = component.get("c.saveMaterials"),
					la;
			action.setParams({
					"wrJSONStr" : JSON.stringify(component.get("v.materials")),
					"internalPoNumber": component.get("v.internalPoNumber"),
					"erpOrderId" : component.get("v.erpOrderId"),
					"removedMatIds" : component.get("v.removedMaterialIds"),
					"isSaveLater" : isSaveLater
			});

			la = new LightningApex( this, action );
			return la.fire();

			// return new Promise( function( resolve, reject ) {
			// 	action.setCallback(self, function(response) {
			// 			var state = response.getState();
			// 			if (state === "SUCCESS") {
			// 					resolve();
			// 			}
			// 			else if (state === "ERROR") {
			// 				var errors = response.getError();
			// 				if (errors) {
			// 					if (errors[0] )
			// 					{
			// 						if( errors[0].message )
			// 						{
			// 							reject("Error message: " +
			// 											 errors[0].message);
			// 						}
			// 						if( errors[0].fieldErrors )
			// 						{
			// 							var message = '';
			// 							for( var k in errors[0].fieldErrors )
			// 							{
			// 								if( errors[0].fieldErrors.hasOwnProperty( k ) )
			// 								{
			// 									message += k +": " + errors[0].fieldErrors[k][0].message + "\n";
			// 								}
			// 							}
			// 							reject(message);
			// 						}
			// 					}
			// 				} else {
			// 						reject("Unknown error");
			// 				}
			// 				$A.util.addClass( indicator, "slds-hide" );
			// 				// document.querySelector('.siteforceSpinnerManager.siteforcePanelsContainer')
			// 				// if(sp != null)
			// 				// 	sp.classList.add('hideEl');
			// 			}
			// 	});
			// 	$A.enqueueAction(action);
			// });
	},

	removeFromListHelper : function(component, event) {
			var index = event.currentTarget.dataset.recordid;
			var tmpMaterialList = component.get("v.materials");
			var tmpArrList1 = new Array();
			for (var i = 0; i < tmpMaterialList.length; i++) {
					if(i != index) {
							tmpArrList1.push(tmpMaterialList[i]);
					} else if(i == index) {
							if(tmpMaterialList[i].matId != undefined) {
									var removedId = component.get("v.removedMaterialIds");
									removedId += ((removedId.length == 0) ? '' : ':');
									removedId += tmpMaterialList[i].matId;
									component.set("v.removedMaterialIds", removedId);
							}
					}
			}
			component.set("v.materials", tmpArrList1);
			this.calOrderTotal(component, tmpArrList1);
	},


	showMessageHelper : function(isDone, component, message) {
			var toastEvent = $A.get("e.force:showToast");
			if(isDone) {
					if(!$A.util.isEmpty(component.get("v.erpOrderId"))) {
							toastEvent.setParams({
									"message": "Order changed.",
									"type": "success"
							});
					} else {
							toastEvent.setParams({
									"message": "Order successfully created.",
									"type": "success"
							});
					}
			} else {
					message = message === undefined ?
							'There is a problem in adding products. Please contact Administrator' :
							message;
					toastEvent.setParams({
							"message": message,
							"type": "error"
					});
			}
			toastEvent.fire();
			//this.hideShowEventFire(component, event);
	},

})