/**
 * Created by dave on 2020-01-27.
 */

import { LightningElement, api, track } from 'lwc';
import findClosestPartner from '@salesforce/apex/Account_FindClosestPartner.findClosestPartner';

export default class AccountFindClosestPartner extends LightningElement {
  @api cmpTitle;
  @api cmpTitleAlign;
  @api inputLabel;
  @api partnerCount;
  @api mapView;
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
    findClosestPartner( {
      lookupValue: this.lookupValue,
      resultCount: this.partnerCount,
      excludedAccountIds: this.excludedAccountIds
     } )
    .then( result => {
      let r = JSON.parse( result );
      this.mapMarkers = r.mapMarkers;
      this.originAddress = r.origin_address;
    })
    .catch( error => {
      console.log('error');
      console.log( error.message );
    })
    .finally( function() {
      spinner.toggle();
    })
  }
}