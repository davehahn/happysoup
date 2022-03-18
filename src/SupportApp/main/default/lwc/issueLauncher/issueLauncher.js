/**
 * Created by dave on 2021-07-13.
 */

import { LightningElement, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getIssueTypes from "@salesforce/apex/IssueLauncher_Controller.fetchIssueTypes";

export default class IssueLauncher extends NavigationMixin(LightningElement) {
  menuItems;
  recordTypeEnabled = {};

  @wire(getIssueTypes)
  wiredIssueTypes({ error, data }) {
    if (data) {
      this.menuItems = data
        .filter((menuItem) => menuItem.Active__c)
        .sort((a, b) => {
          return a.Menu_Order__c - b.Menu_Order__c;
        });

      this.menuItems.forEach((menuItem) => {
        this.recordTypeEnabled[menuItem.SObject_Name__c] = menuItem.Enable_RecordTypes__c === true ? 1 : 0;
      });
      console.log(JSON.parse(JSON.stringify(this.menuItems)));
    } else if (error) {
      console.log(error);
    }
  }

  openNew(objectApiName) {
    this[NavigationMixin.Navigate]({
      type: "standard__objectPage",
      attributes: {
        objectApiName: objectApiName,
        actionName: "new"
      },
      state: {
        useRecordTypeCheck: this.recordTypeEnabled[objectApiName]
      }
    });
  }

  handleIssue(event) {
    this.fireSelectedEvent();
    this.openNew(event.currentTarget.dataset.sobjectName);
  }

  fireSelectedEvent() {
    const evt = new CustomEvent("selected");
    this.dispatchEvent(evt);
  }
}
