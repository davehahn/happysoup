public with sharing class CampaignSelectorController_mp {
	@AuraEnabled
	public static String getCampaignSources() {
		Map<String, String> campaignMap = new Map<String, String>();
		List<Campaign> campaigns = [SELECT Id, Name, StartDate, EndDate 
																  FROM Campaign
																 WHERE StartDate <= Today
																   AND EndDate >= Today];
		for (Campaign c : campaigns) {
			campaignMap.put(c.Id, c.Name);
		}
		return JSON.serialize(campaignMap);
	}
}