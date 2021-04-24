/**
 * Created by dave on 2021-04-21.
 */

@IsTest
private class Lead_RestResource_Test
{

  private static Lead_RestResource.WebToLeadWrapper buildWrapper()
  {
    Lead_RestResource.WebToLeadWrapper wrapper =  new Lead_RestResource.WebToLeadWrapper();
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

  @IsTest
  static void doPost_Test()
  {
    TriggerHandler.bypass('Lead_TriggerHandler');
    Lead_RestResource.WebToLeadWrapper wrapper = buildWrapper();
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.httpMethod = 'POST';
    RestContext.request = req;
    RestContext.response = res;
    Test.startTest();
    req.requestBody = Blob.valueOf( JSON.serialize( wrapper ) );
    req.requestURI = '/services/apexrest/WebToLead/';
    Lead_RestResource.doPost();
    Test.stopTest();
    Lead_RestResource.WebToLeadWrapper resultWrapper =
      (Lead_RestResource.WebToLeadWrapper)JSON.deserialize(
        res.responseBody.toString(),
        Lead_RestResource.WebToLeadWrapper.class
      );
    System.assertEquals( 200, res.statusCode );
    System.assert( resultWrapper.id != null );
  }

  @IsTest
  static void handlePost_Test()
  {
    TriggerHandler.bypass('Lead_TriggerHandler');
    Lead_RestResource.WebToLeadWrapper wrapper = buildWrapper();
    Test.startTest();
    Lead_RestResource.RestResult response =
      Lead_RestResource.handlePost( wrapper );
    Test.stopTest();

    System.debug( response );
    System.assertEquals( 'success', response.status );
    System.assert( response.data.id != null );
  }

  @IsTest
  static void handlePost_Fail_Test()
  {
    TriggerHandler.bypass('Lead_TriggerHandler');
    Lead_RestResource.WebToLeadWrapper wrapper = buildWrapper();
    wrapper.purchaseByDate = 'Invalid Data';
    Test.startTest();
    Lead_RestResource.RestResult response =
      Lead_RestResource.handlePost( wrapper );
    Test.stopTest();

    System.debug( response );
    System.assertEquals( 'error', response.status );
    System.assert( response.data == null );
    System.assert( response.errorMessage != null );
  }

  @IsTest
  static void handlePost_withCampaign_Test()
  {
    TriggerHandler.bypass('Lead_TriggerHandler');
    Campaign camp = Factory_Campaign.createCampaign('Test Campaign');
    Lead_RestResource.WebToLeadWrapper wrapper = buildWrapper();
    wrapper.campaignId = camp.Id;
    Test.startTest();
    Lead_RestResource.RestResult response =
      Lead_RestResource.handlePost( wrapper );
    Test.stopTest();

    List<CampaignMember> members = [
      SELECT
        Id
      FROM CampaignMember
      WHERE LeadId = :response.data.id
      AND CampaignId = :camp.Id
    ];
    System.assertEquals( 'success', response.status );
    System.assert( response.data.id != null );
    System.assertEquals( 1, members.size() );
  }
}