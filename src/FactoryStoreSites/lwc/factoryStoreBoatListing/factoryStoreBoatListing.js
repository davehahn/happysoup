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
import fetchFullBoatDetails from '@salesforce/apex/FactoryStore_InventoryController.fetchFullBoatDetails';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

export default class FactoryStoreBoatListing extends NavigationMixin(LightningElement) {
  @api locationName;
	@api seriesName;
	@api seriesBlurb;
	@api sectionWidth;

	isMobile = false;
	boats = [];
	boatPromises = [];
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
					.then( (boats) => {
						boats.forEach( (boat, i) => {
						  this.boatPromises.push(
							 	fetchFullBoatDetails({modelId: boat.Id})
							 		.then( (fullBoat) => {
								 		this.boats[i] = {
								 			Base: boat,
								 			Expanded: fullBoat
								 		};
									}).catch(e => {
										console.log('fetchFullBoatDetails error: ', e);
									})
							);
						});
						Promise.all(this.boatPromises).then(() => {
							this.triggerGallery();
      			});
					}).catch(e => {
						console.log('fetch series error:', e);
				 });
		}
	}

 @wire(CurrentPageReference) pageRef;

 triggerGallery(){
//   console.log('all expanded boats?', this.boats);
   this.showListing = true;
	 this.wrapperClass = setWrapperClass(this.sectionWidth, 'allModels');
 }

 	get fullSeriesName(){
 	  let series = this.seriesName;
 		return (series.toLowerCase().indexOf('series') !== -1) ? series : series + '-Series';
  }

  get seriesClass(){
    let series = this.seriesName.toLowerCase();
    return (series.indexOf('series') !== -1) ? series : series + '-series';
  }
}
