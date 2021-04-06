/**
 * Created by Tim on 2021-04-05.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { stringy, stripParentheses, rewriteMotorName, rewriteTrailerName } from 'c/factoryStoreUtils';
import fetchBoat from '@salesforce/apex/FactoryStore_InventoryController.fetchBoat';
import { fireEvent, registerListener, unregisterAllListeners} from 'c/pubsub';


export default class FactoryStoreBoatDetails extends NavigationMixin(LightningElement) {
  @track recordId;
  @track boat;
  @track boatDataLookupRunning = true;
  @track boatDataLoaded = false;
  @track resultEmpty = false;

  @track boatName;
  @track standardMotorName;
  @track standardTrailerName;

  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference){
    this.recordId = currentPageReference.state.c__recordId;
  }

  @wire( fetchBoat, { boatId: '$recordId' } )
  wiredFetchBoat( { error, data } )
  {
    if( data )
    {
      console.log('this boat: ', data);
      if(data.length !== 0){
        this.boat = data;
				this.recordFound();
      } else {
        this.resultEmpty();
      }
    }
    else if( error )
    {
      console.log('Ooops: ', error);
    }
  }

  recordFound(){
    this.boatDataLoaded = true;
    this.boatDataLookupRunning =  false;
    this.boatName = stripParentheses(this.boat.Name);
    this.standardMotorName = rewriteMotorName(this.boat.StandardMotor.Name);
    this.standardTrailerName = rewriteTrailerName(this.boat.StandardTrailer.Name);
  }

  resultEmpty(){
    this.boatDataLookupRunning =  false;
    this.resultEmpty = true;
  }
}