@isTest
public class Project_Service_New_T {
	
   
    @testSetup static void dataSetup(){
        TA_Project_Test_Helper_T.testDataSetup();
    }
    
    @isTest
    static void setStage_Test(){
        Test.startTest();
        TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c from AcctSeed__Project__c  ];
        System.debug('TA_Project_Test_Helper_T.project= '+TA_Project_Test_Helper_T.project);
        TA_Project_Test_Helper_T.project[0].stage__c = 'Quoting';
        Project_Service.setStage(TA_Project_Test_Helper_T.project);
        Test.stopTest();
    }
    @isTest
    static void boatSpecialistChanged_Test(){
        Test.startTest();
        //List<AcctSeed__Project__c> oldProject_List = TA_Project_Test_Helper_T.getOldList();
        TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,Boat_Specialist__c from AcctSeed__Project__c  ];
        AcctSeed__Project__c erp = TA_Project_Test_Helper_T.project[0].clone(true,true,true,true);
        User u = [Select id from user limit 1];
        erp.Boat_Specialist__c =u.id;
        //insert erp;
         
        Project_Service.boatSpecialistChanged(new List<AcctSeed__Project__c>{erp},new Map<id,AcctSeed__Project__c>(TA_Project_Test_Helper_T.project));
        Test.stopTest();
    }
    @isTest
    static void lockProjects_Test(){
    	Test.startTest();
        TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,GL_Account_Variable_1__c from AcctSeed__Project__c  ];
        System.debug('TA_Project_Test_Helper_T.project= '+TA_Project_Test_Helper_T.project);
        TA_Project_Test_Helper_T.project[0].stage__c = 'Quoting';
        //TA_Project_Test_Helper_T.warrantyERP = [select id,AcctSeed__Status__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c from AcctSeed__Project__c  where recordTypeid = :gcConstants.idRtProjectWarranty];
	//	System.debug('TA_Project_Test_Helper_T.warrantyERP= '+TA_Project_Test_Helper_T.warrantyERP);
        Project_Service.lockProjects( new Map<id,AcctSeed__Project__c>(TA_Project_Test_Helper_T.project).keyset());    
    	Test.stopTest();
    }
    @isTest
    static void lockIfNoBalanceDue_Test(){
        Test.startTest();
        TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c from AcctSeed__Project__c  ];
        System.debug('TA_Project_Test_Helper_T.project= '+TA_Project_Test_Helper_T.project);
        TA_Project_Test_Helper_T.generateCashReceipt(TA_Project_Test_Helper_T.project);
        List<AcctSeed__Transaction__c> lst = [SELECT id, AcctSeed__Project__c  FROM AcctSeed__Transaction__c  ];
        System.debug('lst= '+lst);
        Project_Service.lockIfNoBalanceDue( new Map<id,AcctSeed__Project__c>(TA_Project_Test_Helper_T.project).keyset());    
		Test.stopTest();
    }
    @isTest
    static void createServiceERP_Test(){
        Test.startTest();
    	TA_Project_Test_Helper_T.project = [select id,Total_Labour_Hours__c,Service_ERP__c,AcctSeed__Status__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c from AcctSeed__Project__c  ];
        System.debug('##@ TA_Project_Test_Helper_T.project= '+TA_Project_Test_Helper_T.project);
        TA_Project_Test_Helper_T.project[0].Total_Labour_Hours__c =20;
        TA_Project_Test_Helper_T.project[0].AcctSeed__Status__c = 'Completed';
        TA_Project_Test_Helper_T.project[0].Service_ERP__c = null;
        update TA_Project_Test_Helper_T.project[0];
        //TA_Project_Test_Helper_T.customer = [select id,RecordTypeId,FirstName,LastName,Type,PersonEmail,GL_Account_Variable_1__c from account where id = :TA_Project_Test_Helper_T.customer.id limit 1];
    	//System.debug('##@ TA_Project_Test_Helper_T.customer= '+ TA_Project_Test_Helper_T.customer);
        Project_Service.createServiceERP( new Map<id,AcctSeed__Project__c>(TA_Project_Test_Helper_T.project).keyset());    
    	Test.stopTest();
    }
    
	@isTest
    static void rename_Test(){
      Test.startTest();  
      TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c from AcctSeed__Project__c  ];
      TA_Project_Test_Helper_T.generateOpportunity(TA_Project_Test_Helper_T.project) ;
      TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c from AcctSeed__Project__c  ];
	  Project_Service.rename(new Map<id,AcctSeed__Project__c>(TA_Project_Test_Helper_T.project).keyset());		
       Test.stopTest();	
    }
    @isTest
    static void revertOppStage_Test(){
      Test.startTest();
      TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c from AcctSeed__Project__c  ];
      TA_Project_Test_Helper_T.generateOpportunity(TA_Project_Test_Helper_T.project) ;
      TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c from AcctSeed__Project__c  ];
	  Project_Service.revertOppStage(TA_Project_Test_Helper_T.project);		  
      Test.stopTest();
    }
    @isTest
    static void retrieveStatics_Test(){
      Test.startTest();
      TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,name,RecordTypeId,GL_Account_Variable_1__c,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c from AcctSeed__Project__c  ];
      TA_Project_Test_Helper_T.generateOpportunity(TA_Project_Test_Helper_T.project) ;
     // TA_Project_Test_Helper_T.manufacturedProductERP(TA_Project_Test_Helper_T.project);  
      TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Manufactured_Product__c,GMBLASERP__Warehouse__c,GL_Account_Variable_3__c,GL_Account_Variable_1__c,AcctSeedERP__Work_Order_Number__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c from AcctSeed__Project__c  ];
	  new Project_Service().retrieveStatics(TA_Project_Test_Helper_T.project);		  
      Test.stopTest();
    }
    
    @isTest
	static void recalculateInsurance_Test()
    {
        Test.startTest();
        TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,name,Service_Follow_Up_Tasked__c,RecordTypeId,GL_Account_Variable_1__c,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c from AcctSeed__Project__c  ];
        TA_Project_Test_Helper_T.generateERPTask(TA_Project_Test_Helper_T.project);	
        TA_Project_Test_Helper_T.insuranceProductERP(TA_Project_Test_Helper_T.project,5,10,'Single',gcConstants.idGlv3Others);
        TA_Project_Test_Helper_T.project = [select id,Boat_Product__c,Service_Follow_Up_Tasked__c,Pre_Insurance_Total__c,Insurance_Term__c,Deposit__c,Finance_Annual_Interest__c,Finance_Ammortization__c,AcctSeedERP__Manufactured_Product__c,GMBLASERP__Warehouse__c,GL_Account_Variable_3__c,GL_Account_Variable_1__c,AcctSeedERP__Work_Order_Number__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c from AcctSeed__Project__c  ]; 
        AcctSeed__Project__c oldERP = TA_Project_Test_Helper_T.project[0].clone(true,true,true,true);
        TA_Project_Test_Helper_T.project[0].Deposit__c =100;
        TA_Project_Test_Helper_T.project[0].Finance_Annual_Interest__c =10;
        TA_Project_Test_Helper_T.project[0].Finance_Ammortization__c =5;
		TA_Project_Test_Helper_T.project[0].Insurance_Term__c  =10;
        TA_Project_Test_Helper_T.project[0].Finance_Term__c=8;
        TA_Project_Test_Helper_T.project[0].Tax_Rate_Retail__c =10;
        TA_Project_Test_Helper_T.project[0].Service_Follow_Up_Tasked__c = true;
        Project_Service.recalculateInsuranceItems(new List<AcctSeed__Project__c>{TA_Project_Test_Helper_T.project[0]},new Map<id,AcctSeed__Project__c>(new List<AcctSeed__Project__c>{oldERP})); 	
    	
        Test.stopTest();
    }
    @isTest
	static void recalculateInsurance_Test1()
    {
        Test.startTest();
        TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,name,Service_Follow_Up_Tasked__c,RecordTypeId,GL_Account_Variable_1__c,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c from AcctSeed__Project__c  ];
        TA_Project_Test_Helper_T.generateERPTask(TA_Project_Test_Helper_T.project);	
        TA_Project_Test_Helper_T.insuranceProductERP(TA_Project_Test_Helper_T.project,5,10,'Joint',gcConstants.idGlv3Others);
        TA_Project_Test_Helper_T.project = [select id,Boat_Product__c,Service_Follow_Up_Tasked__c,Pre_Insurance_Total__c,Insurance_Term__c,Deposit__c,Finance_Annual_Interest__c,Finance_Ammortization__c,AcctSeedERP__Manufactured_Product__c,GMBLASERP__Warehouse__c,GL_Account_Variable_3__c,GL_Account_Variable_1__c,AcctSeedERP__Work_Order_Number__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c from AcctSeed__Project__c  ]; 
        AcctSeed__Project__c oldERP = TA_Project_Test_Helper_T.project[0].clone(true,true,true,true);
        TA_Project_Test_Helper_T.project[0].Deposit__c =100;
        TA_Project_Test_Helper_T.project[0].Finance_Annual_Interest__c =10;
        TA_Project_Test_Helper_T.project[0].Finance_Ammortization__c =5;
		TA_Project_Test_Helper_T.project[0].Insurance_Term__c  =8;
        TA_Project_Test_Helper_T.project[0].Finance_Term__c=11;
        TA_Project_Test_Helper_T.project[0].Tax_Rate_Retail__c =10;
        TA_Project_Test_Helper_T.project[0].Service_Follow_Up_Tasked__c = true;
        Project_Service.recalculateInsuranceItems(new List<AcctSeed__Project__c>{TA_Project_Test_Helper_T.project[0]},new Map<id,AcctSeed__Project__c>(new List<AcctSeed__Project__c>{oldERP})); 	
    	
        Test.stopTest();
    }
    @isTest
    static void notifyOnOwnerChange_Test(){
        Test.startTest();
        //List<AcctSeed__Project__c> oldProject_List = TA_Project_Test_Helper_T.getOldList();
        TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,OwnerId,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,Boat_Specialist__c from AcctSeed__Project__c  ];
        AcctSeed__Project__c erp = TA_Project_Test_Helper_T.project[0].clone(true,true,true,true);
        User u = [Select id from user limit 1];
        erp.OwnerId =u.id;
        //insert erp;
         
        Project_Service.notifyOnOwnerChange(new Map<id,AcctSeed__Project__c>(new List<AcctSeed__Project__c>{erp}),new Map<id,AcctSeed__Project__c>(TA_Project_Test_Helper_T.project));
        Test.stopTest();
    }
    @isTest
    static void beforeSaveERP_insert(){
        Test.startTest(); 
        //List<AcctSeed__Project__c> oldProject_List = TA_Project_Test_Helper_T.getOldList();
        TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,OwnerId,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,Boat_Specialist__c,
											Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c from AcctSeed__Project__c  ];
        TA_Project_Test_Helper_T.generateOpportunity(TA_Project_Test_Helper_T.project) ;
      	TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c from AcctSeed__Project__c  ];
	    
        AcctSeed__Project__c erp = TA_Project_Test_Helper_T.project[0].clone(true,true,true,true);
        erp.Salesperson__c = null;
        erp.ContactEmail__c = null;
         erp.Tax_Override__c = false;
        erp.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        new Project_Service().beforeSaveERP(new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       new map<Id,AcctSeed__Project__c> (new List<AcctSeed__Project__c>{erp}),
                                                        new list<AcctSeed__Project__c> {erp},
                                                         true, true, false, false);
        
       
    }
     @isTest
    static void beforeSaveERP_delete(){
        Test.startTest(); 
        //List<AcctSeed__Project__c> oldProject_List = TA_Project_Test_Helper_T.getOldList();
        TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,OwnerId,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,Boat_Specialist__c,
											Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c from AcctSeed__Project__c  ];
        TA_Project_Test_Helper_T.generateOpportunity(TA_Project_Test_Helper_T.project) ;
      	TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c from AcctSeed__Project__c  ];
	    
        AcctSeed__Project__c erp = TA_Project_Test_Helper_T.project[0].clone(true,true,true,true);
        erp.Salesperson__c = null;
        erp.ContactEmail__c = null;
         erp.Tax_Override__c = false;
        erp.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        new Project_Service().beforeSaveERP(new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       new map<Id,AcctSeed__Project__c> (new List<AcctSeed__Project__c>{erp}),
                                                        new list<AcctSeed__Project__c> {erp},
                                                         true, false, false, true);
        
            }
     @isTest
    static void beforeSaveERP_update(){
        Test.startTest(); 
        //List<AcctSeed__Project__c> oldProject_List = TA_Project_Test_Helper_T.getOldList();
        TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,OwnerId,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,Boat_Specialist__c,
											Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c from AcctSeed__Project__c  ];
        TA_Project_Test_Helper_T.generateOpportunity(TA_Project_Test_Helper_T.project) ;
      	TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c,AcctSeed__Opportunity__r.account.id from AcctSeed__Project__c  ];
	    System.debug('nefore= '+TA_Project_Test_Helper_T.project[0].GL_Account_Variable_1__c);
        AcctSeed__Project__c erp = TA_Project_Test_Helper_T.project[0].clone(true,true,true,true);
        erp.Salesperson__c = null;
        erp.ContactEmail__c = null;
        erp.Tax_Override__c = false;
        erp.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        erp.AcctSeed__Account__c = null;
        Id erpId = TA_Project_Test_Helper_T.changeGLV1(TA_Project_Test_Helper_T.project[0]);
        erp = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c,AcctSeed__Opportunity__r.account.id from AcctSeed__Project__c where id = :erp.id ];
		System.debug('nefore old= '+TA_Project_Test_Helper_T.project[0].GL_Account_Variable_1__c);
        System.debug('nefore new= '+erp.GL_Account_Variable_1__c);
        System.debug('old id='+TA_Project_Test_Helper_T.project[0].id);
        System.debug('new id= '+erp.id);
        new Project_Service().beforeSaveERP(new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       new map<Id,AcctSeed__Project__c> (new List<AcctSeed__Project__c>{erp}),
                                                        new list<AcctSeed__Project__c> {erp},
                                                         true, false, true, false);
        
       
    }
     @isTest
    static void beforeSaveERP_update_GLV1_Test(){
        Test.startTest(); 
        //List<AcctSeed__Project__c> oldProject_List = TA_Project_Test_Helper_T.getOldList();
        TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,OwnerId,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,Boat_Specialist__c,
											Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c,AcctSeed__Opportunity__r.account.id from AcctSeed__Project__c  ];
        TA_Project_Test_Helper_T.generateOpportunity(TA_Project_Test_Helper_T.project) ;
      	TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c,AcctSeed__Opportunity__r.account.id from AcctSeed__Project__c  ];
	    
        AcctSeed__Project__c erp = TA_Project_Test_Helper_T.project[0].clone(true,true,true,true);
        erp.Salesperson__c = null;
        erp.ContactEmail__c = null;
        erp.Tax_Override__c = false;
        erp.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        //erp.AcctSeed__Account__c = null;
        Account acc = Factory_Account.insertCustomerAccounts(1)[0];
        erp.AcctSeed__Account__c = acc.id;
        List<AcctSeed__Project__c> oldList = TA_Project_Test_Helper_T.getOldList();
        
        Id erpId = TA_Project_Test_Helper_T.changeGLV1(TA_Project_Test_Helper_T.project[0]);
        erpId = TA_Project_Test_Helper_T.changeSerialNo(TA_Project_Test_Helper_T.project[0]);
        erpId = TA_Project_Test_Helper_T.changeStatus(TA_Project_Test_Helper_T.project[0]);
        new Project_Service().beforeSaveERP(new map<Id,AcctSeed__Project__c> (oldList),
                                                       new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       TA_Project_Test_Helper_T.project,
                                                         true, false, true, false);
        new Project_Service().afterSaveERP(new map<Id,AcctSeed__Project__c> (oldList),
                                                       new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       TA_Project_Test_Helper_T.project,
                                                         false, false, true, false);
        
       
    }

    @isTest
    static void beforeSaveERP_update_manufacturedProductERP_Test(){
        Test.startTest(); 
        //List<AcctSeed__Project__c> oldProject_List = TA_Project_Test_Helper_T.getOldList();
           //TA_Project_Test_Helper_T.generateOpportunity(TA_Project_Test_Helper_T.project) ;
      	Id erpId = TA_Project_Test_Helper_T.manufacturedProductERP();
        TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c from AcctSeed__Project__c where id = :erpId  ];
	    
        AcctSeed__Project__c erp = TA_Project_Test_Helper_T.project[0].clone(true,true,true,true);
        erp.Salesperson__c = null;
        erp.ContactEmail__c = null;
        erp.Tax_Override__c = false;
        erp.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        erp.AcctSeed__Account__c = null;
        
        
        new Project_Service().beforeSaveERP(new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       new map<Id,AcctSeed__Project__c> (new List<AcctSeed__Project__c>{erp}),
                                                        new list<AcctSeed__Project__c> {erp},
                                                         true, false, true, false);
        
       
    }
    
  	 @isTest
    static void beforeSaveERP_update_manufacturedProductERP_Service_Test(){
        Test.startTest(); 
        //List<AcctSeed__Project__c> oldProject_List = TA_Project_Test_Helper_T.getOldList();
           //TA_Project_Test_Helper_T.generateOpportunity(TA_Project_Test_Helper_T.project) ;
      	Id erpId = TA_Project_Test_Helper_T.manufacturedProductERP();
        TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c from AcctSeed__Project__c where id = :erpId  ];
	    
        AcctSeed__Project__c erp = TA_Project_Test_Helper_T.project[0].clone(true,true,true,true);
        Id retailERPID = TA_Project_Test_Helper_T.retailBoatSaleERP();
        erp.Salesperson__c = null;
        erp.ContactEmail__c = null;
        erp.Tax_Override__c = false;
        erp.Retail_ERP__c = retailERPID;
        erp.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        erp.AcctSeed__Account__c = null;
        
       
        new Project_Service().beforeSaveERP(new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       new map<Id,AcctSeed__Project__c> (new List<AcctSeed__Project__c>{erp}),
                                                        new list<AcctSeed__Project__c> {erp},
                                                         true, false, true, false);
        new Project_Service().afterSaveERP(new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       new map<Id,AcctSeed__Project__c> (new List<AcctSeed__Project__c>{erp}),
                                                        new list<AcctSeed__Project__c> {erp},
                                                         false, false, true, false);
        
       
    }
    
     @isTest
    static void beforeSaveERP_update_CounterSaleERP_Test(){
        Test.startTest(); 
        //List<AcctSeed__Project__c> oldProject_List = TA_Project_Test_Helper_T.getOldList();
           //TA_Project_Test_Helper_T.generateOpportunity(TA_Project_Test_Helper_T.project) ;
      	Id erpId = TA_Project_Test_Helper_T.counterSaleERP();
        TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c from AcctSeed__Project__c where id = :erpId  ];
	    
        AcctSeed__Project__c erp = TA_Project_Test_Helper_T.project[0].clone(true,true,true,true);
        erp.Salesperson__c = null;
        erp.ContactEmail__c = null;
        erp.Tax_Override__c = false;
        erp.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        erp.AcctSeed__Account__c = null;
        
        
        new Project_Service().beforeSaveERP(new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       new map<Id,AcctSeed__Project__c> (new List<AcctSeed__Project__c>{erp}),
                                                        new list<AcctSeed__Project__c> {erp},
                                                         true, true, false, false);
        
       
    }
    
    
    @isTest
    static void GLV3IsNull(){
        Test.startTest();
        TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c from AcctSeed__Project__c  ];
	    
        AcctSeed__Project__c erp = TA_Project_Test_Helper_T.project[0].clone(true,true,true,true);
        erp.GL_Account_Variable_3__c = null;
       
        new Project_Service().beforeSaveERP(new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       new map<Id,AcctSeed__Project__c> (new List<AcctSeed__Project__c>{erp}),
                                                        new list<AcctSeed__Project__c> {erp},
                                                         true, true, false, false);
        
        Test.stopTest();
    }

    @isTest
    static void afterSaveERP_update(){
        Test.startTest();
        //List<AcctSeed__Project__c> oldProject_List = TA_Project_Test_Helper_T.getOldList();
        TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,OwnerId,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,Boat_Specialist__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c from AcctSeed__Project__c  ];
        TA_Project_Test_Helper_T.generateOpportunity(TA_Project_Test_Helper_T.project) ;
      	TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c from AcctSeed__Project__c  ];
        
        AcctSeed__Project__c erp = TA_Project_Test_Helper_T.project[0].clone(true,true,true,true);
         erp.Tax_Override__c = false;
         new Project_Service().beforeSaveERP(new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       new map<Id,AcctSeed__Project__c> (new List<AcctSeed__Project__c>{erp}),
                                                        new list<AcctSeed__Project__c> {erp},
                                                         true, true, false, false);
        new Project_Service().afterSaveERP(new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       new map<Id,AcctSeed__Project__c> (new List<AcctSeed__Project__c>{erp}),
                                                        new list<AcctSeed__Project__c> {erp},
                                                         false, false, true, false);
        
        new Project_Service().afterSaveERP(new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       new map<Id,AcctSeed__Project__c> (new List<AcctSeed__Project__c>{erp}),
                                                        new list<AcctSeed__Project__c> {erp},
                                                         false, true, false, false);
        new Project_Service().afterSaveERP(new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       new map<Id,AcctSeed__Project__c> (new List<AcctSeed__Project__c>{erp}),
                                                        new list<AcctSeed__Project__c> {erp},
                                                         false, false, false, true);
    }
    
    @isTest
    static void beforeSaveERP_delete1(){
        Test.startTest();
        //List<AcctSeed__Project__c> oldProject_List = TA_Project_Test_Helper_T.getOldList();
        TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,OwnerId,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,Boat_Specialist__c from AcctSeed__Project__c  ];
        
        AcctSeed__Project__c erp = TA_Project_Test_Helper_T.project[0].clone(true,true,true,true);
        new Project_Service().beforeSaveERP(new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       new map<Id,AcctSeed__Project__c> (new List<AcctSeed__Project__c>{erp}),
                                                        new list<AcctSeed__Project__c> {erp},
                                                         true, false, false, true);
    }
    
    @isTest
    
    static void GL_Account_Variable_Test(){
        Test.startTest(); 
        //List<AcctSeed__Project__c> oldProject_List = TA_Project_Test_Helper_T.getOldList();
        TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,OwnerId,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,Boat_Specialist__c,
											Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c from AcctSeed__Project__c  ];
        TA_Project_Test_Helper_T.generateOpportunity(TA_Project_Test_Helper_T.project) ;
      	TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c from AcctSeed__Project__c  ];
	    
        AcctSeed__Project__c erp = TA_Project_Test_Helper_T.project[0].clone(true,true,true,true);
        erp.Salesperson__c = null;
         erp.Tax_Override__c = false;
        erp.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        new Project_Service().beforeSaveERP(new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       new map<Id,AcctSeed__Project__c> (new List<AcctSeed__Project__c>{erp}),
                                                        new list<AcctSeed__Project__c> {erp},
                                                        true, false, true, false);
                                                        
                                                        }
    @isTest
    static void projectBoatSale_Test(){
        
        Test.startTest();
        Id erpId = TA_Project_Test_Helper_T.partnerBoatSaleERP();
        
	    
        TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c,Service_ERP__c,AcctSeed__Opportunity__r.account.id  from AcctSeed__Project__c where id = :erpId  ];
  	      
    	 
  		List<AcctSeed__Project__c> oldList = TA_Project_Test_Helper_T.getOldList();
        TA_Project_Test_Helper_T.changeStatus(TA_Project_Test_Helper_T.project[0]);
        TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c,Service_ERP__c,AcctSeed__Opportunity__r.account.id  from AcctSeed__Project__c where id = :TA_Project_Test_Helper_T.project[0].id  ];
  	      
		new Project_Service().beforeSaveERP(new map<Id,AcctSeed__Project__c> (oldList),
                                                       new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       TA_Project_Test_Helper_T.project,
                                                         true, true, false, false);
        new Project_Service().afterSaveERP(new map<Id,AcctSeed__Project__c> (oldList),
                                                       new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       TA_Project_Test_Helper_T.project,
                                                         false, true, false, false);
    	Test.stopTest();
    }
    
    @isTest
    static void counterBoatSale_gvl1_Test(){
        
        Test.startTest();
        Id erpId = TA_Project_Test_Helper_T.counterSaleERP();
        
	    
        TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c,Service_ERP__c,AcctSeed__Opportunity__r.account.id  from AcctSeed__Project__c where id = :erpId  ];
  	      
    	 
  		List<AcctSeed__Project__c> oldList = TA_Project_Test_Helper_T.getOldList();
       // TA_Project_Test_Helper_T.changeGLV1(TA_Project_Test_Helper_T.project[0]);
        TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c,Service_ERP__c,AcctSeed__Opportunity__r.account.id  from AcctSeed__Project__c where id = :TA_Project_Test_Helper_T.project[0].id  ];
  	      
		new Project_Service().beforeSaveERP(new map<Id,AcctSeed__Project__c> (oldList),
                                                       new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       TA_Project_Test_Helper_T.project,
                                                         true, true, false, false);
        new Project_Service().afterSaveERP(new map<Id,AcctSeed__Project__c> (oldList),
                                                       new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       TA_Project_Test_Helper_T.project,
                                                         false, true, false, false);
    	Test.stopTest();
    }
    static void insuranceERP_Test(){
        Test.startTest();
        TA_Project_Test_Helper_T.insuranceProductERP(TA_Project_Test_Helper_T.project,5,10,'Joint',gcConstants.idGlv3Others);
        TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c,Service_ERP__c,AcctSeed__Opportunity__r.account.id  from AcctSeed__Project__c  ];
  	      
    	 
  		List<AcctSeed__Project__c> oldList = TA_Project_Test_Helper_T.getOldList();
       // TA_Project_Test_Helper_T.changeGLV1(TA_Project_Test_Helper_T.project[0]);
        TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c,Service_ERP__c,AcctSeed__Opportunity__r.account.id  from AcctSeed__Project__c  ];
  	      
		new Project_Service().beforeSaveERP(new map<Id,AcctSeed__Project__c> (oldList),
                                                       new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       TA_Project_Test_Helper_T.project,
                                                         true, true, false, false);
        new Project_Service().afterSaveERP(new map<Id,AcctSeed__Project__c> (oldList),
                                                       new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       TA_Project_Test_Helper_T.project,
                                                         false, true, false, false);
    	Test.stopTest();
    }
    static void counterSaleWithPickup_Test(){
    	Test.startTest();
        Id erpId = TA_Project_Test_Helper_T.counterSaleERP();
        
	    
        TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c,Service_ERP__c,AcctSeed__Opportunity__r.account.id  from AcctSeed__Project__c where id = :erpId  ];
  	      
    	 
  		List<AcctSeed__Project__c> oldList = TA_Project_Test_Helper_T.getOldList();
       // TA_Project_Test_Helper_T.changeGLV1(TA_Project_Test_Helper_T.project[0]);
        erpId = TA_Project_Test_Helper_T.addPickupLocation(TA_Project_Test_Helper_T.project[0]);
        TA_Project_Test_Helper_T.project = [select id,AcctSeedERP__Work_Order_Number__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,ContactEmail__c,GL_Account_Variable_3__c,GMBLASERP__Warehouse__c,AcctSeedERP__Manufactured_Product__c,AcctSeed__Status__c,AcctSeed__Opportunity__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c,
                                            Pickup_Location__c,Internal_Partner_Boat_Sale__c,Internal_Partner_Parts_Order__c,
                                            Internal_Warranty__c,Locked__c,Tax_Rate_Federal__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_is_Harmonized__c
                                            ,Tax_Override__c,Fixed_Asset__c,Internal_Labour_Service__c,Retail_ERP__c,Service_ERP__c,AcctSeed__Opportunity__r.account.id  from AcctSeed__Project__c where id = :erpId  ];
  	      
		new Project_Service().beforeSaveERP(new map<Id,AcctSeed__Project__c> (oldList),
                                                       new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       TA_Project_Test_Helper_T.project,
                                                         true, true, false, false);
        new Project_Service().afterSaveERP(new map<Id,AcctSeed__Project__c> (oldList),
                                                       new map<Id,AcctSeed__Project__c> (TA_Project_Test_Helper_T.project),
                                                       TA_Project_Test_Helper_T.project,
                                                         false, true, false, false);
    	Test.stopTest();    
    }
    
    @isTest
    static void lockIfNoBalanceDueWithInventoryInbound_Test(){
        Test.startTest();
        Id erpId = TA_Project_Test_Helper_T.inventoryMovement();
        TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c from AcctSeed__Project__c  where id = :erpId];
        System.debug('TA_Project_Test_Helper_T.project= '+TA_Project_Test_Helper_T.project);
        TA_Project_Test_Helper_T.generateCashReceipt(TA_Project_Test_Helper_T.project);
        List<AcctSeed__Transaction__c> lst = [SELECT id, AcctSeed__Project__c  FROM AcctSeed__Transaction__c  ];
        System.debug('lst= '+lst);
        Project_Service.lockIfNoBalanceDue( new Map<id,AcctSeed__Project__c>(TA_Project_Test_Helper_T.project).keyset());    
		Test.stopTest();
    }
 
	@isTest
    static void deleteERP_Test(){
        Test.startTest();
        
       TA_Project_Test_Helper_T.project = [select id,AcctSeed__Status__c,name,RecordTypeId,AcctSeed__Account__c,Serial_Number__c,Customer_Notes__c,GMBLASERP__Pricebook__c,Salesperson__c,Service_Date__c,Stage__c from AcctSeed__Project__c ];
              
        Project_Service.deleteERPS( new Map<id,AcctSeed__Project__c>(TA_Project_Test_Helper_T.project));    
		Test.stopTest();
    }
 
}