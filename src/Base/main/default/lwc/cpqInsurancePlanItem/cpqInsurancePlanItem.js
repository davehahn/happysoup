/**
 * Created by dave on 2023-01-21.
 */

import { LightningElement, api, track, wire } from "lwc";
import fetchItem from "@salesforce/apex/CPQ_InsuranceSelector_Controller.fetchInsurancePlanItem";

export default class CpqInsurancePlanItem extends LightningElement {
  @api item;

//  @track planItem;
  @track coverageType = "Single";
  @track isSelected = false;
  @track rate;
  @track termOutOfRange = false;

  _rates;

  initialized = true;
  coverageTypeOptions = [
    { label: "Single", value: "Single" },
    { label: "Joint", value: "Joint" }
  ];

//  @wire(fetchItem, { productId: "$productId", taxZoneId: "$taxZoneId" })
//  wiredItem({ error, data }) {
//    if (data) {
//      const planItem = JSON.parse(data);
//      this._rates = planItem.Insurance_Rates__r.records;
//      this._findCurrentRate();
//      this.initialized = true;
//    }
//    if (error) {
//      console.log(JSON.parse(JSON.stringify(error)));
//    }
//  }

  get coverageTypeEnabled() {
    return !this.item.isSelected;
  }

  get rowClass(){
    let klass = 'insurance-item-row';
    if( this.item.isSelected ){
      klass += ' selected';
    }
    if( this.item.termOutOfRange ){
      klass += ' term-out-of-range';
    }
    return klass;
  }

  get unitPriceClass() {
    let klass = "unit-price-input";
    if (this.item.isSelected) {
      klass += " selected";
    }
    return klass;
  }

  handleSelected(event) {
    console.log('insuranceLineItemSelected');
    console.log( JSON.parse( JSON.stringify( this.item ) ) );
    const evt = new CustomEvent("selected", { detail: { value: event.currentTarget.checked, id: this.item.Id } });
    this.dispatchEvent(evt);
  }

  handleCoverageTypeChange(event){
    this.coverageType = event.currentTarget.value;
    //this._findCurrentRate();
    const evt = new CustomEvent('coveragetypechanged', {detail: {id: this.item.Id, value: this.coverageType}});
    this.dispatchEvent(evt);
  }

//  handleValueChange(event) {
//    const insuranceProduct = {
//      id: this.productId,
//      activePricebookEntryId: this.pricebookEntryId,
//      name: this.item.Name,
//      coverage: this.coverageType,
//      insuranceRate: this.rate,
//      unitPrice: event.currentTarget.value,
//      isResidual: this.isResidual
//    };
//    const evt = new CustomEvent("planitemchange", { detail: insuranceProduct });
//    this.dispatchEvent(evt);
//  }

//  _findCurrentRate() {
//    const result = this._rates.filter(
//      (rate) =>
//        (this.term >= rate.Lower_Term__c &&
//          this.term <= rate.Upper_Term__c &&
//          this.finTerm >= rate.Lower_Finance_Term__c &&
//          this.finTerm <= rate.Upper_Finance_Term__c) ||
//        (this.term >= rate.Lower_Term__c &&
//          this.term <= rate.Upper_Term__c &&
//          (rate.Lower_Finance_Term__c == null || rate.Upper_Finance_Term__c == null))
//    );
//    if (result.length > 0) {
//      this.termOutOfRange = false;
//      if (this.coverageType === "Single") {
//        this.rate = result[0].Single__c;
//      } else if (this.coverageType === "Joint") {
//        if (this.isFromQuebec) {
//          this.rate = result[0].Joint_Factored_Result__c;
//        } else {
//          this.rate = result[0].Joint__c;
//        }
//      } else {
//        this.rate = null;
//      }
//    } else {
//      this.termOutOfRange = true;
//    }
//
//    let evt = new CustomEvent("ratechange", { detail: { id: this.item.Id, value: this.item.rate } });
//    this.dispatchEvent(evt);
//  }
}
