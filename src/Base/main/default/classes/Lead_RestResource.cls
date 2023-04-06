/**
 * Created by dave on 2021-04-21.
 */
@RestResource(UrlMapping='/WebToLead/*')
global with sharing class Lead_RestResource {
  global class RestResult {
    public String status;
    public WebToLeadWrapper data;
    public String errorMessage;
    public RestResult() {
    }
  }

  public class WebToLeadWrapper {
    private Lead record;

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
    public String boatModel;
    public String subscribeToNewsletter;
    public String campaignId;
    public String language;
    public String notes;
    public String leadSource;
    public String description;
    public Boolean leadNotificationPending;
    public Map<String, String> boatAppraisalData;
    public Map<String, String> financingApplicationData;
//    public String closestDealer;

    public WebToLeadWrapper() {
    }

    public WebToLeadWrapper toLeadObject() {
      this.record = new Lead(
              FirstName = this.firstName,
              LastName = this.lastName,
              Street = this.street,
              City = this.city,
              State = this.province,
              Country = this.country,
              PostalCode = this.postalCode,
              Email = this.email,
              Phone = this.phone,
              Description = this.description,
              hubspot_plan_to_purchase__c = this.purchaseByDate,
              hubspot_Boat_Type__c = this.boatType,
              hubspot_subscribe_legend_newsletter__c = this.subscribeToNewsletter,
              Preferred_Language__c = this.language,
              Marketing_Cloud_Notes__c = this.notes,
              LeadSource = this.leadSource,
              Lead_Notification_Pending__c = true
//              CreatedById = '2F005i0000002c3UY'
      );
      if(this.boatModel != ''){
        this.record.BoatModel__c = this.boatModel;
      }
      return this;
    }

    public Lead getRecord() {
      return this.record;
    }

    public WebToLeadWrapper updateFromLead(Lead l) {
      this.record = l;
      this.id = this.record.Id;
      this.firstName = this.record.FirstName;
      this.lastName = this.record.LastName;
      this.street = this.record.Street;
      this.city = this.record.City;
      this.province = this.record.State;
      this.country = this.record.Country;
      this.postalCode = this.record.PostalCode;
      this.email = this.record.Email;
      this.purchaseByDate = this.record.hubspot_plan_to_purchase__c;
      this.boatType = this.record.hubspot_Boat_Type__c;
      this.boatModel = this.record.BoatModel__c;
      this.subscribeToNewsletter = this.record.hubspot_subscribe_legend_newsletter__c;
      this.language = this.record.Preferred_Language__c;
      this.notes = this.record.Marketing_Cloud_Notes__c;
      this.leadSource = this.record.LeadSource;
      this.leadNotificationPending = this.record.Lead_Notification_Pending__c;
      //      this.closestDealer = this.record.Closest_Partner__c;

      return this;
    }

    public void addToCampaign() {
      System.debug('AddToCampaign');
      System.debug(this);
      List<CampaignMember> members = CampaignMember_Selector.allByLeadAndCampaignId(this.id, this.campaignId);
      if (members.size() == 0) {
        insert new CampaignMember(LeadId = this.id, CampaignId = this.campaignId);
      }
    }

    public void createBoatAppraisalRecord(String data){
      BoatAppraisal_Service baService = new BoatAppraisal_Service();
      System.debug('in create appraisal ' + data);
      System.debug('this.id: ' + this.id);
      baService.insertBoatAppraisalRequest(data, this.id);
    }

    public void createFinancingApplicationRecord(String data){
      FinancingApplication_Service faService = new FinancingApplication_Service();
      System.debug('in financing Application ' + data);
      faService.insertFinancingApplication(data, this.id);
    }
  }

  @HttpPost
  global static void doPost() {
    RestRequest req = RestContext.request;
    RestResponse res = RestContext.response;
    String jsonWrapper = req.requestBody.toString();
    WebToLeadWrapper wrapper = (WebToLeadWrapper) JSON.deserialize(jsonWrapper, WebToLeadWrapper.class);
    RestResult result = handlePost(wrapper);
    if (result.status == 'success') {
      res.statusCode = 200;
      res.responseBody = Blob.valueOf('{"status": "success", "id": "' + result.data.id + '"}');
      // Add record to Lead Submission History
      createLeadSubmissionHistoryRecord(req, result);

    } else {
      res.statusCode = 500;
      res.responseBody = Blob.valueOf('{"status": "error", "message": "' + result.errorMessage + '"}');
    }
    return;
  }

  public static void createLeadSubmissionHistoryRecord(RestRequest req, RestResult result){
    LeadSubmissionHistories_Service lshService = new LeadSubmissionHistories_Service();
    lshService.insertLeadSubmissionHistory(req, result);
  }

  @TestVisible
  private static RestResult handlePost(WebToLeadWrapper wrapper) {
    System.Savepoint savePoint = Database.setSavepoint();
    RestResult response = new RestResult();
//    System.debug(wrapper);
//    System.debug(wrapper.boatAppraisalData);
    System.debug(wrapper.toLeadObject().getRecord());
    Lead_Service service = new Lead_Service(wrapper.toLeadObject().getRecord());
    Lead_Service.LeadSaveResult sr = service.insertOrUpdateDuplicate();
    if (sr.isSuccess()) {
      response.status = 'success';
      response.data = wrapper.updateFromLead(sr.getRecord());
      if (wrapper.campaignId != null) {
        try {
          wrapper.addToCampaign();
        } catch (Exception e) {
          Database.rollback(savePoint);
          response.status = 'error';
          response.errorMessage = 'Campaign error: ' + e.getMessage();
          response.data = null;
        }
      }
      if (wrapper.boatAppraisalData != null) {
        try{
          wrapper.createBoatAppraisalRecord(JSON.serialize((wrapper.boatAppraisalData)));
        } catch(Exception e){
          Database.rollback(savePoint);
          response.status = 'error';
          response.errorMessage = 'Boat Appraisal error: ' + e.getMessage();
          response.data = null;
        }
      }
      if(wrapper.financingApplicationData != null){
        try{
          wrapper.createFinancingApplicationRecord(JSON.serialize((wrapper.financingApplicationData)));
        } catch (Exception e){
          Database.rollback(savePoint);
          response.status = 'error';
          response.errorMessage = 'Finance Application error: ' + e.getMessage();
          response.data = null;
        }
      }

      return response;
    }
    response.status = 'error';
    response.errorMessage = sr.getErrors()[0];
    return response;
  }
}