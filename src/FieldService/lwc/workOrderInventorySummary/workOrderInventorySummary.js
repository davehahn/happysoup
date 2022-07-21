/**
 * Created by dave on 2020-12-09.
 */

import { LightningElement, api, track } from "lwc";
import { errorToast, reduceErrors } from "c/utils";
import fetchSummary from "@salesforce/apex/WorkOrderInventorySummary_Controller.getInventory";

export default class WorkOrderInventorySummary extends LightningElement {
  @api recordId;
  spinner;
  @track summaryLines;
  headings = ["Product", "Required", "Warehouse", "Pick and Pack"];

  async connectedCallback() {
    try {
      this.summaryLines = await fetchSummary({ workOrderId: this.recordId });
      this.init();
    } catch (error) {
      errorToast(this, reduceErrors(error).join(", "));
    }
  }

  init() {
    if (this.summaryLines) {
      if (
        this.summaryLines &&
        this.summaryLines.length > 0 &&
        this.summaryLines[0].resourceLines &&
        this.summaryLines[0].resourceLines.length > 0
      ) {
        console.log(this.summaryLines[0].resourceLines);
        this.summaryLines[0].resourceLines.reduce((acc, rl) => {
          acc.push(rl.name);
          return acc;
        }, this.headings);
      }
      this.toggleSpinner(false);
    }
  }

  toggleSpinner(open) {
    if (this.spinner === undefined) this.spinner = this.template.querySelector("c-legend-spinner");

    open ? this.spinner.open() : this.spinner.close();
  }
}
