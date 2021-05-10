({
	search : function(component, event) {
		console.log('serno_search.helper.search');
		var action 		= component.get("c.findBySerialNumber"),
				query	 		= component.get("v.serno"),
				combobox 	= component.find('name_combobox'),
				context 	= component.get('v.context'),
				retrictToThisProduct = component.get('v.RestrictToThisProduct');

		console.log(query);

		//RESET
		// component.set('v.showProductCard',false);
		component.set('v.accountName', null);

		if (query.length >= 2) {
			action.setParams({
				"serno": query,
				"context": context,
				"retrictToThisProduct": retrictToThisProduct
			});
			action.setCallback(this, function(response) {
				this.renderResults(response, component);
			});
			$A.enqueueAction(action);
		} else {
			component.set('v.showProductCard',false);
			// component.set('v.sernoId', null);
			component.set('v.ProductName',null);
			component.set('v.ProductDescription',null);
			component.set('v.ProductType',null);
			component.set('v.ProductLocation',null);
			component.set("v.items", null);
			this.toggle(combobox, 'close');
		}
	},

	renderResults : function(response, component) {
		var data 			= response.getReturnValue(),
				combobox 	= component.find('name_combobox');

		try {
			if (data.length > 0) {
				console.log(data);
				component.set("v.items", data);
				this.toggle(combobox, 'open');
			} else {
				console.log("error: no data");
				component.set("v.items", '');
				this.toggle(combobox, 'close');
			}
		} catch(e) {
			console.log("error:null");
			component.set("v.items", '');
			this.toggle(combobox, 'close');
		}
	},

	toggle : function(element, action) {
		if (action == 'open') {
			$A.util.removeClass(element, 'slds-is-closed');
			$A.util.addClass(element, 'slds-is-open');
		} else if (action == 'close') {
			$A.util.removeClass(element, 'slds-is-open');
			$A.util.addClass(element, 'slds-is-closed');
		}
	},

	clickSerialNumber : function (component, event) {
		console.log('clickSerialNumber');
		var self 					= this,
				selectedItem 	= event.currentTarget,
				serno 				= selectedItem.dataset.name,
				sernoId 			= selectedItem.dataset.sernoid,
				nestId 				= selectedItem.dataset.sernoid,
				skipCard			= component.get('v.skipCard');

		return new Promise(function(resolve, reject) {
			if (skipCard) {
				self.fillNest(component, event, serno, sernoId, nestId)
						.then(function() {
							console.log('resolve?');
							resolve();
						});
			} else {
				self.populateSerialCard(component, event, serno, sernoId, nestId)
						.then(function() {
							console.log('resolve?');
							resolve();
						});
			}
		});
	},

	getCard : function (component, event) {
		console.log('helper.getCard');
		var sernoId 			= component.get('v.sernoId'),
				// serno 				= component.get('v.serno'),
				nestId 				= sernoId;

		console.log('sernoId:');
		console.log(sernoId);

		console.log('nestId:');
		console.log(nestId);
		if( sernoId !== undefined && sernoId !== null && sernoId.length > 0)
		{
		  this.populateSerialCard(component, event, '', sernoId, nestId);
		}
	},

	populateSerialCard : function (component, event, serno, sernoId, nestId) {
		console.log('populateSerialCard');

		var details = component.get("c.findBySerialId"),
				combobox = component.find('name_combobox');

		component.set('v.selectionMade', true);

		this.toggle(combobox, 'close');

		return new Promise(function(resolve, reject) {
			details.setParams({
				"sernoId": sernoId
			});
			details.setCallback(this, function(response) {
				resolve();
				var productDetails = response.getReturnValue();
				console.log('PROD DETAILS!!!!!');
				console.log(productDetails);
				component.set('v.sernoId', sernoId);
				component.set('v.serno', productDetails[0].Name);
				component.set('v.sernoName', productDetails[0].Name);
				component.set('v.nestId', nestId);
				component.set('v.lot', productDetails[0].GMBLASERP__Lot__r.Name);
				component.set('v.ProductName', productDetails[0].Product_Name__c);
				component.set('v.ProductDescription', productDetails[0].Description__c);
				component.set('v.ProductType', productDetails[0].Product_Record_Type__c);
				component.set('v.ProductLocation', productDetails[0].Location__c);
				component.set('v.showProductCard',true);
				component.set('v.canBeNest', productDetails[0].GMBLASERP__Product__r.Can_be_Nest__c);
				if( productDetails[0].Registrations__r !== undefined && productDetails[0].Registrations__r[0].Account__r !== undefined) {
					component.set('v.accountId', productDetails[0].Registrations__r[0].Account__c);
					component.set('v.accountName', productDetails[0].Registrations__r[0].Account__r.Name);
				}
				component.set('v.ProductId', productDetails[0].GMBLASERP__Product__r.Id);
			});
			$A.enqueueAction(details);
		});
	},

	fillNest : function (component, event, serno, sernoId, nestId) {
		console.log('fillNest:' + serno);
		component.set('v.selectionMade', true);

		var details = component.get("c.findBySerialId"),
				combobox = component.find('name_combobox');

		this.toggle(combobox, 'close');

		return new Promise(function(resolve, reject) {
			details.setParams({
				"sernoId": sernoId
			});
			details.setCallback(this, function(response) {
				var productDetails = response.getReturnValue();
				console.log( productDetails );
				component.set('v.sernoId', sernoId);
				component.set('v.serno', serno);
				component.set('v.nestId', nestId);
				component.set('v.ProductName', productDetails[0].Product_Name__c);
				component.set('v.ProductDescription', productDetails[0].Description__c);
				component.set('v.ProductType', productDetails[0].Product_Record_Type__c);
				component.set('v.ProductLocation', productDetails[0].Location__c);
				component.set('v.showProductCard',true);
				component.set('v.canBeNest', productDetails[0].GMBLASERP__Product__r.Can_be_Nest__c);

				console.log('nest filled?');

				resolve();
			});
			$A.enqueueAction(details);
		});
	}
})