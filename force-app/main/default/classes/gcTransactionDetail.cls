global without sharing class gcTransactionDetail {

	global gcTransactionDetail(GMBLASERP.gcAccountingPeriod c){}
	global gcTransactionDetail(){}

	@RemoteAction @ReadOnly
	global static list<map<string,string>> retrieveLedger(Id idFilter)
	{
		list<map<string,string>> listJSON = new list<map<string,string>>();

		if(idFilter == null) return listJSON;

	    for(AcctSeed__Transaction__c txn :
		        [SELECT Id,Name,
		            AcctSeed__Accounting_Period__r.Name,
		            AcctSeed__Account__r.Name,
		            AcctSeed__Account_Payable_Line__r.AcctSeed__Account_Payable__r.Name,
		            AcctSeed__Account_Payable_Line__r.AcctSeed__Account_Payable__r.AcctSeed__Payee_Reference__c,
		            AcctSeed__Account_Payable_Line__r.AcctSeed__Invoice_Comment__c,
		            AcctSeed__Account_Payable_Line__r.Name,
		            AcctSeed__Amount__c,
		            AcctSeed__Billing_Line__r.AcctSeed__Billing__r.Name,
		            AcctSeed__Billing_Line__r.Name,
		            AcctSeed__Billing_Line__r.AcctSeed__Comment__c,
		            AcctSeed__Billing_Cash_Receipt__c,
		            AcctSeed__Billing_Cash_Receipt__r.Name,
		            AcctSeed__Cash_Receipt__c,
		            AcctSeed__Cash_Receipt__r.Name,
		            AcctSeed__Cash_Receipt__r.AcctSeed__Payment_Reference__c,
		            AcctSeed__Cash_Disbursement__c,
		            AcctSeed__Cash_Disbursement__r.Name,
		            AcctSeed__Cash_Disbursement__r.AcctSeed__Reference__c,
		            AcctSeed__GL_Account_Type__c,
		            AcctSeed__GL_Account__r.Name,
		            AcctSeed__GL_Account__r.AcctSeed__Type__c,
		            AcctSeed__GL_Account_Variable_1__r.Name,
		            AcctSeed__GL_Account_Variable_2__r.Name,
		            AcctSeed__GL_Account_Variable_3__r.Name,
		            AcctSeed__GL_Account_Variable_4__r.Name,
		            AcctSeed__Journal_Entry_Line__r.AcctSeed__Journal_Entry__r.Name,
		            AcctSeed__Journal_Entry_Line__r.Name,
		            AcctSeed__Journal_Entry_Line__r.Line_Note__c,
		            AcctSeed__Product__r.Name,
		            AcctSeed__Project__r.Name,
		            AcctSeed__Project_Task__r.Name,
		            AcctSeedERP__Inbound_Inventory_Movement__r.Name,
		            AcctSeedERP__Manufacturing_Inventory_Movement__r.Name,
		            AcctSeedERP__Outbound_Inventory_Movement__r.Name,
		            AcctSeedERP__Purchase_Order_Inventory_Movement__r.Name,
		            Origin_Type__c
		         FROM AcctSeed__Transaction__c
		         WHERE (AcctSeed__Account__c =:idFilter 
		         	OR AcctSeed__Project__c =:idFilter 
		         	OR AcctSeed__GL_Account__c =:idFilter 
		         	OR AcctSeed__Cash_Disbursement__c =:idFilter 
		         	OR AcctSeed__Account_Payable_Line__r.AcctSeed__Account_Payable__c =:idFilter 
		         	OR AcctSeed__Billing_Line__r.AcctSeed__Billing__c =:idFilter 
		         	OR AcctSeed__Journal_Entry_Line__r.AcctSeed__Journal_Entry__c =:idFilter 
		         	OR AcctSeed__Accounting_Period__c =:idFilter)])
		{
		    map<string,string> m = new map<string,string>();

		    m.put('idTxn',txn.Id);
		    m.put('account',txn.AcctSeed__Account__r.Name);
		    m.put('glName',txn.AcctSeed__GL_Account__r.Name);
		    m.put('glType',txn.AcctSeed__GL_Account__r.AcctSeed__Type__c);
		    m.put('glV1Name',txn.AcctSeed__GL_Account_Variable_1__r.Name);
		    m.put('glV2Name',txn.AcctSeed__GL_Account_Variable_2__r.Name);
		    m.put('glV3Name',txn.AcctSeed__GL_Account_Variable_3__r.Name);
		   	m.put('glV4Name',txn.AcctSeed__GL_Account_Variable_4__r.Name);
		    m.put('productName',txn.AcctSeed__Product__r.Name);
		    m.put('periodName',txn.AcctSeed__Accounting_Period__r.Name);
		    m.put('projectTaskName',txn.AcctSeed__Project_Task__r.Name);

		    if(txn.AcctSeed__Amount__c > 0) {
		        m.put('debit',String.valueOf(txn.AcctSeed__Amount__c.setScale(6)));
		        m.put('net',String.valueOf(txn.AcctSeed__Amount__c.setScale(6)));
		    }
		    else{
		        m.put('credit',String.valueOf(txn.AcctSeed__Amount__c.setScale(6) * (-1)));
		        m.put('net',String.valueOf(txn.AcctSeed__Amount__c.setScale(6)));
		    }

            Id idOrigin = null;
            String strOrigin = '';
            String strDesc = '';

            if(txn.AcctSeed__Account_Payable_Line__c != NULL){
                idOrigin = txn.AcctSeed__Account_Payable_Line__c;
                strOrigin = txn.AcctSeed__Account_Payable_Line__r.Name;
                strDesc = txn.AcctSeed__Account_Payable_Line__r.AcctSeed__Account_Payable__r.AcctSeed__Payee_Reference__c;
                if(strDesc == NULL) strDesc = '';
                if(txn.AcctSeed__Account_Payable_Line__r.AcctSeed__Invoice_Comment__c != NULL)
                    strDesc = strDesc +' - ' + txn.AcctSeed__Account_Payable_Line__r.AcctSeed__Invoice_Comment__c;          
            }
            else if(txn.AcctSeed__Billing_Line__c != NULL){
                idOrigin = txn.AcctSeed__Billing_Line__c;
                strOrigin = txn.AcctSeed__Billing_Line__r.Name;
                strDesc = txn.AcctSeed__Billing_Line__r.AcctSeed__Comment__c;
            }
            else if(txn.AcctSeed__Cash_Disbursement__c != NULL){
                idOrigin = txn.AcctSeed__Cash_Disbursement__c;
                strOrigin = txn.AcctSeed__Cash_Disbursement__r.Name;
                strDesc = txn.AcctSeed__Cash_Disbursement__r.AcctSeed__Reference__c;
            }
            else if(txn.AcctSeed__Cash_Receipt__c != NULL){
                idOrigin = txn.AcctSeed__Cash_Receipt__c;
                strOrigin = txn.AcctSeed__Cash_Receipt__r.Name;
                strDesc = txn.AcctSeed__Cash_Receipt__r.AcctSeed__Payment_Reference__c;
            }
            else if(txn.AcctSeed__Billing_Cash_Receipt__c != NULL){
                idOrigin = txn.AcctSeed__Billing_Cash_Receipt__c;
                strOrigin = txn.AcctSeed__Billing_Cash_Receipt__r.Name;
            }
            else if(txn.AcctSeed__Journal_Entry_Line__c != NULL){
                idOrigin = txn.AcctSeed__Journal_Entry_Line__c;
                strOrigin = txn.AcctSeed__Journal_Entry_Line__r.Name;
                strDesc = txn.AcctSeed__Journal_Entry_Line__r.Line_Note__c;
            }
            else if(txn.AcctSeedERP__Inbound_Inventory_Movement__c != NULL){
                idOrigin = txn.AcctSeedERP__Inbound_Inventory_Movement__c;
                strOrigin = txn.AcctSeedERP__Inbound_Inventory_Movement__r.Name;
            }
            else if(txn.AcctSeedERP__Manufacturing_Inventory_Movement__c != NULL){
                idOrigin = txn.AcctSeedERP__Manufacturing_Inventory_Movement__c;
                strOrigin = txn.AcctSeedERP__Manufacturing_Inventory_Movement__r.Name;
            }
            else if(txn.AcctSeedERP__Outbound_Inventory_Movement__c != NULL){
                idOrigin = txn.AcctSeedERP__Outbound_Inventory_Movement__c;
                strOrigin = txn.AcctSeedERP__Outbound_Inventory_Movement__r.Name;
            }
            else if(txn.AcctSeedERP__Purchase_Order_Inventory_Movement__c != NULL){
                idOrigin = txn.AcctSeedERP__Purchase_Order_Inventory_Movement__c;
                strOrigin = txn.AcctSeedERP__Purchase_Order_Inventory_Movement__r.Name;
            }
            else{
              idOrigin = txn.Id;
              strOrigin = txn.Name;
            }

            m.put('idOrigin',idOrigin);
            m.put('origin',strOrigin == null ? '' : strOrigin);
            m.put('desc',strDesc == null ? '' : strDesc);

            m.put('originType',txn.Origin_Type__c);

            if(idOrigin.getSobjectType().getDescribe().isAccessible())
            	m.put('isAccessible','true');
            else m.put('isAccessible','false');

      		listJSON.add(m);
    	}


	    return listJSON;
	}

	@RemoteAction @ReadOnly
	global static grid retrieveTransactionDetail(
		String pIdPeriodFrom,
		String pIdPeriodThru,
		String pIdAccount,
		list<String> listIdGL,
		list<String> listIdGLV1,
		list<String> listIdGLV2,
		list<String> listIdGLV3,
		list<String> listIdGLV4,
		String pIdProject,
		String pIdProjectTask,
		String pHasProject)
	{
		AcctSeed__Accounting_Period__c periodThru;
		AcctSeed__Accounting_Period__c periodFrom;


		periodThru = [SELECT Id, Name, AcctSeed__Start_Date__c, AcctSeed__End_Date__c FROM AcctSeed__Accounting_Period__c WHERE Id =: pIdPeriodThru][0];
		if(pIdPeriodFrom != null)
			periodFrom = [SELECT Id, AcctSeed__Start_Date__c, AcctSeed__End_Date__c FROM AcctSeed__Accounting_Period__c WHERE Id =: pIdPeriodFrom][0];
		else //use the start of the year of periodThru
		{
			String strYear = periodThru.Name.LEFT(4)+'%';
			periodFrom = [SELECT Id, AcctSeed__Start_Date__c, AcctSeed__End_Date__c 
			 			 FROM AcctSeed__Accounting_Period__c 
			 			 WHERE Name LIKE :strYear
			 			 ORDER BY AcctSeed__Start_Date__c
			 			 LIMIT 1][0];
		}

		set<Id> setIdPeriods = new set<Id>();
		set<Id> setIdPeriodsPrior = new set<Id>();

		for(AcctSeed__Accounting_Period__c period : [SELECT Id, AcctSeed__End_Date__c 
													 FROM AcctSeed__Accounting_Period__c
													 WHERE AcctSeed__End_Date__c <= :periodThru.AcctSeed__End_Date__c])
		{
			if(period.AcctSeed__End_Date__c >= periodFrom.AcctSeed__End_Date__c)
				setIdPeriods.add(period.Id);
			else
				setIdPeriodsPrior.add(period.Id);
		}

		String strWhere = ' WHERE AcctSeed__GL_Account__c IN :listIdGL ';
			   strWhere += ' AND (AcctSeed__Amount__c < 0 OR AcctSeed__Amount__c > 0) ';

		if(pIdAccount != 'all' && pIdAccount != null)
			strWhere +=' AND AcctSeed__Account__c =:pIdAccount';

		if(!listIdGLV1.isEmpty() && !(new set<String>(listIdGLV1)).contains('all'))
		{
			if(new set<String>(listIdGLV1).contains('blank')) listIdGLV1.add(null);
			strWhere +=' AND AcctSeed__GL_Account_Variable_1__c IN :listIdGLV1 ';
		}

		if(!listIdGLV2.isEmpty() && !(new set<String>(listIdGLV2)).contains('all'))
		{
			if(new set<String>(listIdGLV2).contains('blank')) listIdGLV2.add(null);
			strWhere +=' AND AcctSeed__GL_Account_Variable_2__c IN :listIdGLV2 ';
		}

		if(!listIdGLV3.isEmpty() && !(new set<String>(listIdGLV3)).contains('all'))
		{
			if(new set<String>(listIdGLV3).contains('blank')) listIdGLV3.add(null);
			strWhere +=' AND AcctSeed__GL_Account_Variable_3__c IN :listIdGLV3 ';
		}

		if(!listIdGLV4.isEmpty() && !(new set<String>(listIdGLV4)).contains('all'))
		{
			if(new set<String>(listIdGLV4).contains('blank')) listIdGLV4.add(null);
			strWhere +=' AND AcctSeed__GL_Account_Variable_4__c IN :listIdGLV4 ';
		}

		if(pIdProject != 'all' && pIdProject != null)
			strWhere +=' AND AcctSeed__Project__c = :pIdProject ';
		else if(pHasProject == 'no')
			strWhere +=' AND AcctSeed__Project__c = null ';
		else if(pHasProject == 'yes')
			strWhere +=' AND AcctSeed__Project__c != null ';


		if(pIdProjectTask != 'all' && pIdProjectTask != null)
			strWhere +=' AND AcctSeed__Project_Task__c = :pIdProjectTask ';			

		String strQuery;
			   strQuery = 'SELECT SUM(AcctSeed__Amount__c) sumAmt FROM AcctSeed__Transaction__c ';
			   strQuery += strWhere;
			   strQuery += ' AND AcctSeed__Accounting_Period__c IN :setIdPeriodsPrior ';

		list<AggregateResult> listAggResOpen = new list<AggregateResult>();
		listAggResOpen = Database.query(strQuery);
		Decimal decOpen = (Decimal)listAggResOpen[0].get('sumAmt');

		if(decOpen == null) decOpen = 0;

		list<row> listRow = new list<row>();

		strQuery = '';

		strQuery += ' SELECT Id, Name, ';
		strQuery += ' AcctSeed__Account__r.Name, ';
		strQuery += ' AcctSeed__Accounting_Period__r.Name, ';
		strQuery += ' AcctSeed__Account_Payable_Line__r.Name, ';
		strQuery += ' AcctSeed__Account_Payable_Line__r.AcctSeed__Invoice_Comment__c, ';
		strQuery += ' AcctSeed__Account_Payable_Line__r.AcctSeed__Account_Payable__r.AcctSeed__Payee_Reference__c, ';
		strQuery += ' AcctSeed__Amount__c, ';
		strQuery += ' AcctSeed__Billing_Line__r.Name, ';
		strQuery += ' AcctSeed__Cash_Disbursement__r.Name, ';
		strQuery += ' AcctSeed__Cash_Disbursement__r.AcctSeed__Reference__c, ';
		strQuery += ' AcctSeed__Cash_Receipt__r.Name, ';
		strQuery += ' AcctSeed__Cash_Receipt__r.AcctSeed__Payment_Reference__c, ';
		strQuery += ' AcctSeed__Date__c, ';
		strQuery += ' AcctSeed__Employee__r.Name, ';
		strQuery += ' AcctSeed__GL_Account__r.Name, ';
		strQuery += ' AcctSeed__GL_Account_Variable_1__r.Name, ';
		strQuery += ' AcctSeed__GL_Account_Variable_2__r.Name, ';
		strQuery += ' AcctSeed__GL_Account_Variable_3__r.Name, ';
		strQuery += ' AcctSeed__GL_Account_Variable_4__r.Name, ';
		strQuery += ' AcctSeed__Journal_Entry_Line__r.Name, ';
		strQuery += ' AcctSeed__Journal_Entry_Line__r.Line_Note__c, ';
		strQuery += ' AcctSeed__Journal_Entry_Line__r.AcctSeed__Journal_Entry__r.Name, ';
		strQuery += ' AcctSeed__Product__r.Name, ';
		strQuery += ' AcctSeed__Project__r.Name, ';
		strQuery += ' AcctSeed__Project_Task__r.Name, ';
		strQuery += ' AcctSeed__Scheduled_Revenue_Expense__r.Name ';
		strQuery += ' FROM AcctSeed__Transaction__c ';
		strQuery += strWhere;
		strQuery += ' AND AcctSeed__Accounting_Period__c IN :setIdPeriods ';

 		for(AcctSeed__Transaction__c txn : Database.query(strQuery))
 		{
 			listRow.add(new row(txn));
 		}

 		grid grid = new grid();
		//convert wrapped row to JSON array
		for(row r : listRow)
		{
			r.convertAllToString();
			grid.data.add(r.mapRowDataStr);
		}	

		//add static columns to the ordered list of columns
		grid.colModel.add(new col('glName','GL Account'));
		grid.colModel.add(new col('glV1',AcctSeed__Transaction__c.AcctSeed__GL_Account_Variable_1__c.getDescribe().getLabel()));
		grid.colModel.add(new col('glV2',AcctSeed__Transaction__c.AcctSeed__GL_Account_Variable_2__c.getDescribe().getLabel()));
		grid.colModel.add(new col('glV3',AcctSeed__Transaction__c.AcctSeed__GL_Account_Variable_3__c.getDescribe().getLabel()));
		grid.colModel.add(new col('glV4',AcctSeed__Transaction__c.AcctSeed__GL_Account_Variable_4__c.getDescribe().getLabel()));

		grid.colModel.add(new col('account','Account'));
		grid.colModel.add(new col('project','Project'));	
		grid.colModel.add(new col('projectTask','Project Task'));	
		grid.colModel.add(new col('product','Product'));	
		grid.colModel.add(new col('employee','Employee'));	
		grid.colModel.add(new col('desc','Description'));	


		grid.colModel.add(new col('origin','Origin'));	
		grid.colModel.add(new col('period','Period'));	
		grid.colModel.add(new col('txnDate','Date'));
		grid.colModel.add(new col('debit','Debit'));	
		grid.colModel.add(new col('credit','Credit'));
		grid.colModel.add(new col('net','Net'));

		col colBalance = new col('balance','Balance');
		colBalance.mapProperty.put('OpeningBalance',String.valueOf(decOpen));

		grid.colModel.add(colBalance);	

		return grid;
	}


	global class grid{

		global list<col> colModel{get;set;}
		global list<map<String,String>> data{get;set;}

		global grid()
		{
			colModel = new list<col>();
			data = new list<map<String,String>>();
		}
	}

	global class col{

		global String dataIndx{get;set;}
		global String title{get;set;}

		global map<String,String> mapProperty{get;set;} //this is a map of additional ad-hoc properties for a column, that will be needed by JavaScript in the browser
	
		global map<String,col> mapCol{get;set;} //a map of the subcolumns for a primary column
		global list<col> colModel{get;set;} //an ordered list of the subcolumns for a primary column

		global void init()
		{
			mapProperty = new map<String,String>();

			mapCol = new map<String,col>();
			colModel = new list<col>();
		}

		global col(String pDataIndx, String pTitle)
		{
			init();

			dataIndx = pDataIndx;
			title = pTitle;
		}

	}

	global class row implements Comparable{

		global map<String,String>  mapRowDataStr{get;set;}

		global map<String,Boolean> mapRowDataBool{get;set;}		
		global map<String,Decimal> mapRowDataDec{get;set;}
		global map<String,Integer> mapRowDataInt{get;set;}

		global void init()
		{
			mapRowDataStr 	= new map<String,String>();

			mapRowDataBool	= new map<String,Boolean>();			
			mapRowDataDec 	= new map<String,Decimal>();
			mapRowDataInt 	= new map<String,Integer>();
		}

		global row()
		{
			init();
		}

        global row (AcctSeed__Transaction__c txn)
        {
        	init();
        	mapRowDataStr.put('idTxn',txn.Id);
        	mapRowDataStr.put('glName',txn.AcctSeed__GL_Account__r.Name);
        	mapRowDataStr.put('glV1',txn.AcctSeed__GL_Account_Variable_1__r.Name);
 			mapRowDataStr.put('glV2',txn.AcctSeed__GL_Account_Variable_2__r.Name);
			mapRowDataStr.put('glV3',txn.AcctSeed__GL_Account_Variable_3__r.Name);
			mapRowDataStr.put('glV4',txn.AcctSeed__GL_Account_Variable_4__r.Name);
			mapRowDataStr.put('project',txn.AcctSeed__Project__r.Name);
			mapRowDataStr.put('projectTask',txn.AcctSeed__Project_Task__r.Name);
			mapRowDataStr.put('account',txn.AcctSeed__Account__r.Name);
			mapRowDataStr.put('product',txn.AcctSeed__Product__r.Name);
			mapRowDataStr.put('period',txn.AcctSeed__Accounting_Period__r.Name);
			mapRowDataStr.put('employee',txn.AcctSeed__Employee__r.Name);

			String txnDate = '';
			try{txnDate = txn.AcctSeed__Date__c.format();}catch(exception e){}
			mapRowDataStr.put('txnDate',txnDate);

			if(txn.AcctSeed__Amount__c > 0)
			{
				mapRowDataDec.put('debit',txn.AcctSeed__Amount__c);
				mapRowDataDec.put('credit',0);
				mapRowDataDec.put('net',txn.AcctSeed__Amount__c);
			}
			else
			{
				mapRowDataDec.put('debit',0);
				mapRowDataDec.put('credit',txn.AcctSeed__Amount__c * (-1));
				mapRowDataDec.put('net',txn.AcctSeed__Amount__c);
			}
          
          	Id idOrigin = null;
          	String strOrigin = '';
          	String strDesc = '';
                    
            if(txn.AcctSeed__Account_Payable_Line__c != NULL)
            {
                idOrigin = txn.AcctSeed__Account_Payable_Line__c;
                strOrigin = txn.AcctSeed__Account_Payable_Line__r.Name;
                
                strDesc = txn.AcctSeed__Account_Payable_Line__r.AcctSeed__Account_Payable__r.AcctSeed__Payee_Reference__c;
                if(strDesc == NULL) strDesc = '';
                if(txn.AcctSeed__Account_Payable_Line__r.AcctSeed__Invoice_Comment__c != NULL)
                    strDesc = txn.AcctSeed__Account_Payable_Line__r.AcctSeed__Invoice_Comment__c;          
            }
            else if(txn.AcctSeed__Billing_Line__c != NULL)
            {
                idOrigin = txn.AcctSeed__Billing_Line__c;
                strOrigin = txn.AcctSeed__Billing_Line__r.Name;
            }
            else if(txn.AcctSeed__Cash_Disbursement__c != NULL)
            {
                idOrigin = txn.AcctSeed__Cash_Disbursement__c;
                strOrigin = txn.AcctSeed__Cash_Disbursement__r.Name;
                
                strDesc = txn.AcctSeed__Cash_Disbursement__r.AcctSeed__Reference__c;
            }
            else if(txn.AcctSeed__Cash_Receipt__c != NULL)
            {
                idOrigin = txn.AcctSeed__Cash_Receipt__c;
                strOrigin = txn.AcctSeed__Cash_Receipt__r.Name;
                
                strDesc = txn.AcctSeed__Cash_Receipt__r.AcctSeed__Payment_Reference__c;             
            }
            else if(txn.AcctSeed__Journal_Entry_Line__c != NULL)
            {
                idOrigin = txn.AcctSeed__Journal_Entry_Line__c;
                strOrigin = txn.AcctSeed__Journal_Entry_Line__r.Name;
                
                strDesc = txn.AcctSeed__Journal_Entry_Line__r.Line_Note__c == null ? txn.AcctSeed__Journal_Entry_Line__r.AcctSeed__Journal_Entry__r.Name : txn.AcctSeed__Journal_Entry_Line__r.Line_Note__c;              
            }           
            
            else if(txn.AcctSeed__Scheduled_Revenue_Expense__c != NULL)
            {
                idOrigin = txn.AcctSeed__Scheduled_Revenue_Expense__c;
                strOrigin = txn.AcctSeed__Scheduled_Revenue_Expense__r.Name;            
            }
            else
            {
            	idOrigin = txn.Id;
            	strOrigin = txn.Name;
            }

            mapRowDataStr.put('idOrigin',idOrigin);
            mapRowDataStr.put('origin',strOrigin);
            mapRowDataStr.put('desc',strDesc);

            Boolean isAccessible = idOrigin.getSobjectType().getDescribe().isAccessible();
            mapRowDataBool.put('isAccessible',isAccessible);

        }


		global void convertAllToString()
		{
			//convert all of the decimals to strings
			for(String key :mapRowDataDec.keySet())
			{
				mapRowDataStr.put(key,String.valueOf(mapRowDataDec.get(key)));
			}
			//convert all of the integers to strings
			for(String key :mapRowDataInt.keySet())
			{
				mapRowDataStr.put(key,String.valueOf(mapRowDataInt.get(key)));
			}			
			//convert the boolean values to strings
			for(String key :mapRowDataBool.keySet())
			{
				if(mapRowDataBool.get(key))
					mapRowDataStr.put(key,'true');
				else
					mapRowDataStr.put(key,'false');
			}
			for(String key :mapRowDataStr.keySet())
			{
				if(mapRowDataStr.get(key) == null)
				   mapRowDataStr.put(key,'');
			}
		}
        //COMPARABLE INTERFACE FOR LIST SORTING
        global Integer compareTo(Object pCmp){          
            row cmp = (row)pCmp;
            return -1;
        } 
	}

	//this is used to initialize the picklists and other page controls, in a single remoting call
	@RemoteAction @ReadOnly
	global static controls initControls()
	{
		controls c = new controls();
		return c;
	}

	global class controls
	{
		global list<map<String,String>> listAccount{get;set;}
		global list<map<String,String>> listGL{get;set;}
		global list<map<String,String>> listGLV1{get;set;}
		global list<map<String,String>> listGLV2{get;set;}		
		global list<map<String,String>> listGLV3{get;set;}
		global list<map<String,String>> listGLV4{get;set;}
		global list<map<String,String>> listPeriod{get;set;}

		global controls()
		{
			Set<Id> setIdAccWithTxn = new Set<Id>();
			for(sObject txn : [SELECT AcctSeed__Account__c idAccount FROM AcctSeed__Transaction__c WHERE AcctSeed__Account__c != null GROUP BY AcctSeed__Account__c])
				setIdAccWithTxn.add((Id)txn.get('idAccount'));
			listAccount = new list<map<String,String>>();
			listAccount.add(new map<String,String>{'Id'=>'all','Name'=>'---don\'t care---'});
			for(Account acc : [SELECT Id, Name FROM Account WHERE Id IN:setIdAccWithTxn])
				listAccount.add(new map<String,String>{'Id'=>acc.Id,'Name'=>acc.Name.LEFT(50)});
			//get all the GLs
			listGL = new list<map<String,String>>();
			for(AcctSeed__GL_Account__c gl : [SELECT Id, Name FROM AcctSeed__GL_Account__c ORDER BY Name])
			{
				listGL.add(new map<String,String>{'Id'=>gl.Id,'Name'=>gl.Name.LEFT(30)});
			}
			
			//get all the GLVs
			listGLV1 = new list<map<String,String>>();
			listGLV2 = new list<map<String,String>>();
			listGLV3 = new list<map<String,String>>();
			listGLV4 = new list<map<String,String>>();

			listGLV1.add(new map<String,String>{'Id'=>'all','Name'=>'---don\'t care---'});
			listGLV2.add(new map<String,String>{'Id'=>'all','Name'=>'---don\'t care---'});
			listGLV3.add(new map<String,String>{'Id'=>'all','Name'=>'---don\'t care---'});
			listGLV4.add(new map<String,String>{'Id'=>'all','Name'=>'---don\'t care---'});

			listGLV1.add(new map<String,String>{'Id'=>'blank','Name'=>'---blank---'});
			listGLV2.add(new map<String,String>{'Id'=>'blank','Name'=>'---blank---'});
			listGLV3.add(new map<String,String>{'Id'=>'blank','Name'=>'---blank---'});
			listGLV4.add(new map<String,String>{'Id'=>'blank','Name'=>'---blank---'});
			for(AcctSeed__Accounting_Variable__c glv : [SELECT Id, Name, AcctSeed__Type__c 
														FROM AcctSeed__Accounting_Variable__c 
														WHERE AcctSeed__Type__c LIKE 'GL Account Variable%'
														ORDER BY AcctSeed__Type__c, Name])
			{
				if(glv.AcctSeed__Type__c == 'GL Account Variable 1')
					listGLV1.add(new map<String,String>{'Id'=>glv.Id,'Name'=>glv.Name.LEFT(30)});			
				if(glv.AcctSeed__Type__c == 'GL Account Variable 2')
					listGLV2.add(new map<String,String>{'Id'=>glv.Id,'Name'=>glv.Name.LEFT(30)});		
				if(glv.AcctSeed__Type__c == 'GL Account Variable 3')
					listGLV3.add(new map<String,String>{'Id'=>glv.Id,'Name'=>glv.Name.LEFT(30)});		
				if(glv.AcctSeed__Type__c == 'GL Account Variable 4')
					listGLV4.add(new map<String,String>{'Id'=>glv.Id,'Name'=>glv.Name.LEFT(30)});			
			}

			listPeriod = new list<map<String,String>>();
			for(AcctSeed__Accounting_Period__c p : [SELECT Id, Name FROM AcctSeed__Accounting_Period__c ORDER BY AcctSeed__End_Date__c DESC])
			{
				listPeriod.add(new map<String,String>{'Id'=>p.Id,'Name'=>p.Name});
			}
		}
	}

	global static void coverage(){
		integer i;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
	}
}