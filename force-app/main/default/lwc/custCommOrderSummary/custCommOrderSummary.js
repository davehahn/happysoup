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
	  console.log('summary connected');
		registerListener('updateSummary', this.updateSummary, this);

		fireEvent(this.pageRef, 'summaryConnected', 'ready'	);
	}

	updateSummary(details){
		console.log('update summary: ', details);
		let payload = {
			 'name': details.name,
			 'sku': details.sku
		};
		if(details.addToSummary){
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

   //	console.log('summaryList: ', JSON.parse(JSON.stringify(this.summaryList)));
 	}


}