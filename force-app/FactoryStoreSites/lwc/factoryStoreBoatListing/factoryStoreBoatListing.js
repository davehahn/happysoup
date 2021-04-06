/**
 * Created by Tim on 2021-03-23.
 */

import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners} from 'c/pubsub';
import fetchBoats from '@salesforce/apex/FactoryStore_InventoryController.fetchBoats';
import fetchBoatsBySeries from '@salesforce/apex/FactoryStore_InventoryController.fetchBoatsBySeries';
import fetchBoat from '@salesforce/apex/FactoryStore_InventoryController.fetchBoat';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import gothamFonts from '@salesforce/resourceUrl/GothamHTF';

export default class FactoryStoreBoatListing extends NavigationMixin(LightningElement) {
	@api seriesName;
	//fullSeriesName;
	@api seriesBlurb;
	isMobile = false;
	boats;
	@track boat;
	@track selectedBoat;
	@track showListing = true;
	@track showBoat = false;

	@wire( fetchBoatsBySeries, { seriesName: '$seriesName' } )
	wiredFetchBoatsBySeries( { error, data })
	{
	 	if( data )
	  {
	    console.log(this.seriesName, data);
	    this.boats = data;
   	}
   	else if ( error )
   	{
    	console.log('fetch series error:', error);
   	}
 }

 @wire(CurrentPageReference) pageRef;

 	get fullSeriesName(){
 	  let series = this.seriesName;
 		return (series.toLowerCase().indexOf('series') !== -1) ? series : series + '-Series';
  }

 	handleOpenBoat( event ){
 	  console.log('handleOpenBoat');
		console.log('recordId', event.detail);
		fetchBoat({ boatId: event.detail })
			.then((data) => {
				console.log('returned boat', data);
				this.boat = data;
				this.showBoat = true;
				this.showListing = false;
			})
			.catch((error) => {
				console.log('error fetching boat', error);
			});
	}

	closeBoat( event ){
		this.showBoat = false;
		this.showListing = true;
		this.recordId = null;
	}

}