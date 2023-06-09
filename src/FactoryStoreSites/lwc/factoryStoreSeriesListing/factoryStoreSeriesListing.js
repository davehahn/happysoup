/**
 * Created by Tim on 2021-07-08.
 */

import { LightningElement, api, wire } from "lwc";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import {
  stringy,
  stripParentheses,
  rewriteMotorName,
  rewriteTrailerName,
  weeklyPayment,
  formatPrice,
  setWrapperClass,
  renderEN,
  renderFR
} from "c/communitySharedUtils";
import Id from "@salesforce/community/Id";
import fetchCommunityDetails from "@salesforce/apex/CommSharedURL_Controller.fetchCommunityDetails";

export default class FactoryStoreSeriesListing extends NavigationMixin(LightningElement) {
  @api sectionWidth;
  @api seriesName;
  @api seriesBlurb;
  @api seriesModelShot;
  @api seriesZebra;

  @api seriesButtonText;
  @api seriesButtonLink;
  seriesButtonLinkRewrite;
  profileImageSrc;
  profileImageAlt;
  seriesImageryClass;
  seriesImageryBgClass;

  isEN = renderEN();
  isFR = renderFR();

  outerWrapperClass = "full";
  wrapperClass = "series";

  connectedCallback() {
    fetchCommunityDetails({ communityId: Id })
      .then((result) => {
        this.outerWrapperClass = this.seriesZebra ? "full zebra" : "full";
        console.log("series wrapper class", this.wrapperClass);
        this.seriesButtonLinkRewrite = result.siteUrl + "/s" + this.seriesButtonLink;
        this.wrapperClass = setWrapperClass(this.sectionWidth, this.wrapperClass);
        this.profileImageSrc = result.siteUrl + "/cms/delivery/media/" + this.seriesModelShot;
        this.profileImageAlt = "Profile image of a model from the " + this.seriesName;
        this.seriesImageryClass = "series__imagery " + this.seriesName.toLowerCase();
        this.seriesImageryBgClass = "series__bg " + this.seriesName.toLowerCase();
      })
      .catch((e) => {
        console.log("fetch community url error: ", e);
      });
  }

  renderedCallback() {}

  @wire(CurrentPageReference) pageRef;

  get fullSeriesName() {
    let series = this.seriesName;
    if (this.isEN) {
      return series.toLowerCase().indexOf("series") !== -1 || series.toLowerCase().indexOf("splash") !== -1
        ? series
        : series + "-Series";
    } else {
      console.log("series name: ", series);
      return series.toLowerCase().indexOf("series") !== -1 || series.toLowerCase().indexOf("splash") !== -1
        ? "Série " + series.replace("-Series", "")
        : "Série " + series;
    }
  }

  get seriesClass() {
    let series = this.seriesName.toLowerCase();
    return series.indexOf("series") !== -1 ? series : series + "-series";
  }
}