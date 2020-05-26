/**
 * Created by Tim on 2020-04-23.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners} from 'c/pubsub';

export default class CustCommOrderBoatImage extends LightningElement {
    @api size;
    @api motorDetails;
    @api page;
    @track boatImage;

		@wire(CurrentPageReference) pageRef;

		connectedCallback(){
		  if(this.page !== 'undefined'){
		  	registerListener('motorSelection', this.handleImageChange, this);
    	}
		}

//    get boatImage(){
//      if(this.motorDetails){
//        return this.motorDetails.optionImage;
//      }
//    }

		handleImageChange(detail){
			if(detail.optionImage !== 'undefined'){
				for(let image of detail.optionImage){
					if(this.page === 'performance'){
						if(image.imageType === 'sideAngle'){
							this.boatImage = 'https://' + image.imageURL;
						}
					}
					if(this.page === 'trailering'){
						if(image.imageType === 'backAngle'){
							this.boatImage = 'https://' + image.imageURL;
						}
					}
					if(this.page === 'electronics'){
						if(image.imageType === 'sideAngle'){
							this.boatImage = 'https://' + image.imageURL;
						}
					}
					if(this.page === 'summary'){
						if(image.imageType === 'frontAngle'){
							this.boatImage = 'https://' + image.imageURL;
						}
					}
				}
			}
		}
}