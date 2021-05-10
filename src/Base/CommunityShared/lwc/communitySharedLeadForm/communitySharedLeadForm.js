/**
 * Created by Tim on 2021-05-03.
 */

import { LightningElement, wire, api, track } from 'lwc';
import insertLead from '@salesforce/apex/CommSharedLeadForm_Controller.insertLead';
import { getTestUser } from 'c/communitySharedUtils';

export default class CommunitySharedLeadForm extends LightningElement {

	@api campaignId;
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