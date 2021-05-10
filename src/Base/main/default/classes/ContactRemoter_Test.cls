@isTest
private class ContactRemoter_Test {

  private static List<Contact> contacts;

  private static void setup()
  {
    contacts = new List<Contact>();
    for( Integer i=0; i<10; i++ )
    {
      contacts.add( Factory_Contact.newContact( null,
                                                'Fname'+ String.valueOf(i),
                                                'Lname'
                                              ) );
    }
    insert contacts;
  }

  @isTest
  static void constructor_Test()
  {
    ContactRemoter cr = new ContactRemoter( new ApexPages.StandardController( new Contact() ) );
  }

	@isTest
  static void findContacts_Test()
  {
		setup();
    List<Id> omit = new List<Id>{ contacts[0].Id, contacts[1].Id };
    List<Contact> result = ContactRemoter.findContacts('Fname', JSON.serialize(omit) );

    System.assertEquals( 8, result.size() );
	}


}