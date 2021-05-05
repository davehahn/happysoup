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

export default class FactoryStoreBoatListing extends NavigationMixin(LightningElement) {
	@api seriesName;
	//fullSeriesName;
	@api seriesBlurb;
	isMobile = false;
	boats;
	@track boat;
	@track selectedBoat;
	@track showListing = false;

	@wire( fetchBoatsBySeries, { seriesName: '$seriesName' } )
	wiredFetchBoatsBySeries( { error, data })
	{
	 	if( data )
	  {
	    console.log(this.seriesName, data);
	    this.boats = data;
	    this.showListing = true;
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

  get seriesClass(){
    let series = this.seriesName.toLowerCase();
    return (series.indexOf('series') !== -1) ? series : series + '-series';
  }
}