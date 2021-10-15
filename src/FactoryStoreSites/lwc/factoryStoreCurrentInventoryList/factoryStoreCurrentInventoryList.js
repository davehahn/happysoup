/**
 * Created by Tim on 2021-07-09.
 */

import { LightningElement, api, wire } from 'lwc';
import { stringy, stripParentheses, rewriteMotorName, rewriteTrailerName, convertLength, parseLocationName, formatPrice, weeklyPayment, renderEN, renderFR } from 'c/communitySharedUtils';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import fetchNewInStockInventory from '@salesforce/apex/FactoryStore_InventoryController.fetchNewInStockInventory';
import fetchFullBoatDetails from '@salesforce/apex/FactoryStore_InventoryController.fetchFullBoatDetails';

export default class FactoryStoreCurrentInventoryList extends NavigationMixin(LightningElement) {

	@api boat;
	@api boatId;
	@api locationName;

	currentStockQuantity;
	storeStock = [];
	currentStock = [];
	stockPromises = [];

	pBoat;
	pStock = [];

	isEN = renderEN();
	isFR = renderFR();

	lookupHasRunPreviously = false;

	@wire(CurrentPageReference) pageRef;

	renderedCallback(){

		if(this.lookupHasRunPreviously){
		  console.log('clear stock array');
		  if(this.currentStock.length > 0){
		    this.currentStock.length = 0;
    	}
		}

	  this.pBoat = JSON.parse(JSON.stringify(this.boat));
	  console.log('run lookup for ' + this.pBoat.Base.Name);


		const inventory = fetchNewInStockInventory({ location: parseLocationName(this.locationName), year: 2021, modelId: this.boatId })
			.then((boats) => {
			  this.lookupHasRunPreviously = true;
			  if(boats.RiggedBoats.length > 0){
			    boats.RiggedBoats.forEach((boat, index) => {
						this.storeStock.push({
							Base: {
								SerialId: boat.Serial.serialNumberId,
								ProductName: stripParentheses(boat.Serial.productName),
								ProductId: boat.Serial.productId,
								SerialNumber: boat.Serial.serialNumberValue,
								BaseRetailPrice: this.pBoat.Expanded.RetailPrice,
								StartingWeeklyPrice: weeklyPayment(this.pBoat.Expanded.RetailPrice),
								StartingRetailPrice: this.pBoat.Expanded.RetailPrice,
								ActualRetailPrice: 'TBD',
								ActualWeeklyPrice: 'TBD',
								Equipment: []
							},
							Expanded: this.pBoat
						});
						if(boat.Equipment){
						 let retailUpgradeCost = 0;
						 boat.Equipment.forEach((e, i) => {
								if(e.productType === 'Motor'){
									// TO FIX!! fullBoat is not the full boat details. need to figure this out for upgrade stuff to work!
									if(typeof this.pBoat.Expanded.MotorUpgrades !== 'undefined'){
										this.pBoat.Expanded.MotorUpgrades.forEach( (motor, index) => {
											if(motor.Id === e.productId){
												console.log('motor.RetailUpgradeCost boat ' + index + ': ', motor.RetailUpgradeCost);
												retailUpgradeCost += motor.RetailUpgradeCost;
											}
										});
									}
								} else {
									if(typeof this.pBoat.Expanded.TrailerUpgrades !== 'undefined'){
										this.pBoat.Expanded.TrailerUpgrades.forEach( (trailer, index) => {
											if(trailer.Id === e.productId){
												console.log('trailer.RetailUpgradeCost boat ' + index + ': ', trailer.RetailUpgradeCost);
												retailUpgradeCost += trailer.RetailUpgradeCost
											}
										});
									}
								}

								let productName = (e.productType === 'Motor') ? rewriteMotorName(e.productName) : ' and ' + rewriteTrailerName(e.productName);
								this.storeStock[index].Base.Equipment.push({
									ProductType: e.productType,
									ProductId: e.productId,
									ProductName: productName
								});
								this.storeStock[index].Base.Equipment.sort(function(a, b) {
									 return a.ProductType.toLowerCase().localeCompare(b.ProductType.toLowerCase());
								});

							});
							console.log('full upgrade cost boat ' + index + ':', retailUpgradeCost);
							this.storeStock[index].Base.RetailUpgradeCost = retailUpgradeCost;
							this.storeStock[index].Base.StartingRetailPrice = this.pBoat.Expanded.RetailPrice + retailUpgradeCost;
						}
					});
					this.triggerStockList(this.pBoat.Base.Name);
     		} //if(boats.length > 0){
			}).catch(e => {
				console.log('Fetch Inventory Error: ', e);
			});
 	}

 	triggerStockList(boatName){
		console.log('current ' + boatName + ' inventory (component): ', this.storeStock);

		this.storeStock.forEach((boat, index) => {
			boat.Base.StartingWeeklyPrice = (this.isEN) ? weeklyPayment(boat.Base.StartingRetailPrice) : weeklyPayment(boat.Base.StartingRetailPrice, 'fr');
			boat.Base.StartingRetailPrice = (this.isEN) ? formatPrice(boat.Base.StartingRetailPrice, true) : formatPrice(boat.Base.StartingRetailPrice, true, 'fr');
		});

		this.currentStock = this.storeStock;
		this.storeStockQuantity = this.currentStock.length;

		const passStockEvent = new CustomEvent('updatestockvalue', {
			detail: this.storeStockQuantity
  	});
  	this.dispatchEvent(passStockEvent);

	}

	quickQuote(event) {
		// 	  console.log('trigger quick quote');
		// 	  console.log('display quick connect form for modelId: ', event.currentTarget.dataset.record);
		let details = {
			recordId: event.currentTarget.dataset.record,
			boatName: event.currentTarget.dataset.name,
			serialNumber: event.currentTarget.dataset.serial
		}
		console.log('details to send to form: ', details);
		fireEvent(this.pageRef, 'openOverlay', details);
		event.preventDefault();
	}

	showroomVisit(event) {
		//    console.log('trigger showroom visit');
		let page = 'schedule-a-showroom-visit',
			params = {
				c__recordId: event.currentTarget.dataset.record,
				c__SN: event.currentTarget.dataset.serial
			};
		//    console.log(params);
		this.navigateToCommunityPage(page, params);
		event.preventDefault();
	}

	navigateToCommunityPage(pageName, params) {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				pageName: pageName
			},
			state: params
		});
	}

}