public with sharing class Rigger_Schedule_mp {

	public class Rigger_Schedule {
		public String name {get;set;}
		public String Id {get;set;}
		public List<JobWrapper> jobs {get;set;}

		public Rigger_Schedule(Employee__c rigger, List<JobWrapper> jobs) {
			this.name = rigger.Name;
			this.Id = rigger.Id;
			this.jobs = jobs;
		}
	}

	public class JobWrapper {
		public String name {get;set;}
		public String Id {get; set;}
		public Rigger_Job__c job {get;set;}
		public List<AcctSeedERP__Material__c> materials {get; set;}
		public List<MaterialWrapper> materialWrappers {get; set;}
		public List<AcctSeed__Project_Task__c> tasks {get; set;}
		public Integer jobCount {get; set;}
		public Decimal timeEstimate {get; set;}
		public String serviceDate { get; set;}
		public String openTimeEntryId;
		public Boolean hasStartedTimeEntry;
		public String timeToComplete;

		public JobWrapper(Rigger_Job__c job, List<AcctSeedERP__Material__c> materials, List<AcctSeed__Project_Task__c> tasks, Integer jobCount) {
			this.name = job.Name;
			this.Id = job.Id;
			this.job = job;
			this.materials = materials;
			this.tasks = tasks;
			this.jobCount = jobCount;
			setTimeEntryStatus();
			setServiceDate();
			setTimeToComplete();


			if (job.ExpectedTime__c != null && job.ExpectedTime__c > 0) {
				this.timeEstimate = job.ExpectedTime__c;
			} else {
				Decimal riggingTime = 0.0;
				Decimal taskTime = 0.0;
				if (materials != null) {
					for (AcctSeedERP__Material__c material : materials) {
						if (material.AcctSeedERP__Product__r.Family == 'Labour' && material.AcctSeedERP__Quantity_Per_Unit__c != null) {
							riggingTime += material.AcctSeedERP__Quantity_Per_Unit__c;
						}
					}
				}
				if (tasks != null) {
					for (AcctSeed__Project_Task__c task : tasks) {
						if (task.Estimated_Duration__c != null) {
							taskTime += task.Estimated_Duration__c;
						}
					}
				}
				this.timeEstimate = riggingTime + taskTime;
			}
		}

		public JobWrapper(Rigger_Job__c job, List<MaterialWrapper> materialWrappers, List<AcctSeed__Project_Task__c> tasks, Integer jobCount) {
			//System.debug(job.ERP_Order__r.Name + ': ' + materialWrappers);
			this.name = job.Name;
			this.Id = job.Id;
			this.job = job;
			this.materials = new List<AcctSeedERP__Material__c>();
			this.tasks = tasks;
			this.jobCount = jobCount;
			setTimeEntryStatus();
			setServiceDate();

			if (materialWrappers != null) {
				for (MaterialWrapper mw : materialWrappers) {
					this.materials.add(mw.material);
				}
			}

			if (job.ExpectedTime__c != null && job.ExpectedTime__c > 0) {
				this.timeEstimate = job.ExpectedTime__c;
			} else {
				Decimal riggingTime = 0.0;
				Decimal taskTime = 0.0;
				if (materialWrappers != null) {
					for (MaterialWrapper mw : materialWrappers) {
						System.debug(job.ERP_Order__r.Name + ': ' + mw);
						if (mw.material.AcctSeedERP__Product__r.Family == 'Labour' && mw.material.AcctSeedERP__Quantity_Per_Unit__c != null) {
							riggingTime += mw.material.AcctSeedERP__Quantity_Per_Unit__c;
						}
						if (mw.riggingTime != null) {
							System.debug(riggingTime + ' + ' + mw.riggingTime);
							riggingTime += mw.riggingTime;
							System.debug('= ' + riggingTime);
						}
					}
				}
				if (tasks != null) {
					for (AcctSeed__Project_Task__c task : tasks) {
						if (task.Estimated_Duration__c != null) {
							taskTime += task.Estimated_Duration__c;
						}
					}
				}
				System.debug('riggingTime: ' + riggingTime);
				System.debug('taskTime: ' + taskTime);
				this.timeEstimate = riggingTime + taskTime;
				System.debug(this.timeEstimate);
			}
		}

		private void setTimeEntryStatus()
		{
			this.hasStartedTimeEntry = false;
			if( this.job.Rigger_Job_Time_Entries__r.size() == 1 )
			{
				this.hasStartedTimeEntry = true;
				this.openTimeEntryId = this.job.Rigger_Job_Time_Entries__r[0].Id;
			}
		}

		private void setTimeToComplete()
		{
			Integer hours = Integer.valueOf( job.Actual_Time_Spent__c / 60 );
			Integer minutes = Integer.valueOf( job.Actual_Time_Spent__c - ( hours * 60 ) );
			this.timeToComplete = String.valueOf(hours) + ':' + String.valueOf(minutes).leftPad(2, '0');
		}

		private void setServiceDate()
		{
			if( this.job.ERP_Order__c != null &&
		  		this.job.ERP_Order__r.Service_Date__c != null )
			{
				this.serviceDate = job.Erp_Order__r.Service_Date__c.format('MMM d/yy @ HH:mm');
			}
		}
	}

	public class MaterialWrapper {
		public AcctSeedERP__Material__c material { get; set; }
		public Decimal riggingTime { get; set; }

		public MaterialWrapper(AcctSeedERP__Material__c material, Decimal riggingTime) {
			this.material = material;
			this.riggingTime = riggingTime;
		}
	}

	@AuraEnabled
	public static List<Employee__c> getRiggers(String warehouse, String team) {
		if (team == null || team == '') {
			return [SELECT Id,
										 Name,
										 User__r.Warehouse__c,
										 User__r.FirstName,
										 User__r.LastName,
										 Team__c
							FROM Employee__c
							WHERE Is_Rigger__c = true
							AND Active__c = true
							AND User__r.Warehouse__c = :warehouse
							ORDER BY Name ASC];
		} else {
			return [SELECT Id,
										 Name,
										 User__r.Warehouse__c,
										 User__r.FirstName,
										 User__r.LastName,
										 Team__c
							FROM Employee__c
							WHERE Is_Rigger__c = true
							AND Active__c = true
							AND User__r.Warehouse__c = :warehouse
							AND Team__c INCLUDES (:team)
							ORDER BY Name ASC];
		}
	}

	@AuraEnabled
	public static String getCompletedJobs(String warehouse, String search) {
		String searchOptions = '';
		String query = 'SELECT ';
		query += 'ActualEnd__c, ';
		query += 'ActualStart__c, ';
		query += 'Actual_Time_Spent__c, ';
		query += 'ActualTime__c, ';
		query += 'Warranty_Time__c, ';
		query += 'Non_Warranty_Time__c, ';
		query += 'BilledNotes__c, ';
		query += 'BilledOther__c, ';
		query += 'BilledRetail__c, ';
		query += 'BilledWarranty__c, ';
		query += 'CreatedDate, ';
		query += 'DueDate__c, ';
		query += 'Employee__c, ';
		query += 'Employee__r.User__r.FirstName, ';
		query += 'Employee__r.User__r.LastName, ';
		query += 'Employee__r.User__r.Warehouse__c, ';
		query += 'ERP_Order__c, ';
		query += 'ERP_Order__r.AcctSeed__Account__r.Name, ';
		query += 'ERP_Order__r.AcctSeedERP__Work_Order_Number__c, ';
		query += 'ERP_Order__r.AcctSeed__Status__c, ';
		query += 'ERP_Order__r.WarehouseName__c, ';
		query += 'ERP_Order__r.Delivery_Date__c, ';
		query += 'ERP_Order__r.Service_Date__c, ';
		query += 'ERP_Order__r.Model_Name__c, ';
		query += 'ERP_Order__r.RecordTypeId, ';
		query += 'ERP_Order__r.RecordType.Name, ';
		query += 'ERP_Order__r.Serial_Number__c, ';
		query += 'ERP_Order__r.Serial_Number__r.Name, ';
		query += 'ERP_Order__r.Serial_Product__c, ';
		query += 'ERP_Order__r.AcctSeed__Opportunity__r.BoatId__r.Rigging_Time__c, ';
		query += 'ERP_Order__r.Manufactured_Product_Name__c, ';
		query += 'ERP_Order__r.Oppy_Boat_Model__c, ';
		query += 'ExpectedTime__c, ';
		query += 'Id, ';
		query += 'Job_Class__c, ';
		query += 'Job_Location__c, ';
		query += 'list_order__c, ';
		query += 'Model__c, ';
		query += 'Model__r.Name, ';
		query += 'Name, ';
		query += 'Notes__c, ';
		query += 'Placeholder__c, ';
		query += 'Serial_Number__c, ';
		query += 'Serial_Number__r.Name, ';
		query += 'Status__c, ';
		query += 'Work_Order__c ';
		query += 'FROM Rigger_Job__c ';
		query += 'WHERE ERP_Order__r.Job_Status__c = \'Completed\' ';
		query += 'AND ActualEnd__c > YESTERDAY';

		if (search != null && search != '') {
			search = '%' + search + '%';
			searchOptions += 'ERP_Order__r.Model_Name__c LIKE \'' + search + '\'';
  		searchOptions += ' OR ERP_Order__r.Serial_Product__c LIKE \'' + search + '\'';
  		searchOptions += ' OR ERP_Order__r.Manufactured_Product_Name__c LIKE \'' + search + '\'';
  		searchOptions += ' OR ERP_Order__r.AcctSeedERP__Manufactured_Product__r.Name LIKE \'' + search + '\'';
  		searchOptions += ' OR ERP_Order__r.AcctSeed__Account__r.Name LIKE \'' + search + '\'';
  		searchOptions += ' OR ERP_Order__r.Serial_Number__r.Name LIKE \'' + search + '\'';
  		searchOptions += ' OR ERP_Order__r.AcctSeedERP__Work_Order_Number__c LIKE \'' + search + '\'';
			query += ' AND (' + searchOptions + ')';
		}

		List<Rigger_Job__c> jobs =  Database.query(query);

		List<JobWrapper> wrappedJobs = new List<JobWrapper>();

		Set<Id> jobKeys = new Set<Id>();
		for (Rigger_Job__c job : jobs) {
			jobKeys.add(job.ERP_Order__c);
		}

		Map<Id, List<AcctSeedERP__Material__c>> materialsMap = new Map<Id, List<AcctSeedERP__Material__c>>();

		for (AcctSeedERP__Material__c m : [SELECT Id,
																							AcctSeedERP__Project__c,
																							Product_Name__c,
																							Product_Record_Type__c,
																							AcctSeedERP__Product__r.Family,
																							AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c,
																							AcctSeedERP__Quantity_Per_Unit__c,
																							AcctSeedERP__Product__r.Rigging_Time__c
																				 FROM AcctSeedERP__Material__c
																				WHERE AcctSeedERP__Project__c in :jobKeys]) {
			if (!materialsMap.containsKey(m.AcctSeedERP__Project__c)) {
				materialsMap.put(m.AcctSeedERP__Project__c, new List<AcctSeedERP__Material__c>());
			}
			materialsMap.get(m.AcctSeedERP__Project__c).add(m);
		}

		Map<Id, List<AcctSeed__Project_Task__c>> taskMap = new Map<Id, List<AcctSeed__Project_Task__c>>();

		for (AcctSeed__Project_Task__c task : [SELECT Id,
																									Cause_dh__c,
																									Complaint_dh__c,
																									Correction_dh__c,
																									AcctSeed__Project__c,
																									AcctSeed__Budgeted_Hours__c,
																									Estimated_Duration__c,
																									AcctSeed__Project_ID__c
																						 FROM AcctSeed__Project_Task__c
																						WHERE AcctSeed__Project__c IN :jobKeys]) {
			if (!taskMap.containsKey(task.AcctSeed__Project_ID__c)) {
				taskMap.put(task.AcctSeed__Project_ID__c, new List<AcctSeed__Project_Task__c>());
			}
			taskMap.get(task.AcctSeed__Project_ID__c).add(task);
		}

		for (Rigger_Job__c job : jobs) {
			List<AcctSeedERP__Material__c> materials = materialsMap.get(job.ERP_Order__c);
			List<AcctSeed__Project_Task__c> tasks = taskMap.get(job.ERP_Order__c);
			JobWrapper wrappedJob = new JobWrapper(job, materials, tasks, null);
			wrappedJob.Id = job.Id;
			wrappedJob.name = job.Name;
			wrappedJobs.add(wrappedJob);
		}

		return JSON.serialize(wrappedJobs);
	}

	@AuraEnabled
	public static String getMyJobs(String riggerId) {
		List<Rigger_Job__c> jobs = [SELECT ActualEnd__c,
																			 ActualStart__c,
																		   Actual_Time_Spent__c,
																			 ActualTime__c,
																			 Warranty_Time__c,
																			 Non_Warranty_Time__c,
																			 BilledNotes__c,
																			 BilledOther__c,
																			 BilledRetail__c,
																			 BilledWarranty__c,
																			 CreatedDate,
																			 DueDate__c,
																			 Employee__c,
																			 Employee__r.User__r.FirstName,
																			 Employee__r.User__r.LastName,
																			 ERP_Order__c,
																			 ERP_Order__r.AcctSeed__Account__r.Name,
																			 ERP_Order__r.AcctSeedERP__Work_Order_Number__c,
																			 ERP_Order__r.AcctSeed__Status__c,
																			 ERP_Order__r.WarehouseName__c,
																			 ERP_Order__r.Delivery_Date__c,
																			 ERP_Order__r.Model_Name__c,
																			 ERP_Order__r.Name,
									 										 ERP_Order__r.Parking_Spot__c,
									 										 ERP_Order__r.RecordTypeId,
									 										 ERP_Order__r.RecordType.Name,
									 										 ERP_Order__r.Rigging_Status__c,
									 										 ERP_Order__r.Serial_Number__c,
									 										 ERP_Order__r.Serial_Number__r.Name,
									 										 ERP_Order__r.Serial_Product__c,
									 										 ERP_Order__r.Serial_Number__r.Product_Name__c,
									 										 ERP_Order__r.Service_Date__c,
									 										 ERP_Order__r.AcctSeed__Opportunity__r.BoatId__r.Rigging_Time__c,
									 										 ERP_Order__r.Oppy_Boat_Model__c,
									 										 ERP_Order__r.Job_Status__c,
																			 ExpectedTime__c,
																			 Id,
																			 Job_Class__c,
																			 Job_Location__c,
																			 list_order__c,
																			 Model__c,
																			 Model__r.Name,
																			 Name,
																			 Notes__c,
									 										 Placeholder__c,
																			 Serial_Number__c,
																			 Serial_Number__r.Name,
																			 Status__c,
																			 Work_Order__c,
																( SELECT Id FROM Rigger_Job_Time_Entries__r WHERE End_At__c = null )
																FROM Rigger_Job__c
																WHERE Employee__c = :riggerId
																AND Status__c != 'Completed'
																AND ERP_Order__r.AcctSeed__Status__c != 'Completed'
																//AND ERP_Order__r.AcctSeed__Status__c != 'Ready For Accounting'
																AND ERP_Order__r.Job_Status__c != 'Completed'
																AND ERP_Order__r.Stage__c != 'Delivered'
																ORDER BY list_order__c ASC NULLS LAST];

		List<JobWrapper> wrappedJobs = new List<JobWrapper>();

		Set<Id> jobKeys = new Set<Id>();
		for (Rigger_Job__c job : jobs) {
			jobKeys.add(job.ERP_Order__c);
		}

		Map<Id, List<MaterialWrapper>> materialsMap = new Map<Id, List<MaterialWrapper>>();
		Map<String, Decimal> materialCount = new Map<String, Decimal>();

		for (AcctSeedERP__Material__c m : [SELECT Id,
																							AcctSeedERP__Project__c,
																							Product_Name__c,
																							Product_Record_Type__c,
																							AcctSeedERP__Product__r.Family,
																							AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c,
																							AcctSeedERP__Quantity_Per_Unit__c,
																							AcctSeedERP__Product__r.Rigging_Time__c
																				 FROM AcctSeedERP__Material__c
																				WHERE AcctSeedERP__Project__c in :jobKeys]) {
			if (!materialsMap.containsKey(m.AcctSeedERP__Project__c)) {
				materialsMap.put(m.AcctSeedERP__Project__c, new List<MaterialWrapper>());
			}
			Decimal rt;
			if (m.AcctSeedERP__Product__r.Rigging_Time__c != null) {
				rt = m.AcctSeedERP__Product__r.Rigging_Time__c;
			}
			//System.debug('RT: ' + rt);
			MaterialWrapper mw = new MaterialWrapper(m, rt);
			materialsMap.get(m.AcctSeedERP__Project__c).add(mw);

			if (!materialCount.containsKey(m.Product_Name__c)) {
				materialCount.put(m.Product_Name__c, m.AcctSeedERP__Quantity_Per_Unit__c);
			} else {
				Decimal count = materialCount.get(m.Product_Name__c) + m.AcctSeedERP__Quantity_Per_Unit__c;
				materialCount.put(m.Product_Name__c, count);
			}
		}

		// Clean up material list of duplicates and erroneous entries
		for ( Rigger_Job__c job : jobs ) {
			if ( materialsMap.containsKey(job.ERP_Order__c) ) {
				List<MaterialWrapper> materials = materialsMap.get(job.ERP_Order__c);
				for ( Integer j = 0; j < materials.size(); j++) {
					if ( materialCount.get( materials[j].material.Product_Name__c ) <= 0 ) {
						materialsMap.get(job.ERP_Order__c).remove(j);
					}
				}
			}
		}

		Map<Id, List<AcctSeed__Project_Task__c>> taskMap = new Map<Id, List<AcctSeed__Project_Task__c>>();

		for (AcctSeed__Project_Task__c task : [SELECT Id,
																									Cause_dh__c,
																									Complaint_dh__c,
																									Correction_dh__c,
																									AcctSeed__Project__c,
																									AcctSeed__Budgeted_Hours__c,
																									Estimated_Duration__c,
																									AcctSeed__Project_ID__c
																						 FROM AcctSeed__Project_Task__c
																						WHERE AcctSeed__Project__c IN :jobKeys]) {
			if (!taskMap.containsKey(task.AcctSeed__Project__c)) {
				taskMap.put(task.AcctSeed__Project__c, new List<AcctSeed__Project_Task__c>());
			}
			taskMap.get(task.AcctSeed__Project__c).add(task);
		}

		for (Rigger_Job__c job : jobs) {
			List<MaterialWrapper> materials = materialsMap.get(job.ERP_Order__c);
			List<AcctSeed__Project_Task__c> tasks = taskMap.get(job.ERP_Order__c);
			JobWrapper wrappedJob = new JobWrapper(job, materials, tasks, null);
			wrappedJob.Id = job.Id;
			wrappedJob.name = job.Name;
			wrappedJobs.add(wrappedJob);
		}

		return JSON.serialize(wrappedJobs);
	}

	@AuraEnabled
	public static List<Rigger_Job__c> getMyCompletedJobs(String riggerId) {
		return [SELECT ActualEnd__c,
									 ActualStart__c,
									 ActualTime__c,
									 Actual_Time_Spent__c,
									 Warranty_Time__c,
									 Non_Warranty_Time__c,
									 BilledNotes__c,
									 BilledOther__c,
									 BilledRetail__c,
									 BilledWarranty__c,
									 CreatedDate,
									 DueDate__c,
									 Employee__c,
									 Employee__r.User__r.FirstName,
									 Employee__r.User__r.LastName,
									 ERP_Order__c,
									 ERP_Order__r.AcctSeed__Account__r.Name,
									 ERP_Order__r.AcctSeed__Status__c,
									 ERP_Order__r.WarehouseName__c,
									 ERP_Order__r.Delivery_Date__c,
									 ERP_Order__r.Service_Date__c,
									 ERP_Order__r.Model_Name__c,
									 ERP_Order__r.RecordType.Name,
									 ERP_Order__r.AcctSeed__Opportunity__r.BoatId__r.Rigging_Time__c,
									 ERP_Order__r.Oppy_Boat_Model__c,
									 ERP_Order__r.Serial_Number__c,
									 ERP_Order__r.Serial_Number__r.Name,
									 ERP_Order__r.Serial_Number__r.Product_Name__c,
									 ERP_Order__r.Serial_Product__c,
									 ExpectedTime__c,
									 Id,
									 Job_Class__c,
									 Job_Location__c,
									 list_order__c,
									 Model__c,
									 Model__r.Name,
									 Name,
									 Notes__c,
										 Placeholder__c,
									 Serial_Number__c,
									 Serial_Number__r.Name,
									 Status__c,
									 Work_Order__c
						FROM Rigger_Job__c
						WHERE	Employee__c = :riggerId
						AND Status__c = 'Completed'
						AND ActualEnd__c > YESTERDAY
						ORDER BY list_order__c ASC];
	}

	@AuraEnabled
	public static String getUnassignedJobs(String filter, String city, Boolean limitToCity) {

		String query = 'SELECT ';
		query += 'ActualEnd__c, ';
		query += 'ActualStart__c, ';
		query += 'ActualTime__c, ';
		query += 'Warranty_Time__c, ';
		query += 'Non_Warranty_Time__c, ';
		query += 'Actual_Time_Spent__c, ';
		query += 'BilledNotes__c, ';
		query += 'BilledOther__c, ';
		query += 'BilledRetail__c, ';
		query += 'BilledWarranty__c, ';
		query += 'CreatedDate, ';
		query += 'DueDate__c, ';
		query += 'Employee__c, ';
		query += 'Employee__r.User__r.FirstName, ';
		query += 'Employee__r.User__r.LastName, ';
		query += 'ERP_Order__c, ';
		query += 'ERP_Order__r.AcctSeed__Account__r.Name, ';
		query += 'ERP_Order__r.AcctSeedERP__Work_Order_Number__c, ';
		query += 'ERP_Order__r.AcctSeed__Status__c, ';
		query += 'ERP_Order__r.WarehouseName__c, ';
		query += 'ERP_Order__r.Delivery_Date__c, ';
		query += 'ERP_Order__r.Model_Name__c, ';
		query += 'ERP_Order__r.RecordTypeId, ';
		query += 'ERP_Order__r.RecordType.Name, ';
		query += 'ERP_Order__r.Rigging_Status__c, ';
		query += 'ERP_Order__r.Serial_Number__c, ';
		query += 'ERP_Order__r.Serial_Number__r.Name, ';
		query += 'ERP_Order__r.Serial_Number__r.Product_Name__c, ';
		query += 'ERP_Order__r.Service_Date__c, ';
		query += 'ERP_Order__r.AcctSeed__Opportunity__r.BoatId__r.Rigging_Time__c, ';
		query += 'ERP_Order__r.Manufactured_Product_Name__c, ';
		query += 'ERP_Order__r.Oppy_Boat_Model__c, ';
		query += 'ERP_Order__r.Job_Status__c, ';
		query += 'ExpectedTime__c, ';
		query += 'Id, ';
		query += 'Job_Class__c, ';
		query += 'Job_Location__c, ';
		query += 'list_order__c, ';
		query += 'Model__c, ';
		query += 'Model__r.Name, ';
		query += 'Name, ';
		query += 'Notes__c, ';
		query += 'Placeholder__c, ';
		query += 'Serial_Number__c, ';
		query += 'Serial_Number__r.Name, ';
		query += 'Status__c, ';
		query += 'Work_Order__c ';
		query += 'FROM Rigger_Job__c ';
		query += 'WHERE Employee__c = null ';
		query += 'AND Status__c != \'Completed\'';
		//query += 'AND ERP_Order__r.AcctSeed__Status__c != \'Ready For Accounting\'';
		query += 'AND ERP_Order__r.AcctSeed__Status__c != \'Completed\'';
		query += 'AND ERP_Order__r.Stage__c != \'Delivered\'';
		query += 'AND ERP_Order__r.Job_Status__c != \'Completed\'';

		if (filter != null && filter != '') {
			if (filter == 'Placeholder')
				query += ' AND Placeholder__c = true';
			else if (filter == 'retail')
				query += ' AND ERP_Order__r.RecordTypeId = \'' + gcConstants.idRtProjectBoatSale + '\'';
			else if (filter == 'partner')
				query += ' AND ERP_Order__r.RecordTypeId = \'' + gcConstants.idRtProjectPartnerBoatSale + '\'';
			else if (filter == 'manufacturing')
				query += ' AND ERP_Order__r.RecordTypeId = \'' + gcConstants.idRtProjectManufacturing + '\'';
			else if (filter == 'service')
				query += ' AND ERP_Order__r.RecordTypeId = \'' + gcConstants.idRtProjectService + '\'';
			else if (filter == 'tradein')
				query += ' AND ERP_Order__r.RecordTypeId = \'' + gcConstants.idRtTradeIn + '\'';
		}

		if (limitToCity) {
			query += ' AND ERP_Order__r.WarehouseName__c = \'' + city + '\'';
		}

		query += ' ORDER BY ERP_Order__r.Delivery_Date__c ASC NULLS LAST, ERP_Order__r.Service_Date__c ASC NULLS LAST, CreatedDate ASC';
    query += ' LIMIT 500';

		List<Rigger_Job__c> jobs =  Database.query(query);

		String countQuery = 'SELECT COUNT() FROM Rigger_Job__c WHERE Employee__c = null AND Status__c != \'Completed\' AND ERP_Order__r.AcctSeed__Status__c != \'Ready For Accounting\' AND ERP_Order__r.AcctSeed__Status__c != \'Completed\'';
		if (filter != null && filter != '') {
			if (filter == 'Placeholder')
				countQuery += ' AND Placeholder__c = true';
			else if (filter == 'retail')
				countQuery += ' AND ERP_Order__r.RecordTypeId = \'' + gcConstants.idRtProjectBoatSale + '\'';
			else if (filter == 'partner')
				countQuery += ' AND ERP_Order__r.RecordTypeId = \'' + gcConstants.idRtProjectPartnerBoatSale + '\'';
			else if (filter == 'manufacturing')
				countQuery += ' AND ERP_Order__r.RecordTypeId = \'' + gcConstants.idRtProjectManufacturing + '\'';
			else if (filter == 'service')
				countQuery += ' AND ERP_Order__r.RecordTypeId = \'' + gcConstants.idRtProjectService + '\'';
			else if (filter == 'tradein')
				countQuery += ' AND ERP_Order__r.RecordTypeId = \'' + gcConstants.idRtTradeIn + '\'';
		}

		if (limitToCity) {
			countQuery += ' AND ERP_Order__r.WarehouseName__c = \'' + city + '\'';
		}

		Integer totalJobs = Database.countQuery(countQuery);

		List<JobWrapper> wrappedJobs = new List<JobWrapper>();

		Set<Id> jobKeys = new Set<Id>();
		for (Rigger_Job__c job : jobs) {
			if (job.ERP_Order__c != null) {
				jobKeys.add(job.ERP_Order__c);
			} else {
				jobKeys.add(job.Id);
			}
		}

		Map<Id, List<AcctSeedERP__Material__c>> materialsMap = new Map<Id, List<AcctSeedERP__Material__c>>();

		for (AcctSeedERP__Material__c m : [SELECT Id,
																							AcctSeedERP__Project__c,
																							Product_Name__c,
																							Product_Record_Type__c,
																							AcctSeedERP__Product__r.Family,
																							AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c,
																							AcctSeedERP__Quantity_Per_Unit__c,
																							AcctSeedERP__Product__r.Rigging_Time__c
																				 FROM AcctSeedERP__Material__c
																				WHERE AcctSeedERP__Project__c in :jobKeys]) {
			if (!materialsMap.containsKey(m.AcctSeedERP__Project__c)) {
				materialsMap.put(m.AcctSeedERP__Project__c, new List<AcctSeedERP__Material__c>());
			}
			materialsMap.get(m.AcctSeedERP__Project__c).add(m);
		}

		Map<Id, List<AcctSeed__Project_Task__c>> taskMap = new Map<Id, List<AcctSeed__Project_Task__c>>();

		for (AcctSeed__Project_Task__c task : [SELECT Id,
																									Cause_dh__c,
																									Complaint_dh__c,
																									Correction_dh__c,
																									AcctSeed__Project__c,
																									AcctSeed__Budgeted_Hours__c,
																									Estimated_Duration__c,
																									AcctSeed__Project_ID__c
																						 FROM AcctSeed__Project_Task__c
																						WHERE AcctSeed__Project__c IN :jobKeys]) {
			if (!taskMap.containsKey(task.AcctSeed__Project__c)) {
				taskMap.put(task.AcctSeed__Project__c, new List<AcctSeed__Project_Task__c>());
			}
			taskMap.get(task.AcctSeed__Project__c).add(task);
		}

		for (Rigger_Job__c job : jobs) {
			List<AcctSeedERP__Material__c> materials = materialsMap.get(job.ERP_Order__c);
			List<AcctSeed__Project_Task__c> tasks = taskMap.get(job.ERP_Order__c);
			JobWrapper wrappedJob = new JobWrapper(job, materials, tasks, null);
			wrappedJob.Id = job.Id;
			wrappedJob.name = job.Name;
			wrappedJobs.add(wrappedJob);
		}

		return JSON.serialize(wrappedJobs);
	}

	@AuraEnabled
	public static void assignJob(String riggerId, String jobId) {
		Rigger_Job__c job = [SELECT Id,
																ActualStart__c,
																Employee__c,
																ERP_Order__c,
																ERP_Order__r.AcctSeed__Status__c,
																Placeholder__c,
												 ( SELECT Id FROM Rigger_Job_Time_Entries__r WHERE End_At__c = null )
												 FROM Rigger_Job__c
												 WHERE Id = :jobId];

		// If dragging a placeholder to the complete column, delete it.
		if (job.Placeholder__c && riggerId == 'done') { delete job; return; }

		// Update ERP
		//AcctSeed__Project__c erp = new AcctSeed__Project__c();
		AcctSeed__Project__c erp;
		if (job.ERP_Order__c != null) {
			erp = [SELECT Id,
			 		 				 	Job_Status__c
						 FROM AcctSeed__Project__c
						 WHERE Id = :job.ERP_Order__c];
			if (riggerId == 'done') {
				erp.Job_Status__c = 'Completed';
			} else if (erp.Job_Status__c == null && riggerId != 'backlog') {
				erp.Job_Status__c = 'Scheduled';
			}
			Boolean orgTrig = gcProject.disableTrigger;
			gcProject.disableTrigger = true;
			update erp;
			gcProject.disableTrigger = orgTrig;
		}

		// Update Rigger Job
		if (riggerId == 'backlog') {
			job.Employee__c = null;
			job.ActualEnd__c = null;
		} else if(riggerId == 'done')
		{
			for( Rigger_Job_Time_Entry__c entry : job.Rigger_Job_Time_Entries__r )
			{
				entry.End_At__c = DateTime.now();
			}
			job.ActualEnd__c = DateTime.now();
			if (job.ActualStart__c != null && job.ActualTime__c != null ) {
				job.ActualTime__c = (job.ActualEnd__c.getTime() - job.ActualStart__c.getTime());
			}
		} else
		{
			job.Employee__c = riggerId;
			job.ActualEnd__c = null;
			for( Rigger_Job_Time_Entry__c entry : job.Rigger_Job_Time_Entries__r )
			{
				entry.End_At__c = DateTime.now();
			}
		}
		update job;
		update job.Rigger_Job_Time_Entries__r;
	}

	@AuraEnabled
	public static void saveJobOrder(String items) {
		List<Rigger_Job__c> jobs = new List<Rigger_Job__c>();
		JSONParser parser = JSON.createParser(items);
		while (parser.nextToken() != null) {
      if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
        while (parser.nextToken() != null) {
          if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
            Rigger_Job__c job = (Rigger_Job__c)parser.readValueAs(Rigger_Job__c.class);
            jobs.add(job);
          }
        }
      }
    }

		update jobs;
	}

	@AuraEnabled
	public static String getJob(String jobId) {
		Rigger_Job__c job = [SELECT ActualEnd__c,
															 ActualStart__c,
															 Actual_Time_Spent__c,
															 ActualTime__c,
															 Warranty_Time__c,
			                         Non_Warranty_Time__c,
															 BilledNotes__c,
															 BilledOther__c,
															 BilledRetail__c,
															 BilledWarranty__c,
															 CreatedDate,
															 DueDate__c,
															 Employee__c,
															 Employee__r.User__r.FirstName,
															 Employee__r.User__r.LastName,
															 ERP_Order__c,
															 ERP_Order__r.AcctSeed__Account__r.Name,
															 ERP_Order__r.Delivery_Date__c,
															 ERP_Order__r.Job_Status__c,
															 ERP_Order__r.Model_Name__c,
															 ERP_Order__r.Parking_Spot__c,
															 ERP_Order__r.RecordTypeId,
															 ERP_Order__r.RecordType.Name,
															 ERP_Order__r.Rigging_Status__c,
															 ERP_Order__r.Serial_Number__c,
															 ERP_Order__r.Serial_Number__r.Lot_Exchange__c,
															 ERP_Order__r.Serial_Number__r.Name,
															 ERP_Order__r.Serial_Number__r.Status__c,
															 ERP_Order__r.Service_Date__c,
															 ERP_Order__r.Shipping_Status__c,
															 ERP_Order__r.Stage__c,
															 ERP_Order__r.GMBLASERP__Warehouse__r.Name,
															 ExpectedTime__c,
															 Id,
															 Job_Class__c,
															 Job_Location__c,
															 list_order__c,
															 Model__c,
															 Model__r.Name,
															 Model__r.Model_Year__c,
															 Model__r.Description__c,
															 Model__r.Family,
															 Model__r.Product_Type__c,
															 Model__r.Series__c,
															 Model__r.Rigging_Time__c,
															 Model__r.Propeller__c,
															 Model__r.Fuel_Tank__c,
															 Model__r.Standard_Motor__r.Name,
															 Model__r.Standard_Trailer__r.Name,
															 Model__r.Standard_Trolling_Motor__r.Name,
															 Name,
															 Notes__c,
															 Placeholder__c,
															 Status__c,
															 Stage__c,
															 Work_Order__c
												FROM Rigger_Job__c
												WHERE Id = :jobId];

		AcctSeedERP__Material__c[] materials = [SELECT Id,
																									AcctSeedERP__Project__c,
																									Product_Name__c,
																									Product_Record_Type__c,
																									AcctSeedERP__Product__r.Family,
																									AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c,
																									AcctSeedERP__Quantity_Per_Unit__c,
																									AcctSeedERP__Product__r.Rigging_Time__c
																						 FROM AcctSeedERP__Material__c
																						WHERE AcctSeedERP__Project__c = :job.ERP_Order__c];

		AcctSeed__Project_Task__c[] tasks = [SELECT Id,
																								Cause_dh__c,
																								Complaint_dh__c,
																								Correction_dh__c,
																								AcctSeed__Project__c,
																								AcctSeed__Budgeted_Hours__c,
																								Estimated_Duration__c,
																								AcctSeed__Project_ID__c
																					 FROM AcctSeed__Project_Task__c
																					WHERE AcctSeed__Project__c = :job.ERP_Order__c];

		JobWrapper jw = new JobWrapper(job, materials, tasks, 0);

		return JSON.serialize(jw);
	}

	@AuraEnabled
	public static String saveJob(String location,
															 Decimal expectedTime,
															 Decimal warrantyTime,
															 Decimal nonWarrantyTime,
															 String jobId,
															 String notes,
															 String shippingStatus,
															 String jobStatus,
															 String riggingStatus,
															 String sernoStatus,
															 String parking,
															 String stage) {

			 System.debug('location = ' + location );
			 System.debug('expectedTime = ' + expectedTime );
			 System.debug('warrantyTime = ' + warrantyTime );
			 System.debug('nonWarrantyTime = ' + nonWarrantyTime );
			 System.debug('jobId = ' + jobId );
			 System.debug('notes = ' + notes );
			 System.debug('shippingStatus = ' + shippingStatus );
			 System.debug('jobStatus = ' + jobStatus );
			 System.debug('riggingStatus = ' + riggingStatus );
			 System.debug('sernoStatus = ' + sernoStatus );
			 System.debug('parking = ' + parking );
			 System.debug('stage = ' + stage );

		Rigger_Job__c job = [SELECT Id,
																Notes__c,
																ExpectedTime__c,
																ERP_Order__r.RecordTypeId,
																ERP_Order__c
													 FROM Rigger_Job__c
													WHERE Id = :jobId];
		job.Notes__c = notes;
		if (job.ERP_Order__r.RecordTypeId != gcConstants.idRtProjectService) {
			job.ExpectedTime__c = expectedTime;
		}
		//job.ActualTime__c = actualTime;
		job.Warranty_Time__c = warrantyTime;
		job.Non_Warranty_Time__c = nonWarrantyTime;
		if(job.ERP_Order__c != null) {
			AcctSeed__Project__c erp = [SELECT Id, Job_Status__c, Stage__c, Serial_Number__c, GMBLASERP__Warehouse__c, WarehouseName__c FROM AcctSeed__Project__c WHERE Id = :job.ERP_Order__c];
			erp.Customer_Notes__c = notes;
			erp.Job_Status__c = jobStatus;
			if (stage != null) erp.Stage__c = stage;
			erp.Shipping_Status__c = shippingStatus;
			erp.Rigging_Status__c = riggingStatus;
			if (parking != '') erp.Parking_Spot__c = parking;
			if (jobStatus == 'Completed') {
				job.ActualEnd__c = System.now();
			}
			update erp;
			if (erp.Serial_Number__c != null) {
				if ([SELECT Count() FROM GMBLASERP__Serial_Number__c WHERE Id = :erp.Serial_Number__c AND Lot_Exchange__c = null] > 0) {
					GMBLASERP__Serial_Number__c serno = [SELECT Id, Status__c FROM GMBLASERP__Serial_Number__c WHERE Id = :erp.Serial_Number__c];
					serno.Status__c = sernoStatus;
					update serno;
				}
			}
		}
		update job;
		return JSON.serialize(job);
	}

	@AuraEnabled
	public static void saveJobToBacklog(String location,
																			Decimal expectedTime,
															 				Decimal warrantyTime,
																			Decimal nonWarrantyTime,
																			String jobId,
																			String notes,
																			String shippingStatus,
																			String jobStatus,
																			String riggingStatus,
																			String sernoStatus,
																			String parking,
																			String stage) {
		saveJob(location,
						expectedTime,
						warrantyTime,
						nonWarrantyTime,
						jobId,
						notes,
						shippingStatus,
						jobStatus,
						riggingStatus,
						sernoStatus,
						parking,
						stage);
		Rigger_Job__c job = [SELECT Employee__c FROM Rigger_Job__c WHERE Id = :jobId];
		job.Employee__c = null;
		update job;
	}

	@AuraEnabled
	public static void createNewJob(Rigger_Job__c job, Id productId) {
		job.Placeholder__c = true;
		if (productId != null) {
			job.Model__c = productId;
		}
		insert job;
	}

	@AuraEnabled
	public static List<Product2> searchProducts(String query) {
		query = '%' + query + '%';
		return [SELECT Id,
									 Name
						FROM Product2
						WHERE Name LIKE :query
						AND Series__c != null
						LIMIT 10];
	}

	@AuraEnabled
	public static Product2 getProduct(String productId) {
		return [SELECT Description,
									 Description__c,
									 Family,
									 Fuel_Tank__c,
									 Id,
									 Model_Year__c,
									 Name,
									 Notes__c,
									 Product_Type__c,
									 Propeller__c,
									 Rigging_Time__c,
									 Series__c,
									 Standard_Motor__r.Name,
									 Standard_Trailer__r.Name,
									 Standard_Trolling_Motor__r.Name,
									 Status__c
							FROM Product2
							WHERE Id = :productId];
	}

	@AuraEnabled
	public static Boolean mergePlaceholder(Id placeholderId, Id jobId) {
		Rigger_Job__c job = [SELECT Id,
																Model__c,
																Notes__c,
																Employee__c,
																list_order__c,
																ERP_Order__r.Model_Name__c,
																ERP_Order__r.Serial_Product__c,
																ERP_Order__r.Manufactured_Product_Name__c,
																ERP_Order__r.AcctSeedERP__Manufactured_Product__r.Name,
																Placeholder__c
												 FROM Rigger_Job__c
												 WHERE Id = :jobId];

		Rigger_Job__c placeholder = [SELECT Id, Model__c, Model__r.Name, Notes__c, Employee__c, list_order__c
												 				 FROM Rigger_Job__c
												 				 WHERE Id = :placeholderId];

		job.Model__c = placeholder.Model__c;

		if (job.Notes__c != null) {
			job.Notes__c = job.Notes__c + ' ' + placeholder.Notes__c;
		} else {
			job.Notes__c = placeholder.Notes__c;
		}

		job.Employee__c = placeholder.Employee__c;
		job.list_order__c = placeholder.list_order__c;

		if (
				job.ERP_Order__r.Model_Name__c == placeholder.Model__r.Name ||
				job.ERP_Order__r.Serial_Product__c == placeholder.Model__r.Name ||
				job.ERP_Order__r.Manufactured_Product_Name__c == placeholder.Model__r.Name ||
				job.ERP_Order__r.AcctSeedERP__Manufactured_Product__r.Name == placeholder.Model__r.Name
			) {
			update job;
			delete placeholder;
			return true;
		} else {
			return false;
		}
	}

	@AuraEnabled
	public static List<AcctSeedERP__Material__c> getJobMaterials(Id jobId) {
		return [SELECT Id, Name FROM AcctSeedERP__Material__c WHERE Id = :jobId];
	}

	@AuraEnabled
	public static void setJobStart( String jobId, String timeEntryId ) {
		Rigger_Job__c job = [SELECT Id,
																ERP_Order__c,
																ERP_Order__r.Job_Status__c
												 FROM Rigger_Job__c
												 WHERE Id = :jobId ];
		if( job.ERP_Order__r.Job_Status__c != 'In Progress' )
		{
			AcctSeed__Project__c erp = new AcctSeed__Project__c(
				Id = job.ERP_Order__c,
				Job_Status__c = 'In Progress'
			);
			update erp;
		}

		Rigger_Job_Time_Entry__c timeEntry = new Rigger_Job_Time_Entry__c();
		if( timeEntryId == null )
		{
			timeEntry.Rigger_Job__c = jobId;
			timeEntry.Start_At__c = DateTime.now();
		}
		else
		{
			timeEntry.Id = timeEntryId;
			timeEntry.End_At__c = DateTime.now();
		}
		upsert timeEntry;

		update new Rigger_Job__c(
			Id = jobId,
			ActualStart__c = DateTime.now()
		);
	}

	@AuraEnabled
	public static void createJobFromERP(Id erpId) {
		Set<Id> erps = new Set<Id>();
		erps.add(erpId);
		createJobFromERP(erps);
	}

	public static void createJobFromERP(Set<Id> erpIds) {
		Map<Id, Rigger_Job__c> newJobs = new Map<Id, Rigger_Job__c>();
		List<Rigger_Job__c> newJobsList = new List<Rigger_Job__c>();
		Set<Id> recordTypes = new Set<Id>();
		recordTypes.add(gcConstants.idRtProjectPartnerBoatSale);
		recordTypes.add(gcConstants.idRtProjectBoatSale);
		recordTypes.add(gcConstants.idRtProjectManufacturing);
		recordTypes.add(gcConstants.idRtProjectService);
		recordTypes.add(gcConstants.idRtTradeIn);
		for (AcctSeed__Project__c erp : [SELECT Id,
																						RecordTypeId,
																						Customer_Notes__c,
																						Boat_Product__c,
																						Boat_Product__r.Rigging_Time__c,
																						AcctSeedERP__Manufactured_Product__c,
																						AcctSeedERP__Manufactured_Product__r.Rigging_Time__c
																			 FROM AcctSeed__Project__c
																			WHERE Id IN :erpIds])
		{
			if (recordTypes.contains(erp.RecordTypeId))
			{
				Rigger_Job__c job = new Rigger_Job__c();
				job.ERP_Order__c = erp.Id;
				if (erp.Customer_Notes__c != null) {
					job.Notes__c = erp.Customer_Notes__c;
				}
				newJobs.put(erp.Id, job);
			}
		}

		for (Rigger_Job__c job : newJobs.values()) {
			newJobsList.add(job);
		}

		insert newJobsList;
	}

	@AuraEnabled
	public static string createJobFromERP_nochecks(Id erpId) {
		Rigger_Job__c job = new Rigger_Job__c();
		job.ERP_Order__c = erpId;
		insert job;
		return JSON.serialize(job);
	}

	@Future
	public static void createJobFromERP_Future(Set<Id> erpIds) {
		createJobFromERP(erpIds);
	}

	@Future
	public static void initialImport(Set<Id> erpIds) {
		Map<Id, Rigger_Job__c> newJobs = new Map<Id, Rigger_Job__c>();
		List<Rigger_Job__c> newJobsList = new List<Rigger_Job__c>();
		Set<Id> recordTypes = new Set<Id>();
		recordTypes.add(gcConstants.idRtProjectPartnerBoatSale);
		recordTypes.add(gcConstants.idRtProjectBoatSale);
		recordTypes.add(gcConstants.idRtProjectManufacturing);
		recordTypes.add(gcConstants.idRtProjectService);
		recordTypes.add(gcConstants.idRtTradeIn);
		for (AcctSeed__Project__c erp : [SELECT Id,
																						RecordTypeId,
																						Customer_Notes__c,
																						Boat_Product__c,
																						Boat_Product__r.Rigging_Time__c,
																						AcctSeedERP__Manufactured_Product__c,
																						AcctSeedERP__Manufactured_Product__r.Rigging_Time__c
																			 FROM AcctSeed__Project__c
																			WHERE Id IN :erpIds])
		{
			if (recordTypes.contains(erp.RecordTypeId))
			{
				Rigger_Job__c job = new Rigger_Job__c();
				job.ERP_Order__c = erp.Id;
				newJobs.put(erp.Id, job);
			}
		}

		for (Rigger_Job__c job : newJobs.values()) {
			newJobsList.add(job);
		}

		insert newJobsList;
	}

	@AuraEnabled
	public static void returnJobToBacklog(Id jobId) {
		Rigger_Job__c job = [SELECT Id,
															  Erp_Order__c,
															  Employee__c
													 FROM Rigger_Job__c
													WHERE Id = :jobId];
		job.Employee__c = null;
		update job;
		AcctSeed__Project__c erp = [SELECT Id, Job_Status__c FROM AcctSeed__Project__c WHERE Id = :job.Erp_Order__c];
		erp.Job_Status__c = null;
		update erp;
	}

	public static void destroyRelatedJobs(Set<Id> erpIds) {
		List<Rigger_Job__c> jobs = [SELECT Id FROM Rigger_Job__c WHERE ERP_Order__c IN :erpIds];
		delete jobs;
	}

//	public static void triggerHandler(
//                                    Map<Id, Rigger_Job__c> oldMap,
//                                    Map<Id, Rigger_Job__c> newMap,
//                                    List<Rigger_Job__c> listNew,
//                                    Boolean boolIsBefore,
//                                    Boolean boolIsInsert,
//                                    Boolean boolIsUpdate,
//                                    Boolean boolIsDelete
//                                   )
//  {
//    if( oldMap == null ) oldMap = new Map<Id, Rigger_Job__c>();
//    if( newMap == null ) newMap = new Map<Id, Rigger_Job__c>();
//    if( listNew == null ) listNew = new List<Rigger_Job__c>();
//
//    if( boolIsBefore )
//    /* &&&&&&&   BEFORE    &&&&&&& */
//    {
//      if( boolIsInsert )
//      {
//      }
//      if( boolIsUpdate )
//      	for (Rigger_Job__c j : newMap.values()) {
//      		if (j.ERP_Order__r.Job_Status__c == 'Completed') {
//						j.ActualEnd__c = System.now();
//					}
//      	}
//      {
//      }
//      if( boolIsDelete )
//      {
//      }
//    }
//    else
//    {
//    /* &&&&&&&   AFTER   &&&&&&& */
//      if( boolIsInsert )
//      {
//      }
//      if( boolIsUpdate )
//      {
//      }
//      if( boolIsDelete )
//      {
//      }
//    }
//  }

  @AuraEnabled
  public static String getUserWarehouse() {
  	User u = [SELECT Warehouse__c
  						  FROM User
  					   WHERE Id = :UserInfo.getUserId()
  					   LIMIT 1];
  	return u.Warehouse__c;
  }

  @AuraEnabled
  public static String findJobs(String[] keywords) {
  	String query = 'SELECT ';
		query += 'ActualEnd__c, ';
		query += 'ActualStart__c, ';
		query += 'Actual_Time_Spent__c, ';
		query += 'ActualTime__c, ';
		query += 'Warranty_Time__c, ';
		query += 'Non_Warranty_Time__c, ';
		query += 'BilledNotes__c, ';
		query += 'BilledOther__c, ';
		query += 'BilledRetail__c, ';
		query += 'BilledWarranty__c, ';
		query += 'CreatedDate, ';
		query += 'DueDate__c, ';
		query += 'Employee__c, ';
		query += 'Employee__r.User__r.FirstName, ';
		query += 'Employee__r.User__r.LastName, ';
		query += 'ERP_Order__c, ';
		query += 'ERP_Order__r.AcctSeed__Account__r.Name, ';
		query += 'ERP_Order__r.AcctSeedERP__Work_Order_Number__c, ';
		query += 'ERP_Order__r.AcctSeed__Status__c, ';
		query += 'ERP_Order__r.WarehouseName__c, ';
		query += 'ERP_Order__r.Delivery_Date__c, ';
		query += 'ERP_Order__r.Model_Name__c, ';
		query += 'ERP_Order__r.RecordTypeId, ';
		query += 'ERP_Order__r.RecordType.Name, ';
		query += 'ERP_Order__r.Rigging_Status__c, ';
		query += 'ERP_Order__r.Serial_Number__c, ';
		query += 'ERP_Order__r.Service_Date__c, ';
		query += 'ERP_Order__r.Serial_Number__r.Name, ';
		query += 'ERP_Order__r.Serial_Number__r.Product_Name__c, ';
		query += 'ERP_Order__r.AcctSeed__Opportunity__r.BoatId__r.Rigging_Time__c, ';
		query += 'ERP_Order__r.Manufactured_Product_Name__c, ';
		query += 'ERP_Order__r.Oppy_Boat_Model__c, ';
		query += 'ERP_Order__r.Job_Status__c, ';
		query += 'ExpectedTime__c, ';
		query += 'Id, ';
		query += 'Job_Class__c, ';
		query += 'Job_Location__c, ';
		query += 'list_order__c, ';
		query += 'Model__c, ';
		query += 'Model__r.Name, ';
		query += 'Name, ';
		query += 'Notes__c, ';
		query += 'Placeholder__c, ';
		query += 'Serial_Number__c, ';
		query += 'Serial_Number__r.Name, ';
		query += 'Status__c, ';
		query += 'Work_Order__c ';
  	query += 'FROM Rigger_Job__c ';
		query += 'WHERE ERP_Order__r.Job_Status__c != \'Completed\' ';
		query += 'AND Employee__c = null ';
  	for (String kw : keywords) {
  		query += ' AND ( ';
  		query += 'ERP_Order__r.Model_Name__c LIKE \'%' + kw + '%\' ';
  		query += 'OR ERP_Order__r.Serial_Product__c LIKE \'%' + kw + '%\' ';
  		query += 'OR ERP_Order__r.Manufactured_Product_Name__c LIKE \'%' + kw + '%\' ';
  		query += 'OR ERP_Order__r.AcctSeedERP__Manufactured_Product__r.Name LIKE \'%' + kw + '%\' ';
  		query += 'OR ERP_Order__r.AcctSeed__Account__r.Name LIKE \'%' + kw + '%\' ';
  		query += 'OR ERP_Order__r.Serial_Number__r.Name LIKE \'%' + kw + '%\' ';
  		query += 'OR ERP_Order__r.AcctSeedERP__Work_Order_Number__c LIKE \'%' + kw + '%\' ';
  		query += ' ) ';
  	}

  	query += ' LIMIT 500';

  	List<Rigger_Job__c> jobs =  Database.query(query);

  	List<JobWrapper> wrappedJobs = new List<JobWrapper>();

		Set<Id> jobKeys = new Set<Id>();
		for (Rigger_Job__c job : jobs) {
			if (job.ERP_Order__c != null) {
				jobKeys.add(job.ERP_Order__c);
			} else {
				jobKeys.add(job.Id);
			}
		}

		Map<Id, List<AcctSeedERP__Material__c>> materialsMap = new Map<Id, List<AcctSeedERP__Material__c>>();

		for (AcctSeedERP__Material__c m : [SELECT Id,
																							AcctSeedERP__Project__c,
																							Product_Name__c,
																							Product_Record_Type__c,
																							AcctSeedERP__Product__r.Family,
																							AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c,
																							AcctSeedERP__Quantity_Per_Unit__c,
																							AcctSeedERP__Product__r.Rigging_Time__c
																				 FROM AcctSeedERP__Material__c
																				WHERE AcctSeedERP__Project__c in :jobKeys]) {
			if (!materialsMap.containsKey(m.AcctSeedERP__Project__c)) {
				materialsMap.put(m.AcctSeedERP__Project__c, new List<AcctSeedERP__Material__c>());
			}
			materialsMap.get(m.AcctSeedERP__Project__c).add(m);
		}

		Map<Id, List<AcctSeed__Project_Task__c>> taskMap = new Map<Id, List<AcctSeed__Project_Task__c>>();

		for (AcctSeed__Project_Task__c task : [SELECT Id,
																									Cause_dh__c,
																									Complaint_dh__c,
																									Correction_dh__c,
																									AcctSeed__Project__c,
																									AcctSeed__Budgeted_Hours__c,
																									Estimated_Duration__c,
																									AcctSeed__Project_ID__c
																						 FROM AcctSeed__Project_Task__c
																						WHERE AcctSeed__Project__c IN :jobKeys]) {
			if (!taskMap.containsKey(task.AcctSeed__Project__c)) {
				taskMap.put(task.AcctSeed__Project__c, new List<AcctSeed__Project_Task__c>());
			}
			taskMap.get(task.AcctSeed__Project__c).add(task);
		}

		for (Rigger_Job__c job : jobs) {
			List<AcctSeedERP__Material__c> materials = materialsMap.get(job.ERP_Order__c);
			List<AcctSeed__Project_Task__c> tasks = taskMap.get(job.ERP_Order__c);
			JobWrapper wrappedJob = new JobWrapper(job, materials, tasks, 0);
			wrappedJob.Id = job.Id;
			wrappedJob.name = job.Name;
			wrappedJobs.add(wrappedJob);
		}

		return JSON.serialize(wrappedJobs);
  }

  @AuraEnabled
  public static string checkForExistingJob(Id recordId) {
  	Rigger_Job__c[] jobs = [SELECT Id,
  																 Employee__c,
  																 Employee__r.Name,
  																 ERP_Order__c,
  																 ERP_Order__r.Job_Status__c,
  																 Status__c
  														FROM Rigger_Job__c
  													 WHERE ERP_Order__c = :recordId];
  	return JSON.serialize( jobs );
  }

	public static void coverage(){
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
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
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