@isTest
private class LGND_Lead_Test {
//  private static Integer LEAD_COUNT = 0;
//
//  private static Lead buildLead(Boolean isPersonAccount)
//  {
//    LEAD_COUNT ++;
//    return new Lead( FirstName = '_unitTest_First_' + LEAD_COUNT,
//                     LastName = '_unitTest_Last_' +  LEAD_COUNT,
//                     Email = 'unitTest_' + LEAD_COUNT +'@testing.net',
//                     isPersonAccount__c = isPersonAccount,
//                     Company = '_unitTest_Company_' + LEAD_COUNT );
//  }
//
//	@isTest static void PersonAccountFix_Test() {
//		Lead personlead = buildLEad( true );
//    Lead businesslead = buildLead( false );
//    insert personlead;
//    insert businesslead;
//
//    Lead afterPerson = [SELECT Id, Company FROM Lead WHERE Id = :personlead.Id];
//    Lead afterBusiness = [SELECT Id, Company FROM Lead WHERE Id = :businesslead.Id];
//
//    System.assertEquals( null, afterPerson.Company );
//    System.assert( afterBusiness.Company != null );
//
//	}
//
//  @isTest static void AutoConvertFromAppSite_NewLead_Test()
//  {
//    Lead l = buildLead( true );
//    l.LeadSource = 'Purchased at Dealer';
//    insert l;
//
//    Lead convertedLead = [SELECT Id, isConverted FROM Lead WHERE Id = :l.Id];
//    System.assert( convertedLead.isConverted == true);
//  }
//
//  @isTest static void AutoConvertFromAppSite_ExistingLead_Test()
//  {
//    Lead l = buildLead( true );
//    insert l;
//    l = [SELECT Id, isConverted, Email FROM Lead WHERE Id = :l.Id];
//    System.assert( l.isConverted == false );
//
//    Lead l2 = buildLead( true );
//    l2.LeadSource = 'Purchased at Dealer';
//    l2.Email = l.Email;
//    insert l2;
//
//    l = [SELECT Id, isConverted, Email FROM Lead WHERE Id = :l.Id];
//    List<Lead> l2check = [SELECT Id FROM Lead WHERE id = :l2.Id];
//
//    System.assert( l.isConverted == true );
//    System.assert( l2check.isEmpty() );
//
//  }

}