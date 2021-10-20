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
	hasCurrentStock = false;
	nonCurrentStock = [];
	hasNonCurrentStock = false;

	parseCurrentStock = [];
	parseNonCurrentStock = [];

	stockPromises = [];

	pBoat;
	pBoatName;
	pStock = [];

	isEN = renderEN();
	isFR = renderFR();

	calendarYear = new Date().getFullYear();
	calendarMonth = new Date().getMonth();
	modelYear;

	lookupHasRunPreviously = false;

	@wire(CurrentPageReference) pageRef;

	renderedCallback(){

		if(this.lookupHasRunPreviously){
		  console.log('clear stock array');
		  if(this.currentStock.length > 0){
		    this.currentStock.length = 0;
		    this.parseCurrentStock.length = 0;
		    this.parseNonCurrentStock.length = 0;
    	}
		}

	  this.pBoat = JSON.parse(JSON.stringify(this.boat));
	  this.pBoatName = stripParentheses(this.pBoat.Base.Name);
	  console.log('run lookup for ' + this.pBoat.Base.Name);

	  this.modelYear = (this.calendarMonth >= 9) ? this.calendarYear + 1 : this.calendarYear;
	  console.log('current model year: ', this.modelYear);


		const inventory = fetchNewInStockInventory({ location: parseLocationName(this.locationName), year: this.modelYear, modelId: this.boatId })
			.then((boats) => {
			  this.lookupHasRunPreviously = true;
			  if(boats.RiggedBoats.length > 0){
			    boats.RiggedBoats.forEach((boat, index) => {
						let setSavings = (typeof boat.Serial.serialSavings === 'undefined') ? 0 : boat.Serial.serialSavings;
						this.storeStock.push({
							Base: {
								SerialId: boat.Serial.serialNumberId,
								ProductName: stripParentheses(boat.Serial.productName),
								ProductId: boat.Serial.productId,
								SerialNumber: boat.Serial.serialNumberValue,
								SerialModelYear: boat.Serial.serialModelYear,
								BaseRetailPrice: this.pBoat.Expanded.RetailPrice,
								StartingWeeklyPrice: weeklyPayment(this.pBoat.Expanded.RetailPrice),
								StartingRetailPrice: this.pBoat.Expanded.RetailPrice,
								SpecialRetailPrice: 0,
								SpecialWeeklyPrice: 0,
								HasSpecialPrice: false,
								Savings: setSavings,
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

							this.storeStock[index].Base.HasSpecialPrice = (this.storeStock[index].Base.Savings < 0) ? true : false;
							this.storeStock[index].Base.SpecialRetailPrice = (this.pBoat.Expanded.RetailPrice + this.storeStock[index].Base.Savings) + retailUpgradeCost;

							if(this.storeStock[index].Base.SerialModelYear === this.modelYear){
								 this.parseCurrentStock.push(this.storeStock[index]);
       				} else {
       					this.parseNonCurrentStock.push(this.storeStock[index]);
           		}
						}
					});
					this.triggerStockList();
     		} //if(boats.length > 0){
			}).catch(e => {
				console.log('Fetch Inventory Error: ', e);
			});
 	}

 	triggerStockList(){
//		console.log('current ' + boatName + ' inventory (component): ', this.storeStock);

		console.log('current year stock: ', this.parseCurrentStock);
		console.log('non current year stock: ', this.parseNonCurrentStock);

		this.formatListingPrices(this.parseCurrentStock);
		this.formatListingPrices(this.parseNonCurrentStock);

		this.currentStock = this.parseCurrentStock;
		this.nonCurrentStock = this.parseNonCurrentStock;

		this.hasCurrentStock = (this.currentStock.length > 0) ? true : false;
		this.hasNonCurrentStock = (this.nonCurrentStock.length > 0) ? true : false;
		this.storeStockQuantity = this.currentStock.length + this.nonCurrentStock.length;

		const passStockEvent = new CustomEvent('updatestockvalue', {
			detail: this.storeStockQuantity
  	});
  	this.dispatchEvent(passStockEvent);

	}

	formatListingPrices(list){
	  list.forEach((boat, index) => {
			boat.Base.StartingWeeklyPrice = (this.isEN) ? weeklyPayment(boat.Base.StartingRetailPrice) : weeklyPayment(boat.Base.StartingRetailPrice, 'fr');
			boat.Base.StartingRetailPrice = (this.isEN) ? formatPrice(boat.Base.StartingRetailPrice, true) : formatPrice(boat.Base.StartingRetailPrice, true, 'fr');

			boat.Base.SpecialWeeklyPrice = (this.isEN) ? weeklyPayment(boat.Base.SpecialRetailPrice) : weeklyPayment(boat.Base.SpecialRetailPrice, 'fr')
			boat.Base.SpecialRetailPrice = (this.isEN) ? formatPrice(boat.Base.SpecialRetailPrice, true) : formatPrice(boat.Base.SpecialRetailPrice, true, 'fr');
		});
		return list;
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