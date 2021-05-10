import { LightningElement, api } from 'lwc';

export default class RecordType_PicklistValues extends LightningElement {

    @api objectName;

    @api fieldName;

    @api recordTypeId;

    @api isRequired;

    @api errorMessage;

    @api fieldValue;

    @api validate() {
        if( !this.isRequired
            || ( this.isRequired && this.fieldValue && this.fieldValue.length > 0 ) ){
            return { isValid: true };
        } else {
            return {
                isValid: false,
                errorMessage: this.errorMessage
             };
         }
    }

    handleFieldChange( event ){
        this.fieldValue = event.target.value;
    }
}