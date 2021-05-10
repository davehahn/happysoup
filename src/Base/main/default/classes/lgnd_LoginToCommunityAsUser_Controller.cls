public with sharing class lgnd_LoginToCommunityAsUser_Controller {

	public class CommunityUser {
		public Id id {get; set;}
		public Account account {get; set;}
		public List<User> users {get; set;}
	}

	@AuraEnabled
	public static Boolean checkUserPermissions() {
		Boolean permitted = LGND_Utilities.DoesRunningUserHavePermission('PermissionsManagePartners');
		System.debug('Permitted: ' + permitted);
		return permitted;
	}

	@AuraEnabled
	public static String getOrgId() {
		return UserInfo.getOrganizationId().mid(0,15);
	}

	//@AuraEnabled
	//public static String getDealerId(String recordId) {
	//	String id = [SELECT AccountId FROM Contact WHERE Id =  :recordId].AccountId;
	//	return id;
	//}

	@AuraEnabled
	public static String getSetupId(String recordId) {
		Id userId = recordId;
		return String.valueOf([SELECT NetworkId FROM NetworkMember WHERE MemberId = :userId AND Network.Status = 'Live' LIMIT 1]).mid(26,15);
	}

	@AuraEnabled
	public static String getUserId(String recordId) {
		//String accountId = [SELECT AccountId FROM Contact WHERE Id = :recordId LIMIT 1].AccountId;
		return [SELECT Id FROM User WHERE ContactId = :recordId LIMIT 1].Id;
	}

	@AuraEnabled
	public static String getCommunityUsers() {

		List<CommunityUser> communityUsers = new List<CommunityUser>();

		Map<Id, NetworkMember> members = new Map<Id, NetworkMember>();
		for (NetWorkMember m : [SELECT Id, MemberId, NetworkId FROM NetworkMember]) {
			members.put(m.MemberId, m);
		}

		List<User> users = [SELECT Id, AccountId, Name FROM User WHERE Id IN :members.keyset() AND isActive = true];

		List<Id> accountIds = new List<Id>();
		for (User u : users) {
			accountIds.add(u.AccountId);
		}

		for (Account a : [SELECT Id, Name FROM Account WHERE Id IN :accountIds ORDER BY Name]) {
			CommunityUser cu = new CommunityUser();
			List<User> comUsers = new List<User>();
			cu.id = a.id;
			cu.account = a;
			for (User u : users) {
				if (u.AccountId == a.Id) {
					comUsers.add(u);
				}
			}
			cu.users = comUsers;
			communityUsers.add(cu);
		}

		return JSON.serialize(communityUsers);
	}
}