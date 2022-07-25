/**
 * Created by Tim on 2021-04-01.
 */

import { LightningElement, api, track } from "lwc";
import { renderEN, renderFR } from "c/factoryStoreUtils";

export default class FactoryStoreFooterCopyright extends LightningElement {
  isEN = renderEN();
  isFR = renderFR();

  get currentYear() {
    let d = new Date();
    return d.getFullYear();
  }
}
