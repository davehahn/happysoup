/**
 * Created by Tim on 2021-04-05.
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
  convertLength,
  renderEN,
  renderFR
} from "c/communitySharedUtils";
import Id from "@salesforce/community/Id";
import BANNER from "@salesforce/resourceUrl/FactoryStoreModelBanner";
import fetchCommunityDetails from "@salesforce/apex/CommSharedURL_Controller.fetchCommunityDetails";
import fetchBoat from "@salesforce/apex/FactoryStore_InventoryController.fetchBoat";

import { fireEvent, registerListener, unregisterAllListeners } from "c/pubsub";

export default class FactoryStoreBoatDetails extends NavigationMixin(LightningElement) {
  @api sectionWidth;
  @api moreInfoBackground;
  @api backgroundReference;

  isEN = renderEN();
  isFR = renderFR();

  recordId;
  boat;
  boatDataLookupRunning = true;
  boatDataLoaded = false;
  modelWrapperClass = "model model--loading";
  resultEmpty = false;

  currentStockQuantity = 0;
  stockWrapperClass = "model__currentStock";

  boatType;
  boatSeries;
  boatName;
  modelYear;
  standardMotorName;
  standardTrailerName;
  hasPremiumPack = false;

  bannerBg = "background-image: url(" + BANNER + ")";

  // Lead forms
  leadFormName;
  @api campaignId;
  locationName;

  photoGallery;
  hasPhotoGallery = false;

  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    this.recordId = currentPageReference.state.c__recordId;
  }

  @wire(fetchCommunityDetails, { communityId: Id })
  wiredFetchCommunityDetails({ error, data }) {
    if (data) {
      this.locationName = data.name;
      this.backgroundReference =
        'background-image: url("' + data.siteUrl + "/cms/delivery/media/" + this.moreInfoBackground + '")';
    } else if (error) {
      console.log("fetch community error: ", error);
    }
  }

  @wire(fetchBoat, { boatId: "$recordId" })
  wiredFetchBoat({ error, data }) {
    if (data) {
      console.log("this boat: ", data);
      if (data.length !== 0) {
        this.boat = data;
        this.recordFound();
      } else {
        this.resultEmpty();
      }
    } else if (error) {
      console.log("Ooops: ", error);
    }
  }

  recordFound() {
    console.log("record found!");
    this.boatDataLoaded = true;
    this.modelWrapperClass = setWrapperClass(this.sectionWidth, "model");
    this.boatDataLookupRunning = false;
    this.standardMotorName = rewriteMotorName(this.boat.StandardMotor.Name);
    this.standardTrailerName =
      typeof this.boat.StandardTrailer !== "undefined"
        ? this.isEN
          ? "and " + rewriteTrailerName(this.boat.StandardTrailer.Name)
          : "et " + rewriteTrailerName(this.boat.StandardTrailer.Name)
        : "";
    this.hasPhotoGallery = typeof this.boat.MarketingImages !== "undefined" ? true : false;
    this.photoGallery = this.hasPhotoGallery ? this.boat.MarketingImages : "";
    this.hasPremiumPack = typeof this.boat.PremiumPackage !== "undefined" ? true : false;
    this.boatType = this.boat.Family;
    this.boatSeries = this.boat.Series;
    this.boatName = stripParentheses(this.boat.Name);
    this.modelYear = this.boat.PricebookName.replace(" - Retail", "");
    this.leadFormName = this.boatName + " - Lead Form";
  }

  resultEmpty() {
    this.boatDataLookupRunning = false;
    this.resultEmpty = true;
  }

  get weeklyPrice() {
    return this.isEN ? weeklyPayment(this.boat.RetailPrice) : weeklyPayment(this.boat.RetailPrice, "fr");
  }

  get retailPrice() {
    return this.isEN ? formatPrice(this.boat.RetailPrice, true) : formatPrice(this.boat.RetailPrice, true, "fr");
  }

  get introPhoto() {
    let photoURL = this.boat.DefaultImage;
    return "background-image: url(" + photoURL.replace("/sf_gallery", "") + ")";
  }

  get boatSpecs() {
    let props = JSON.parse(stringy(this.boat.BoatSpecs));
    let translate = {
      "Package Width": { fr: "Largeur de l’ensemble", unit: "&rdquo;" },
      "Package Length": { fr: "Longueur de l’ensemble", unit: "convertLength" },
      "Bottom Width": { fr: "Largeur du fond", unit: "&rdquo;" },
      "Inside Depth": { fr: "Profondeur intérieure", unit: "&rdquo;" },
      "Hull Depth": { fr: "Profondeur max.", unit: "&rdquo;" },
      "Aluminum Thickness": { fr: "Épaisseur d’aluminium", unit: "" },
      Color: {
        fr: "Couleur",
        unit: "",
        translations: {
          Black: "Noir",
          "Black / Charcoal": "Noir / Charbon",
          "White / Black": "Blanc / Noir",
          "Dark Blue/White": "Bleu Foncé/Blanc"
        }
      },
      "Cup Holders": { fr: "Portes-gobelets", unit: "" },
      "Maximum Horsepower": { fr: "Puissance max.", unit: "" },
      "Maximum Capacity": { fr: "Charge max.", unit: " lbs" },
      Beam: { fr: "Largeur", unit: "&rdquo;" },
      "Centerline Length": { fr: "Longueur du centre", unit: "convertLength" },
      Length: { fr: "Longueur du centre", unit: "convertLength" },
      "Towing Weight": { fr: "Poids de remorquage", unit: " lbs" },
      "Fuel Capacity": { fr: "Réservoir d’essence", unit: "" },
      "Pontoon Aluminum Thickness": { fr: "Épaisseur des tubes", unit: "" },
      "Pontoon Diameter": { fr: "Diamètre des tubes", unit: "&rdquo;" },
      "Overall Length": { fr: "Longueur", unit: "convertLength" },
      "Maximum Persons": { fr: "Capacité-personnes", unit: "" },
      "Pontoon Length": { fr: "Longueur des tubes", unit: "convertLength" },
      "Deck Length": { fr: "Longueur de pont", unit: "convertLength" },
      "Livewell / Cooler": { fr: "Vivier/ Glacière", unit: "" },
      Weight: { fr: "Poids", unit: " lbs" }
    };

    let sortOrder;
    let sortedArray = [];

    if (this.boat.Family === "Pontoon") {
      console.log("it's a pontoon");
      sortOrder = [
        "Overall Length",
        "Beam",
        "Maximum Horsepower",
        "Fuel Capacity",
        "Deck Length",
        "Pontoon Length",
        "Pontoon Diameter",
        "Maximum Persons",
        "Maximum Capacity",
        "Weight"
      ];
    } else if (this.boat.Family === "Deck Boat") {
      console.log("it's a deck boat");
      sortOrder = [
        "Overall Length",
        "Beam",
        "Inside Depth",
        "Maximum Horsepower",
        "Fuel Capacity",
        "Hull Depth",
        "Package Length",
        "Maximum Persons",
        "Towing Weight",
        "Maximum Capacity"
      ];
    } else {
      console.log("it's a fishing boat");
      sortOrder = [
        "Centerline Length",
        "Beam",
        "Hull Depth",
        "Inside Depth",
        "Aluminum Thickness",
        "Maximum Horsepower",
        "Maximum Capacity",
        "Weight",
        "Bottom Width",
        "Package Length",
        "Package Width",
        "Towing Weight",
        "Livewell / Cooler",
        "Fuel Capacity"
      ];
    }
    console.log("sortOrder", sortOrder);
    console.log("props", props);

    sortOrder.forEach((sOption, sIndex) => {
      for (const [pIndex, pOption] of Object.entries(props)) {
        if (sOption === pIndex) {
          let spec = pOption + translate[pIndex].unit;
          let unit = translate[pIndex].unit;
          if (translate[pIndex].unit === "convertLength") {
            let truncateLengthTrailingZero = true;
            if (this.recordId === "01t1Y00000ATJfUQAX" && pIndex === "Overall Length") {
              truncateLengthTrailingZero = false;
            } else if (this.recordId === "01ti0000004zco9AAA" && pIndex === "Length") {
              truncateLengthTrailingZero = false;
            } else if (
              this.recordId === "01t1Y00000ATDipQAH" &&
              (pIndex === "Centerline Length" || pIndex === "Deck Length")
            ) {
              truncateLengthTrailingZero = false;
            }
            spec = convertLength(pOption, truncateLengthTrailingZero);
          }

          let specName = this.isEN ? pIndex : translate[pIndex].fr;
          sortedArray[sIndex] = {
            Name: specName,
            Value: "<strong>" + spec + "</strong>"
          };
        }
      }
    });
    let filteredArray = sortedArray.filter((el) => {
      return el != null;
    });
    console.log("filteredArray", filteredArray);
    return filteredArray;
  }

  get motorUpgrades() {
    let allMotors = JSON.parse(stringy(this.boat.MotorUpgrades));
    console.log("allMotors", allMotors);
    let availableMotors = allMotors.filter((el) => {
      return el.DisplayOnWeb == true;
    });
    console.log("availableMotors", availableMotors);
    let reducedMotorsDetails = [];
    availableMotors.forEach((motor, index) => {
      //      console.log('motor ' + index, motor);
      console.log(motor.Name);
      reducedMotorsDetails[index] = {
        Name: motor.Name,
        RetailUpgradeCost: formatPrice(motor.RetailUpgradeCost, true),
        WeeklyUpgradeCost: formatPrice(motor.WeeklyUpgradeCost, true)
      };
    });
    console.log("reducedMotorsDetails", reducedMotorsDetails);
    return reducedMotorsDetails;
  }

  get premiumPackItems() {
    const contents = this.boat.PremiumPackage.Contents;
    const sections = Object.entries(contents);
    let packItems = [];
    for (const [section, parts] of sections) {
      const items = Object.values(parts);
      for (const item of items) {
        let description = item.Description,
          description_fr = item.Description_FR,
          value = item.Value,
          valueFormatted = formatPrice(value, true),
          valueFormatted_fr = formatPrice(value, true, "fr"),
          details = {
            description: description,
            description_fr: description_fr,
            value: value,
            valueFormatted: valueFormatted,
            valueFormatted_fr: valueFormatted_fr
          };
        packItems.push(details);
      }
    }

    packItems.sort(function (a, b) {
      return b.value - a.value;
    });
    //   		console.log(packItems);
    return packItems;
  }

  get premiumPackageRetailPrice() {
    return this.isEN
      ? formatPrice(this.boat.PremiumPackage.RetailPrice, true)
      : formatPrice(this.boat.PremiumPackage.RetailPrice, true, "fr");
  }

  get flagshipLink() {
    let Family =
      this.boat.Family === "Pontoon"
        ? "pontoon-boats"
        : this.boat.Family === "Deck Boat"
        ? "deck-boats"
        : "fishing-boats";
    let Series =
      this.boat.Series.toLowerCase().indexOf("series") !== -1
        ? this.boat.Series.toLowerCase()
        : this.boat.Series.toLowerCase() + "-series";
    let Model = stripParentheses(this.boat.Name.toLowerCase());
    let Year = this.boat.PricebookName.replace(" - Retail", "");
    console.log("https://www.legendboats.com/" + Family + "/" + Series + "/" + Model + "/" + Year + "/");
    return "https://www.legendboats.com/" + Family + "/" + Series + "/" + Model + "/" + Year + "/";
  }

  handleUpdateStockValue(e) {
    this.currentStockQuantity = e.detail;
    this.stockWrapperClass = "model__currentStock model__currentStock--available";
  }
}
