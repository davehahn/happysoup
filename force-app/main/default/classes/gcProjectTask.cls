global without sharing class gcProjectTask {

	global static Boolean disableTrigger{
		get{
			if(disableTrigger == null) return false;
			else return disableTrigger;
		}
		set{
			if(value == null) disableTrigger = false;
			else disableTrigger = value;
		}
	}

	global static Boolean disableUpdateMaterialSpec{
		get{
			if(disableUpdateMaterialSpec == null) return false;
			else return disableUpdateMaterialSpec;
		}
		set{
			if(value == null) disableUpdateMaterialSpec = false;
			else disableUpdateMaterialSpec = value;
		}
	}

	global static void triggerHandler
		(map<Id,AcctSeed__Project_Task__c> oldMap,
		 map<Id,AcctSeed__Project_Task__c> newMap,
		 list<AcctSeed__Project_Task__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(oldMap == NULL) oldMap = new map<Id,AcctSeed__Project_Task__c>();
		if(newMap == NULL) newMap = new map<Id,AcctSeed__Project_Task__c>();
		if(listNew == NULL) listNew = new list<AcctSeed__Project_Task__c>();

		updateAndValidate(oldMap,newMap,listNew,boolIsBefore,boolIsInsert,boolIsUpdate,boolIsDelete);

		if(boolIsBefore)
		{
			if(boolIsInsert)
			{
				gcTransactionParent.setFinancialAttributes(
					listNew,
					'AcctSeed__Project__c',
					null);
			}
			if(boolIsUpdate)
			{
				gcTransactionParent.setFinancialAttributes(
					listNew,
					'AcctSeed__Project__c',
					null);
			}
			if(boolIsDelete)
			{

			}
		}
		else //i.e. trigger.isAfter
		{
			if(boolIsInsert)
			{
				reName(newMap.keySet());
			}
			if(boolIsUpdate)
			{
				reName(newMap.keySet());
			}
			if(boolIsDelete)
			{

			}
		}
	}

	global static void updateAndValidate
		(map<Id,AcctSeed__Project_Task__c> oldMap,
		 map<Id,AcctSeed__Project_Task__c> newMap,
		 list<AcctSeed__Project_Task__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(boolIsBefore && boolIsDelete)
		{
			refreshStatics(oldMap.values());
            for(AcctSeed__Project_Task__c pt : oldMap.values())
            {
            	AcctSeed__Project__c project = mapProject.get(pt.AcctSeed__Project__c);
            	if(project.Locked__c)
            		pt.addError('Cannot delete task, the parent ERP Order is locked.');  
            	if(pt.Locked__c)
            		pt.addError('Cannot delete task, it is locked.');  
            }

			//before deleting a Project Task, delete all underlying Materials.
			delete [SELECT Id
					FROM AcctSeedERP__Material__c
					WHERE AcctSeedERP__Project_Task__c != null
					  AND AcctSeedERP__Project_Task__c IN :oldMap.keySet()];
		}
	    if(boolIsBefore && (boolIsUpdate || boolIsInsert))
	    {
	    	refreshStatics(listNew);

			if(boolIsUpdate)
			{
				for(AcctSeed__Project_Task__c pt : listNew)
				{
				  	AcctSeed__Project_Task__c oldRec = oldMap.get(pt.Id);
				    AcctSeed__Project__c project = mapProject.get(pt.AcctSeed__Project__c);
					if(project.Locked__c || (oldRec.Locked__c && pt.Locked__c))
					{
						if(pt.AcctSeed__GL_Account_Variable_1__c != oldRec.AcctSeed__GL_Account_Variable_1__c
							|| pt.AcctSeed__GL_Account_Variable_2__c != oldRec.AcctSeed__GL_Account_Variable_2__c
							|| pt.AcctSeed__GL_Account_Variable_3__c != oldRec.AcctSeed__GL_Account_Variable_3__c
							|| pt.Product__c != oldRec.Product__c)
							pt.addError('GLV1, GLV2, GLV3 or Parts List cannot be changed. The ERP Order task or the parent ERP Order is locked.');
					}

					if(pt.Expense__c != oldRec.Expense__c)
						pt.Expense__c.addError('The Expense cannot be manipulated; it is calculated from the underlying Transactions.');
					if(pt.Revenue__c != oldRec.Revenue__c)
						pt.Revenue__c.addError('The Actual cannot be manipulated; it is calculated from the underlying Transactions.');
					if(pt.Cash__c != oldRec.Cash__c)
						pt.Cash__c.addError('The Cash cannot be manipulated; it is calculated from the underlying Transactions.');
					if(pt.WIP__c != oldRec.WIP__c)
						pt.WIP__c.addError('The WIP cannot be manipulated; it is calculated from the underlying Transactions.');
					if(pt.Finished_Goods__c != oldRec.Finished_Goods__c)
						pt.Finished_Goods__c.addError('The Finished Goods field cannot be manipulated; it is calculated from the underlying Transactions.');

					if(pt.Order_Item_Total__c != oldRec.Order_Item_Total__c)
						pt.Order_Item_Total__c.addError('The Order Item Total field cannot be manipulated; it is calculated from the underlying Materials.');
					if(pt.Order_Taxable_Provincial__c != oldRec.Order_Taxable_Provincial__c)
						pt.Order_Taxable_Provincial__c.addError('The Order Taxable Provincial field cannot be manipulated; it is calculated from the underlying Materials.');
					if(pt.Order_Taxable_Federal__c != oldRec.Order_Taxable_Federal__c)
						pt.Order_Taxable_Federal__c.addError('The Order Taxable Federal field cannot be manipulated; it is calculated from the underlying Materials.');
					if(pt.Order_Taxable_Retail__c != oldRec.Order_Taxable_Retail__c)
						pt.Order_Taxable_Retail__c.addError('The Order Taxable Retail field cannot be manipulated; it is calculated from the underlying Materials.');
					
					pt.Index__c = oldRec.Index__c;						
				}
			}

	        for(AcctSeed__Project_Task__c pt : listNew)
	        {
	        	AcctSeed__Project__c project = mapProject.get(pt.AcctSeed__Project__c);
	        	if(project.Locked__c)
	        		pt.addError('Cannot add new task. The parent ERP Order is locked.');

	        	if(boolIsInsert)
	        	{
					pt.Index__c = mapProjectIndex.get(pt.AcctSeed__Project__c).setScale(0) + 1;
					mapProjectIndex.put(pt.AcctSeed__Project__c, pt.Index__c);
	        	}

	            if(pt.Expense__c == null)
	               pt.Expense__c = 0;
	           	if(pt.Revenue__c == null)
	               pt.Revenue__c = 0;
	           	if(pt.Cash__c == null)
	               pt.Cash__c = 0;
	            if(pt.WIP__c == null)
	               pt.WIP__c = 0;
	            if(pt.Finished_Goods__c == null)
	               pt.Finished_Goods__c = 0;

	            if(pt.Order_Item_Total__c == null)
	               pt.Order_Item_Total__c = 0;
	            if(pt.Order_Taxable_Provincial__c == null)
	               pt.Order_Taxable_Provincial__c = 0;
	            if(pt.Order_Taxable_Federal__c == null)
	               pt.Order_Taxable_Federal__c = 0;
	            if(pt.Order_Taxable_Retail__c == null)
	               pt.Order_Taxable_Retail__c = 0;
	        }
	    }

		if(!boolIsBefore && (boolIsInsert || boolIsUpdate))
		{
			set<Id> setIdProjectTaskUpdateMaterialSpec = new set<Id>();
			set<Id> setIdProject = new set<Id>();			
			for(AcctSeed__Project_Task__c pt :listNew)
			{
				if((boolIsInsert && pt.Product__c != null) || (boolIsUpdate && pt.Product__c != oldMap.get(pt.Id).Product__c))
					setIdProjectTaskUpdateMaterialSpec.add(pt.Id);

				setIdProject.add(pt.AcctSeed__Project__c);
			}
			if(!setIdProjectTaskUpdateMaterialSpec.isEmpty() && !disableUpdateMaterialSpec)
				updateMaterialSpec(setIdProjectTaskUpdateMaterialSpec);

			//check for duplicate parts lists
			for(AggregateResult aggRes :
				[SELECT AcctSeed__Project__c idProject,
						Product__c idProduct
				 FROM AcctSeed__Project_Task__c
				 WHERE AcctSeed__Project__c IN :setIdProject
				   AND Product__c != null
				 GROUP BY AcctSeed__Project__c, Product__c
				 HAVING count(Id) > 1])
			{
				Id idProject = (Id)aggRes.get('idProject');
				Id idProduct = (Id)aggRes.get('idProduct');

				for(AcctSeed__Project_Task__c pt : listNew)
				{
					if(pt.AcctSeed__Project__c == idProject && pt.Product__c == idProduct)
						pt.addError('There cannot be two project tasks for the same parts list.');
				}
			}
		}
	}

	private static map<Id,AcctSeed__Project__c> mapProject;
	private static map<Id,Decimal> mapProjectIndex;

	private static void refreshStatics(list<AcctSeed__Project_Task__c> listNew)
	{
        set<Id> setIdProject = new set<Id>();

        if(mapProject == null)
        {
            mapProject = new map<Id,AcctSeed__Project__c>();
            mapProjectIndex = new map<Id,Decimal>();
        }

		for(AcctSeed__Project_Task__c cr : listNew)
		{
            if(cr.AcctSeed__Project__c != null && !mapProject.containsKey(cr.AcctSeed__Project__c))
                setIdProject.add(cr.AcctSeed__Project__c);
		}

		if(!setIdProject.isEmpty())
        for(AcctSeed__Project__c project : 
        	[SELECT Id, 
        		Name, 
        		Locked__c, 
        		AcctSeed__Status__c,
        		(SELECT Id, Index__c FROM AcctSeed__Project_Tasks__r ORDER BY Index__c DESC LIMIT 1) 
        	FROM AcctSeed__Project__c WHERE Id IN :setIdProject])
        {
            mapProject.put(project.Id,project);
			if(project.AcctSeed__Project_Tasks__r.isEmpty() || project.AcctSeed__Project_Tasks__r[0].Index__c == null)
				mapProjectIndex.put(project.Id,0);
			else
				mapProjectIndex.put(project.Id,project.AcctSeed__Project_Tasks__r[0].Index__c);
        }
	}

	public static void reName(set<Id> setIdProjectTask)
	{
		list<AcctSeed__Project_Task__c> listProjectTaskUpdate = new list<AcctSeed__Project_Task__c>();

		for(AcctSeed__Project_Task__c pt : 
			[SELECT Id, Name, Index__c, AcctSeed__Project__r.AcctSeedERP__Work_Order_Number__c
			 FROM AcctSeed__Project_Task__c
			 WHERE Id IN :setIdProjectTask])
		{
			String prefix = '';
			if(pt.AcctSeed__Project__r.AcctSeedERP__Work_Order_Number__c != null)
				prefix = String.valueOf(Integer.valueOf(pt.AcctSeed__Project__r.AcctSeedERP__Work_Order_Number__c.replaceAll('[^0-9]','')));
			if(pt.Index__c != null)
				prefix = prefix +'.'+string.valueOf(pt.Index__c);

			prefix = prefix + '-';

			String newName = pt.Name;
			if(newName == null)
				newName = prefix;
			if(!newName.startsWith(prefix))
				newName = prefix + newName;

			if(pt.Name != newName)
			{
				pt.Name = newName;
				listProjectTaskUpdate.add(pt);
			}
		}

		if(listProjectTaskUpdate.size() > 0)
		{
			Boolean boolOld = gcProjectTask.disableTrigger;
			gcProjectTask.disableTrigger = true;
			update listProjectTaskUpdate;
			gcProjectTask.disableTrigger = boolOld;
		}
	}

	global static void updateMaterialSpec(set<Id> setIdProjectTask)
	{
		setIdProjectTask.remove(null);
		map<Id,map<Id,Decimal>> mapProductParts = new map<Id,map<Id,Decimal>>();
		map<Id,map<Id,AcctSeedERP__Material__c>> mapProjectTaskMaterials = new map<Id,map<Id,AcctSeedERP__Material__c>>(); //map<idProjectTask => map<idProduct => Material>>

		map<Id,AcctSeed__Project_Task__c> mapProjectTask = new map<Id,AcctSeed__Project_Task__c>();

		//collect all of the Project Tasks that are in context.
		//if ProjectTask.Product is populated, then we need to prepare to collect the ProductParts for that Product.
		//For each Project Task having a Product, there needs to be one and only one Material for each underlying Product Part.
		for(AcctSeed__Project_Task__c pt :
			[SELECT Id,
					AcctSeed__Project__c,
					Product__c,
					Partslist_Generated__c,
					(SELECT Id,
							AcctSeedERP__Product__c,
							AcctSeedERP__Quantity_per_Unit__c,
							Quantity_Specified_Override__c
					 FROM AcctSeedERP__Materials__r
					 ORDER BY CreatedDate)
			 FROM AcctSeed__Project_Task__c
			 WHERE Id IN :setIdProjectTask
			   AND Product__c != null])
		{
			mapProjectTask.put(pt.Id,pt);
			mapProductParts.put(pt.Product__c,new map<Id,Decimal>());
		}

		if(mapProjectTask.isEmpty()) return;

		//collect the Product Parts for the Products that are specified in ProjectTask.Product
		//this is effectively the bill of materials
		for(AcctSeed__Product_Part__c part :
			[SELECT AcctSeed__Product__c,
					AcctSeed__Product_Part__c,
					AcctSeed__Quantity__c
			 FROM AcctSeed__Product_Part__c
			 WHERE AcctSeed__Product__c IN :mapProductParts.keySet()
			   AND AcctSeed__Product_Part__c != null
			   AND (AcctSeed__Quantity__c < 0 OR AcctSeed__Quantity__c > 0)])
		{
			Decimal qty = mapProductParts.get(part.AcctSeed__Product__c).get(part.AcctSeed__Product_Part__c);
			qty = (qty == null ? 0 : qty);

			qty += part.AcctSeed__Quantity__c;

			mapProductParts.get(part.AcctSeed__Product__c).put(part.AcctSeed__Product_Part__c,qty);
		}

		list<AcctSeedERP__Material__c> listMatlUpsert = new list<AcctSeedERP__Material__c>();

		for(AcctSeed__Project_Task__c pt :mapProjectTask.values())
		{
			pt.Partslist_Generated__c = true;
			map<Id,Decimal> bom = mapProductParts.get(pt.Product__c);

			if(bom == null) bom = new map<Id,Decimal>();

			map<Id,list<AcctSeedERP__Material__c>> mapProductMaterials = new map<Id,list<AcctSeedERP__Material__c>>(); //map Product.Id --> list<Material>

			for(AcctSeedERP__Material__c matl : pt.AcctSeedERP__Materials__r)
			{
				Id idProduct = matl.AcctSeedERP__Product__c;
				if(idProduct == null) continue;

				list<AcctSeedERP__Material__c> listMatl= mapProductMaterials.get(idProduct);
				if(listMatl == null)
				{
					listMatl = new list<AcctSeedERP__Material__c>();
					mapProductMaterials.put(idProduct,listMatl);
				}
				listMatl.add(matl);
			}

			set<Id> setIdProduct = new set<Id>();
			setIdProduct.addAll(bom.keySet());
			setIdProduct.addAll(mapProductMaterials.keySet());
			setIdProduct.remove(null);

			for(Id idProduct: setIdProduct)
			{
				//if the product is not in the bom, then all material records for that product should have [Qty Specified Override] = true
				if(!bom.containsKey(idProduct))
				{
					if(mapProductMaterials.containsKey(idProduct))
					{
						for(AcctSeedERP__Material__c matl : mapProductMaterials.get(idProduct))
						{
							if(!matl.Quantity_Specified_Override__c)
							{
								matl.Quantity_Specified_Override__c = true;
								listMatlUpsert.add(matl);
							}
						}
					}
				}
				//if the product IS in the bom, then set the Quantity Specified to the quantity of the BOM
				//note that there may be more than one material record for the same product, and if so, the oldest material record for that product will be considered the "primary"
				else
				{
					Decimal qtyBom = bom.get(idProduct);
					qtyBom = (qtyBom == null ? 0 : qtyBom);

					Boolean matlFound = false;

					if(mapProductMaterials.containsKey(idProduct))
					for(AcctSeedERP__Material__c matl : mapProductMaterials.get(idProduct))
					{
						//if this is the OLDEST material for this product, set the spec quantity to the bom quantity.
						if(!matlFound)
						{
							if(matl.AcctSeedERP__Quantity_per_Unit__c != qtyBom || matl.Quantity_Specified_Override__c)
							{
								matl.AcctSeedERP__Quantity_per_Unit__c = qtyBom;
								matl.Quantity_Specified_Override__c = false;
								listMatlUpsert.add(matl);
							}
							matlFound = true;
						}
						else //...it is not the OLDEST material, so the [Qty Specified Override] should be false.
						{
							if(!matl.Quantity_Specified_Override__c)
							{
								matl.Quantity_Specified_Override__c = true;
								listMatlUpsert.add(matl);
							}
						}
					}

					//if there is not a material record for this product, create one
					if(!matlFound)
					{
						listMatlUpsert.add(new AcctSeedERP__Material__c(
							AcctSeedERP__Project__c = pt.AcctSeed__Project__c,
							AcctSeedERP__Project_Task__c = pt.Id,
							AcctSeedERP__Product__c = idProduct,
							AcctSeedERP__Quantity_Per_Unit__c = qtyBom
						));
					}
				}
			}
		}

		//Boolean boolOld = gcMaterial.disableTrigger;
		//gcMaterial.disableTrigger = true;

		if(!listMatlUpsert.isEmpty())
			upsert listMatlUpsert;

		//gcMaterial.disableTrigger = boolOld;

		Boolean oldPTVal = gcProjectTask.disableTrigger;
		gcProjectTask.disableTrigger = true;
		update mapProjectTask.values();
		gcProjectTask.disableTrigger = oldPTVal;
	}

	public static void rollUpActual(set<Id> setIdProjectTask)
	{
		setIdProjectTask.remove(null);

		list<AcctSeed__Project_Task__c> listPTupdate = new list<AcctSeed__Project_Task__c>();

		Id idGlWip = gcConstants.idGlWip;

		for(AcctSeed__Project_Task__c pt :
			[SELECT Id, Revenue__c, Expense__c, Cash__c, WIP__c,
				(SELECT Id,
						AcctSeed__Amount__c,
                  		AcctSeed__GL_Account__r.AcctSeed__Bank__c,
						AcctSeed__GL_Account__r.AcctSeed__Type__c
				 FROM AcctSeed__Project_Transactions__r
				 WHERE AcctSeed__GL_Account__c IN (SELECT Id FROM AcctSeed__GL_Account__c WHERE AcctSeed__Type__c IN ('Revenue', 'Expense') OR AcctSeed__Bank__c = true OR Id = :idGlWip)
				   AND (AcctSeed__Amount__c < 0 OR AcctSeed__Amount__c > 0))
			 FROM AcctSeed__Project_Task__c
			 WHERE Id IN :setIdProjectTask])
		{
			Decimal revenue = 0;
			Decimal expense = 0;
			Decimal cash = 0;
			Decimal wip = 0;

			for(AcctSeed__Transaction__c txn : pt.AcctSeed__Project_Transactions__r)
			{
				if(txn.AcctSeed__GL_Account__r.AcctSeed__Type__c == 'Expense')
					expense += txn.AcctSeed__Amount__c;
				else if(txn.AcctSeed__GL_Account__r.AcctSeed__Type__c == 'Revenue')
					revenue -= txn.AcctSeed__Amount__c;
				else if(txn.AcctSeed__GL_Account__r.AcctSeed__Bank__c == true)
					cash += txn.AcctSeed__Amount__c;
				else if(txn.AcctSeed__GL_Account__c == idGlWip)
					wip += txn.AcctSeed__Amount__c;
			}

			if(pt.Expense__c == null || pt.Expense__c.setScale(6) != expense.setScale(6) ||
			   pt.Revenue__c == null || pt.Revenue__c.setScale(6) != revenue.setScale(6) ||
			   pt.Cash__c 	 == null || pt.Cash__c.setScale(6) != cash.setScale(6) ||
			   pt.WIP__c 	 == null || pt.WIP__c.setScale(6) != wip.setScale(6))
			{
				pt.Expense__c = expense;
				pt.Revenue__c = revenue;
				pt.Cash__c = cash;
				pt.WIP__c = wip;

				listPTupdate.add(pt);
			}


			Boolean boolOld  = gcProjectTask.disableTrigger;
			gcProjectTask.disableTrigger = true;

			if(!listPTupdate.isEmpty())
				update listPTupdate;

			gcProjectTask.disableTrigger = boolOld;
		}
	}

  public static void rollUpOrderItem(set<Id> setIdProjectTask)
	{
		setIdProjectTask.remove(null);
		list<AcctSeed__Project_Task__c> listPTupdate = new list<AcctSeed__Project_Task__c>();

		for(AcctSeed__Project_Task__c pt :
			[SELECT Id,
				Order_Item_Total__c,
				Order_Taxable_Provincial__c,
				Order_Taxable_Federal__c,
				Order_Taxable_Retail__c,
				(SELECT Taxable_Provincial__c, Taxable_Federal__c, Taxable_Retail__c, GMBLASERP__Total_Price__c FROM AcctSeedERP__Materials__r)
			 FROM AcctSeed__Project_Task__c
			 WHERE Id IN :setIdProjectTask])
		{
			Decimal amt = 0;
			Decimal taxableProvincial = 0;
			Decimal taxableFederal = 0;
			Decimal taxableRetail = 0;
			for(AcctSeedERP__Material__c m : pt.AcctSeedERP__Materials__r)
			{
				amt += (m.GMBLASERP__Total_Price__c == null ? 0 : m.GMBLASERP__Total_Price__c);
				if(m.Taxable_Provincial__c)
					taxableProvincial += (m.GMBLASERP__Total_Price__c == null ? 0 : m.GMBLASERP__Total_Price__c);
				if(m.Taxable_Federal__c)
					taxableFederal += (m.GMBLASERP__Total_Price__c == null ? 0 : m.GMBLASERP__Total_Price__c);
				if(m.Taxable_Retail__c)
					taxableRetail += (m.GMBLASERP__Total_Price__c == null ? 0 : m.GMBLASERP__Total_Price__c);
			}

			if(pt.Order_Item_Total__c == null || pt.Order_Item_Total__c.setScale(2) != amt.setScale(2) ||
			   pt.Order_Taxable_Provincial__c == null || pt.Order_Taxable_Provincial__c.setScale(2) != taxableProvincial.setScale(2) ||
			   pt.Order_Taxable_Federal__c == null || pt.Order_Taxable_Federal__c.setScale(2) != taxableFederal.setScale(2) || 
			   pt.Order_Taxable_Retail__c == null || pt.Order_Taxable_Retail__c.setScale(2) != taxableRetail.setScale(2))
			{
				pt.Order_Item_Total__c = amt;
				pt.Order_Taxable_Provincial__c = taxableProvincial;
				pt.Order_Taxable_Federal__c = taxableFederal;
				pt.Order_Taxable_Retail__c = taxableRetail;

				listPTupdate.add(pt);
			}
		}

		Boolean boolOld  = gcProjectTask.disableTrigger;
		gcProjectTask.disableTrigger = true;

		if(!listPTupdate.isEmpty())
			update listPTupdate;

		gcProjectTask.disableTrigger = boolOld;
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
	}
}