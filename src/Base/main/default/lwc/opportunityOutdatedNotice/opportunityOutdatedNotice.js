/**
 * Created by dave on 2022-04-12.
 */

import { LightningElement, api, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";

const FIELDS = ["Opportunity.IsPricebookCurrent__c", "Opportunity.StageName"];

export default class OpportunityOutdatedNotice extends LightningElement {
  @api recordId;
  isPricebookCurrent = true;
  oppStage;
  iconName = "utility:alert";
  title = "The Pricing used to construct this Opportunity and related Quotes is now outdated";
  message =
    "You are now unable to edit or add any Quotes to this Opportunity.  Please Closed-Lost this opportunity and create a new Quote/Opportunity.";

  @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
  wiredRecord({ error, data }) {
    if (data) {
      this.isPricebookCurrent = data.fields.IsPricebookCurrent__c.value;
      this.oppStage = data.fields.StageName.value;
    } else if (error) {
      console.log({ ...error });
    }
  }

  get isOpenAndOutdated() {
    let stage = String(this.oppStage);
    return !stage.includes("Closed") && !this.isPricebookCurrent;
  }
}
