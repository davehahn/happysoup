/**
 * Created by Tim on 2021-03-30.
 */

import { LightningElement, api, wire, track } from "lwc";
import { loadStyle, loadScript } from "lightning/platformResourceLoader";
import { renderEN, renderFR } from "c/communitySharedUtils";

import CommunitySharedResources from "@salesforce/resourceUrl/communitySharedResources";

export default class CommunitySharedShoppingTools extends LightningElement {
  @api toolsFindADealer;
  @api toolsShowroomVisit;
  @api toolsRequestAQuote;
  @api toolsBuildPrice;
  @api toolsDownloadCatalogue;

  @track isEN = renderEN();
  @track isFR = renderFR();

  calendarIcon = `${CommunitySharedResources + "/img/calendar.svg"}#calendarIcon`;
  contractIcon = `${CommunitySharedResources + "/img/contract.svg"}#contractIcon`;
  downloadIcon = `${CommunitySharedResources + "/img/download.svg"}#downloadIcon`;
  pinIcon = `${CommunitySharedResources + "/img/pin.svg"}#pinIcon`;

  get findDealerURL() {
    return this.isEN
      ? "/support/s/find-your-closest-dealer/?language=en_US"
      : "/support/s/find-your-closest-dealer/?language=fr";
  }

  get scheduleVisitURl() {
    return this.isEN
      ? "https://www.legendboats.com/go/schedule-a-showroom-visit/"
      : "https://www.legendboats.com/fr/aller/prevoir-une-visite/";
  }
  get requestQuoteURL() {
    return this.isEN
      ? "https://www.legendboats.com/go/request-a-quote/"
      : "https://www.legendboats.com/fr/aller/demander-une-soumission/";
  }

  get catalogueURL() {
    return this.isEN
      ? "https://www.legendboats.com/go/download-a-catalogue/"
      : "https://www.legendboats.com/fr/aller/obtenez-vos-catalogues/";
  }
}
