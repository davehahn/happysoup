/**
 * Created by Tim on 2020-04-22.
 */

import { LightningElement, api, track, wire } from "lwc";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { fireEvent, registerListener, unregisterAllListeners } from "c/pubsub";

export default class CustCommOrderCheckbox extends NavigationMixin(LightningElement) {
  @api optionShowUpgradePrice;
  @api optionPage;
  @api optionParentPage;
  @api optionParentSku;
  @api optionIsAddon;
  @api displayImage;
  @api optionTriggerUiChange;
  @api optionBoatRetail;
  @api optionLayout = "standard";
  @api optionGroupingName;

  @api productOptions;
  //@track useCheckbox;

  @track displayRPM;
  @track displayKM;

  isEN = true;
  isFR = false;

  @wire(CurrentPageReference) pageRef;

  renderedCallback() {
    registerListener("purchasePriceConnected", this.pageReady, this);
    registerListener("motorSelection", this.handleMotorSelection, this);
    registerListener("foundSelection", this.checkRelatedMotorOption, this);
    registerListener("clearSelectedTrailerOptions", this.clearTrailerOptions, this);
    registerListener("languageChange", this.handleLanguageChange, this);
    if (this.template.querySelector(".detailedSummary")) {
      this.summaryFrag();
    }
  }

  get useCheckbox() {
    return this.productOptions.inputType !== "radio" ? true : false;
  }

  get optionInputName() {
    if (this.optionGroupingName) {
      return this.optionGroupingName;
    }
    return "option_" + this.optionPage;
  }

  get optionFormattedPrice() {
    let displayPrice = this.productOptions.displayPrice;
    if (displayPrice === 0) {
      if (this.optionPage === "performance") {
        displayPrice = this.optionBoatRetail;
        return (displayPrice = new Intl.NumberFormat("en-CA", {
          style: "currency",
          currency: "CAD",
          minimumFractionDigits: 0
        }).format(displayPrice));
      } else {
        return (displayPrice = this.isEN ? "Included" : "Inclus");
      }
    } else {
      return (displayPrice = new Intl.NumberFormat("en-CA", {
        style: "currency",
        currency: "CAD",
        minimumFractionDigits: 0
      }).format(displayPrice));
    }
  }
  get optionFormattedPriceFR() {
    let displayPrice = this.productOptions.displayPrice;
    if (displayPrice === 0) {
      if (this.optionPage === "performance") {
        displayPrice = this.optionBoatRetail;
        return (displayPrice = new Intl.NumberFormat("fr-CA", {
          style: "currency",
          currency: "CAD",
          minimumFractionDigits: 0
        }).format(displayPrice));
      } else {
        return (displayPrice = this.isEN ? "Included" : "Inclus");
      }
    } else {
      return (displayPrice = new Intl.NumberFormat("fr-CA", {
        style: "currency",
        currency: "CAD",
        minimumFractionDigits: 0
      }).format(displayPrice));
    }
  }

  get hasIncludedProducts() {
    return this.productOptions.includedProducts.length !== 0 ? true : false;
  }

  get hasDetailedSummary() {
    return this.productOptions.detailedSummary !== null ? true : false;
  }

  get hasOptionsDeck() {
    return this.productOptions.blurb !== null ? true : false;
  }

  get hasSwatch() {
    return this.productOptions.swatch !== null ? `background-image: url(${this.productOptions.swatch})` : "";
  }

  summaryFrag() {
    this.template.querySelector(".detailedSummaryTrigger strong").innerHTML = this.isEN ? "Show" : "Montrer";
    this.template.querySelector(".detailedSummary").innerHTML = this.isEN
      ? this.productOptions.detailedSummary
      : this.productOptions.detailedSummary_fr;
  }

  showHideSummary(e, elm) {
    const trigger = e !== null ? e.currentTarget : this.template.querySelector(elm);
    //	 const trigger = e.currentTarget;
    const triggerActionText = trigger.querySelector("strong");
    const summary = trigger.nextSibling;
    const summaryState = summary.getAttribute("data-state");
    if (e !== null) {
      if (summaryState === "collapsed") {
        summary.setAttribute("data-state", "expanded");
        triggerActionText.classList.add("open");
        triggerActionText.innerHTML = this.isEN ? "Hide" : "Cacher";
      } else {
        summary.setAttribute("data-state", "collapsed");
        triggerActionText.classList.remove("open");
        triggerActionText.innerHTML = this.isEN ? "Show" : "Montrer";
      }
    } else {
      summary.setAttribute("data-state", "collapsed");
      triggerActionText.classList.remove("open");
      triggerActionText.innerHTML = this.isEN ? "Show" : "Montrer";
    }
  }

  pageReady(detail) {
    if (detail === "ready") {
      if (this.productOptions.init) {
        this.handleChange(null, true);
      }
    }
  }

  get showAsSwatches() {
    return this.optionLayout === "alt-swatch" ? true : false;
  }

  handleChange(event, init) {
    let isChecked = false;
    let ppSku = this.productOptions.ppSku;
    if (event) {
      isChecked = event.currentTarget.checked;
      ppSku = event.currentTarget.dataset.parentsku ? event.currentTarget.dataset.parentsku : this.productOptions.ppSku;
    } else if (init) {
      isChecked = true;
    }

    const onUserSelection = event ? true : false;
    let userSelectionName = null;
    if (onUserSelection) {
      userSelectionName = event.currentTarget.getAttribute("name");
    } else {
      userSelectionName = this.optionGroupingName;
    }

    let details = {
      optionSKU: this.productOptions.sku,
      motorSpeed: this.productOptions.km,
      motorRPM: this.productOptions.rpm,
      optionImage: this.productOptions.images,
      optionParentPage: this.optionPage,
      optionName: this.productOptions.name,
      optionType: this.productOptions.inputType,
      addToComposite: isChecked,
      onUserSelection: onUserSelection,
      userSelectionName: userSelectionName
    };
    let summaryDetails = {
      sku: this.productOptions.sku,
      ppSku: ppSku,
      name: this.productOptions.name,
      name_fr: this.productOptions.name_fr,
      price: this.productOptions.retailPrice,
      addToSummary: isChecked,
      section: this.optionPage,
      type: this.productOptions.inputType,
      addon: this.optionIsAddon,
      userSelectionName: userSelectionName
    };

    let purchasePrice = {
      sku: this.productOptions.sku,
      price: this.productOptions.retailPrice,
      addToPrice: isChecked,
      section: this.optionPage,
      type: this.productOptions.inputType,
      addon: this.optionIsAddon,
      userSelectionName: userSelectionName
    };

    if (this.optionPage === "performance") {
      fireEvent(this.pageRef, "motorSelection", details);
    }
    if (this.optionPage === "trailering") {
      fireEvent(this.pageRef, "traileringSelection", details);
    }
    if (this.optionPage === "electronics") {
      fireEvent(this.pageRef, "electronicsSelection", details);
    }

    fireEvent(this.pageRef, "updateSummary", summaryDetails);
    console.log("fire updatedListItems a");
    fireEvent(this.pageRef, "updateListItems", summaryDetails);
    fireEvent(this.pageRef, "updatePurchasePrice", purchasePrice);

    if (this.optionLayout === "alt-swatch") {
      let extraPadding = 0;
      if (this.template.querySelector(".options_deck")) {
        extraPadding = this.template.querySelector(".options_deck").offsetHeight;
      }
      const selectEvent = new CustomEvent("swatchchange", {
        detail: extraPadding
      });
      this.dispatchEvent(selectEvent);
      fireEvent(this.pageRef, "clearSelectedTrailerOptions", summaryDetails);
    }
  }

  handleMotorSelection(detail) {
    let relatedOptions = this.template.querySelectorAll(`[data-parentpage="${detail.optionParentPage}"]`);

    relatedOptions.forEach((option) => {
      if (option.checked) {
        option.checked = false;
        const optionLabel = option.dataset.label;
        const newDetails = {
          details: detail,
          sameLabel: optionLabel
        };
        fireEvent(this.pageRef, "foundSelection", newDetails);
      }
    });
  }

  checkRelatedMotorOption(detail) {
    const sameLabel = detail.sameLabel;
    const relatedOptionLabel = this.productOptions.name;
    const selectedSku = detail.details.optionSKU;
    const relatedOptionParentSku = this.productOptions.parentSku;
    if (sameLabel === relatedOptionLabel) {
      if (selectedSku === relatedOptionParentSku) {
        const optionToCheck = this.template.querySelector(`[data-parentsku="${relatedOptionParentSku}"]`);
        optionToCheck.checked = true;
      }
    }
  }

  clearTrailerOptions(summaryDetails) {
    const optionsToClear = this.template.querySelectorAll(`[data-parentpage="${summaryDetails.userSelectionName}"`);

    optionsToClear.forEach((option) => {
      option.checked = false;

      let optionDetails = {
        sku: option.getAttribute("data-sku"),
        ppSku: option.getAttribute("data-parentsku"),
        name: option.getAttribute("data-label"),
        price: option.getAttribute("data-retail-price"),
        addToSummary: false,
        section: option.getAttribute("data-page"),
        type: option.getAttribute("type"),
        addon: false,
        userSelectionName: option.getAttribute("name")
      };

      fireEvent(this.pageRef, "updateSummary", optionDetails);
      console.log("fire updatedListItems b");
      fireEvent(this.pageRef, "updateListItems", optionDetails);
    });
  }

  handleLanguageChange(detail) {
    if (detail) {
      this.isEN = detail === "EN" ? true : false;
      this.isFR = detail === "FR" ? true : false;
      this.showHideSummary(null, ".detailedSummaryTrigger");
    }
  }
}
