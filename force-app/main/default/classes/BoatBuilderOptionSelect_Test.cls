@isTest
private class BoatBuilderOptionSelect_Test {

	@isTest static void selectListTest() {
		BoatBuilderOptionSelect bbos = new BoatBuilderOptionSelect();
    bbos.startNum = 1;
    bbos.endNum = 10;

    List<SelectOption> selects = bbos.getOptionsFromRange();

    System.assertEquals(10, selects.size() );
    System.assertEquals('5', selects[4].getValue() );
    System.assertEquals('5', selects[4].getLabel() );
	}

	@isTest static void mapForHTMLSelectsTest() {
		BoatBuilderOptionSelect bbos = new BoatBuilderOptionSelect();
    bbos.startNum = 1;
    bbos.endNum = 10;

    Map<Decimal, String> selects = bbos.getOptionsFromRangeHtml();

    System.assertEquals(10, selects.size() );
    System.assertEquals('5', selects.get(5) );

	}

}