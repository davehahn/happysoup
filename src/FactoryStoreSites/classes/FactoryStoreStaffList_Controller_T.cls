/**
 * Created by Tim on 2021-07-27.
 */
@IsTest
private class FactoryStoreStaffList_Controller_T {

    static final String WH_NAME = 'Test Warehouse';

    @TestSetup static void dataSetup()
    {
        AcctSeedERP__Warehouse__c wh = new AcctSeedERP__Warehouse__c(
                Name = WH_NAME
        );
        insert wh;
    }

    private static void init(String department)
    {
        if(department == 'Sales'){
            department = 'Display on Sales Team Page';
        } else if(department == 'Service'){
            department = 'Display on Parts and Service Team Page';
        }

        Profile sysAdmin = [
                SELECT
                        Id
                FROM Profile
                WHERE Name = 'System Administrator'
        ];

        List<User> users = new List<User>();
        Integer random = Integer.valueOf( Math.random() * 1000 );
        User u = Factory_User.buildUser(
                String.valueOf(random) + 'fName',
                'lName',
                sysAdmin.Id
        );
        u.Display_User_on_Retail_Site_Staff_List__c = department;
        u.Warehouse__c = WH_NAME;
        users.add( u );

        insert users;
    }

    @IsTest
    static void fetchStaffList_Sales()
    {
        String location = WH_NAME;
        String department = 'Sales';
        init(department);
        Test.startTest();
        List<User> result = FactoryStoreStaffList_Controller.fetchStaffList(
                location,
                department
        );
        Test.stopTest();

        System.assertEquals( 1, result.size() );
    }

    @IsTest
    static void fetchStaffList_Service()
    {
        String location = WH_NAME;
        String department = 'Service';
        init(department);
        Test.startTest();
        List<User> result = FactoryStoreStaffList_Controller.fetchStaffList(
                location,
                department
        );
        Test.stopTest();

        System.assertEquals( 1, result.size() );
    }

}