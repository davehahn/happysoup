/**
 * Created by Tim on 2020-05-27.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners} from 'c/pubsub';

export default class CustCommOrderPurchasePrice extends LightningElement {
	@api boatRetailPrice;
	@api boatSku;
	@track totalPrice;

	baseItem = [];
	performanceItems = [];
	traileringItems = [];
	electronicsItems = [];
 	@track priceMatrixString;

 	@track totalPrice;

	@wire(CurrentPageReference) pageRef;

	connectedCallback(){
		let defaultPayload = {
			 'sku': this.boatSku,
			 'price': this.boatRetailPrice
		};
		this.baseItem.push(defaultPayload);

		registerListener('updatePurchasePrice', this.handlePurchasePrice, this);
		fireEvent(this.pageRef, 'purchasePriceConnected', 'ready'	);
	}

	handlePurchasePrice(details){

		let payload = {
			 'sku': details.sku,
			 'price': details.price
		};
		if(details.addToPrice){
			//add item to list
			if(details.type === 'radio'){
				//replace the existing item for this section
				if(details.addon){
				} else {
					if(details.section === 'performance'){
						this.performanceItems.pop();
						this.performanceItems.push(payload);
					} else if(details.section === 'trailering'){
						this.traileringItems.pop();
						this.traileringItems.push(payload);
					} else if(details.section === 'electronics'){
						this.electronicsItems.pop();
						this.electronicsItems.push(payload);
					}
				}
			}	else {
				//append the item to this section
				if(details.section === 'performance'){
					this.performanceItems.push(payload);
				} else if(details.section === 'trailering'){
					this.traileringItems.push(payload);
				} else if(details.section === 'electronics'){
					this.electronicsItems.push(payload);
				}
			}
		} else {
			//remove item from list
			if(details.section === 'performance'){
				this.performanceItems = this.performanceItems.filter(obj => obj.sku !== payload.sku);
			} else if(details.section === 'trailering'){
				this.traileringItems = this.traileringItems.filter(obj => obj.sku !== payload.sku);
			} else if(details.section === 'electronics'){
				this.electronicsItems = this.electronicsItems.filter(obj => obj.sku !== payload.sku);
			}
		}

		let itemMatrix = this.baseItem.concat(this.performanceItems, this.traileringItems, this.electronicsItems);

		let priceMatrix = [];
		const reducer = (accumulator, currentValue) => accumulator + currentValue;
		for(const item of itemMatrix){
			priceMatrix.push(item.price);
  	}
		const sumTotal = priceMatrix.reduce(reducer)
		this.totalPrice = new Intl.NumberFormat('en-CA', {
														style: 'currency',
														currency: 'CAD',
														minimumFractionDigits: 0
														}).format(sumTotal);
 	}
}