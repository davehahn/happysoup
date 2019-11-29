@isTest
private class LightningLookupController_Test {

    private static Contact jackSparrow;

    private static void setup(){
        jackSparrow = new Contact(FirstName = 'Jack', LastName = 'Sparrow', Email = 'where.is.the.rum@gmail.com');
        insert jackSparrow;
    }

    @isTest
    static void valueOfContactIsItsName() {
        setup();

        Test.startTest();

        System.assertEquals('Jack Sparrow', LightningLookupController.getCurrentValue('Contact', jackSparrow.Id));

        Test.stopTest();
    }

    @isTest
    static void valueOfInvalidTypeIsNothing() {
        setup();

    	Test.startTest();

    	System.assert(String.isBlank(LightningLookupController.getCurrentValue(null,         jackSparrow.Id)));
    	System.assert(String.isBlank(LightningLookupController.getCurrentValue('',           jackSparrow.Id)));
    	System.assert(String.isBlank(LightningLookupController.getCurrentValue('PirateShip', jackSparrow.Id)));

    	Test.stopTest();
    }

    @isTest
    static void valueOfInvalidIdIsNothing() {
        setup();

    	Test.startTest();

    	System.assert(String.isBlank(LightningLookupController.getCurrentValue('Contact', null)));
    	System.assert(String.isBlank(LightningLookupController.getCurrentValue('Contact', '')));
    	System.assert(String.isBlank(LightningLookupController.getCurrentValue('Contact', 'BlackPearl')));

    	Test.stopTest();
    }

    @isTest
    static void valueOfNothingIsNothing() {
        setup();

    	Test.startTest();

    	System.assert(String.isBlank(LightningLookupController.getCurrentValue(null, null)));
    	System.assert(String.isBlank(LightningLookupController.getCurrentValue('', '')));

    	Test.stopTest();
    }

    /*
     * We can't really test the searchSObject method due to a limitation of testing methods containing SOSL queries.
     * All SOSL queries return an empty list, unless we mock the result via Test.setFixedSearchResults().
     * However, if we mock the result, we're not testing that the query was even set up properly.
     * We will run some test cases anyway to ensure the method never blows up.
     */

    @isTest
    static void searchingExistingTypeAndContactThrowsNoErrors() {
        setup();
        Test.setFixedSearchResults(new List<String>{jackSparrow.Id});

        Test.startTest();

        String searchResultsJson = LightningLookupController.searchSObject('Contact', 'Jack Sparrow', null, null, null);
        System.assert(!String.isBlank(searchResultsJson));
        List<LightningLookupController.SearchResult> searchResults =
            (List<LightningLookupController.SearchResult>)JSON.deserialize(searchResultsJson, List<LightningLookupController.SearchResult>.class);
        System.assertEquals(1, searchResults.size());

        Test.stopTest();
    }

    @isTest
    static void searchingNonExistingTypeYieldsNothing() {
        setup();

        Test.startTest();

        String searchResultsJson = LightningLookupController.searchSObject('Treasure_Chest__c', 'Jack Sparrow', null, null, null);
        System.assert(String.isBlank(searchResultsJson));

        Test.stopTest();
    }

    @isTest
    static void searchingNoTypeYieldsNothing() {
        setup();
        Test.startTest();

        String searchResultsJson = LightningLookupController.searchSObject(null, 'Jack Sparrow', null, null, null);
        System.assert(String.isBlank(searchResultsJson));

        Test.stopTest();
    }

    @isTest
    static void searchingEmptyTypeYieldsNothing() {
        setup();
        Test.startTest();

        String searchResultsJson = LightningLookupController.searchSObject('', 'Jack Sparrow', null, null, null);
        System.assert(String.isBlank(searchResultsJson));

        Test.stopTest();
    }

    @isTest
    static void searchingNonExistingContactThrowsNoErrors() {
        setup();
        Test.startTest();

        String searchResultsJson = LightningLookupController.searchSObject('Contact', 'I am an ex pirate', null, null, null);
        System.assert(!String.isBlank(searchResultsJson));
        List<LightningLookupController.SearchResult> searchResults =
            (List<LightningLookupController.SearchResult>)JSON.deserialize(searchResultsJson, List<LightningLookupController.SearchResult>.class);
        System.assertEquals(0, searchResults.size());

        Test.stopTest();
    }

    @isTest
    static void searchingEmptyContactNameYieldsNothing() {
        setup();
        Test.startTest();

        String searchResultsJson = LightningLookupController.searchSObject('Contact', '', null, null, null);
        System.assert(String.isBlank(searchResultsJson));

        Test.stopTest();
    }

    @isTest
    static void searchingNoContactNameYieldsNothing() {
        setup();
        Test.startTest();

        String searchResultsJson = LightningLookupController.searchSObject('Contact', null, null, null, null);
        System.assert(String.isBlank(searchResultsJson));

        Test.stopTest();
    }

    @isTest
    static void searchingWithFiltersThrowsNoErrors() {
        setup();
        String filtersJson = '[{"value":"where.is.the.rum@gmail.com","comparator":"=","field":"Email"}]';
        Test.setFixedSearchResults(new List<String>{jackSparrow.Id});

        Test.startTest();

        String searchResultsJson = LightningLookupController.searchSObject('Contact', 'Jack Sparrow', filtersJson, null, null);
        System.assert(!String.isBlank(searchResultsJson));
        List<LightningLookupController.SearchResult> searchResults =
            (List<LightningLookupController.SearchResult>)JSON.deserialize(searchResultsJson, List<LightningLookupController.SearchResult>.class);
        System.assertEquals(1, searchResults.size());

        Test.stopTest();
    }

    @isTest
    static void searchingWithInvalidFiltersYieldsNothing() {
        setup();
        String filtersJson = '[{"Is_Drunk__c":"true"}]';
        Test.setFixedSearchResults(new List<String>{jackSparrow.Id});

        Test.startTest();

        String searchResultsJson = LightningLookupController.searchSObject('Contact', 'Jack Sparrow', filtersJson, null, null);
        System.assert(String.isBlank(searchResultsJson));

        Test.stopTest();
    }

    @isTest
    static void searchingWithEmptyFilterListThrowsNoErrors() {
        setup();
        Test.setFixedSearchResults(new List<String>{jackSparrow.Id});

        Test.startTest();

        String searchResultsJson = LightningLookupController.searchSObject('Contact', 'Jack Sparrow', '[]', null, null);
        System.assert(!String.isBlank(searchResultsJson));
        List<LightningLookupController.SearchResult> searchResults =
            (List<LightningLookupController.SearchResult>)JSON.deserialize(searchResultsJson, List<LightningLookupController.SearchResult>.class);
        System.assertEquals(1, searchResults.size());

        Test.stopTest();
    }

    @isTest(seeAllData=true)
    static void searchingWithPricebookThrowsNoErrors() {
        setup();
        Id pricebookId = Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c;
        Pricebook2 pricebook = [SELECT Id FROM Pricebook2 WHERE Id = :pricebookId];
        BoatTestFactory factory = new BoatTestFactory();
        Product2 blackPearl = factory.insertTestProducts(1, 'Boat', pricebook)[0];
        Test.setFixedSearchResults(new List<String>{blackPearl.Id});

        Test.startTest();

        String searchResultsJson = LightningLookupController.searchSObject('Product2', 'Black Pearl', null, pricebookId, null);
        System.assert(!String.isBlank(searchResultsJson));
        List<LightningLookupController.SearchResult> searchResults =
            (List<LightningLookupController.SearchResult>)JSON.deserialize(searchResultsJson, List<LightningLookupController.SearchResult>.class);
        System.assertEquals(1, searchResults.size());

        Test.stopTest();
    }

    @isTest(seeAllData=true)
    static void searchingWithPricebookButNoProductYieldsNothing() {
        setup();
        Id pricebookId = Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c;

        Test.startTest();

        String searchResultsJson = LightningLookupController.searchSObject('Contact', 'Jack Sparrow', null, pricebookId, null);
        System.assert(String.isBlank(searchResultsJson));

        Test.stopTest();
    }

    @isTest
    static void validTypeHasLabel() {
        System.assertEquals('Product', LightningLookupController.getSObjectLabel('Product2'));
    }

    @isTest
    static void invalidTypeHasNoLabel() {
        System.assert(String.isBlank(LightningLookupController.getSObjectLabel('Black_Pearl__c')));
    }
}