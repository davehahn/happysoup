/**
 * Created by dave on 2021-04-22.
 */

public inherited sharing class CampaignMember_Selector extends Application_Selector {
  public CampaignMember_Selector() {
    this.sObjectName = 'CampaignMember';
    this.fields = new List<String>{ 'Id', 'CampaignId', 'LeadId' };
  }

  public static List<CampaignMember> allByLeadAndCampaignId(Id leadId, Id campaignId) {
    return new CampaignMember_Selector()
      .addWhere('LeadId = \'' + leadId + '\'')
      .addWhere('CampaignId = \'' + campaignId + '\'', 'AND')
      .query();
  }
}
