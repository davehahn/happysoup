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
		  console.log('conPage: ', this.page);
			registerListener('motorSelection', this.handleMotorSelection, this);
		}
		disconnectedCallback() {
			unregisterAllListeners(this);
		}

//    get boatImage(){
//      if(this.motorDetails){
//        return this.motorDetails.motorImage;
//      }
//    }

    handleMotorSelection(detail){
      console.log('motor selection');
      console.log(this.page);
      console.log(JSON.parse(JSON.stringify(detail)));
			if(detail.motorImage){
				for(let image of detail.motorImage){
					if(this.page === 'performance'){
					  console.log('set performance boat image');
						if(image.imageType === 'sideAngle'){
							this.boatImage = 'https://' + image.imageURL;
						}
					}
					if(this.page === 'trailering'){
					  console.log('set trailering boat image');
						if(image.imageType === 'backAngle'){
							this.boatImage = 'https://' + image.imageURL;
						}
					}
					if(this.page === 'electronics'){
						console.log('set electronics boat image');
						if(image.imageType === 'sideAngle'){
							this.boatImage = 'https://' + image.imageURL;
						}
					}
					if(this.page === 'summary'){
						console.log('set summary boat image');
						if(image.imageType === 'frontAngle'){
							this.boatImage = 'https://' + image.imageURL;
						}
					}
				}
		 }
	}
}