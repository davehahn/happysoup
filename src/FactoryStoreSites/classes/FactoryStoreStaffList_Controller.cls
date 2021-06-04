/**
 * Created by Tim on 2021-05-07.
 */

public with sharing class FactoryStoreStaffList_Controller {
    @AuraEnabled(Cacheable=true)
    public static List<User> fetchStaffList(String location, String department){
        String[] roles;
        if(department == 'Sales'){
            roles = new String[]{
                '%Store Manager%',
                '%Memory Makers%',
                '%Business Office Managers%'
            };
        } else if(department == 'Service'){
            roles = new String[]{
               '%Boat Specialist%',
               '%Memory Builders%'
            };
        }
        List<User> users = new List<User>();
        for( User u : [SELECT Id,
                              FirstName,
                              LastName,
                              Department,
                              Title,
                              Phone,
                              Email,
                              MediumPhotoUrl,
                              UserRole.Name,
                              Warehouse__c,
                              IsActive
                        FROM User
                        WHERE Warehouse__c = :location
                        AND UserRole.Name LIKE :roles
                        AND IsActive = true
                        ORDER BY LastName ASC])
        {
            users.add( u );
        }
        System.debug('Tim users: ' + users);
        return users;
    }
}