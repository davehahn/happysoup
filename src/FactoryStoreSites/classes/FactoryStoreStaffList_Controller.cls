/**
 * Created by Tim on 2021-05-07.
 */

public without sharing class FactoryStoreStaffList_Controller {
    @AuraEnabled(Cacheable=true)
    public static List<User> fetchStaffList(String location, String department){
        if(department == 'Sales'){
            department = 'Display on Sales Team Page';
        } else if(department == 'Service'){
            department = 'Display on Parts and Service Team Page';
        }
        return [
            SELECT
                Id,
                FirstName,
                LastName,
                Department,
                Title,
                Phone,
                Email,
                Retail_Bio_Hometown__c,
                Retail_Bio_Start_Year__c,
                Retail_Bio_Story__c,
                MediumPhotoUrl,
                UserRole.Name,
                Warehouse__c,
                IsActive
            FROM User
            WHERE Warehouse__c = :location
            AND Display_User_on_Retail_Site_Staff_List__c = :department
            ORDER BY LastName ASC
        ];
    }
}