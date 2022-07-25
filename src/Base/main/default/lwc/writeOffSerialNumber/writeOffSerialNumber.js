/**
 * Created by Legend on 6/12/21.
 */

import { LightningElement, api, wire } from "lwc";
import { getRecordNotifyChange } from "lightning/uiRecordApi";
import fetchSerialInformation from "@salesforce/apex/gcSerialNumber_Ext.fetchSerialInfo";
import createWriteOff from "@salesforce/apex/gcSerialNumber_Ext.createWriteOffSerial";
import hasPermission from "@salesforce/customPermission/Can_Write_Off_Serial_Number";
import { CloseActionScreenEvent } from "lightning/actions";
import { refreshApex } from "@salesforce/apex";

import SERIAL_OBJECT from "@salesforce/schema/GMBLASERP__Serial_Number__c";
import STATUS_FIELD from "@salesforce/schema/GMBLASERP__Serial_Number__c.Status__c";
import DESC_FIELD from "@salesforce/schema/GMBLASERP__Serial_Number__c.Description__c";

import OUT_OBJECT from "@salesforce/schema/AcctSeedERP__Outbound_Inventory_Movement__c";
import GLV1_FIELD from "@salesforce/schema/AcctSeedERP__Outbound_Inventory_Movement__c.AcctSeedERP__GL_Account_Variable_1__c";
import GLV2_FIELD from "@salesforce/schema/AcctSeedERP__Outbound_Inventory_Movement__c.AcctSeedERP__GL_Account_Variable_2__c";
import DEBIT_FIELD from "@salesforce/schema/AcctSeedERP__Outbound_Inventory_Movement__c.AcctSeedERP__Debit_GL_Account__c";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { errorToast, reduceErrors } from "c/utils";

export default class WriteOffSerialNumber extends LightningElement {
  @api recordId;
  @api serialNumber;

  serialObject = SERIAL_OBJECT;
  statusField = STATUS_FIELD;
  descField = DESC_FIELD;

  outObject = OUT_OBJECT;
  debitField = DEBIT_FIELD;
  glv1Field = GLV1_FIELD;
  glv2Field = GLV2_FIELD;
  ready = false;
  error;
  wiredResult;
  _spinner;
  _rendered = false;
  _dataLoaded = false;

  renderedCallback() {
    if (!this._rendered) {
      this._spinner = this.template.querySelector("c-legend-spinner");
      this._spinner.open();
      this._rendered = true;
    }
    this.init();
  }

  clickSubmit() {
    var outboundKeyValue = {};
    var serialKeyValue = {};
    const inputFields = this.template.querySelectorAll("lightning-input-field");
    var submitFields = true;
    if (inputFields) {
      inputFields.forEach((field) => {
        if (field.value == null) {
          field.reportValidity();
          submitFields = false;
        } else {
          console.log("field");
          console.log(field.fieldName);
          console.log(field.value);
          if (field.fieldName == "Status__c" || field.fieldName == "Description__c") {
            serialKeyValue[field.fieldName] = field.value;
          } else {
            outboundKeyValue[field.fieldName] = field.value;
          }
        }
      });
      if (submitFields) {
        console.log("KeyValue");
        serialKeyValue.Id = this.serialNumber.Id;
        console.log(serialKeyValue);

        outboundKeyValue.AcctSeedERP__Quantity__c = 1;
        outboundKeyValue.GMBLASERP__Serial_Number__c = this.serialNumber.Id;
        outboundKeyValue.GMBLASERP__Product__c = this.serialNumber.GMBLASERP__Product__c;
        outboundKeyValue.GMBLASERP__Lot__c = this.serialNumber.GMBLASERP__Lot__c;
        outboundKeyValue.AcctSeedERP__Inventory_Balance__c = this.serialNumber.GMBLASERP__Inventory_Balance__c;
        outboundKeyValue.AcctSeedERP__Type__c = "Accounting";
        console.log(outboundKeyValue);
        this.doTheSubmit(serialKeyValue, outboundKeyValue);
      }
    }
  }

  doTheSubmit(serial, outbound) {
    this._spinner.open();
    createWriteOff({ serial: serial, outbound: outbound })
      .then((result) => {
        console.log("result 2");
        this._spinner.close();
        this.showToast("Success", "Update successful.", "success");
        getRecordNotifyChange([{ recordId: this.recordId }]);
        refreshApex(this.wiredResult);
        eval("$A.get('e.force:refreshView').fire();");
        this.dispatchEvent(new CloseActionScreenEvent());
      })
      .catch((error) => {
        console.log("error");
        console.log(error);
        this.showToast("Error", JSON.stringify(error), "error");
        this._spinner.close();
      });
  }

  handleSubmit(event) {
    event.preventDefault();
  }

  @wire(fetchSerialInformation, { serialId: "$recordId" })
  wiredItems(result) {
    this.wiredResult = result;
    if (result.data) {
      console.log("result");
      console.log(JSON.parse(result.data));
      this.serialNumber = JSON.parse(result.data);
      if (!hasPermission) {
        this.error = "You do not have permission to access this feature.";
        this._spinner.close();
      } else if (this.serialNumber.Location__c == "OUT") {
        this.error = "The Serial is not in inventory.";
        this._spinner.close();
      } else {
        this._dataLoaded = true;
        this.ready = true;
      }
    } else if (result.error) {
      console.log("error");
      console.log(result.error);
      this.error = result.error.body.message;
      this._spinner.close();
    }
  }
  init() {
    if (this._rendered && this._dataLoaded) {
      this._spinner.close();
    }
  }

  showToast(tTitle, tMessage, tVariant) {
    const event = new ShowToastEvent({
      title: tTitle,
      message: tMessage,
      variant: tVariant
    });
    this.dispatchEvent(event);
  }
}
