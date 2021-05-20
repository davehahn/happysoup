/**
 * Created by Tim on 2021-05-03.
 */

import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import insertLead from '@salesforce/apex/CommSharedLeadForm_Controller.insertLead';
import LeadForm_FirstName from '@salesforce/label/c.LeadForm_FirstName';
import LeadForm_LastName from '@salesforce/label/c.LeadForm_LastName';
import { getTestUser, renderEN, renderFR, setWrapperClass } from 'c/communitySharedUtils';

export default class CommunitySharedLeadForm extends NavigationMixin(LightningElement) {

	@api formName;
  @api campaignId;
  @api introTitle;
  @api introBlurb;
  @api collectFirstName;
  @api collectLastName;
  @api collectStreet;
  @api collectCity;
  @api collectPostalCode;
  @api collectProvince;
  @api collectEmail;
  @api collectPhone;
  @api collectTypeInterest;
  @api collectBoatInterest;
  @api collectPlanToPurchase;
  @api collectNotes;
  @api collectNewsletterOptin;
  @api sectionWidth;
  @api location;

  @api boatModelId;

  emailPrefill;

	wrapperClass = 'leadFormWrapper';
  showForm = true;
  showThankyou = false;
  showLoading = false;
  formErrors;
  formHasErrors = false;

  labels = {
    LeadForm_FirstName,
    LeadForm_LastName
  }

	defaultCampaignId = '701q0000000mL7GAAU';

	@wire(CurrentPageReference)
		setCurrentPageReference(currentPageReference){
		  console.log('currentPageReference.state.c__preFillEmail: ', currentPageReference.state.c__preFillEmail);
		  if(currentPageReference.state.c__preFillEmail){
		  	this.emailPrefill = currentPageReference.state.c__preFillEmail;
    	}
    	if(currentPageReference.state.c__recordId){
    	  this.boatModelId = currentPageReference.state.c__recordId;
     }
  }

	renderedCallback(){
		this.wrapperClass = setWrapperClass(this.sectionWidth, 'leadFormWrapper');
 	}

	validateLead( event ){
		const allValid = [...this.template.querySelectorAll('lightning-input')]
				.reduce((validSoFar, inputCmp) => {
					inputCmp.reportValidity();
					console.log('validSoFar', validSoFar);
					console.log('inputCmp.checkValidity()', inputCmp.checkValidity());
					return validSoFar && inputCmp.checkValidity();
    		}, true);
    if(allValid){
      console.log('All valid, submit form!');
      this.submitLead();
    } else {
      console.log('You have input errors.');
    }
    event.preventDefault();
 	}

	submitLead(){
	  this.showLoading = true;
	  const newLead = this.formatLeadObject();
	  const cid = (this.campaignId != undefined) ? this.campaignId : this.defaultCampaignId;
	  const submit = insertLead({l: newLead, cid: cid})
	  	.then( (result) =>{
	  		console.log('submitLead result: ', result);
	  		this.showForm = false;
	  		this.showLoading = false;
	  		this.showThankyou = true;
    	}).catch(e => {
    	  console.log('submitLead error: ', e);
     });
 	}

 	formatLeadObject(){
 	  console.log('get data!');
 	  const data = {
 	    FirstName: (this.template.querySelector('[data-id="FirstName"]')) ? this.template.querySelector('[data-id="FirstName"]').value : '',
			LastName: (this.template.querySelector('[data-id="LastName"]')) ? this.template.querySelector('[data-id="LastName"]').value : '',
			Street: (this.template.querySelector('[data-id="Street"]')) ? this.template.querySelector('[data-id="Street"]').value : '',
			City: (this.template.querySelector('[data-id="City"]')) ? this.template.querySelector('[data-id="City"]').value : '',
			State: (this.template.querySelector('[data-id="Province"]')) ? this.template.querySelector('[data-id="Province"]').value : '',
			Country: 'Canada',
			PostalCode: (this.template.querySelector('[data-id="PostalCode"]')) ? this.template.querySelector('[data-id="PostalCode"]').value : '',
			Email: (this.template.querySelector('[data-id="Email"]')) ? this.template.querySelector('[data-id="Email"]').value : '',
			Phone: (this.template.querySelector('[data-id="Phone"]')) ? this.template.querySelector('[data-id="Phone"]').value : '',
			Description: this.formName,
			hubspot_plan_to_purchase__c: (this.template.querySelector('[data-id="PurchaseByDate"]')) ? this.template.querySelector('[data-id="PurchaseByDate"]').value : '',
			hubspot_Boat_Type__c: (this.template.querySelector('[data-id="BoatType"]')) ? this.template.querySelector('[data-id="BoatType"]').value : '',
			BoatModel__c: (this.boatModelId) ? this.boatModelId : ((this.template.querySelector('[data-id="BoatModel"]')) ? this.template.querySelector('[data-id="BoatModel"]').value : ''),
			hubspot_subscribe_legend_newsletter__c: (this.template.querySelector('[data-id="Newsletter"]')) ? ((this.template.querySelector('[data-id="Newsletter"]').checked) ? 'Yes' : 'No') : 'No',
			Preferred_Language__c: (renderEN) ? 'English' : 'French',
			Marketing_Cloud_Notes__c: (this.template.querySelector('[data-id="Notes"]')) ? this.template.querySelector('[data-id="Notes"]').value : '',
			LeadSource: this.location + ' Factory Store'
    }
    console.log('data: ', data);
 	  return data;
  }

  get provinces() {
    return [
      { label: 'Alberta', value: 'Alberta' },
      { label: 'British Columbia', value: 'British Columbia' },
      { label: 'Manitoba', value: 'Manitoba' },
      { label: 'New Brunswick', value: 'New Brunswick' },
      { label: 'Newfoundland and Labrador', value: 'Newfoundland and Labrador' },
      { label: 'Nova Scotia', value: 'Nova Scotia' },
      { label: 'Ontario', value: 'Ontario' },
      { label: 'Prince Edward Island', value: 'Prince Edward Island' },
      { label: 'Quebec', value: 'Quebec' },
      { label: 'Saskatchewan', value: 'Saskatchewan' },
    ];
  }
  get purchaseByDateOptions(){
    return [
      { label: 'Within 3 months', value: 'Within 3 months' },
      { label: '3 to 6 months', value: '3 to 6 months' },
      { label: '6 to 12 months', value: '6 to 12 months' },
      { label: '12+ months', value: '12+ months' },
      { label: 'Not considering the purchase of a boat at this time', value: 'Not considering the purchase of a boat at this time' },
    ];
  }
  get boatTypeOptions(){
		return [
			{ label: 'Fishing Boats', value: 'Fishing Boats' },
			{ label: 'Pontoon Boats', value: 'Pontoon Boats' },
			{ label: 'Deck Boats', value: 'Deck Boats' },
		];
	}

}