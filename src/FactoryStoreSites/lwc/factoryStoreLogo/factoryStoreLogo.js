/**
 * Created by Tim on 2021-08-12.
 */

import { LightningElement, wire, api } from "lwc";
import {
  stringy,
  stripParentheses,
  rewriteMotorName,
  rewriteTrailerName,
  weeklyPayment,
  formatPrice,
  setWrapperClass
} from "c/communitySharedUtils";
import Id from "@salesforce/community/Id";
import { NavigationMixin } from "lightning/navigation";
import fetchCommunityDetails from "@salesforce/apex/CommSharedURL_Controller.fetchCommunityDetails";

export default class CommunitySharedCompanyLogo extends NavigationMixin(LightningElement) {
  @api storeLogo;
  @api logoRef;

  communityHomePageRef;
  url;

  connectedCallback() {
    this.communityHomePageRef = {
      type: "comm__namedPage",
      attributes: {
        name: "Home"
      }
    };
    this[NavigationMixin.GenerateUrl](this.communityHomePageRef).then((url) => {
      this.url = url;
      console.log("this communityHomePageRef url: ", this.url);
    });

    fetchCommunityDetails({ communityId: Id })
      .then((result) => {
        console.log("fetch community url result: ", result);
        this.logoRef = 'background-image: url("' + result.siteUrl + "/cms/delivery/media/" + this.storeLogo + '")';
      })
      .catch((e) => {
        console.log("fetch community url error: ", e);
      });
  }

  navigateToPage(e) {
    e.preventDefault();
    e.stopPropagation;

    this[NavigationMixin.Navigate](this.communityHomePageRef);
  }
}
