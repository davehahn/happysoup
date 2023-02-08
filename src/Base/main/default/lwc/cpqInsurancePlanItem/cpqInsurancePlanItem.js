/**
 * Created by dave on 2023-01-21.
 */

import { LightningElement, api, track, wire } from "lwc";
import fetchItem from "@salesforce/apex/CPQ_InsuranceSelector_Controller.fetchInsurancePlanItem";

export default class CpqInsurancePlanItem extends LightningElement {
  @api item;

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
    const evt = new CustomEvent("selected", { detail: { value: event.currentTarget.checked, id: this.item.Id } });
    this.dispatchEvent(evt);
  }

  handleCoverageTypeChange(event){
    this.coverageType = event.currentTarget.value;
    const evt = new CustomEvent('coveragetypechanged', {detail: {id: this.item.Id, value: this.coverageType}});
    this.dispatchEvent(evt);
  }

}
