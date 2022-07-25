/**
 * Created by Tim on 2021-03-30.
 */

import { LightningElement, api, wire } from "lwc";
import { loadStyle, loadScript } from "lightning/platformResourceLoader";
import { setWrapperClass, renderEN, renderFR } from "c/communitySharedUtils";
import Id from "@salesforce/community/Id";
import fetchCommunityDetails from "@salesforce/apex/CommSharedURL_Controller.fetchCommunityDetails";
import fetchPlacesApiResult from "@salesforce/apex/CommSharedPlacesApi_Controller.fetchPlacesApiResult";
import fetchDistanceApiResult from "@salesforce/apex/CommSharedPlacesApi_Controller.fetchDistanceApiResult";

export default class FactoryStoreHoursAndLocation extends LightningElement {
  @api layout;
  @api sectionWidth;

  wrapperClass = "hourAndLocationWrapper";

  currentStatus;
  statusClass;
  currentHours;
  weekday_text;

  name;
  street_number;
  route;
  locality;
  administrative_area_level_1;
  postal_code;

  lat;
  lng;
  mapMarkers;
  mapOptions = {
    disableDefaultUI: true
  };
  @api zoomLevel;

  isEN = renderEN();
  isFR = renderFR();

  gpResult;
  locationName;
  inputType = "textquery";
  mapLanguage = this.isEN ? "en" : "fr-CA";
  fields = "photos,formatted_address,name,rating,opening_hours,geometry,place_id";

  @wire(fetchCommunityDetails, { communityId: Id })
  wiredFetchCommunityDetails({ error, data }) {
    if (data) {
      this.locationName = data.name;
      this.runPlacesApi();
    } else if (error) {
      console.log("fetch community error: ", error);
    }
  }

  runPlacesApi() {
    if (this.locationName) {
      fetchPlacesApiResult({
        input: this.locationName,
        inputType: this.inputType,
        fields: this.fields,
        language: this.mapLanguage
      })
        .then((result) => {
          this.gpResult = result;
          this.updateLocationDetails();
        })
        .catch((e) => {
          console.log("fetch places api error: ", e);
        });
    }
  }

  //	@wire( fetchDistanceApiResult, {origin: '40.6655101,-73.89188969999998', destinations: '40.6905615%2C-73.9976592%7C40.6905615%2C-73.9976592%7C40.6905615%2C-73.9976592%7C40.6905615%2C-73.9976592%7C40.6905615%2C-73.9976592%7C40.6905615%2C-73.9976592%7C40.659569%2C-73.933783%7C40.729029%2C-73.851524%7C40.6860072%2C-73.6334271%7C40.598566%2C-73.7527626%7C40.659569%2C-73.933783%7C40.729029%2C-73.851524%7C40.6860072%2C-73.6334271%7C40.598566%2C-73.7527626'})
  //		wiredFetchDistanceApiResult( {error, data} )
  //		{
  //			if( data )
  //			{
  //				console.log('destinations api result: ', data);
  //			}
  //			else if ( error ){
  //				console.log('destinations apir error: ', error);
  //			}
  //		}

  updateLocationDetails() {
    this.parseAddress();
    this.currentHours = this.parsePeriods();
    this.statusClass = this.gpResult.opening_hours.open_now
      ? "currentStatus currentStatus--open"
      : "currentStatus currentStatus--closed";

    if (this.layout === "Condensed") {
      this.currentStatus = this.gpResult.opening_hours.open_now
        ? this.isEN
          ? "Open!"
          : "Ouvert!"
        : this.isEN
        ? "Closed"
        : "Fermé";
    } else if (this.layout === "Expanded") {
      this.wrapperClass = setWrapperClass(this.sectionWidth, "hourAndLocationWrapper");
      this.mapMarkers = [
        {
          location: {
            Latitude: this.gpResult.geometry.location.lat,
            Longitude: this.gpResult.geometry.location.lng
          }
        }
      ];
      this.name = this.gpResult.name;
      this.currentStatus = this.gpResult.opening_hours.open_now
        ? this.isEN
          ? "We're Open!"
          : "Étaient ouverts!"
        : this.isFR
        ? "Sorry, we're closed."
        : "Désolé, nous sommes fermés";
      this.weekday_text = this.parseWeekdayText(this.gpResult.opening_hours.weekday_text);
      let weekday_text_fr = [];
      if (this.isFR) {
        this.weekday_text.forEach((day, index) => {
          const mapObj = {
            Monday: "Lundi",
            Tuesday: "Mardi",
            Wednesday: "Mercredi",
            Thursday: "Jeudi",
            Friday: "Vendredi",
            Saturday: "Samedi",
            Sunday: "Dimanche",
            Closed: "Fermé"
          };
          day = day.replace(
            /\b(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|Closed)\b/gi,
            (matched) => mapObj[matched]
          );
          weekday_text_fr.push(day);
        });
        this.weekday_text = weekday_text_fr;
      }
    }
  }

  parseAddress() {
    const address_components = this.gpResult.address_components;
    address_components.forEach((c, i) => {
      if (c.types.indexOf("street_number") >= 0) {
        this.street_number = c.long_name;
      } else if (c.types.indexOf("route") >= 0) {
        this.route = c.long_name;
      } else if (c.types.indexOf("locality") >= 0) {
        this.locality = c.long_name;
      } else if (c.types.indexOf("administrative_area_level_1") >= 0) {
        this.administrative_area_level_1 = c.long_name;
      } else if (c.types.indexOf("postal_code") >= 0) {
        this.postal_code = c.long_name;
      }
    });
  }

  parsePeriods() {
    const n = new Date().getDay() - 1;
    const open = this.gpResult.opening_hours.periods[n].open.time;
    let openHr = open.substr(0, 2);
    let openMin = open.substr(2, 2);
    let openAMPM = openHr >= 12 ? "pm" : "am";
    openHr = openHr % 12 || 12;

    const close = this.gpResult.opening_hours.periods[n].close.time;
    let closeHr = close.substr(0, 2);
    let closeMin = close.substr(2, 2);
    let closeAMPM = closeHr >= 12 ? "pm" : "am";
    closeHr = closeHr % 12 || 12;

    return openHr + ":" + openMin + openAMPM + " - " + closeHr + ":" + closeMin + closeAMPM;
  }

  parseWeekdayText(data) {
    let expandedDates = [];
    const n = new Date().getDay() - 1;
    data.forEach((day, index) => {
      if (index === n) {
        expandedDates.push('<span class="heading heading--xs">' + day + "</span>");
      } else {
        expandedDates.push(day);
      }
    });
    return expandedDates;
  }

  get currentDate() {
    return this.isEN
      ? new Date().toLocaleDateString("en-CA", { weekday: "long", month: "long", day: "numeric" })
      : new Date().toLocaleDateString("fr-CA", { weekday: "long", month: "long", day: "numeric" });
  }

  get showCondensed() {
    return this.layout === "Condensed" ? true : false;
  }

  get showExpanded() {
    return this.layout === "Expanded" ? true : false;
  }
}
