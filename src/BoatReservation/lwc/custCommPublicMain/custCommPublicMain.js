/**
 * Created by dave on 2020-04-09.
 */

import { LightningElement, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import LOGO from "@salesforce/resourceUrl/LegendLogo";
import fetchBoats from "@salesforce/apex/OnlineBoatReservation_Controller.fetchBoats";
import { loadStyle, loadScript } from "lightning/platformResourceLoader";
import gothamFonts from "@salesforce/resourceUrl/GothamHTF";

export default class CustCommPublicMain extends NavigationMixin(LightningElement) {
  isMobile = false;

  logo = LOGO;
  @wire(fetchBoats) boats;

  connectedCallback() {
    window.addEventListener("resize", (event) => {
      this.isMobile = event.currentTarget.outerWidth < 1024 ? true : false;
    });

    this.isMobile = window.outerWidth < 1024 ? true : false;
  }

  renderedCallback() {
    loadStyle(this, gothamFonts + "/fonts.css").then(() => {});
  }

  toggleMenu() {
    this.template.querySelector(".overlay").classList.toggle("open");
    this.template.querySelector(".slide-menu").classList.toggle("open");
  }

  navToBoat(event) {
    event.preventDefault();

    let page = "order-builder",
      params = {
        c__recordId: event.target.dataset.recordId
      };

    this.navigateToCommunityPage(page, params);
  }

  //  handleSignIn( event )
  //  {
  //    this[NavigationMixin.Navigate]({
  //      type: 'comm__loginPage',
  //         attributes: {
  //             actionName: 'login'
  //         }
  //    });
  //  }

  navigateToCommunityPage(pageName, params) {
    console.log(pageName);
    console.log(params);
    this[NavigationMixin.Navigate]({
      type: "comm__namedPage",
      attributes: {
        pageName: pageName
      },
      state: params
    });
  }
}
