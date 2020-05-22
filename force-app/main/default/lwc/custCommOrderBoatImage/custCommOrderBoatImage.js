/**
 * Created by Tim on 2020-04-23.
 */

import { LightningElement, api } from 'lwc';

export default class CustCommOrderBoatImage extends LightningElement {
    @api size;
    @api motorDetails;

    get boatImage(){
      if(this.motorDetails){
        return this.motorDetails.motorImage;
      }
    }
}