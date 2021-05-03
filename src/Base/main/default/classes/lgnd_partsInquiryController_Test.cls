@isTest
private class lgnd_partsInquiryController_Test {

	@isTest static void save_Test() {
		String caseId = lgnd_partsInquiryController.save(
      '1234567890',
      'Test Boat',
      2017,
      'This is the description',
      null
    );
    Case c = [SELECT Id,
                     Inquiry_Serial_Number__c,
                     Inquiry_Product_Name__c,
                     Inquiry_Product_Year__c,
                     Description
              FROM Case
              WHERE Id = :caseId];
    System.assert( caseId != null );
    System.assertEquals('1234567890', c.Inquiry_Serial_Number__c);
    System.assertEquals('Test Boat', c.Inquiry_Product_Name__c);
    System.assertEquals(2017, c.Inquiry_Product_Year__c);
    System.assertEquals('This is the description', c.Description);
	}
}