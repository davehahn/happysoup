/**
 * Created by dave on 2020-02-21.
 */

import { LightningElement, api, track, wire } from "lwc";
import Id from "@salesforce/user/Id";
import { CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { fireEvent } from "c/pubsub";
import statusChange from "@salesforce/apex/CommissionRecord2_Controller.paymentStatusChange";
import hasManagerPermission from "@salesforce/apex/CommissionRecord2_Controller.fetchManagerCustomPermission";

export default class CommissionPaymentCard extends LightningElement {
  userId = Id;
  @wire(CurrentPageReference) pageRef;
  @api payment;
  @api canSeeManagerData;
  @api isEditing;
  @track showDisputeReason = false;
  @track disputeReason;
  @track paymentType;
  _status;
  userSelectFields = ["Name", "SmallPhotoUrl", "Commission_Gross_Margin_Percent_Override__c"];
  userFilterFields = ["Name"];

  get options() {
    return [
      { label: "Standard", value: "Standard" },
      { label: "Manager", value: "Manager" }
    ];
  }

  get renderIndicator() {
    return this.payment.status !== "New";
  }

  get renderSplit() {
    console.log(this.payment);
    return this.payment.cType === "Standard";
  }

  get renderStatusMenu() {
    return (
      this.payment.status === "New" &&
      this.payment.ownerId === this.userId &&
      this.payment.commissionRecordStatus === "Approved"
    );
  }

  get indicatorIconName() {
    if (this.payment.status === "Accepted") return "action:following";
    if (this.payment.status === "Disputed") return "action:priority";
  }

  get disputeFormInvalid() {
    return !this.disputeReason;
  }

  handleTypeChange(event) {
    this.paymentType = event.detail.value;
    if (this.paymentType != "Standard") {
      this.amount = 0;
    }
  }

  handleDisputeReasonChange(event) {
    this.disputeReason = event.target.value;
  }

  handleSpitPercentChange(event) {
    let changeData = {
      split: event.detail.value
    };
    this.updatePayment(changeData);
  }

  handleOwnerSelect(event) {
    let owner = event.detail.value,
      changeData;

    changeData = {
      owner: owner.Name,
      ownerId: owner.Id,
      avatarURL: owner.SmallPhotoUrl
    };
    if (
      typeof owner.Commission_Gross_Margin_Percent_Override__c !== "undefined" &&
      owner.Commission_Gross_Margin_Percent_Override__c !== null
    ) {
      changeData.grossMarginPaymentPercent = owner.Commission_Gross_Margin_Percent_Override__c;
    } else {
      changeData.grossMarginPaymentPercent = 10;
    }
    this.updatePayment(changeData);
  }

  handleRemovePayment(event) {
    fireEvent(this.pageRef, "paymentRemoved", {
      paymentId: event.currentTarget.value
    });
  }

  updatePayment(changeData) {
    let data = Object.assign({}, this.payment);
    Object.keys(changeData).forEach((attr) => (data[attr] = changeData[attr]));
    data.amount = this.reCalcAmount(data);
    fireEvent(this.pageRef, "paymentChanged", {
      id: data.id,
      payment: data
    });
  }

  reCalcAmount(data) {
    console.log(data);
    if (data.usesGrossCalculation) {
      if (data.cType != "Manager") {
        return data.totalProfit * (data.grossMarginPaymentPercent / 100) * (data.split / 100);
      } else {
        if (data.mcType == "Gross Margin" || data.mcType == "Revenue")
          return data.totalProfit * (data.grossMarginPaymentPercent / 100);
        else if (data.mcType == "Business Revenue") return data.totalPayment * (data.grossMarginPaymentPercent / 100);
      }
    } else {
      if (data.cType == "Manager") {
        if (data.mcType == "Gross Margin" || data.mcType == "Revenue")
          return data.totalProfit * (data.grossMarginPaymentPercent / 100);
        else if (data.mcType == "Business Revenue") return data.totalPayment * (data.grossMarginPaymentPercent / 100);
      } else return data.totalPayment * (data.split / 100);
    }
  }

  handleStatusChange(event) {
    this._status = event.target.value;
    if (this._status === "Accepted") this.doStatusUpdate();
    if (this._status === "Disputed") {
      this.disputeReason = null;
      this.showDisputeReason = true;
    }
  }

  doStatusUpdate() {
    let spinner = this.template.querySelector("c-legend-spinner"),
      title,
      state,
      message;

    spinner.toggle();

    statusChange({
      recordId: this.payment.id,
      status: this._status,
      disputeReason: this.disputeReason
    })
      .then((result) => {
        this.payment = result;
        if (this._status === "Disputed") {
          this.dispatchEvent(
            new CustomEvent("paymentdispute", {
              detail: { recordId: this.payment.id }
            })
          );
        }
        title = "Success";
        state = "success";
        message = "Payment Successfully updated";
      })
      .catch((error) => {
        title = error.message ? error.message : "There was an Error";
        state = "error";
        message = error;
      })
      .finally(() => {
        spinner.toggle();
        this.resetDisputeForm();
        this.dispatchEvent(
          new ShowToastEvent({
            title: title,
            message: message,
            variant: state
          })
        );
      });
  }

  fetchManagerPermission() {
    let spinner = this.template.querySelector("c-legend-spinner"),
      title,
      state,
      message;

    spinner.toggle();

    fetchManagerCustomPermission()
      .then((result) => {
        this.canSeeManagerData = result;
      })
      .catch((error) => {
        title = error.message ? error.message : "There was an Error";
        state = "error";
        message = error;
      })
      .finally(() => {
        spinner.toggle();
      });
  }

  handleSaveDispute() {
    this.doStatusUpdate();
  }

  handleCancelDispute() {
    this.resetDisputeForm();
  }

  resetDisputeForm() {
    this.disputeReason = null;
    this._status = null;
    this.showDisputeReason = false;
  }
}
