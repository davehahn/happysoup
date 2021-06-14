/**
 * Created by Tim on 2021-03-23.
 */

import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners} from 'c/pubsub';
import { setWrapperClass } from 'c/communitySharedUtils';
import Id from '@salesforce/community/Id';
import fetchCommunityDetails from '@salesforce/apex/CommSharedURL_Controller.fetchCommunityDetails';
import fetchBoats from '@salesforce/apex/FactoryStore_InventoryController.fetchBoats';
import fetchBoatsBySeries from '@salesforce/apex/FactoryStore_InventoryController.fetchBoatsBySeries';
import fetchBoat from '@salesforce/apex/FactoryStore_InventoryController.fetchBoat';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

export default class FactoryStoreBoatListing extends NavigationMixin(LightningElement) {
  @api locationName;
	@api seriesName;
	@api seriesBlurb;
	@api sectionWidth;

	isMobile = false;
	boats;
	@track boat;
	@track selectedBoat;
	@track showListing = false;

	wrapperClass = 'allModels';

	@wire( fetchCommunityDetails, {communityId: Id} )
		wiredFetchCommunityDetails( { error, data } )
		{
			if( data )
			{
				this.locationName = data.name;
				this.runBoatsBySeries();
			}
			else if( error )
			{
				console.log('fetch community error: ', error);
			}
		}

	runBoatsBySeries(){
		if(this.locationName){
				fetchBoatsBySeries({seriesName: this.seriesName})
					.then( (result) => {
						console.log(this.seriesName, result);
						this.boats = result;
						this.showListing = true;
						this.wrapperClass = setWrapperClass(this.sectionWidth, 'allModels');
					}).catch(e => {
						console.log('fetch series error:', e);
				 });
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