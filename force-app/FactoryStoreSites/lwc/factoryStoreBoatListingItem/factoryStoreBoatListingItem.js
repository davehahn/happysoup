/**
 * Created by Tim on 2021-03-25.
 */

import { LightningElement, api, wire, track } from 'lwc';

export default class FactoryStoreBoatListingItem extends LightningElement {
 @api boat;

 selectBoat( event ){
		console.log('select boat:', event.currentTarget.dataset.recordId);
		const selectedBoat = event.currentTarget.dataset.recordId;
		console.log('selectedBoat', selectedBoat);
		const selectBoatEvent = new CustomEvent('selectboat', {
			bubbles: true,
			detail: selectedBoat
		});
		this.dispatchEvent(selectBoatEvent);
	}
}