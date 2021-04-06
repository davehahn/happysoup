/**
 * Created by Tim on 2021-03-25.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { stringy, stripParentheses, rewriteMotorName, rewriteTrailerName } from 'c/factoryStoreUtils';

export default class FactoryStoreBoatListingItem extends NavigationMixin(LightningElement) {
 @api boat;

 @track boatName;

 navToBoat( event ){
		console.log(JSON.stringify(event.currentTarget.dataset));
		console.log(event.currentTarget.nodeName);
		console.log(event.target.nodeName);
		let page = 'boat-model',
				params = {
					c__recordId: event.currentTarget.dataset.record
    		};
    this.navigateToCommunityPage( page, params );
    event.preventDefault();
	}

	navigateToCommunityPage( pageName, params ){
	  console.log( pageName );
	  console.log( params );
	  this[NavigationMixin.Navigate]({
	  	type: 'comm__namedPage',
	  	attributes: {
	  		pageName: pageName
    	},
    	state: params
   	});
 	}

 	renderedCallback(){
 	  this.boatName = stripParentheses(this.boat.Name);
  }

}