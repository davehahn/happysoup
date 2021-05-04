/**
 * Created by Tim on 2021-05-03.
 */

import { LightningElement, wire, api, track } from 'lwc';
import insertLead from '@salesforce/apex/CommSharedLeadForm_Controller.insertLead';
import LeadForm_FirstName from '@salesforce/label/c.LeadForm_FirstName';
import LeadForm_LastName from '@salesforce/label/c.LeadForm_LastName';
import { getTestUser } from 'c/communitySharedUtils';

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
  @api collectPlanToPurchase;
  @api collectNotes;
  @api collectNewsletterOptin;
  @api collectBoatType;
  @api collectBoatModel;

  labels = {
    LeadForm_FirstName,
    LeadForm_LastName
  }

	defaultCampaignId = '701q0000000mL7GAAU';

	submitLead(){
	  const newLead = getTestUser();
	  console.log('newlead: ', newLead);
	  const campaignId = (this.campaignId != undefined) ? this.campaignId : this.defaultCampaignId;
	  const submit = insertLead({l: newLead, cid: campaignId})
	  	.then( (result) =>{
	  		console.log('submitLead result: ', result);
    	}).catch(e => {
    	  console.log('submitLead error: ', e);
     });
 	}

}