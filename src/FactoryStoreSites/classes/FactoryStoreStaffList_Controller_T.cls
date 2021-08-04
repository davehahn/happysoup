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

    private static void init()
    {
        Map<String, String[]> roleNamesByDepartment = new Map<String, String[]>{
                'Sales' => new List<String>{
                        'Store Manager',
                        'Memory Makers',
                        'Business Office Managers'
                },
                'Service' => new List<String>{
                        'Boat Specialist',
                        'Memory Builders'
                }
        };
        Map<String, UserRole> roles = new Map<String, UserRole>();
        for( String department : roleNamesByDepartment.keySet() )
        {
            for (String roleName : roleNamesByDepartment.get(department))
            {
                roles.put( roleName, new UserRole(
                        Name = roleName,
                        DeveloperName = roleName.replace(' ', '')
                ));
            }
        }
        insert roles.values();

        Profile sysAdmin = [
                SELECT
                        Id
                FROM Profile
                WHERE Name = 'System Administrator'
        ];

        List<User> users = new List<User>();
        for( String department : roleNamesByDepartment.keySet() )
        {
            System.debug(department);
            for (String roleName : roleNamesByDepartment.get(department))
            {
                Integer random = Integer.valueOf( Math.random() * 1000 );
                User u = Factory_User.buildUser(
                        String.valueOf(random) + 'fName',
                        'lName',
                        sysAdmin.Id
                );
                u.Department = department;
                u.UserRoleId = roles.get( roleName ).Id;
                u.Warehouse__c = WH_NAME;
                users.add( u );
            }
        }
        insert users;
    }

    @IsTest
    static void fetchStaffList_Sales()
    {
        init();
        String location = WH_NAME;
        String department = 'Sales';
        Test.startTest();
        List<User> result = FactoryStoreStaffList_Controller.fetchStaffList(
                location,
                department
        );
        Test.stopTest();

        System.assertEquals( 3, result.size() );
    }

    @IsTest
    static void fetchStaffList_Service()
    {
        init();
        String location = WH_NAME;
        String department = 'Service';
        Test.startTest();
        List<User> result = FactoryStoreStaffList_Controller.fetchStaffList(
                location,
                department
        );
        Test.stopTest();

        System.assertEquals( 2, result.size() );
    }

}