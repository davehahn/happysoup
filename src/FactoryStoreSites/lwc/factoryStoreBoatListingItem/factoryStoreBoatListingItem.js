/**
 * Created by Tim on 2021-03-25.
 */

import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import { stringy, stripParentheses, rewriteMotorName, rewriteTrailerName, convertLength, parseLocationName, formatPrice, weeklyPayment, renderEN, renderFR } from 'c/communitySharedUtils';
import fetchStandardProducts from '@salesforce/apex/FactoryStore_InventoryController.fetchBoat';

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

	isEN = renderEN();
	isFR = renderFR();

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
//	  console.log(JSON.parse(JSON.stringify(this.boat)));
	  this.startingRetailPrice = (this.isEN) ? formatPrice(this.boat.Expanded.RetailPrice, true) : formatPrice(this.boat.Expanded.RetailPrice, true, 'fr');
	 	this.startingWeeklyPrice = (this.isEN) ? weeklyPayment(this.boat.Expanded.RetailPrice) : weeklyPayment(this.boat.Expanded.RetailPrice, 'fr');
		this.boatName = this.setBoatName(stripParentheses(this.boat.Base.Name));
		this.modelListingPhoto = 'background-image: url(' + this.boat.Base.Default_Gallery_Image_Original__c + ')';
		this.standardMotor = (this.boat.Base.Standard_Motor__r) ? rewriteMotorName(this.boat.Base.Standard_Motor__r.Name) : '';
		if(this.isEN){
			this.standardTrailer = (this.boat.Base.Standard_Trailer__r) ? ' and ' + rewriteTrailerName(this.boat.Base.Standard_Trailer__r.Name) : '';
  	} else {
  		this.standardTrailer = (this.boat.Base.Standard_Trailer__r) ? ' et ' + rewriteTrailerName(this.boat.Base.Standard_Trailer__r.Name) : '';
   	}
		if (this.boat.Base.Overall_Length__c) {
			this.overallLength = convertLength(this.boat.Base.Overall_Length__c);
		}
		if (this.boat.Base.Length__c) {
			this.centerlineLength = convertLength(this.boat.Base.Length__c);
		}
		if (this.boat.Base.Package_Length__c) {
			this.packageLength = convertLength(this.boat.Base.Package_Length__c);
		}
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

	setBoatName(name){
		return (this.isFR) ? 'Serie ' + name.replace('-Series', '') : name;
 	}

	handleUpdateStockValue( e ){
		this.currentStockQuantity = e.detail;
 	}
}
