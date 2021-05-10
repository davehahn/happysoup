@isTest(seeAllData=true)
private class LGND_Store_Test {

	@isTest static void barrie_Test() {
    doTest('Barrie');
	}

	@isTest static void montreal_Test() {
    doTest('Montreal');
  }

  @isTest static void whitefish_Test() {
    doTest('Whitefish');
  }

  @isTest static void extras_Test() {
    LGND_Store nullStore = new LGND_Store(null);
    Lgnd_Store randomStore = new LGND_Store('ghfuew');

    System.assertEquals('Whitefish', nullStore.Name);
    System.assertEquals('Whitefish', randomStore.Name);
  }

  private static void doTest(String storeName)
  {
    LGND_Store store = new LGND_Store(storeName);
    LGND_Store__c known = LGND_Store__c.getAll().get(storeName);
    String addr = known.Street__c+ ' - ' + known.City__c + ', ' + known.Province__c + ' - ' + known.PostalCode__c;

    System.assertEquals( storeName, store.Name );
    System.assertEquals( addr, store.getAddress() );
    System.assertEquals( known.Phone__c, store.Phone );
    System.assertEquals( known.TollFree__c, store.TollFree );
    System.assertEquals( known.Fax__c, store.Fax );
  }


}