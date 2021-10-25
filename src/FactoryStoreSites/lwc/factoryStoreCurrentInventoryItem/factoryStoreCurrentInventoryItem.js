/**
 * Created by Tim on 2021-10-19.
 */

import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import { stringy, stripParentheses, rewriteMotorName, rewriteTrailerName, convertLength, parseLocationName, formatPrice, weeklyPayment, renderEN, renderFR } from 'c/communitySharedUtils';

export default class FactoryStoreCurrentInventoryItem extends NavigationMixin(LightningElement) {
	@api stock;
	@api isCurrent;

	isEN = renderEN();
	isFR = renderFR();

	@wire(CurrentPageReference) pageRef;

	get isCurrentModel(){
		return (this.isCurrent === 'true') ? true : false;
 	}

 	get savings(){
 	  return formatPrice((this.stock.Base.Savings * -1), true);
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