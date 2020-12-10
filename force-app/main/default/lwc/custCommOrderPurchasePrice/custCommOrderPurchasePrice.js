/**
 * Created by Tim on 2020-05-27.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners} from 'c/pubsub';

export default class CustCommOrderPurchasePrice extends LightningElement {
	@api boatRetailPrice;
	@api boatSku;
	@api paymentType;

	baseItem = [];
	performanceItems = [];
	traileringItems = [];
	electronicsItems = [];
	freightItems = [];
 	@track priceMatrixString;

 	@track totalPrice;
 	@track payments;

 	@track isEN = true;
	@track isFR = false;

	@wire(CurrentPageReference) pageRef;

	connectedCallback(){
		let defaultPayload = {
			 'sku': this.boatSku,
			 'price': this.boatRetailPrice,
			 'inputName': ''
		};
		this.baseItem.push(defaultPayload);

		registerListener('updatePurchasePrice', this.handlePurchasePrice, this);
		registerListener('paymentAmountChanged', this.handlePaymentAmountChange, this);

		fireEvent(this.pageRef, 'purchasePriceConnected', 'ready'	);
	}

	renderedCallback(){
		registerListener('languageChange', this.handleLanguageChange, this);
	}

	get displayLoanData()
	{
	  return this.paymentType == 'loan' && this.payments;
  }

  get displayCashData()
  {
    return this.paymentType == 'cash';
  }

	handlePurchasePrice(details)
	{
	  console.log('handlePurchasePrice');
		let payload = {
			 'price': details.price,
			 'sku': details.sku,
			 'inputName': details.userSelectionName
		};
		if(details.addToPrice){
			//add item to list
			if(details.type === 'radio'){
				//replace the existing item for this section
				if(details.addon){
				} else {
					if(details.section === 'performance'){
						this.ifContains(this.performanceItems, payload);
					} else if(details.section === 'trailering'){
						this.ifContains(this.traileringItems, payload);
					} else if(details.section === 'electronics'){
						this.ifContains(this.electronicsItems, payload);
					}
				}
			}	else if(details.type === 'select'){
			  if(details.section === 'freight'){
			    //remove the old item
			    this.freightItems = this.freightItems.filter(obj => obj.sku !== payload.sku);
			    //add the new item
			    this.freightItems.push(payload);
     		}
   		} else {
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

		let itemMatrix = this.baseItem.concat(this.performanceItems, this.traileringItems, this.electronicsItems, this.freightItems);
		let priceMatrix = [];
		const reducer = (accumulator, currentValue) => accumulator + currentValue;
		for(const item of itemMatrix){
			priceMatrix.push(item.price);
  	}
		this.totalPrice = priceMatrix.reduce(reducer)
    console.log(`totalPrice = ${this.totalPrice}`);
		fireEvent( this.pageRef, 'purchasePriceChanged', this.totalPrice );
 	}

 	handlePaymentAmountChange( payments )
 	{
 	  console.log('handling payment change');
 	  this.payments = payments;
  }



 	ifContains(array, object){
		let index = array.findIndex(({inputName}) => inputName === object.inputName);
		if(index === -1){
			array.push(object);
		} else{
			array[index] = object;
		}
	}

	handleLanguageChange(detail){
			if(detail){
				this.isEN = (detail === 'EN') ? true : false;
				this.isFR = (detail === 'FR') ? true : false;
		}
	}

}