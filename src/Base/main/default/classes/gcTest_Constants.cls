@isTest
private class gcTest_Constants{

    static testMethod void test1()
    {
        gcConstants.coverage();
        gcConstants.coverage1();
    }
}
/*
	static testMethod void test1()
	{
		Id myId;

		clearConstants();
		myId = gcConstants.idRtProjectManufacturing;
		myId = gcConstants.idRtProjectManufacturing;
		clearConstants();
        myId = gcConstants.idRtProjectService;
        myId = gcConstants.idRtProjectService;

		clearConstants();
        myId = gcConstants.idGlWip;

		clearConstants();
        myId = gcConstants.idGlCash;
        myId = gcConstants.idGlCash;
        clearConstants();
        myId = gcConstants.idGlCreditCard;
        myId = gcConstants.idGlCreditCard;
        clearConstants();
        myId = gcConstants.idGlCogsParts;
        myId = gcConstants.idGlCogsParts;
        clearConstants();
        myId = gcConstants.idGlDeposit;
        myId = gcConstants.idGlDeposit;
        clearConstants();
        myId = gcConstants.idGlProjectParts;
        myId = gcConstants.idGlProjectParts;
        clearConstants();
        myId = gcConstants.idGlProjectPartsClearing;
        myId = gcConstants.idGlProjectPartsClearing;
    }

    static void clearConstants()
    {
    	gcConstants.idRtProjectManufacturing = null;
    	gcConstants.idRtProjectService = null;

    	gcConstants.idGlWip = null;

        gcConstants.idGlCash = null;
        gcConstants.idGlCreditCard = null;
        gcConstants.idGlCogsParts = null;
        gcConstants.idGlDeposit = null;
        gcConstants.idGlProjectParts = null;
        gcConstants.idGlProjectPartsClearing = null;
    }
}
*/