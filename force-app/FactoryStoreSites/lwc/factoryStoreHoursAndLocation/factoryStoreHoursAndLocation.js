/**
 * Created by Tim on 2021-03-30.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';


export default class FactoryStoreHoursAndLocation extends LightningElement {

	@api storeLocation;

	@track currentStatus = 'Open';
	@track currentHours = '8AM - 5PM';

	@track streetNumber = '4795';
	@track route = 'Regional Road 55';
	@track locality = 'Whitefish';
	@track administrativeArea = 'ON';
	@track postalCode = 'POM 3EO';

	get statusClass(){
	  return (this.currentStatus === 'Open') ? 'currentStatus currentStatus--open' : 'currentStatus currentStatus--closed';
 }

 get currentDate(){
   return new Date().toLocaleDateString("en-CA", {weekday: 'long', month: 'long', day: 'numeric'});
 }
}