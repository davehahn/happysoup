/**
 * Created by Tim on 2021-03-25.
 */

import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import { stringy, stripParentheses, rewriteMotorName, rewriteTrailerName, convertLength, parseLocationName, formatPrice, weeklyPayment } from 'c/communitySharedUtils';
import fetchStandardProducts from '@salesforce/apex/FactoryStore_InventoryController.fetchBoat';
import fetchNewInStockInventory from '@salesforce/apex/FactoryStore_InventoryController.fetchNewInStockInventory';
import fetchFullBoatDetails from '@salesforce/apex/FactoryStore_InventoryController.fetchFullBoatDetails';
//import fetchNewInStockCurrentBoats from '@salesforce/apex/FactoryStore_InventoryController.fetchNewInStockCurrentBoats';
//import fetchRiggedEquipment from '@salesforce/apex/FactoryStore_InventoryController.fetchRiggedEquipment';

export default class FactoryStoreBoatListingItem extends NavigationMixin(LightningElement) {
	@api boat;
	@api locationName;

	startingRetailPrice;
	startingWeeklyPrice;
	boatName;
	modelListingPhoto;
	standardMotor;
	standardTrailer;
	standardTollingMotor;
	overallLength;
	centerlineLength;
	packageLength;

	currentStockQuantity;
	currentStock = [];

	stockPromises = [];


	@wire(CurrentPageReference) pageRef;

	navToBoat(event) {
		let page = 'boat-model',
			params = {
				c__recordId: event.currentTarget.dataset.record
			};
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

	quickQuote(event) {
		// 	  console.log('trigger quick quote');
		// 	  console.log('display quick connect form for modelId: ', event.currentTarget.dataset.record);
		let details = {
			recordId: this.boat.Base.Id,
			boatName: this.boatName,
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

	connectedCallback() {
	  console.log(JSON.parse(JSON.stringify(this.boat)));
	  this.startingRetailPrice = formatPrice(this.boat.Expanded.RetailPrice, true);
	 	this.startingWeeklyPrice = weeklyPayment(this.boat.Expanded.RetailPrice);
		this.boatName = stripParentheses(this.boat.Base.Name);
		this.modelListingPhoto = 'background-image: url(' + this.boat.Base.Default_Gallery_Image_Original__c + ')';
		this.standardMotor = (this.boat.Base.Standard_Motor__r) ? rewriteMotorName(this.boat.Base.Standard_Motor__r.Name) : '';
		this.standardTrailer = (this.boat.Base.Standard_Trailer__r) ? ' and ' + rewriteTrailerName(this.boat.Base.Standard_Trailer__r.Name) : '';
		if (this.boat.Base.Overall_Length__c) {
			this.overallLength = convertLength(this.boat.Base.Overall_Length__c);
		}
		if (this.boat.Base.Length__c) {
			this.centerlineLength = convertLength(this.boat.Base.Length__c);
		}
		if (this.boat.Base.Package_Length__c) {
			this.packageLength = convertLength(this.boat.Base.Package_Length__c);
		}

		const inventory = fetchNewInStockInventory({ location: parseLocationName(this.locationName), year: 2021, modelId: this.boat.Base.Id })
			.then((boats) => {
				boats.forEach((boat, index) => {

				  this.stockPromises.push(

						fetchFullBoatDetails({modelId: boat.Serial.productId})
							.then( (fullBoat) => {

								this.currentStock.push({
									Base: {
										SerialId: boat.Serial.serialId,
										ProductName: stripParentheses(boat.Serial.productName),
										ProductId: boat.Serial.productId,
										SerialNumber: boat.Serial.serialNumber,
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
              		this.currentStock[index].Base.RetailUpgradeCost += retailUpgradeCost;
              		this.currentStock[index].Base.StartingRetailPrice += retailUpgradeCost;

									let productName = (e.productType === 'Motor') ? rewriteMotorName(e.productName) : ' and ' + rewriteTrailerName(e.productName);
									this.currentStock[index].Base.Equipment.push({
										ProductId: e.productId,
										ProductName: productName
									});

								});

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

	get isDeckBoat() {
		return (this.boat.Base.Family === 'Deck Boat') ? true : false;
	}
	get isPontoon() {
		return (this.boat.Base.Family === 'Pontoon') ? true : false;
	}

	get isFishingBoat() {
		return (this.boat.Base.Family !== 'Deck Boat' && this.boat.Base.Family !== 'Pontoon') ? true : false;
	}

	triggerStockList(){
		console.log('current inventory', this.currentStock);
		this.currentStock.forEach((boat, index) => {
		  boat.Base.StartingWeeklyPrice = weeklyPayment(boat.Base.StartingRetailPrice);
			boat.Base.StartingRetailPrice = formatPrice(boat.Base.StartingRetailPrice, true);
  	});
		this.currentStockQuantity = this.currentStock.length;
 	}

}
