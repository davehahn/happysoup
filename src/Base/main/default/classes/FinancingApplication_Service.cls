/**
 * Created by Tim on 2023-02-23.
 */

public with sharing class FinancingApplication_Service {

    private Financing_Application__c application;

    public String id;
    public String firstName;
    public String lastName;
    public String email;
    public String streetAddress;
    public String city;
    public String province;
    public String postalCode;

    public Date financingApplicationDateOfBirth;
    public String financingApplicationDreamBoatComments;
    public String financingApplicationDreamBoatCondition;
    public Decimal financingApplicationDreamBoatMaxPrice;
    public Decimal financingApplicationDreamBoatMinPrice;
    public String financingApplicationDreamBoatModel;
    public String financingApplicationDreamBoatType;

    public String financingApplicationPrimaryBank;
    public String financingApplicationPrimaryBankUsage;

    public String financingApplicationEaAdditionalInformation;
    public Decimal financingApplicationEaAnnualSalaryOrWages;
    public String financingApplicationEaCity;
    public String financingApplicationEaEmail;
    public String financingApplicationEaEmployerName;
    public String financingApplicationEaEmploymentDuration;
    public String financingApplicationEaJobTitle;
    public String financingApplicationEaOccupation;
    public String financingApplicationEaPermissionToContactEmployer;
    public String financingApplicationEaPhone;
    public String financingApplicationEaPostalCode;
    public String financingApplicationEaProvince;
    public String financingApplicationEaStreetAddress;

    public String financingApplicationEcAdditionalInformation;
    public Decimal financingApplicationEcAnnualSalaryOrWages;
    public String financingApplicationEcCity;
    public String financingApplicationEcEmail;
    public String financingApplicationEcEmployerName;
    public String financingApplicationEcEmploymentDuration;
    public String financingApplicationEcJobTitle;
    public String financingApplicationEcOccupation;
    public String financingApplicationEcPermissionToContactEmployer;
    public String financingApplicationEcPhone;
    public String financingApplicationEcPostalCode;
    public String financingApplicationEcProvince;
    public String financingApplicationEcStreetAddress;

    public String financingApplicationHomePhone;
    public String financingApplicationHowLongAtResidence;

    public String financingApplicationJaCity;
    public Date financingApplicationJaDateOfBirth;
    public String financingApplicationJaEmail;
    public String financingApplicationJaFirstName;
    public String financingApplicationJaHomePhone;
    public String financingApplicationJaHowLongAtResidence;
    public String financingApplicationJaLastName;
    public Decimal financingApplicationJaMortgageBalance;
    public String financingApplicationJaMortgageOwner;
    public String financingApplicationJaPostalCode;
    public String financingApplicationJaProvince;
    public Decimal financingApplicationJaRentOrMortgageMonthlyAmount;
    public String financingApplicationJaRentOrOwnHome;
    public String financingApplicationJaStreetAddress;
    public Decimal financingApplicationJaValueOfHome;
    public String financingApplicationJaWorkPhone;

    public Decimal financingApplicationMortgageBalance;
    public String financingApplicationMortgageOwner;
    public Decimal financingApplicationRentOrMortgageMonthlyAmount;
    public String financingApplicationRentOrOwnHome;
    public String financingApplicationSendMeACopy;
    public Decimal financingApplicationValueOfHome;
    public String financingApplicationWorkPhone;


    public FinancingApplication_Service() {

    }

    public Financing_Application__c getRecord(){
        return this.application;
    }

    //Get it working this way, then work to refactor it as an extended class
    public void insertFinancingApplication(String data, Id leadId){
        System.debug('insertFinancingApplication: ' + data);
        RestResponse res = RestContext.response;
        FinancingApplication_Service applicationObject = (FinancingApplication_Service) JSON.deserialize(
                data,
                FinancingApplication_Service.class);

        try{
            Financing_Application__c financingApplication = this.createFinancingApplicationRecord(applicationObject, leadId).getRecord();
            insert financingApplication;
        } catch(Exception error){
            System.debug('Error Creating Financing Application Record: ' + error.getMessage());
        }

    }

    public FinancingApplication_Service createFinancingApplicationRecord(FinancingApplication_Service data, Id leadId){
//        String listName = data.firstName + ' ' + data.lastName + ' - ' + Date.today().format();
        System.debug('createFinancingApplicationRecord: ' + data);
        System.debug('leadId: ' + leadId);

        Boolean eaPermission = false;
        if(String.isNotBlank(data.financingApplicationEaPermissionToContactEmployer)){
            eaPermission = (data.financingApplicationEaPermissionToContactEmployer == 'yes') ? true : false;
        }
        Boolean ecPermission = false;
        if(String.isNotBlank(data.financingApplicationEcPermissionToContactEmployer)){
            ecPermission = (data.financingApplicationEcPermissionToContactEmployer == 'yes') ? true : false;
        }
        Boolean sendMeCopy = false;
        if(String.isNotBlank(data.financingApplicationSendMeACopy)){
            sendMeCopy = (data.financingApplicationSendMeACopy == 'yes') ? true : false;
        }

        this.application = new Financing_Application__c(
            Lead__c = leadId,
            First_Name__c = data.firstName,
            Last_Name__c = data.lastName,
            Email__c = data.email,
            Street_Address__c = data.streetAddress,
            City__c = data.city,
            Province__c = data.province,
            Postal_Code__c = data.postalCode,
            Date_of_Birth__c = data.financingApplicationDateOfBirth,
            Dream_Boat_Comments__c = data.financingApplicationDreamBoatComments,
            Dream_Boat_Condition__c = data.financingApplicationDreamBoatCondition,
            Dream_Boat_Maximum_Price__c = data.financingApplicationDreamBoatMaxPrice,
            Dream_Boat_Minimum_Price__c = data.financingApplicationDreamBoatMinPrice,
            Dream_Boat_Type__c = data.financingApplicationDreamBoatType,
            Primary_Bank__c = data.financingApplicationPrimaryBank,
            Primary_Bank_Usage__c = data.financingApplicationPrimaryBankUsage,
            EA_Additional_Information__c = data.financingApplicationEaAdditionalInformation,
            EA_Annual_Salary_or_Wages__c = data.financingApplicationEaAnnualSalaryOrWages,
            EA_City__c = data.financingApplicationEaCity,
            EA_Email__c = data.financingApplicationEaEmail,
            EA_Employer_Name__c = data.financingApplicationEaEmployerName,
            EA_Employment_Duration__c = data.financingApplicationEaEmploymentDuration,
            EA_Job_Title__c = data.financingApplicationEaJobTitle,
            EA_Occupation__c = data.financingApplicationEaOccupation,
            EA_Permission_to_Contact_Employer__c = eaPermission,
            EA_Phone__c = data.financingApplicationEaPhone,
            EA_Postal_Code__c = data.financingApplicationEaPostalCode,
            EA_Province__c = data.financingApplicationEaProvince,
            EA_Street_Address__c = data.financingApplicationEaStreetAddress,
            EC_Additional_Information__c = data.financingApplicationEcAdditionalInformation,
            EC_Annual_Salary_or_Wages__c = data.financingApplicationEcAnnualSalaryOrWages,
            EC_City__c = data.financingApplicationEcCity,
            EC_Email__c = data.financingApplicationEcEmail,
            EC_Employer_Name__c = data.financingApplicationEcEmployerName,
            EC_Employment_Duration__c = data.financingApplicationEcEmploymentDuration,
            EC_Job_Title__c = data.financingApplicationEcJobTitle,
            EC_Occupation__c = data.financingApplicationEcOccupation,
            EC_Permission_to_Contact_Employer__c = ecPermission,
            EC_Phone__c = data.financingApplicationEcPhone,
            EC_Postal_Code__c = data.financingApplicationEcPostalCode,
            EC_Province__c = data.financingApplicationEcProvince,
            EC_Street_Address__c = data.financingApplicationEcStreetAddress,
            Home_Phone__c = data.financingApplicationHomePhone,
            How_Long_at_Residence__c = data.financingApplicationHowLongAtResidence,
            JA_City__c = data.financingApplicationJaCity,
            JA_Date_of_Birth__c = data.financingApplicationJaDateOfBirth,
            JA_Email__c = data.financingApplicationJaEmail,
            JA_First_Name__c = data.financingApplicationJaFirstName,
            JA_Home_Phone__c = data.financingApplicationJaHomePhone,
            JA_How_Long_at_Residence__c = data.financingApplicationJaHowLongAtResidence,
            JA_Last_Name__c = data.financingApplicationJaLastName,
            JA_Mortgage_Balance__c = data.financingApplicationJaMortgageBalance,
            JA_Mortgage_Owner__c = data.financingApplicationJaMortgageOwner,
            JA_Postal_Code__c = data.financingApplicationJaPostalCode,
            JA_Province__c = data.financingApplicationJaProvince,
            JA_Rent_or_Mortgage_Monthly_Amount__c = data.financingApplicationJaRentOrMortgageMonthlyAmount,
            JA_Rent_or_Own_Home__c = data.financingApplicationJaRentOrOwnHome,
            JA_Street_Address__c = data.financingApplicationJaStreetAddress,
            JA_Value_of_Home__c = data.financingApplicationJaValueOfHome,
            JA_Work_Phone__c = data.financingApplicationJaWorkPhone,
            Mortgage_Balance__c = data.financingApplicationMortgageBalance,
            Mortgage_Owner__c = data.financingApplicationMortgageOwner,
            Rent_or_Mortgage_Monthly_Amount__c = data.financingApplicationRentOrMortgageMonthlyAmount,
            Rent_or_Own_Home__c = data.financingApplicationRentOrOwnHome,
            Send_me_a_Copy__c = sendMeCopy,
            Value_of_Home__c = data.financingApplicationValueOfHome,
            Work_Phone__c = data.financingApplicationWorkPhone
        );
        if(data.financingApplicationDreamBoatModel != ''){
            this.application.Dream_Boat_Model__c = data.financingApplicationDreamBoatModel;
        }
        return this;
    }

}