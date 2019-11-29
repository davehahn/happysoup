global with sharing class mobilePerformanceViewerController {

    public mobilePerformanceViewerController(ApexPages.StandardController controller) {

    }
    
    
    @RemoteAction
    global static string getBoats(string productFamily){
        string html = '<option value="">Select a Boat Model</option>';
        for(Product2 p:[SELECT Id,Name from Product2 WHERE IsActive=true AND Product2.RecordType.Name='Boat' AND Family =:productFamily]){
            html +='<option value="'+p.Id+'">'+p.Name+'</option>';
        }
        return html;
    }
    @RemoteAction
    global static string getMotors(string boatId){
        list<Product2> motors = [SELECT Id,Name,Standard_Motor__c,Standard_Motor__r.Name,
                        (SELECT From_Product__c,From_Product__r.Name FROM To_Product_Options__r WHERE From_Product__r.RecordType.Name='Motor')
                         FROM Product2 WHERE Id=:boatId];
        string html = '<option value="">Select Motor</option>';
        for(Product2 m :motors){
            if(m.Standard_Motor__c !=null){
                html +='<option value="'+m.Standard_Motor__c+'">'+m.Standard_Motor__r.Name+' (standard)</option>';
            }
            for(Product_Option__c p:m.To_Product_Options__r){
                html +='<option value="'+p.From_Product__c+'">'+p.From_Product__r.Name+'</option>';
            }
        }
        return html;
    }
    
    @RemoteAction
    global static string getPropellers(string productFamily){
        string html = '<option value="">Select Propellers</option>';
        //(Propeller Tested: Record TypeEQUALSPart) AND (Propeller Tested: Product FamilyEQUALSPropellers)
        for(Product2 p:[SELECT Id,Name from Product2 WHERE Product2.RecordType.Name='Part' AND Family =:productFamily]){
            html +='<option value="'+p.Id+'">'+p.Name+'</option>';
        }
        return html;
    }
    @RemoteAction
    global static string getOptions(string fieldName){
        string options = '';
                Schema.DescribeFieldResult fieldResult = Schema.SObjectType.Performance_Tracker__c.fields.getMap().get(fieldName).getDescribe(); 
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                //isDefaultValue() 
                for( Schema.PicklistEntry f : ple){
                        options +='<option value="'+f.getLabel()+'" '+(f.isDefaultValue() ? 'selected' : '')+'>'+f.getValue()+'</option>';
                        //options.add(new SelectOption(f.getLabel(), f.getValue()));
                }       
                return options;
        }
    @RemoteAction
    global static string createPerformance(performanceTracker perTracker){
        system.debug('===============hello============');
        system.debug('===============record============'+perTracker);
        Performance_Tracker__c perNewRec=new Performance_Tracker__c(Id=perTracker.recordId);
        
        perNewRec.Boat_Type__c      	= perTracker.boatType;
        perNewRec.Boat_Model_Tested__c  = perTracker.boatModelTested;
        perNewRec.Motor_Tested__c       = perTracker.motorTested;
        perNewRec.Propeller_Tested__c   = perTracker.propellerTested;
        perNewRec.Fuel_Level__c         = perTracker.fuelLevel;
        perNewRec.Number_of_People__c   = perTracker.noOfPeople;
        perNewRec.Engine_Hole_Number__c = perTracker.engineHoleNumber;
        perNewRec.Max_Speed__c          = perTracker.maxSpeed;
        perNewRec.Max_RPM__c            = perTracker.maxRPM;
        perNewRec.Time_to_Plane_Seconds__c = perTracker.timeToPlane;
        
        upsert perNewRec;
        return perNewRec.Id;
    }
    @RemoteAction
    global static performanceTracker getRecord(string recordId){
        performanceTracker perTracker = null;
        list<Performance_Tracker__c> perTrackers = [SELECT Id, Boat_Model_Tested__c, Motor_Tested__c, Propeller_Tested__c,
        								Fuel_Level__c, Number_of_People__c, Engine_Hole_Number__c, Max_Speed__c, Max_RPM__c, 
        								Time_to_Plane_Seconds__c, Boat_Type__c
        								FROM Performance_Tracker__c WHERE Id =:	recordId];
       if(perTrackers.size() > 0){
       	   perTracker = new performanceTracker();
       	   perTracker.recordId 				= perTrackers[0].Id;
	       perTracker.boatType 				= perTrackers[0].Boat_Type__c;
	       perTracker.boatModelTested		= perTrackers[0].Boat_Model_Tested__c;
	       perTracker.motorTested			= perTrackers[0].Motor_Tested__c;
	       perTracker.propellerTested 		= perTrackers[0].Propeller_Tested__c;
	       perTracker.fuelLevel 			= perTrackers[0].Fuel_Level__c;
	       perTracker.noOfPeople 			= perTrackers[0].Number_of_People__c;
	       perTracker.engineHoleNumber 		= perTrackers[0].Engine_Hole_Number__c;
	       perTracker.maxSpeed 				= perTrackers[0].Max_Speed__c;
	       perTracker.maxRPM 				= perTrackers[0].Max_RPM__c;
	       perTracker.timeToPlane 			= perTrackers[0].Time_to_Plane_Seconds__c;
       }
       return perTracker;
    }
    
    global class performanceTracker{
       public string recordId { get; set;}
       public string boatType { get; set;}
       public string boatModelTested { get; set;}
       public string motorTested { get;set; }
       public string propellerTested { get;set; }
       public string fuelLevel { get;set; }
       public string noOfPeople { get;set; }
       public string engineHoleNumber { get;set; }
       public string maxSpeed { get;set; }
       public string maxRPM { get;set; }
       public string timeToPlane { get;set; }
       public performanceTracker(){}
                                   

}
    
}