/**
 * Created by Tim on 2020-04-23.
 */

import { LightningElement, api } from 'lwc';

export default class CustCommOrderMotorStats extends LightningElement {
    @api motorStats = {
        'motorSpeed' : '48km',
        'motorRPM' : '5300-6300'
    };
    motorSpeed;
    motorRPM;

    connectedCallback(){
        this.motorSpeed = this.motorStats.motorSpeed;
        this.motorRPM = this.motorStats.motorRPM;
    }

    get motorSpeed(){
        return this.motorSpeed;
    }
    get motorRPM(){
        return this.motorRPM;
    }
}