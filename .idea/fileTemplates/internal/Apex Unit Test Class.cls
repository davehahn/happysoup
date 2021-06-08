#parse("Apex File Header.cls")

@IsTest
private class ${NAME}
{

    @testSetup static void dataSetup()
    {
      new Factory_TestData();
      Factory_CustomSettings.setupInventorySettings();
    }
    
    @IsTest
    static void testBehavior()
    {
    }
}