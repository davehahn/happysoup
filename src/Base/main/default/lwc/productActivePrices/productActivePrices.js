/**
 * Created by dave on 2022-05-26.
 */

import { LightningElement, api, wire } from "lwc";
import { errorToast, successToast, reduceErrors } from "c/utils";
import { NavigationMixin } from "lightning/navigation";
import fetchPrices from "@salesforce/apex/Product_ActivePrices_Controller.getCurrentPricing";
import { refreshApex } from "@salesforce/apex";

import UNIT_PRICE_FIELD from "@salesforce/schema/PricebookEntry.UnitPrice";
import ACTIVE_FIELD from "@salesforce/schema/PricebookEntry.isActive";
import PRICEBOOKID_FIELD from "@salesforce/schema/PricebookEntry.Pricebook2Id";
import PRODUCTID_FIELD from "@salesforce/schema/PricebookEntry.Product2Id";

export default class ProductActivePrices extends NavigationMixin(LightningElement) {
  unitPriceField = UNIT_PRICE_FIELD;
  isActiveField = ACTIVE_FIELD;
  pricebookIdField = PRICEBOOKID_FIELD;
  productIdFiled = PRODUCTID_FIELD;

  @api recordId;
  showForm = false;
  isBusy = false;
  wiredPrices;
  prices;
  editingRecordId;
  pricebookId;
  editObjectApiName = "PricebookEntry";

  @wire(fetchPrices, { prodId: "$recordId" })
  wiredResult(result) {
    this.wiredPrices = result;
    if (result.data) {
      this.prices = result.data;
    }
    if (result.error) {
      errorToast(this, reduceErrors(result.error)[0]);
    }
  }

  get formHeader() {
    let text = this.editingRecordId ? "Edit" : "Create";
    return text + " Pricebook Entry";
  }

  handleEdit(event) {
    this.editingRecordId = event.target.dataset.recordId;
    this.showForm = true;
  }

  handleCancel() {
    this.editingRecordId = null;
    this.pricebookId = null;
    this.showForm = false;
  }

  handleEditSubmit() {
    this.isBusy = true;
  }

  handleEditSuccess() {
    successToast(this, "Pricebook Entry Updated", "Success");
    this.isBusy = false;
    this.showForm = false;
    this.editingRecordId = null;
    refreshApex(this.wiredPrices);
  }

  handleEditError(event) {
    errorToast(this, event.detail.message);
    this.isBusy = false;
  }

  handleCreateEntry(event) {
    this.pricebookId = event.target.dataset.pricebookId;
    console.log(this.pricebookId);
    this.showForm = true;
  }
}
