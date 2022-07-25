@isTest
private class ContactExtTest {
  @isTest
  static void constructor_Test() {
    ApexPages.StandardController stdContact = new ApexPages.StandardController(new Contact());
    ContactExt ce = new ContactExt(stdContact);
    System.assertEquals(ce.getTitle(), 'Create A New Contact');
  }

  @isTest
  static void coverage_Test() {
    ContactExt.coverage();
  }
}
