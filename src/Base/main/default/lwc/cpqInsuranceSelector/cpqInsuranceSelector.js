/**
 * Created by dave on 2023-01-21.
 */

import { LightningElement, api, track, wire } from 'lwc';
import initInsurance from '@salesforce/apex/CPQ_InsuranceSelector_Controller.init'
import fetchPlanItems from '@salesforce/apex/CPQ_InsuranceSelector_Controller.fetchPlanItems'
import { doInsuranceCalculations } from "c/utils";

export default class CpqInsuranceSelector extends LightningElement {

  @api cpq;
  @api preInsuranceTotal;

  @track selectedPlanId;
//  @track hasChanges=false;
//  @track isFromQuebec=false;

  planOptions=[];
  @track groupedPlanItems;
  @track initInsurance;
  ready=false;
  selectedItems={};
  _term=0;
  _amort=0;
  _deposit=0;
  _interestRate=0;


  connectedCallback(){
    initInsurance({recordId: this.cpq.saveToRecordId, cacheBypass: Date.now().toString()})
    .then( data => {
      this.initInsurance = JSON.parse(data);
      this._init();
    })
    .catch(error => {
      console.log( JSON.parse( JSON.stringify( error ) ) );
    });
  }

  _init(){
    console.log('%cInitInsurance', 'font-size:18px;color:red');
    console.log( JSON.parse( JSON.stringify( this.initInsurance ) ) );
    this.selectedItems = this.initInsurance.selectedItems;
    this.selectedPlanId = this.initInsurance.planId;
    if(typeof(this.preInsuranceTotal) !== undefined && this.initInsurance.preInsuranceAmount !== this.preInsuranceTotal ){
      this.initInsurance.preInsuranceAmount = this.preInsuranceTotal;
    }
    if( this.initInsurance.plans ) {
      this._buildPlanOptions(this.initInsurance.plans);
      if( typeof(this.selectedPlanId) !== undefined && this.selectedPlanId !== null && this.selectedPlanId.length > 0 ){
        this._fetchPlanItems();
      }
      this.ready=true;
    }
  }

  /*
    @paymentDetails = {
      amort: 120,
      biWeeklyPayment:318.76102371569306,
      deposit: "1000",
      interestRate: 6.99,
      monthlyPayment:690.6488847173349,
      recordId: "0Q0DM000000YKB80AO",
      term: 60,
      weeklyPayment: 159.38051185784653
    }
  */
  @api paymentDetailsChanged(paymentDetails){
    console.log('%cPaymentDetails', 'font-size:18px;color:purple');
    console.log( JSON.parse( JSON.stringify( paymentDetails ) ) );
    const termChanged = this.initInsurance.term !== parseFloat(paymentDetails.insuranceTerm);
    this.initInsurance.term = parseFloat(paymentDetails.insuranceTerm);
    this.initInsurance.amort = parseFloat(paymentDetails.amort);
    this.initInsurance.intrestRate = parseFloat(paymentDetails.interestRate);
    this.initInsurance.deposit = parseFloat(paymentDetails.deposit);
    if( this.groupedPlanItems ){
      if(termChanged){
        this._applyNewInsuranceRate()
      }
      this._recalculateSelected();
    }
  }

  @api preInsuranceAmountChanged( amount ){
    console.log('lwc-preInsuranceAmountChange');
    this.initInsurance.preInsuranceAmount = amount;
    if( this.groupedPlanItems ){
      this._recalculateSelected();
    }
  }

  get isInitialized(){
    return typeof(this.initInsurance) != undefined && typeof(this.planItems) !== undefined;
  }

  get hasPlanItems(){
    return typeof(this.groupedPlanItems) !== undefined;
  }

  handleSelected(event){
    const result = event.detail;
    this.groupedPlanItems.forEach( plan => {
      plan.planItems.forEach( item => {
        if( item.Id === result.id ){
          item.isSelected = result.value;
        }
      });
    });
    this._recalculateSelected();
  }

  handleRateChange(event){
    const result = event.detail;
    this.groupedPlanItems.forEach( plan => {
      plan.planItems.forEach( item => {
        if( item.Id === result.id ){
          item.insuranceRate = result.value;
        }
      });
    });
  }

  handlePlanSelect(event){
    this.selectedPlanId = event.currentTarget.value;
    this._fetchPlanItems();
  }

  handleCoverageTypeChange(event){
    const result = event.detail;
    this.groupedPlanItems.forEach( plan => {
      plan.planItems.forEach( item => {
        if( item.Id === result.id ){
          item.coverageType = result.value;
        }
      });
    });
    this._recalculateSelected();
  }

  _buildPlanOptions(plans) {
    plans.reduce((result, plan) => {
      result.push({label: plan.Name, value: plan.Id});
      return result;
    }, this.planOptions );
  }

  _fetchPlanItems(){
    fetchPlanItems({planId: this.selectedPlanId, pricebookId: this.cpq.activePricebookId, taxZoneId: this.initInsurance.taxZoneId})
    .then( result => {
      this.groupedPlanItems = JSON.parse(result);
      this.groupedPlanItems.forEach( plan => {
        plan.planItems.forEach( item => {
          if( Object.keys(this.selectedItems).indexOf(item.Id) >= 0 ){
            item.unitPrice = this.selectedItems[item.Id].unitPrice;
            item.coverageType = this.selectedItems[item.Id].coverage;
            item.isSelected = true;
          } else {
            item.unitPrice = 0;
            item.isSelected = false;
            item.coverageType = 'Single';
          }
          this._setItemInsuranceRate(item);
          console.log( JSON.parse( JSON.stringify( item ) ) );
        });
      })
    })
    .catch( error => {
      console.log(error);
    })
  }

  _applyNewInsuranceRate(){
    console.log('%capplyNewInsuranceRate', 'font-size:22px');
    let hasTermError=false;
    this.groupedPlanItems.forEach( plan => {
      plan.planItems.forEach( item => {
         this._setItemInsuranceRate(item);
         if( item.termOutOfRange && item.isSelected ){
           hasTermError=true
         }
      })
    });
    console.log(`%chasTErmErrors ${hasTermError}`, 'font-size:16px; color:red');
    const evt = new CustomEvent('insurancetermapplied', {detail: {hasErrors: hasTermError}});
    this.dispatchEvent(evt);
  }

  _setItemInsuranceRate(item){
    const result = item.rates.filter(
      (rate) =>
        (this.initInsurance.term >= rate.Lower_Term__c &&
          this.initInsurance.term <= rate.Upper_Term__c &&
          this.initInsurance.finTerm >= rate.Lower_Finance_Term__c &&
          this.initInsurance.finTerm <= rate.Upper_Finance_Term__c) ||
        (this.initInsurance.term >= rate.Lower_Term__c &&
          this.initInsurance.term <= rate.Upper_Term__c &&
          (rate.Lower_Finance_Term__c == null || rate.Upper_Finance_Term__c == null))
    );
    if (result.length > 0) {
      item.termOutOfRange = false;
      if (item.coverageType === "Single") {
        item.rate = result[0].Single__c;
      } else if (item.coverageType === "Joint") {
        if (this.initInsurance.isFromQuebec) {
          item.rate = result[0].Joint_Factored_Result__c;
        } else {
          item.rate = result[0].Joint__c;
        }
      } else {
        item.rate = null;
      }
    } else {
      item.termOutOfRange = true;
    }
  }

  _recalculateSelected(){
    const params = {
      groupedItems: this.groupedPlanItems,
      amount: this.initInsurance.preInsuranceAmount,
      deposit: this.initInsurance.deposit,
      term: this.initInsurance.term,
      amort: this.initInsurance.amort,
      interestRate: this.initInsurance.intrestRate,
      insuranceTaxRate: this.initInsurance.insuranceTaxRate,
      calculationMethod: this.initInsurance.isFromQuebec ? 'Simple' : 'Recursive'
    }
    doInsuranceCalculations(params);
    this._publishChangeEvent();
  }

  _publishChangeEvent(){
    let selectedItems = [];
    this.groupedPlanItems.forEach( plan => {
      plan.planItems.forEach( item => {
        if( item.isSelected ){
          console.log( JSON.parse( JSON.stringify( item ) ) );
          console.log(`pricebookEntryId = ${item.PricebookEntryId}`);
          selectedItems.push({
            id: item.Id,
            name: item.Name,
            family: item.Family,
            activePricebookEntryId: item.PricebookEntryId,
            type: item.Family,
            coverage: item.coverageType,
            insuranceRate: item.insuranceRate,
            isResidual: item.isResidual === 'true' ? true : false,
            unitPrice: item.unitPrice
          })
        }
      })
    });
    console.log( JSON.parse( JSON.stringify( selectedItems ) ) );
    const evt = new CustomEvent('itemschange', {detail: {insuranceItems: selectedItems }});
    this.dispatchEvent(evt);
  }
}