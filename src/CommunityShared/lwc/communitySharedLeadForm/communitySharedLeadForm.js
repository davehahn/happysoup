/**
 * Created by Tim on 2021-05-03.
 */

import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/community/Id';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import fetchCommunityDetails from '@salesforce/apex/CommSharedURL_Controller.fetchCommunityDetails';
import insertLead from '@salesforce/apex/CommSharedLeadForm_Controller.insertLead';
import LeadForm_FirstName from '@salesforce/label/c.LeadForm_FirstName';
import LeadForm_LastName from '@salesforce/label/c.LeadForm_LastName';
import { getTestUser, renderEN, renderFR, setWrapperClass } from 'c/communitySharedUtils';

export default class CommunitySharedLeadForm extends NavigationMixin(LightningElement) {

	@api formName;
  @api campaignId;
  @api introTitle;
  @api introBlurb;
  @api boatType;
  @api boatSeries;
  @api boatName;
  @api boatModelId;
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
  @api serialNumber = "N/A";
  @api serialNumberId = 'N/A';

  emailPrefill;
  locationName;

  isEN = renderEN();
  isFR = renderFR();
  currLang;

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

	@wire(CurrentPageReference) pageRef;

//	defaultCampaignId = '701q0000000mL7GAAU';

	@wire(CurrentPageReference)
		setCurrentPageReference(currentPageReference){
		  console.log('currentPageReference.state.c__preFillEmail: ', currentPageReference.state.c__preFillEmail);
		  if(currentPageReference.state.c__preFillEmail){
		  	this.emailPrefill = currentPageReference.state.c__preFillEmail;
    	}
    	if(currentPageReference.state.c__recordId){
    	  this.boatModelId = currentPageReference.state.c__recordId;
    	  console.log('this.boatModelId', this.boatModelId);
     	}
		if (currentPageReference.state.c__SN) {
			this.serialNumberId = currentPageReference.state.c__SN;
		}
  }

  @wire( fetchCommunityDetails, {communityId: Id} )
		wiredFetchCommunityDetails( { error, data } )
		{
			if( data )
			{
				this.locationName = data.name;
			}
			else if( error )
			{
				console.log('fetch community error: ', error);
			}
		}

	renderedCallback(){
		this.wrapperClass = setWrapperClass(this.sectionWidth, 'leadFormWrapper');
		registerListener('exposeUsedModelDetails', this.handleUsedModelDetails, this);
 	}

 	handleUsedModelDetails( details ){
 	  console.log('caught used model details: ', details);
 	  this.boatName = details.boatName;
 	  this.boatModelId = details.recordId;
 	  this.serialNumber = details.serialNumber;
 	  this.serialNumberId = details.serialNumberId;
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
	  const newLeadHistory = this.formatLeadHistoryObject();
	  const cid = (this.campaignId != undefined) ? this.campaignId : this.defaultCampaignId;
	  console.log('newLeadHistory', newLeadHistory);
	  const submit = insertLead({l: newLead, cid: cid, lsh: newLeadHistory})
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
// 	  console.log('get data!');
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
			Description: this.formName + " | Serial Number: " + this.serialNumber,
			hubspot_plan_to_purchase__c: (this.template.querySelector('[data-id="PurchaseByDate"]')) ? this.template.querySelector('[data-id="PurchaseByDate"]').value : '',
			hubspot_Boat_Type__c: (this.template.querySelector('[data-id="BoatType"]')) ? this.template.querySelector('[data-id="BoatType"]').value : '',
			BoatModel__c: (this.boatModelId) ? this.boatModelId : ((this.template.querySelector('[data-id="BoatModel"]')) ? this.template.querySelector('[data-id="BoatModel"]').value : ''),
			hubspot_subscribe_legend_newsletter__c: (this.template.querySelector('[data-id="Newsletter"]')) ? ((this.template.querySelector('[data-id="Newsletter"]').checked) ? 'Yes' : 'No') : 'No',
			Preferred_Language__c: (renderEN) ? 'English' : 'French',
			Marketing_Cloud_Notes__c: (this.template.querySelector('[data-id="Notes"]')) ? this.template.querySelector('[data-id="Notes"]').value : '',
			LeadSource: this.locationName + ' Factory Store',
			Lead_Notification_Pending__c: true
    }
//    console.log('data: ', data);
 	  return data;
  }

  formatLeadHistoryObject(){
    const data = {
      First_Name__c: (this.template.querySelector('[data-id="FirstName"]')) ? this.template.querySelector('[data-id="FirstName"]').value : '',
			Last_Name__c: (this.template.querySelector('[data-id="LastName"]')) ? this.template.querySelector('[data-id="LastName"]').value : '',
			Address__c: (this.template.querySelector('[data-id="Street"]')) ? this.template.querySelector('[data-id="Street"]').value : '',
			City__c: (this.template.querySelector('[data-id="City"]')) ? this.template.querySelector('[data-id="City"]').value : '',
			Province__c: (this.template.querySelector('[data-id="Province"]')) ? this.template.querySelector('[data-id="Province"]').value : '',
			Postal_Code__c: (this.template.querySelector('[data-id="PostalCode"]')) ? this.template.querySelector('[data-id="PostalCode"]').value : '',
			Email__c: (this.template.querySelector('[data-id="Email"]')) ? this.template.querySelector('[data-id="Email"]').value : '',
			Phone_Number__c: (this.template.querySelector('[data-id="Phone"]')) ? this.template.querySelector('[data-id="Phone"]').value : '',
			Description__c: this.formName,
			Purchase_By_Date__c: (this.template.querySelector('[data-id="PurchaseByDate"]')) ? this.template.querySelector('[data-id="PurchaseByDate"]').value : '',
			Boat_Type__c: this.boatType,
			Boat_Series__c: this.boatSeries,
			Boat_Model__c: (this.boatModelId) ? this.boatModelId : ((this.template.querySelector('[data-id="BoatModel"]')) ? this.template.querySelector('[data-id="BoatModel"]').value : ''),
			Boat_Name__c: this.boatName,
			Subscribe_to_Newsletter__c: (this.template.querySelector('[data-id="Newsletter"]')) ? ((this.template.querySelector('[data-id="Newsletter"]').checked) ? 'Yes' : 'No') : 'No',
			Preferred_Language__c: (renderEN) ? 'English' : 'French',
			Notes__c: (this.template.querySelector('[data-id="Notes"]')) ? this.template.querySelector('[data-id="Notes"]').value : '',
			Lead_Source__c: this.locationName + ' Factory Store',
			Campaign__c: (this.campaignId != undefined) ? this.campaignId : this.defaultCampaignId,
			Form_Name__c: this.formName,
			Campaign__c: (this.campaignId != undefined) ? this.campaignId : this.defaultCampaignId,
			Model_of_Interest_Serial_Number__c: (this.serialNumber !== "N/A") ? this.serialNumber : '',
			Model_of_Interest_Serial_Number_Lookup__c	: (this.serialNumberId !== "N/A") ? this.serialNumberId : '',
			//Conversion_Id__c
			//Special_Conditions__c
			Lead_Notification_Pending__c: true
    }
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
  get provincesFR(){
    return [
      { label: 'Alberta', value: 'Alberta' },
			 { label: 'Colombie-Britannique', value: 'British Columbia' },
			 { label: 'Manitoba', value: 'Manitoba' },
			 { label: 'Nouveau-Brunswick', value: 'New Brunswick' },
			 { label: 'Terre-Neuve-et-Labrador', value: 'Newfoundland and Labrador' },
			 { label: 'Nouvelle-Écosse', value: 'Nova Scotia' },
			 { label: 'Ontario', value: 'Ontario' },
			 { label: 'Île-du-Prince-Édouard', value: 'Prince Edward Island' },
			 { label: 'Québec', value: 'Quebec' },
			 { label: 'Saskatchewan', value: 'Saskatchewan' }
    ]
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
  get purchaseByDateOptionsFR(){
      return [
        { label: 'Les 3 mois', value: 'Within 3 months' },
        { label: '3 à 6 mois', value: '3 to 6 months' },
        { label: '6 à 12 mois', value: '6 to 12 months' },
        { label: '12+ mois', value: '12+ months' },
        { label: 'Ne considère pas l\'achat d\'un nouveau bateau en ce moment', value: 'Not considering the purchase of a boat at this time' },
      ];
    }
  get boatTypeOptions(){
		return [
			{ label: 'Fishing Boats', value: 'Fishing Boats' },
			{ label: 'Pontoon Boats', value: 'Pontoon Boats' },
			{ label: 'Deck Boats', value: 'Deck Boats' },
		];
	}
	get boatTypeOptionsFR(){
		return [
			{ label: 'Bateaux de Pêche', value: 'Fishing Boats' },
			{ label: 'Bateaux Pontons', value: 'Pontoon Boats' },
			{ label: 'Bateaux Pontés', value: 'Deck Boats' },
		];
	}

}
