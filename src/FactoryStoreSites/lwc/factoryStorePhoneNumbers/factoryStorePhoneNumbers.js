/**
 * Created by Tim on 2021-03-30.
 */

import { LightningElement, api, wire, track } from "lwc";
import { loadStyle, loadScript } from "lightning/platformResourceLoader";
import { renderEN, renderFR } from "c/communitySharedUtils";

export default class FactoryStorePhoneNumbers extends LightningElement {
  @api phoneSales;
  @api phoneService;
  @api phoneParts;
  @api showOneNumber;
  @api showOneNumberLabel;
  @api showOneNumberDigits;

  isEN = renderEN();
  isFR = renderFR();

  get hasPhoneSales() {
    return this.phoneSales !== "" ? true : false;
  }
  get phoneSalesLink() {
    return "tel:" + this.phoneSales;
  }

  get hasPhoneService() {
    return this.phoneService !== "" ? true : false;
  }
  get phoneServiceLink() {
    return "tel:" + this.phoneService;
  }

  get hasPhoneParts() {
    return this.phoneParts !== "" ? true : false;
  }
  get phonePartsLink() {
    return "tel:" + this.phoneParts;
  }

  get phoneSingle() {
    return "tel:" + this.showOneNumberDigits;
  }
}
