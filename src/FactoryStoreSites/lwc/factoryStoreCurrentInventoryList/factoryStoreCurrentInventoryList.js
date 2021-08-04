/**
 * Created by Tim on 2021-07-09.
 */

import { LightningElement, api, wire } from 'lwc';
import { stringy, stripParentheses, rewriteMotorName, rewriteTrailerName, convertLength, parseLocationName, formatPrice, weeklyPayment } from 'c/communitySharedUtils';
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


	renderedCallback(){
		const inventory = fetchNewInStockInventory({ location: parseLocationName(this.locationName), year: 2021, modelId: this.boatId })
			.then((boats) => {
				boats.RiggedBoats.forEach((boat, index) => {
					this.stockPromises.push(
						fetchFullBoatDetails({modelId: boat.Serial.productId})
							.then( (fullBoat) => {

								this.storeStock.push({
									Base: {
										SerialId: boat.Serial.serialId,
										ProductName: stripParentheses(boat.Serial.productName),
										ProductId: boat.Serial.productId,
										SerialNumber: boat.Serial.serialNumberValue,
										BaseRetailPrice: fullBoat.RetailPrice,
										StartingWeeklyPrice: weeklyPayment(fullBoat.RetailPrice),
										StartingRetailPrice: fullBoat.RetailPrice,
										StartingWeeklyPrice: 0,
										RetailUpgradeCost: 0,
										WeeklyUpgradeCost: 0,
										Equipment: []
									},
									Expanded: fullBoat
								});
								if(boat.Equipment){
								 boat.Equipment.forEach((e, i) => {
										let retailUpgradeCost = 0;
										if(e.productType === 'Motor'){
											fullBoat.MotorUpgrades.forEach( (motor, index) => {
												if(motor.Id === e.productId){
													retailUpgradeCost += motor.RetailUpgradeCost
												}
											});
										} else {
											fullBoat.TrailerUpgrades.forEach( (trailer, index) => {
												if(trailer.Id === e.productId){
													retailUpgradeCost += trailer.RetailUpgradeCost
												}
											});
										}
										this.storeStock[index].Base.RetailUpgradeCost += retailUpgradeCost;
										this.storeStock[index].Base.StartingRetailPrice += retailUpgradeCost;

										let productName = (e.productType === 'Motor') ? rewriteMotorName(e.productName) : ' and ' + rewriteTrailerName(e.productName);
										this.storeStock[index].Base.Equipment.push({
											ProductId: e.productId,
											ProductName: productName
										});

									});
        				}

							}).catch(e => {
								console.log('fetchFullBoatDetails error: ', e);
							})

					);

				});
				Promise.all(this.stockPromises).then(() => {
					this.triggerStockList();
				});
			}).catch(e => {
				console.log('Fetch Inventory Error: ', e);
			});
 	}

 	triggerStockList(){
		console.log('current inventory (component): ', this.storeStock);
		this.storeStock.forEach((boat, index) => {
			boat.Base.StartingWeeklyPrice = weeklyPayment(boat.Base.StartingRetailPrice);
			boat.Base.StartingRetailPrice = formatPrice(boat.Base.StartingRetailPrice, true);
		});
		this.currentStock = this.storeStock;
		this.storeStockQuantity = this.storeStock.length;

		const passStockEvent = new CustomEvent('updatestockvalue', {
			detail: this.storeStockQuantity
  	});
  	this.dispatchEvent(passStockEvent);

	}


	@wire(CurrentPageReference) pageRef;
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