/**
 * Created by Tim on 2020-04-23.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners} from 'c/pubsub';

export default class CustCommOrderSummary extends LightningElement {
	@wire(CurrentPageReference) pageRef;

	@track performanceItems = [];
	@track traileringItems = [];
	@track electronicsItems = [];

	connectedCallback(){
		registerListener('updateSummary', this.updateSummary, this);
		fireEvent(this.pageRef, 'summaryConnected', 'ready'	);
	}

	updateSummary(details){

		let payload = {
			 'name': details.name,
			 'sku': details.sku,
			 'inputName': details.userSelectionName
		};
		if(details.addToSummary){
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

   //	console.log('summaryList: ', JSON.parse(JSON.stringify(this.summaryList)));
 	}

	ifContains(array, object){
		let index = array.findIndex(({inputName}) => inputName === object.inputName);
		if(index === -1){
			array.push(object);
 	 	} else{
 	 	  array[index] = object;
    }
 	}

}