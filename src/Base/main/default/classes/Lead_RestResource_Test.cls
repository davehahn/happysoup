/**
 * Created by dave on 2021-04-21.
 */

@IsTest
private class Lead_RestResource_Test {
    private static Lead_RestResource.WebToLeadWrapper buildWrapper() {
        Lead_RestResource.WebToLeadWrapper wrapper = new Lead_RestResource.WebToLeadWrapper();
        wrapper.firstName = 'Tester';
        wrapper.lastName = 'McTesterson';
        wrapper.street = '139 Fittons Rd West';
        wrapper.city = 'Orillia';
        wrapper.province = 'Ontario';
        wrapper.country = 'Canada';
        wrapper.postalCode = 'L3V3V3';
        wrapper.email = 'tester@mctesterson.test';
        wrapper.purchaseByDate = 'Within 3 months';
        wrapper.boatType = 'Pontoon';
        wrapper.subscribeToNewsletter = 'Yes';
        wrapper.language = 'English';
        wrapper.leadSource = 'Online - Web';
        return wrapper;
    }

    private static Lead_RestResource.WebToLeadWrapper buildWrapper_toFail() {
        Lead_RestResource.WebToLeadWrapper wrapper = new Lead_RestResource.WebToLeadWrapper();
        wrapper.id = null;
        return wrapper;
    }

    @IsTest
    static void doPost_Test() {
        TriggerBase.bypass('Lead');
        Lead_RestResource.WebToLeadWrapper wrapper = buildWrapper();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        req.requestBody = Blob.valueOf(JSON.serialize(wrapper));
//    String jsonWrapper = req.requestBody.toString();
        req.requestURI = '/services/apexrest/WebToLead/';
        Lead_RestResource.doPost();
        Test.stopTest();
        Lead_RestResource.WebToLeadWrapper resultWrapper = (Lead_RestResource.WebToLeadWrapper) JSON.deserialize(
                res.responseBody.toString(),
                Lead_RestResource.WebToLeadWrapper.class
        );

        Lead l = [SELECT Id, Lead_Notification_Pending__c FROM Lead WHERE Id = :resultWrapper.id];
        Lead_Submission_History__c lsh = [SELECT Id, Lead_ID__c FROM Lead_Submission_History__c WHERE Lead_ID__c = :resultWrapper.id];
        System.assertEquals(200, res.statusCode);
        System.assert(resultWrapper.id != null);
        System.assertEquals(true, l.Lead_Notification_Pending__c);
        System.assertEquals(lsh.Lead_ID__c, l.Id);
    }

    @IsTest
    static void doPost_Fail_Test() {
        TriggerBase.bypass('Lead');
        Lead_RestResource.WebToLeadWrapper wrapper = buildWrapper_toFail();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        req.requestBody = Blob.valueOf(JSON.serialize(wrapper));
        req.requestURI = '/services/apexrest/WebToLead';
        Lead_RestResource.doPost();
        Test.stopTest();
        System.debug('RestResponse: ' + res);
        System.assertEquals(500, res.statusCode);
    }

    @IsTest
    static void handlePost_Test() {
        TriggerBase.bypass('Lead');
        Lead_RestResource.WebToLeadWrapper wrapper = buildWrapper();
        Test.startTest();
        Lead_RestResource.RestResult response = Lead_RestResource.handlePost(wrapper);
        Test.stopTest();

        System.debug(response);
        System.assertEquals('success', response.status);
        System.assert(response.data.id != null);
        System.assertEquals('Tester', response.data.firstName);
        System.assertEquals(true, response.data.leadNotificationPending);
    }

    @IsTest
    static void handlePost_Fail_Test() {
        TriggerBase.bypass('Lead');
        Lead_RestResource.WebToLeadWrapper wrapper = buildWrapper();
        wrapper.purchaseByDate = 'Invalid Data';
        Test.startTest();
        Lead_RestResource.RestResult response = Lead_RestResource.handlePost(wrapper);
        Test.stopTest();

        System.debug(response);
        System.assertEquals('error', response.status);
        System.assert(response.data == null);
        System.assert(response.errorMessage != null);
    }

    @IsTest
    static void handlePost_withCampaign_Test() {
        TriggerBase.bypass('Lead');
        Campaign camp = Factory_Campaign.createCampaign('Test Campaign');
        Lead_RestResource.WebToLeadWrapper wrapper = buildWrapper();
        wrapper.campaignId = camp.Id;
        Test.startTest();
        Lead_RestResource.RestResult response = Lead_RestResource.handlePost(wrapper);
        Test.stopTest();

        List<CampaignMember> members = [
                SELECT Id
                FROM CampaignMember
                WHERE LeadId = :response.data.id AND CampaignId = :camp.Id
        ];
        System.assertEquals('success', response.status);
        System.assert(response.data.id != null);
        System.assertEquals(1, members.size());
    }

    @IsTest
    static void handlePost_withCampaign_Fail_Test() {
        TriggerBase.bypass('Lead');
        Lead_RestResource.WebToLeadWrapper wrapper = buildWrapper();
        wrapper.campaignId = 'fake campaign id';
        Test.startTest();
        Lead_RestResource.RestResult response = Lead_RestResource.handlePost(wrapper);
        Test.stopTest();

        System.assertEquals('error', response.status);
    }

    @IsTest
    static void handlePost_withBoatAppraisal_Test(){
        TriggerBase.bypass('Lead');
        Lead_RestResource.WebToLeadWrapper wrapper = buildWrapper();
        Map<String, String> boatAppraisalData = new Map<String, String>();
        boatAppraisalData.put('firstName', wrapper.firstName);
        boatAppraisalData.put('lastName', wrapper.lastName);
        boatAppraisalData.put('boatAppraisalCurrentBoatMake', 'Some Boat Make');

        wrapper.boatAppraisalData = boatAppraisalData;
        Test.startTest();
        Lead_RestResource.RestResult response = Lead_RestResource.handlePost(wrapper);
        Test.stopTest();

        System.debug('RestResult: ' + response);

        Boat_Appraisal__c boatAppraisal = [
                SELECT Id, Lead__c, Boat_Make__c
                FROM Boat_Appraisal__c
                WHERE Lead__c = :response.data.id
        ];
        System.assertEquals('success', response.status);
        System.assert(response.data.id != null);
        System.assertEquals(boatAppraisal.Lead__c, response.data.id);
        System.assertEquals(boatAppraisal.Boat_Make__c, 'Some Boat Make');
    }

    @IsTest
    static void handlePost_withBoatAppraisal_Fail_Test(){
        TriggerBase.bypass('Lead');
        Lead_RestResource.WebToLeadWrapper wrapper = buildWrapper();
        Map<String, String> boatAppraisalData = new Map<String, String>();
        boatAppraisalData.put('boatAppraisalCurrentBoatYear', 'Invalid Year');

        wrapper.boatAppraisalData = boatAppraisalData;
        Test.startTest();
        Lead_RestResource.RestResult response = Lead_RestResource.handlePost(wrapper);
        Test.stopTest();
        System.assertEquals('error', response.status);
    }
    @IsTest
    static void handlePost_withFinanceApplication_Test(){
        TriggerBase.bypass('Lead');
        Lead_RestResource.WebToLeadWrapper wrapper = buildWrapper();
        Map<String, String> financeApplicationData = new Map<String, String>();
        financeApplicationData.put('firstName', wrapper.firstName);
        financeApplicationData.put('lastName', wrapper.lastName);
        financeApplicationData.put('email', 'email@testing.com');

        wrapper.financingApplicationData = financeApplicationData;
        Test.startTest();
        Lead_RestResource.RestResult response = Lead_RestResource.handlePost(wrapper);
        Test.stopTest();

        System.debug('RestResult: ' + response);

        Financing_Application__c financingApplication = [
                SELECT Id, Lead__c, Email__c
                FROM Financing_Application__c
                WHERE Lead__c = :response.data.id
        ];
        System.assertEquals('success', response.status);
        System.assert(response.data.id != null);
        System.assertEquals(financingApplication.Lead__c, response.data.id);
        System.assertEquals(financingApplication.Email__c, 'email@testing.com');
    }

    @IsTest
    static void handlePost_withFinanceApplication_Fail_Test(){
        TriggerBase.bypass('Lead');
        Lead_RestResource.WebToLeadWrapper wrapper = buildWrapper();
        Map<String, String> financeApplicationData = new Map<String, String>();
        financeApplicationData.put('financingApplicationMortgageBalance', 'Invalid Mortgage Balance');

        wrapper.financingApplicationData = financeApplicationData;
        Test.startTest();
        Lead_RestResource.RestResult response = Lead_RestResource.handlePost(wrapper);
        Test.stopTest();
        System.assertEquals('error', response.status);
    }
}
