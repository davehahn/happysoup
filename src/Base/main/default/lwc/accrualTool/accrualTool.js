import { LightningElement, api, wire, track } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { errorToast, successToast, warningToast, reduceErrors } from 'c/utils';
import { CloseActionScreenEvent } from 'lightning/actions';
import fetchERPRecord from '@salesforce/apex/AccrualTool_Controller.fetchERPData';
import fetchCommissionLineItems from '@salesforce/apex/AccrualTool_Controller.fetchCommissionRecords';
import fetchSerializedProductsData from '@salesforce/apex/AccrualTool_Controller.fetchSerializedProducts';
import loadExpenseAndRevenue from '@salesforce/apex/AccrualTool_Controller.fetchOrderLines';
import createJournalEntries from '@salesforce/apex/AccrualTool_Controller.createJournalEntry';

import NAME_FIELD from "@salesforce/schema/AcctSeed__Project__c.Name";

const fields = [NAME_FIELD]; //comma separated

export default class AccrualTool extends LightningElement {

  @api recordId;

  @track lineItems;
  @track commissionPayments;
  @track allCommissionReviewed;
  @track serializedProducts;
  @track revenueData;
  @track expenseData;
  @track insuranceData;
  @track journalLineData;
  @track journalData;
  @track totalCredit;
  @track totalDebit;
  @track totalJournalAmountHighlight;
  @track totalRevenue;
  @track totalExpense;
  @track grossMargin;
  @track journalEntryName

  @track progressStep = "1";
  @track showPrevious = false;
  @track showNext = true;
  @track showPost = true;
  @track erpStageAllowed = true;


  @track step1;
  @track step2;
  @track step3;
  @track step4;
  @track step5;
  @track step6;
  @track step7;
  @track step8;

  @track jedate;
  @track jedate2;
  @track usedStatus = false;;

  nextClick() {
    debugger;
    let progStepNum = Number(this.progressStep);
    this.checkERPStage();
    if (progStepNum == 1 && !this.erpStageAllowed) {
      this.showNext = false;
    }

    progStepNum = progStepNum + 1;
    if (progStepNum == 8) {
      this.showNext = false;
    }
    this.progressStep = progStepNum.toString();
    this.showPrevious = true;
    this.getcurrentStep();
    if (this.erpStageAllowed && progStepNum == 4) {
      this.fetchRevenueandExpenses();// need to invoke this at specific step
    }

  }
  previousClick() {
    debugger;
    let progStepNum = Number(this.progressStep);
    if (progStepNum >= 1) {
      progStepNum = progStepNum - 1;
      if (progStepNum == 1) {
        this.showPrevious = false;
      }
    }
    this.showNext = true;
    this.progressStep = progStepNum.toString();
    this.getcurrentStep();
  }

  dateChange(event) {
    debugger;
    this.jedate = event.target.value;
    this.setVisibleDate(false);
  }

  setVisibleDate (onLoad) {
    debugger;
    var date;
    var month;
    var year;
    if(onLoad) {
      var today = new Date();
     date = today.getDate();
     month = today.getMonth() + 1;
     year = today.getFullYear();
    } else{
       if(this.jedate != undefined){
      year = this.jedate.substring(0,4);
     month = parseInt(this.jedate.substring(5,7));
     date = this.jedate.substring(8);
    }
    }
    
    //this.jedate = today.getDate() +"-" + (today.getMonth() + 1) +"-" + today.getFullYear() ;
   
    var monthStr;
    switch(month) {
      case 1: monthStr = 'Jan'; break;
      case 2: monthStr = 'Feb'; break;
      case 3: monthStr = 'Mar'; break;
      case 4: monthStr = 'Apr'; break;
      case 5: monthStr = 'May'; break;
      case 6: monthStr = 'Jun'; break;
      case 7: monthStr = 'Jul'; break;
      case 8: monthStr = 'Aug'; break;
      case 9: monthStr = 'Sep'; break;
      case 10: monthStr = 'Oct'; break;
      case 11: monthStr = 'Nov'; break;
      case 12: monthStr = 'Dec';
    }
  this.jedate2 = date +"-"+ monthStr+"-"+year;

  }

  closeQuickAction() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  getcurrentStep() {
    let progStepNum = Number(this.progressStep);
    switch (progStepNum) {
      case 1:
        this.step1 = true;
        this.step2 = false;
        this.step3 = false;
        this.step4 = false;
        this.step5 = false;
        this.step6 = false;
        this.step7 = false;
        this.step8 = false;
        break;
      case 2:
        this.step1 = false;
        this.step2 = true;
        this.step3 = false;
        this.step4 = false;
        this.step5 = false
        this.step6 = false;
        this.step7 = false;
        this.step8 = false;
        break;
      case 3:
        this.step1 = false;
        this.step2 = false;
        this.step3 = true;
        this.step4 = false;
        this.step5 = false;
        this.step6 = false;
        this.step7 = false;
        this.step8 = false;
        break;
      case 4:
        this.step1 = false;
        this.step2 = false;
        this.step3 = false;
        this.step4 = true;
        this.step5 = false;
        this.step6 = false;
        this.step7 = false;
        this.step8 = false;
        break;
      case 5:
        this.step1 = false;
        this.step2 = false;
        this.step3 = false;
        this.step4 = false;
        this.step5 = true;
        this.step6 = false;
        this.step7 = false;
        this.step8 = false;
        break;
      case 6:
        this.step1 = false;
        this.step2 = false;
        this.step3 = false;
        this.step4 = false;
        this.step5 = false;
        this.step6 = true;
        this.step7 = false;
        this.step8 = false;
        break;
      case 7:
        this.step1 = false;
        this.step2 = false;
        this.step3 = false;
        this.step4 = false;
        this.step5 = false;
        this.step6 = false;
        this.step7 = true;
        this.step8 = false;
        break;
      case 8:
        this.step1 = false;
        this.step2 = false;
        this.step3 = false;
        this.step4 = false;
        this.step5 = false;
        this.step6 = false;
        this.step7 = false;
        this.step8 = true;
    }
  }
  connectedCallback() {
    var today = new Date();
    //this.jedate = today.getFullYear() + "-" + (today.getMonth() + 1) + "-" + today.getDate();
    this.jedate = today.getDate() +"-" + (today.getMonth() + 1) +"-" + today.getFullYear() ;

    this.setVisibleDate(true);
    this.progressStep = "1";
    this.step1 = true;
    refreshApex(this.wiredGetErpRecord);
  }

  //@wire(fetchERPRecord, { erpId: '$recordId' })
  //erprecord;


  @wire(fetchERPRecord, { erpId: '$recordId' })
  wiredGetErpRecord(result) {
    console.log('calling method - $recordId');
    debugger;
    if (result.data) {
      this.erprecord = result.data;
      this.journalEntryName = "Accrual Entry - " + this.erprecord.Name;
      this.checkERPStage();
      if (this.erpStageAllowed) {
        this.getCommissionLineItems();
        this.getSerializedProducts();
      }
    };
  }

  checkERPStage() {
    debugger;
    if(this.erprecord.Journal_Entries__r != null && this.erprecord.Journal_Entries__r.length != 0) {
      this.closeQuickAction();
      errorToast(this, 'Journal Entry for this ERP is already created.', ' Warning!');
    }else if (this.erprecord.Stage__c == "Tagging Pending" || this.erprecord.Stage__c == "Delivered" || this.erprecord.Stage__c == "Closed Lost") {
      this.erpStageAllowed = false;
      this.closeQuickAction();
      errorToast(this, 'This function is not available for current stage', ' Warning!');
    } else {
      this.erpStageAllowed = true;
    }
  }

  createJournalEntry() {
    debugger;
    let spinner = this.template.querySelector("c-legend-spinner");
    spinner.toggle();
    createJournalEntries({ erpId: this.recordId, jounralEntryDate: this.jedate })
      .then(result => {
        debugger;
        console.log(result);
        successToast(this, result, ' Journal Entry Created!');
      })
      .catch(error => {
        debugger;
        console.log(error);
        errorToast(this, error, ' Error!');
      })
      .finally(function () {
        spinner.toggle();
        this.showPost = false;
        this.closeQuickAction();
      });
  }

  fetchRevenueandExpenses() {
    debugger;
    let spinner = this.template.querySelector("c-legend-spinner");
    spinner.toggle();
    loadExpenseAndRevenue({ erpId: this.recordId })
      .then(result => {
        debugger;
        console.log(result);

        this.revenueData = result.Revenue;
        this.expenseData = result.Expense;
        this.insuranceData = result.Insurance;
        this.journalLineData = result.JournalLines;
        this.totalCredit = result.TotalCredit;
        this.totalDebit = result.TotalDebit;
        if (this.totalCredit.totalAmount != this.totalDebit.totalAmount) {
          this.totalJournalAmountHighlight = "background-color:red;";
          this.showPost = false;
        } else {
          this.totalJournalAmountHighlight = "background-color:lightgreen;";
          this.showPost = true;
        }

        this.totalExpense = this.expenseData.totalAmount;// + this.insuranceData.totalAmount;
        this.totalRevenue = this.revenueData.totalAmount;// + this.journalLineData.totalAmount;
        if (this.totalRevenue == this.totalExpense) {
          this.grossMargin = 0;
        } else {
          this.grossMargin = ((this.totalRevenue - this.totalExpense) / this.totalRevenue) * 100;
        }
      })
      .catch(error => {
        debugger;
        console.log(error);
      })
      .finally(function () {
        spinner.toggle();
      });
  }

  getCommissionLineItems() {
    debugger;
    fetchCommissionLineItems({ erpId: this.recordId })
      .then(result => {
        console.log(JSON.parse(JSON.stringify(result)));
        let commissionData = result;
        this.allCommissionReviewed = commissionData.isReviewed;
        this.lineItems = commissionData.commissionRecordsList;
        this.commissionPayments = commissionData.commPaymentWrapper;

        if (!this.allCommissionReviewed) {
          this.showNext = false;
        }

      })
      .catch(error => {
        debugger;
        console.log(error);
        errorToast(this, 'Contact your Salesforce Administrator', ' Error!');
      })
      .finally(function () {
      });
  }
  getSerializedProducts() {
    debugger;
    fetchSerializedProductsData({ erpId: this.recordId })
      .then(result => {
        console.log(JSON.parse(JSON.stringify(result)));
        this.serializedProducts = [...result];

        for(var i= 0 ; i< result.length;i++ ){
          console.log(result[i].Status);
          if(result[i].Status == 'Used'){
          this.usedStatus = true;
          }
        }

      })
      .catch(error => {
        debugger;
        errorToast(this, 'Contact your Salesforce Administrator', ' Error!');
      })
      .finally(function () {
      });
  }

}