/**
 * Created by Tim on 2021-07-09.
 */

import { LightningElement, api } from 'lwc';
import { stringy, stripParentheses, rewriteMotorName, rewriteTrailerName, convertLength, parseLocationName, formatPrice, weeklyPayment } from 'c/communitySharedUtils';
import fetchNewInStockInventory from '@salesforce/apex/FactoryStore_InventoryController.fetchNewInStockInventory';
//import fetchFullBoatDetails from '@salesforce/apex/FactoryStore_InventoryController.fetchFullBoatDetails';

export default class FactoryStoreCurrentInventoryList extends LightningElement {

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
				boats.forEach((boat, index) => {
					this.stockPromises.push(
							boat
//						fetchFullBoatDetails({modelId: boat.Serial.productId})
//							.then( (fullBoat) => {
//
//								this.storeStock.push({
//									Base: {
//										SerialId: boat.Serial.serialId,
//										ProductName: stripParentheses(boat.Serial.productName),
//										ProductId: boat.Serial.productId,
//										SerialNumber: boat.Serial.serialNumber,
//										BaseRetailPrice: fullBoat.RetailPrice,
//										StartingWeeklyPrice: weeklyPayment(fullBoat.RetailPrice),
//										StartingRetailPrice: fullBoat.RetailPrice,
//										StartingWeeklyPrice: 0,
//										RetailUpgradeCost: 0,
//										WeeklyUpgradeCost: 0,
//										Equipment: []
//									},
//									Expanded: fullBoat
//								});
//								boat.Equipment.forEach((e, i) => {
//									let retailUpgradeCost = 0;
//									if(e.productType === 'Motor'){
//										fullBoat.MotorUpgrades.forEach( (motor, index) => {
//											if(motor.Id === e.productId){
//												retailUpgradeCost += motor.RetailUpgradeCost
//											}
//										});
//									} else {
//										fullBoat.TrailerUpgrades.forEach( (trailer, index) => {
//											if(trailer.Id === e.productId){
//												retailUpgradeCost += trailer.RetailUpgradeCost
//											}
//										});
//									}
//									this.storeStock[index].Base.RetailUpgradeCost += retailUpgradeCost;
//									this.storeStock[index].Base.StartingRetailPrice += retailUpgradeCost;
//
//									let productName = (e.productType === 'Motor') ? rewriteMotorName(e.productName) : ' and ' + rewriteTrailerName(e.productName);
//									this.storeStock[index].Base.Equipment.push({
//										ProductId: e.productId,
//										ProductName: productName
//									});
//
//								});
//
//							}).catch(e => {
//								console.log('fetchFullBoatDetails error: ', e);
//							})

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

}