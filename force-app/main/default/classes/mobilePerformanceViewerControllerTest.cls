/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class mobilePerformanceViewerControllerTest {

    static testMethod void myUnitTest() {
        Performance_Tracker__c obj = new Performance_Tracker__c();
        obj.Boat_Type__c = 'test boat';
        insert obj;
        Apexpages.Standardcontroller controller = new Apexpages.Standardcontroller(obj);
        //Pagereference p = Page.PerformanceViewer_2;
        //Test.setCurrentPageReference(p);
        mobilePerformanceViewerController con = new mobilePerformanceViewerController(controller);
        mobilePerformanceViewerController.performanceTracker perTracker = new mobilePerformanceViewerController.performanceTracker();
        mobilePerformanceViewerController.getBoats('test');
        mobilePerformanceViewerController.getMotors('test');
        mobilePerformanceViewerController.getOptions('Number_of_People__c');
        mobilePerformanceViewerController.getPropellers('test');
        mobilePerformanceViewerController.createPerformance(perTracker);
        mobilePerformanceViewerController.getRecord(obj.Id);
    }
}