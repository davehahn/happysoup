/**
 * Created by dave on 2020-02-27.
 */

import { LightningElement, api, track } from "lwc";
import doSearch from "@salesforce/apex/UtilityComponent_Controller.doLiveLookup";

export default class LiveLookupInput extends LightningElement {
  @api value;
  @api label;
  @api placeholder;
  @api resultIcon = "utility:check";
  @api sObjectType;
  @api returnFields;
  @api filterOnFields;
  @api valueField;
  @api displayFields;
  @api whereClause;
  @track selectedRecord;
  @track results;
  @track displayResults;
  _fieldMap;
  _searchTimer;
  _searchActive = false;
  _delay = 500;
  _defaultClass = "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click";

  connectedCallback() {
    this._fieldMap = { id: "Id" };
    this.returnFields.forEach((field, idx) => (this._fieldMap[`field${idx + 1}`] = field));
  }

  get containerClass() {
    let klass = this._defaultClass;
    if (typeof this.results !== "undefined" && this.results !== null && this.results.length > 0) {
      klass += " slds-is-open";
    }
    return klass;
  }

  get displaySearchIcon() {
    return this.value === null && !this._searchActive;
  }

  get displayClearIcon() {
    return this.value !== null && !this._searchActive;
  }

  get displayBusyIcon() {
    return this._searchActive;
  }

  get inputValue() {
    return this.value === undefined ? null : this.value;
  }

  clearInput() {
    this.value = null;
    this.selectedRecord = this.emptyRecord();
    this.results = null;
    this.displayResults = null;
    this.fireSelectedEvent();
  }

  emptyRecord() {
    let record = { Id: null };
    this.returnFields.forEach((field) => (record[field] = null));
    return record;
  }

  handleKeyup(event) {
    let query = event.currentTarget.value;
    this.value = query;
    clearTimeout(this._searchTimer);
    this._searchTimer = setTimeout(() => this.doQuery(query), this._delay);
  }

  doQuery(q) {
    if (q && q.length > 2) {
      this._searchActive = true;
      doSearch({
        sObjectName: this.sObjectType,
        query: q,
        returnFields: this.returnFields,
        filterFields: this.filterOnFields,
        whereClause: this.whereClause
      })
        .then((result) => {
          console.log(JSON.parse(JSON.stringify(result)));
          this.results = result;
          this.displayResults = [];
          result.forEach((r) => this.displayResults.push(this._resultToDisplayObject(r)));
          console.log(JSON.parse(JSON.stringify(this.displayResults)));
        })
        .catch((error) => {
          console.log("LIVE LOOKUP INPUT ERROR:");
          console.log(error.message);
        })
        .finally(() => (this._searchActive = false));
    } else {
      this.results = null;
    }
  }

  handleSelect(event) {
    const id = event.currentTarget.dataset.id;
    this.selectedRecord = this.results.find((r) => id === r.Id);
    this.value = this.selectedRecord[this.valueField];
    this.results = null;
    this.displayResults = null;
    this.fireSelectedEvent();
  }

  fireSelectedEvent() {
    const value = this.selectedRecord;
    const evt = new CustomEvent("select", {
      detail: { value }
    });
    this.dispatchEvent(evt);
  }

  _resultToDisplayObject(result) {
    let obj = {
      id: result.Id,
      value: result[this.valueField],
      extraFields: []
    };
    if (this.displayFields) {
      obj.extraFields = this.displayFields.reduce((acc, val) => {
        if (val !== this.valueField) {
          acc.push(result[val]);
        }
        return acc;
      }, []);
    }
    return obj;
  }
}
