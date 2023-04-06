/**
 * Created by Tim on 2023-02-23.
 */

public with sharing class LeadSubmissionHistories_Service {
    private Lead_Submission_History__c submission;

    public String id;
    public String firstName;
    public String lastName;
    public String phone;
    public String street;
    public String city;
    public String province;
    public String country;
    public String postalCode;
    public String email;
    public String purchaseByDate;
    public String boatType;
    public String boatSeries;
    public String boatModel;
    public String boatName;
    public String modelOfInterestSerialNumber;
    public String modelOfInterestSerialNumberId;
    public String subscribeToNewsletter;
    public String campaignId;
    public String conversionId;
    public String language;
    public String notes;
    public String leadSource;
    public String description;
    public String formName;
    public String specialConditions;

    public LeadSubmissionHistories_Service() {
    }
    public LeadSubmissionHistories_Service toSubmissionHistoryObject(LeadSubmissionHistories_Service lshData, Lead_RestResource.RestResult result) {
        String listName = lshData.firstName + ' ' + lshData.lastName + ': ' + Date.today().format();
        this.submission = new Lead_Submission_History__c(
                Lead_ID__c = result.data.id,
                Name = listName,
                First_Name__c = lshData.firstName,
                Last_Name__c = lshData.lastName,
                Address__c = lshData.street,
                City__c = lshData.city,
                Province__c = lshData.province,
                Postal_Code__c = lshData.postalCode,
                Email__c = lshData.email,
                Phone_Number__c = lshData.phone,
                Description__c = lshData.description,
                Purchase_By_Date__c = lshData.purchaseByDate,
                Boat_Type__c = lshData.boatType,
                Boat_Series__c = lshData.boatSeries,
                Boat_Model__c = lshData.boatModel,
                Boat_Name__c = lshData.boatName,
                Model_of_Interest_Serial_Number__c = lshData.modelOfInterestSerialNumber,
                Model_of_Interest_Serial_Number_Lookup__c = lshData.modelOfInterestSerialNumberId,
                Subscribe_to_Newsletter__c = lshData.subscribeToNewsletter,
                Preferred_Language__c = lshData.language,
                Notes__c = lshData.notes,
                Lead_Source__c = lshData.leadSource,
                Form_Name__c = lshData.formName,
                Campaign__c = lshData.campaignId,
                Conversion_Id__c = lshData.conversionId,
                Special_Conditions__c = lshData.specialConditions,
                Lead_Notification_Pending__c = true
        );
        return this;
    }

    public Lead_Submission_History__c lshGetRecord() {
        return this.submission;
    }

    public void insertLeadSubmissionHistory(RestRequest req, Lead_RestResource.RestResult result) {
        RestResponse res = RestContext.response;
        LeadSubmissionHistories_Service serviceObject = (LeadSubmissionHistories_Service) JSON.deserialize(req.requestBody.toString(), LeadSubmissionHistories_Service.class);
        try {
            insert this.toSubmissionHistoryObject(serviceObject, result).lshGetRecord();
            res.responseBody = Blob.valueOf(
                    '{"status": "success", "id": "' +
                            result.data.id +
                            '", "lshStatus": "success"}'
            );
        } catch (Exception error) {
            res.responseBody = Blob.valueOf(
                    '{"status": "success", "id": "' +
                            result.data.id +
                            '", "lshStatus": "error", "lshError": "' +
                            error.getMessage() +
                            '"}'
            );
        }
    }
}