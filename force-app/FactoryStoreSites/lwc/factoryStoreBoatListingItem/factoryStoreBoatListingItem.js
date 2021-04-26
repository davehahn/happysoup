/**
 * Created by Tim on 2021-03-25.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { stringy, stripParentheses, rewriteMotorName, rewriteTrailerName } from 'c/communitySharedUtils';
import fetchStandardProducts from '@salesforce/apex/FactoryStore_InventoryController.fetchBoat';

export default class FactoryStoreBoatListingItem extends NavigationMixin(LightningElement) {
 @api boat;

 @track boatName;
 @track modelListingPhoto;
 @track standardMotorId;
 @track standardTrailerId;
 @track standardTollingMotorId;

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
 	  console.log('trigger quick quote');
 	  event.preventDefault();
  }

  showroomVisit( event ){
    console.log('trigger showroom visit');
    event.preventDefault();
  }

 	renderedCallback(){
 	  this.boatName = stripParentheses(this.boat.Name);
 	  this.modelListingPhoto = 'background-image: url(' + this.boat.Default_Gallery_Image_Original__c + ')';
// 	  this.standardMotorId = rewriteMotorName(this.boat.StandardMotor);
//		this.standardTrailerId = rewriteTrailerName(this.boat.StandardTrailer);
		this.standardMotorId = this.boat.Standard_Motor__r.Name;
		this.standardTrailerId = this.boat.Standard_Trailer__r.Name;
  }

//  get standardMotorName(){
//    let productIds = [this.standardMotorId, this.standardTrailerId, this.standardTollingMotorId];
//    let standardProducts = fetchStandardProducts(productIds);
//    console.log(standardProducts);
//  }

}