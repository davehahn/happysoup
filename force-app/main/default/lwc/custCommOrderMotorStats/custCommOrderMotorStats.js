/**
 * Created by Tim on 2020-04-23.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners} from 'c/pubsub';

export default class CustCommOrderMotorStats extends LightningElement {
    @api motorDetails = {
        'motorSpeed' : '48km',
        'motorRPM' : '5300-6300'
    };
		previousSpeed = 0;
    motorSpeed = 0;
    motorRPM = '';

    @wire(CurrentPageReference) pageRef;

		connectedCallback(){
			console.log('conPage: ', this.page);
			registerListener('motorSelection', this.handleMotorSelection, this);
		}
		disconnectedCallback() {
			unregisterAllListeners(this);
		}

		handleMotorSelection(detail){
			if(detail){
				var counter = 1;
				var startSpeed = parseInt(this.previousSpeed);
				var motorSpeed = parseInt(this.motorSpeed);
				var self = this;
				var interval = setInterval(function(){

					const difference = detail.motorSpeed - self.previousSpeed;

					if(counter <= Math.abs(difference)){
						if(Math.sign(difference) === 1){
							motorSpeed = motorSpeed + 1;
							counter = counter + 1;
							self.motorSpeed = motorSpeed;
						} else {
							motorSpeed = motorSpeed - 1;
							counter = counter + 1;
							self.motorSpeed = motorSpeed;
						}

					} else{
						clearInterval(interval);
						self.previousSpeed = self.motorDetails.motorSpeed;
					}
				}, 10);

				self.motorRPM = detail.motorRPM;
			}
  	}

//		get motorRPM(){
//			if(this.motorDetails){
//				return this.motorDetails.motorRPM;
//			}
//		}

}