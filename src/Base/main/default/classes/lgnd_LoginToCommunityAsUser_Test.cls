@isTest
private class lgnd_LoginToCommunityAsUser_Test {

	@isTest static void checkUserPermissions() {
		Boolean permitted = lgnd_LoginToCommunityAsUser_Controller.checkUserPermissions();
		System.assert(permitted);
	}

	@isTest static void getOrgId() {
		String orgId = lgnd_LoginToCommunityAsUser_Controller.getOrgId();
		System.assert(orgId.length() == 15);
	}

	//@isTest static void getDealerId() {
	//	String dealerId = lgnd_LoginToCommunityAsUser_Controller.getDealerId(UserInfo.getUserId());
	//	System.assert(dealerId != null);
	//}

	@isTest static void getSetupId() {
		String setupId = lgnd_LoginToCommunityAsUser_Controller.getSetupId(UserInfo.getUserId());
		System.assert(setupId != null);
	}

	@isTest static void gteUserId_Test() {
		Account a = AccountFactory.buildDealerAccount('Patrner Tester');
    insert a;
		User u = User_TestFactory.createPartnerUser( a );
		Contact c = [SELECT Id FROM Contact WHERE AccountId = :a.Id];
		String resultUid = lgnd_LoginToCommunityAsUser_Controller.getUserId( c.Id );

		System.assertEquals( u.Id, resultUid );
	}

	@isTest static void getCommunityUsers() {
		Account a = AccountFactory.buildDealerAccount('Patrner Tester');
    insert a;
		User_TestFactory.createPartnerUser( a );
		String users = lgnd_LoginToCommunityAsUser_Controller.getCommunityUsers();
		List<lgnd_LoginToCommunityAsUser_Controller.CommunityUser> comUsers = (List<lgnd_LoginToCommunityAsUser_Controller.CommunityUser>)JSON.deserialize(users, List<lgnd_LoginToCommunityAsUser_Controller.CommunityUser>.class);
		System.assertEquals(1, comUsers.size() );
	}

}