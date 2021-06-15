/**
 * Created by Tim on 2021-03-25.
 */

import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import { stringy, stripParentheses, rewriteMotorName, rewriteTrailerName, convertLength, parseLocationName } from 'c/communitySharedUtils';
import fetchStandardProducts from '@salesforce/apex/FactoryStore_InventoryController.fetchBoat';
import fetchNewInStockInventory from '@salesforce/apex/FactoryStore_InventoryController.fetchNewInStockInventory';
//import fetchNewInStockCurrentBoats from '@salesforce/apex/FactoryStore_InventoryController.fetchNewInStockCurrentBoats';
//import fetchRiggedEquipment from '@salesforce/apex/FactoryStore_InventoryController.fetchRiggedEquipment';

export default class FactoryStoreBoatListingItem extends NavigationMixin(LightningElement) {
 @api boat;
 @api locationName;

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


 @wire(CurrentPageReference) pageRef;

 navToBoat( event ){
		let page = 'boat-model',
				params = {
					c__recordId: event.currentTarget.dataset.record
    		};
    this.navigateToCommunityPage( page, params );
    event.preventDefault();
	}

	navigateToCommunityPage( pageName, params ){
	  this[NavigationMixin.Navigate]({
	  	type: 'comm__namedPage',
	  	attributes: {
	  		pageName: pageName
    	},
    	state: params
   	});
 	}

 	quickQuote( event ){
// 	  console.log('trigger quick quote');
// 	  console.log('display quick connect form for modelId: ', event.currentTarget.dataset.record);
 	  let details = {
 	    recordId: this.boat.Id,
 	    boatName: this.boatName
    }
//    console.log('details to send to form: ', details);
 	  fireEvent(this.pageRef, 'openOverlay', details);
 	  event.preventDefault();
  }

  showroomVisit( event ){
//    console.log('trigger showroom visit');
    let page = 'schedule-a-showroom-visit',
    		params = {
    			c__recordId: event.currentTarget.dataset.record
      	};
//    console.log(params);
    this.navigateToCommunityPage( page, params );
    event.preventDefault();
  }

 	renderedCallback(){
 	  this.boatName = stripParentheses(this.boat.Name);
 	  this.modelListingPhoto = 'background-image: url(' + this.boat.Default_Gallery_Image_Original__c + ')';
		this.standardMotor = (this.boat.Standard_Motor__r) ? rewriteMotorName(this.boat.Standard_Motor__r.Name) : '';
		this.standardTrailer = (this.boat.Standard_Trailer__r) ? ' and ' + rewriteTrailerName(this.boat.Standard_Trailer__r.Name) : '';
		if(this.boat.Overall_Length__c){
			this.overallLength = convertLength(this.boat.Overall_Length__c);
  	}
  	if(this.boat.Length__c){
  		this.centerlineLength = convertLength(this.boat.Length__c);
   	}
		if(this.boat.Package_Length__c){
			this.packageLength = convertLength(this.boat.Package_Length__c);
 	 	}

 	 	const inventory = fetchNewInStockInventory({location: parseLocationName(this.locationName), year: 2021, modelId: this.boat.Id})
 	 		.then( (result) => {
 	 		  console.log('fetchInventory result: ', result);
 	 		  this.currentStock = result;
 	 		  this.currentStockQuantity = result.length;
      }).catch( e => {
        console.log('Fetch Inventory Error: ', e);
      });
  }

  get allCurrentStock(){
    console.log('allCurrentStock: ', this.currentStock);
    return this.currentStock;
  }

	get isDeckBoat(){
	 return (this.boat.Family === 'Deck Boat') ? true : false;
 	}
  get isPontoon(){
    return (this.boat.Family === 'Pontoon') ? true : false;
  }

  get isFishingBoat(){
    return (this.boat.Family !== 'Deck Boat' && this.boat.Family !== 'Pontoon') ? true : false;
  }

//  get standardMotorName(){
//    let productIds = [this.standardMotorId, this.standardTrailerId, this.standardTollingMotorId];
//    let standardProducts = fetchStandardProducts(productIds);
//    console.log(standardProducts);
//  }

}