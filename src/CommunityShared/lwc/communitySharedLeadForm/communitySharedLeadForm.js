/**
 * Created by Tim on 2021-05-03.
 */

import { LightningElement, wire, api } from 'lwc';
import insertLead from '@salesforce/apex/CommSharedLeadForm_Controller.insertLead';
import LeadForm_FirstName from '@salesforce/label/c.LeadForm_FirstName';
import LeadForm_LastName from '@salesforce/label/c.LeadForm_LastName';
import { getTestUser, renderEN, renderFR } from 'c/communitySharedUtils';

export default class CommunitySharedLeadForm extends LightningElement {

	@api formName;
  @api campaignId;
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

  @api boatModelId;

  showForm = true;
  showThankyou = false;

  labels = {
    LeadForm_FirstName,
    LeadForm_LastName
  }

	defaultCampaignId = '701q0000000mL7GAAU';

	submitLead(){
	  console.log('start submit');
	  const newLead = this.formatDataObject();
	  console.log('newlead: ', newLead);
	  const cid = (this.campaignId != undefined) ? this.campaignId : this.defaultCampaignId;
	  const submit = insertLead({l: newLead, cid: cid})
	  	.then( (result) =>{
	  		console.log('submitLead result: ', result);
	  		this.showForm = false;
	  		this.showThankyou = true;
    	}).catch(e => {
    	  console.log('submitLead error: ', e);
     });
 	}

 	formatDataObject(){
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
			LeadSource: 'Online - Web'
    }
    console.log('data: ', data);
 	  return data;
  }

}