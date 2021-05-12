/**
 * Created by Tim on 2021-03-30.
 */

import { LightningElement, api, wire } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';


export default class FactoryStoreHoursAndLocation extends LightningElement {

	@api storeLocation;
	@api layout;

	currentStatus = 'Open';
	currentHours = '8AM - 5PM';

	@api streetNumber;
	@api route;
	@api locality;
	@api administrativeArea;
	@api postalCode;

	mapMarkers;
	@api zoomLevel;

	connectedCallback(){
	  const street = this.streetNumber + ' ' + this.route;
	  console.log('street: ', street);

	  this.mapMarkers = [{
			location: {
				Street: street,
				City: this.locality,
				Country: 'Canada'
			},
		}];
 }

	apiKey = 'AIzaSyBH4HHMg0ktDvCzZT7LiqXPdgFr32lMCNc';

	renderedCallback(){
		if(this.layout === 'Expanded'){

  	}
 	}

	get statusClass(){
	  return (this.currentStatus === 'Open') ? 'currentStatus currentStatus--open' : 'currentStatus currentStatus--closed';
 }

 get currentDate(){
   return new Date().toLocaleDateString("en-CA", {weekday: 'long', month: 'long', day: 'numeric'});
 }

 get showCondensed(){
   return (this.layout === 'Condensed') ? true : false;
 }

 get showExpanded(){
		return (this.layout === 'Expanded') ? true : false;
	}

}