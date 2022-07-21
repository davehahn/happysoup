/**
 * Created by dave on 2021-06-18.
 */

import { LightningElement, api, wire } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import { getRecord, updateRecord } from "lightning/uiRecordApi";
import { refreshApex } from "@salesforce/apex";
import { successToast, errorToast, reduceErrors } from "c/utils";
import USER_ID from "@salesforce/user/Id";
import ID_FIELD from "@salesforce/schema/Queueable_Exception_Log__c.Id";
//import SYSTEM_ISSUE_FIELD from '@salesforce/scheme/Queueable_Exception_Log__c.System_Issue__c';
import STATUS_FIELD from "@salesforce/schema/Queueable_Exception_Log__c.Status__c";

export default class QueueableExceptionCreateIssue extends LightningElement {
  @api recordId;

  _recordData;
  wiredRecord;
  isBusy = false;
  alreadyCreated = false;
  subject;
  description;

  @api invoke() {
    console.log("component open");
  }

  @wire(getRecord, { recordId: "$recordId", layoutTypes: ["Full"], modes: ["View"] })
  wiredLog(result) {
    console.log("wire done");
    this.wiredRecord = result;
    if (result.data) {
      console.log(JSON.parse(JSON.stringify(result.data)));
      this._recordData = result.data;
      if (this._getFieldValue("System_Issue__c") != null) {
        this.alreadyCreated = true;
      } else {
        this.subject = this._buildSubject();
        this.description = this._buildDescription();
      }
    } else if (result.error) {
      errorToast(this, reduceErrors(error).join(", "));
    }
  }

  get title() {
    return this._recordData == undefined
      ? "Loading ..."
      : this.alreadyCreated
      ? "System Issue Already Created"
      : "Create System Issue";
  }

  handleCancel() {
    this._closeModal();
  }

  handleSubmit() {
    this.isBusy = true;
  }

  handleSuccess(event) {
    this._updateRecord(event.detail.id)
      .then(() => {
        successToast(this, "System Issues Created");
        refreshApex(this.wiredRecord);
      })
      .catch((error) => {
        errorToast(this, reduceErrors(error).join(", "));
      })
      .finally(() => {
        this.isBusy = false;
        this._closeModal();
      });
  }

  handleError() {}

  _closeModal() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  _getFieldValue(fieldName) {
    return this._recordData.fields[fieldName].value;
  }

  _buildSubject() {
    return (
      this._getFieldValue("Type__c") +
      " - " +
      this._getFieldValue("Class_Name__c") +
      "." +
      this._getFieldValue("Method_Name__c")
    );
  }

  _buildDescription() {
    return (
      this._getFieldValue("Type__c") +
      "\n\n" +
      this._getFieldValue("Message__c") +
      "\n\n" +
      this._getFieldValue("Stack_Trace__c")
    );
  }

  _updateRecord(systemIssueId) {
    const fields = {};
    fields[ID_FIELD.fieldApiName] = this.recordId;
    fields[STATUS_FIELD.fieldApiName] = "System Issue Created";
    fields["OwnerId"] = USER_ID;
    fields["System_Issue__c"] = systemIssueId;

    const recordInput = { fields };

    return updateRecord(recordInput);
  }
}
