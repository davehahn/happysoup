/**
 * Created by Tim on 2021-09-21.
 */

@IsTest
private class SerialNumber_Selector_T {

    static GMBLASERP__Serial_Number__c[] availableSerials;

    static void initData() {
        availableSerials = Factory_SerialNumber.insertFullSerials(5, 'Boat', 'Pontoon');
    }

    @IsTest
    static void getSerialNumber()
    {
        initData();
        String sid = availableSerials[0].Id;
        Test.startTest();
        GMBLASERP__Serial_Number__c result =  SerialNumber_Selector.getSerialNumber( sid );
        Test.stopTest();

        System.assertEquals(availableSerials[0].Id, result.Id, 'Should return a Serial Number');
    }
}