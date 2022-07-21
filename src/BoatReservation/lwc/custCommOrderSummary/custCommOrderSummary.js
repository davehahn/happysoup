/**
 * Created by Tim on 2020-04-23.
 */

import { LightningElement, api, wire, track } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import { fireEvent, registerListener, unregisterAllListeners } from "c/pubsub";

export default class CustCommOrderSummary extends LightningElement {
  @wire(CurrentPageReference) pageRef;

  @api usage;

  @track performanceItems = [];
  @track traileringItems = [];
  @track electronicsItems = [];
  @track freightItems = [];

  @track isEN = true;
  @track isFR = false;

  connectedCallback() {
    registerListener("updateSummary", this.updateSummary, this);
    fireEvent(this.pageRef, "summaryConnected", "ready");
  }
  renderedCallback() {
    registerListener("languageChange", this.handleLanguageChange, this);
  }

  get checkIsThanks() {
    return this.usage === "thankyou" ? true : false;
  }

  updateSummary(details) {
    let payload = {
      name: details.name,
      name_fr: details.name_fr,
      sku: details.sku,
      inputName: details.userSelectionName
    };
    if (details.addToSummary) {
      //add item to list
      if (details.type === "radio") {
        //replace the existing item for this section
        if (details.addon) {
        } else {
          if (details.section === "performance") {
            this.ifContains(this.performanceItems, payload);
          } else if (details.section === "trailering") {
            this.ifContains(this.traileringItems, payload);
          } else if (details.section === "electronics") {
            this.ifContains(this.electronicsItems, payload);
          }
        }
      } else if (details.type === "select") {
        this.freightItems.length = 0;
        this.freightItems.push(payload);
      } else {
        //append the item to this section
        if (details.section === "performance") {
          this.performanceItems.push(payload);
        } else if (details.section === "trailering") {
          this.traileringItems.push(payload);
        } else if (details.section === "electronics") {
          this.electronicsItems.push(payload);
        }
      }
    } else {
      //remove item from list
      if (details.section === "performance") {
        this.performanceItems = this.performanceItems.filter((obj) => obj.sku !== payload.sku);
      } else if (details.section === "trailering") {
        this.traileringItems = this.traileringItems.filter((obj) => obj.sku !== payload.sku);
      } else if (details.section === "electronics") {
        this.electronicsItems = this.electronicsItems.filter((obj) => obj.sku !== payload.sku);
      }
    }

    //	console.log('summaryList: ', JSON.parse(JSON.stringify(this.summaryList)));
  }

  ifContains(array, object) {
    let index = array.findIndex(({ inputName }) => inputName === object.inputName);
    if (index === -1) {
      array.push(object);
    } else {
      array[index] = object;
    }
  }

  handleLanguageChange(detail) {
    if (detail) {
      this.isEN = detail === "EN" ? true : false;
      this.isFR = detail === "FR" ? true : false;
    }
  }
}
