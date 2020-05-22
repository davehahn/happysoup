/**
 * Created by Tim on 2020-04-23.
 */

import { LightningElement, api, track } from 'lwc';

export default class CustCommOrderMotorStats extends LightningElement {
    @api motorDetails = {
        'motorSpeed' : '48km',
        'motorRPM' : '5300-6300'
    };
		previousSpeed = 0;
    motorSpeed = 0;

		renderedCallback(){
		  //console.log('in completed callback');
			if(this.motorDetails){
//				console.log('previous Speed: ', this.previousSpeed);
        			//const difference = this.motorDetails.motorSpeed - this.previousSpeed;


        			//console.log(difference);
        			var counter = 1;
        			var startSpeed = parseInt(this.previousSpeed);
        			var motorSpeed = parseInt(this.motorSpeed);
        			var self = this;
        			var interval = setInterval(function(){

        				const difference = self.motorDetails.motorSpeed - self.previousSpeed;
//        				console.log('counter: ', counter);
//        				console.log('startSpeed: ', startSpeed);
//        				console.log('motorSpeed: ', motorSpeed);
        				if(counter <= Math.abs(difference)){
        					if(Math.sign(difference) === 1){
        						motorSpeed = motorSpeed + 1;
        						counter = counter + 1;
//        						console.log('add 1');
        						self.motorSpeed = motorSpeed;
        					} else {
        						motorSpeed = motorSpeed - 1;
										counter = counter + 1;
//										console.log('add 1');
										self.motorSpeed = motorSpeed;
        					}

        				} else{
        					clearInterval(interval);
        					self.previousSpeed = self.motorDetails.motorSpeed;
        				}
        			}, 10);
			}
  	}

		get motorRPM(){
			if(this.motorDetails){
				return this.motorDetails.motorRPM;
			}
		}

		updateSpeed(){

  	}
}