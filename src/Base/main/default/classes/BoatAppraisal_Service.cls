/**
 * Created by Tim on 2023-02-23.
 */

public with sharing class BoatAppraisal_Service {

    private Boat_Appraisal__c appraisal;

    public String id;
    public String firstName;
    public String lastName;
    public String boatAppraisalCurrentBoatMake;
    public String boatAppraisalCurrentBoatModel;
    public Integer boatAppraisalCurrentBoatYear;
    public String boatAppraisalCurrentBoatMotor;
    public Integer boatAppraisalCurrentBoatMotorHours;
    public String boatAppraisalCurrentBoatTrailer;
    public String boatAppraisalCurrentBoatCondition;
    public Decimal boatAppraisalCurrentBoatEstimatedValue;
    public String boatAppraisalCurrentBoatAdditionalInformation;
    public String boatAppraisalTradeIn;
    public String boatAppraisalCashBuyBack;
    public Id boatAppraisalLegendModel;

    public BoatAppraisal_Service() {

    }

    public Boat_Appraisal__c getRecord(){
        return this.appraisal;
    }

    //Get it working this way, then work to refactor it as an extended class
    public void insertBoatAppraisalRequest(String data, Id leadId){
        BoatAppraisal_Service appraisalObject = (BoatAppraisal_Service) JSON.deserialize(
                data,
                BoatAppraisal_Service.class);
        try{
            Boat_Appraisal__c baRecord = this.createBoatAppraisalRecord(appraisalObject, leadId).getRecord();
            insert baRecord;
            System.debug('Created Appraisal Record for Lead Id: ' + leadId);
        } catch(Exception error){
            System.debug('Error Creating Appraisal Record: ' + error.getMessage());
        }

    }

    public BoatAppraisal_Service createBoatAppraisalRecord(BoatAppraisal_Service data, Id leadId){
        String listName = data.firstName + ' ' + data.lastName + ' - ' + Date.today().format();
        Boolean trailerIncluded = false;
        if(String.isNotBlank(data.boatAppraisalCurrentBoatTrailer)){
            trailerIncluded = (data.boatAppraisalCurrentBoatTrailer == 'yes') ? true : false;
        }
        System.debug('createAppraisalRecord: ' + data);
        System.debug('leadId: ' + leadId);
        System.debug('listName: ' + listName);
//        System.debug('Legend_Model_of_Interest__c:' + data.boatAppraisalLegendModel);

        this.appraisal = new Boat_Appraisal__c(
            Lead__c = leadId,
            Name = listName,
            Boat_Make__c = data.boatAppraisalCurrentBoatMake,
            Boat_Model__c = data.boatAppraisalCurrentBoatModel,
            Boat_Year__c = data.boatAppraisalCurrentBoatYear,
            Motor_Make__c = data.boatAppraisalCurrentBoatMotor,
            Motor_Hours__c = data.boatAppraisalCurrentBoatMotorHours,
            Trailer_Included__c = trailerIncluded,
            Condition_Overall__c = data.boatAppraisalCurrentBoatCondition,
            Estimated_Trade_Value_Before_Inspection__c = data.boatAppraisalCurrentBoatEstimatedValue,
            Additional_Information__c = data.boatAppraisalCurrentBoatAdditionalInformation,
            Trade_in_for_New_Boat__c = data.boatAppraisalTradeIn,
            Cash_Buy_Back__c = data.boatAppraisalCashBuyBack,
            Legend_Model_of_Interest__c = data.boatAppraisalLegendModel,
            Status__c = 'Request from Lead Form'
        );

        System.debug('this.appraisal: ' + this.appraisal);

        return this;
    }

}