/**
 * Created by dave on 2020-01-27.
 */

import { LightningElement, api, track } from 'lwc';
import { errorToast, successToast, warningToast, reduceErrors } from 'c/utils';
import findClosestPartner from '@salesforce/apex/Account_FindClosestPartner.findClosestPartner';

export default class AccountFindClosestPartner extends LightningElement {
  @api cmpTitle;
  @api cmpTitleAlign;
  @api inputLabel;
  @api partnerCount;
  @api mapView;
  @api hideSearch=false;
  @api hideResultIcon=false;
  @api isSelectable;
  @api excludedAccountIds;
  @api results;
  @track mapMarkers;
  @track originAddress;
  @api zoomLevel;
  @api lookupValue;

  connectedCallback()
  {
    if( this.partnerCount === 1 )
    {
      this.zoomLevel = 10;
    }
  }

  get titleClass()
  {
    return 'slds-card__header-title slds-truncate slds-m-bottom_xx-small slds-text-align_' + this.cmpTitleAlign;
  }

  get displaySingleResult()
  {
    return this.partnerCount === 1;
  }

  get firstMapMarker()
  {
    return this.mapMarkers[0];
  }

  @api findPartners( lookupValue )
  {
    if( lookupValue === undefined || lookupValue === null ) return;
    this.lookupValue = lookupValue;
    return this.searchPromise();
  }

  checkForEnter( evt )
  {
    this.lookupValue = evt.target.value;
    if( evt.which === 13 )
    {
      this.doSearch();
    }
  }

  doSearch()
  {
    let spinner = this.template.querySelector("c-legend-spinner");
    spinner.toggle();
    this.searchPromise()
    .then( result => {
      //success
    })
    .catch( error => {
      console.log('error');
      console.log( reduceErrors( error )[0] );
      errorToast( this, reduceErrors( error )[0] );
    })
    .finally( function() {
      spinner.toggle();
    })
  }

  searchPromise()
  {
    return new Promise( ( resolve, reject ) => {
      findClosestPartner( {
        lookupValue: this.lookupValue,
        resultCount: this.partnerCount,
        excludedAccountIds: this.excludedAccountIds
       } )
      .then( result => {
        let r = JSON.parse( result );
        this.mapMarkers = r.mapMarkers;
        this.originAddress = r.origin_address;
        resolve('success');
      })
      .catch( error => {
        reject( error );
      })
    });
  }

  handleMarkerSelect( event )
  {
    let selectedAcct =
      this.mapMarkers.filter( marker => marker.id === event.target.selectedMarkerValue )[0];
    this.dispatchEvent(
      new CustomEvent(
        'accountselected',
        { detail: selectedAcct }
      )
    );
  }

  handleAccountSelected( event )
  {
    this.dispatchEvent(
      new CustomEvent(
        'accountselected',
        { detail: event.detail }
      )
    );
  }
}