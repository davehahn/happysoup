/**
 * Created by Tim on 2020-04-23.
 */

import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners} from 'c/pubsub';

export default class CustCommOrderBoatImage extends LightningElement {
    @api size;
    @api motorDetails;
    @api page;
    boatImage;

		@wire(CurrentPageReference) pageRef;

		connectedCallback(){
			registerListener('motorSelection', this.handleMotorSelection, this);
		}

//    get boatImage(){
//      if(this.motorDetails){
//        return this.motorDetails.motorImage;
//      }
//    }

    handleMotorSelection(detail){
			if(detail){
				for(let image of detail){
					if(this.page === 'performance'){
						if(image.imageType === 'sideAngle'){
							this.boatImage = 'https://' + image.imageURL;
						}
					} else if(this.page === 'trailering'){
						if(image.imageType === 'backAngle'){
							this.boatImage = 'https://' + image.imageURL;
						}
					}
				}
		 }
	}
}