@isTest
private class CampaignSelectorController_mp_test {
  @isTest
  static void getCampaignSources() {
    Factory_Campaign.createCampaign('Test Campaign');
    String sources = CampaignSelectorController_mp.getCampaignSources();
    System.assert(sources.length() > 5);
  }
}
