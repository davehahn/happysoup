/**
 * Created by Tim on 2021-03-30.
 */

import { LightningElement } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { loadStyle, loadScript } from "lightning/platformResourceLoader";
import { renderEN, renderFR } from "c/communitySharedUtils";

export default class FactoryStoreFooterStayInTouch extends NavigationMixin(LightningElement) {
  newsPageRef;
  emailAddress;
  url;

  isEN = renderEN();
  isFR = renderFR();

  connectedCallback() {
    console.log("in newsletter callback");
  }

  clickHandler(e) {
    e.preventDefault();
    e.stopPropagation;
    console.log("hello?");
    const emailAddress = this.template.querySelector('[data-id="newsEmail"]').value;
    console.log("emailAddress", emailAddress);
    this.newsPageRef = {
      type: "comm__namedPage",
      attributes: {
        pageName: "Stay_in_Touch__c"
      },
      state: {
        c__preFillEmail: emailAddress
      }
    };
    this.navigateToPage();
  }

  navigateToPage() {
    console.log("please got to page");
    console.log(this.newsPageRef);
    this[NavigationMixin.Navigate](this.newsPageRef);
    console.log("after navigate");
  }

  get placeholder() {
    return this.isEN ? "Please enter your email address" : "Veuillez SVP entrer votre adresse courriel";
  }
  get submitButton() {
    return this.isEN ? "Continue" : "Continuer";
  }
}
