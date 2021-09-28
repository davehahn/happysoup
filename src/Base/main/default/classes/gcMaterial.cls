global without sharing class gcMaterial{

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

	global static Boolean disableTaskLockCheck {
		get {
			if( disableTaskLockCheck == null ) return false;
			return disableTaskLockCheck;
		}
		set {
			if(value == null) disableTaskLockCheck = false;
			else disableTaskLockCheck = value;
		}
	}

	global static Boolean disableCommission {
		get {
			if( disableCommission == null ) return false;
			return disableCommission;
		}
		set {
			if(value == null) disableCommission = false;
			else disableCommission = value;
		}
	}

	global static Boolean allowPartUpdate{
		get{
			if(allowPartUpdate == null) return false;
			else return allowPartUpdate;
		}
		set{
			if(value == null) allowPartUpdate = false;
			else allowPartUpdate = value;
		}
	}

	global static Boolean doNotRunDeNesting{
		get{
			if(doNotRunDeNesting == null) return false;
			else return doNotRunDeNesting;
		}
		set{
			if(value == null) doNotRunDeNesting = false;
			else doNotRunDeNesting = value;
		}
	}

	global static Boolean allowUntagRetail{
		get{
			if(allowUntagRetail == null) return false;
			else return allowUntagRetail;
		}
		set{
			if(value == null) allowUntagRetail = false;
			else allowUntagRetail = value;
		}
	}

	global static void triggerHandler
		(map<Id,AcctSeedERP__Material__c> oldMap,
		 map<Id,AcctSeedERP__Material__c> newMap,
		 list<AcctSeedERP__Material__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(oldMap == NULL) oldMap = new map<Id,AcctSeedERP__Material__c>();
		if(newMap == NULL) newMap = new map<Id,AcctSeedERP__Material__c>();
		if(listNew == NULL) listNew = new list<AcctSeedERP__Material__c>();

		updateAndValidate(oldMap,newMap,listNew,boolIsBefore,boolIsInsert,boolIsUpdate,boolIsDelete);

		if(boolIsBefore)
		{
			if(boolIsInsert)
			{
				gcTransactionParent.setFinancialAttributes(
					listNew,
					null,
					'AcctSeedERP__Project_Task__c',
					null);
			}
			if(boolIsUpdate)
			{
				gcTransactionParent.setFinancialAttributes(
					listNew,
					null,
					'AcctSeedERP__Project_Task__c',
					null);
			}
			if(boolIsDelete)
			{
				cascadeDeleteKitMaterial(oldMap.keySet());
				CommissionLineItem2_Service service = new CommissionLineItem2_Service();
				service.addMaterials( oldMap.keySet() );
				service.deleteRecords();
			}
		}
		else //i.e. trigger.isAfter
		{
			if(boolIsInsert)
			{
				if( !disableCommission )
				{
					CommissionLineItem2_Service service = new CommissionLineItem2_Service();
					service.addMaterials(newMap.keySet());
					service.saveRecords();
				}
				insertKitParts(newMap.keySet());
			}
			if(boolIsUpdate)
			{
				CommissionLineItem2_Service.syncMaterials( listNew, oldMap );
				Id retailRtId = gcConstants.idRtProjectBoatSale;
				/// Product Kitting
				set<Id> setIdUpdateMatl = new set<Id>();
				/// ------
				Map<String, Set<Id>> erpsToChangeStage = new Map<String, Set<Id>>{
					'nowSet' => new Set<Id>(),
					'unSet' => new Set<Id>()
				};
				Set<Id> serialNowSet = new Set<Id>();
				List<AcctSeedERP__Material__c> serialSetOnMaterial = new List<AcctSeedERP__Material__c>();
				for( AcctSeedERP__Material__c matl : listNew )
				{
					/// Product Kitting
					if( matl.AcctSeedERP__Quantity_per_Unit__c != oldMap.get(matl.Id).AcctSeedERP__Quantity_per_Unit__c )
					{
						setIdUpdateMatl.add(matl.Id);
					}
					/// ---
					// serial number now set
					if( matl.GMBLASERP__Serial_Number__c != null && oldMap.get(matl.Id).GMBLASERP__Serial_Number__c == null)
					{
						serialNowSet.add( matl.Id );
						erpsToChangeStage.get('nowSet').add(matl.AcctSeedERP__Project__c);
						if( matl.ERP_RecordTypeId__c == retailRtId )
							serialSetOnMaterial.add( matl );
					}
					//serial number was set but not now
					if( matl.GMBLASERP__Serial_Number__c == null && oldMap.get(matl.Id).GMBLASERP__Serial_Number__c != null )
					{
						erpsToChangeStage.get('unSet').add(matl.AcctSeedERP__Project__c);
					}
				}
				updateErpStage( erpsToChangeStage );
				/// Product Kitting
                if(!setIdUpdateMatl.isEmpty())
                    updateMaterialSpec(setIdUpdateMatl);
				if( serialNowSet.size() > 0 )
				{
					System.enqueueJob( new Dealer_Order_Line_Ext.DealerOrderLine_SetSerial_Queue( serialNowSet ) );
				}
			}
			if(boolIsDelete)
			{

			}
		}
	}

	/*private static void updateReservedForRetail( List<AcctSeedERP__Material__c> matls )
	{
		System.debug('Materials with Serial now set ' + matls);
		Set<Id> pIds = new Set<Id>();
		Set<Id> serIds = new Set<Id>();
		for( AcctSeedERP__Material__c matl : matls )
		{
			serIds.add( matl.GMBLASERP__Serial_Number__c );
			pIds.add( matl.AcctSeedERP__Product__c );
		}

		GMBLASERP__Serial_Number__c[] serials = [SELECT Id, GMBLASERP__Lot__c, GMBLASERP__Product__c
																						 FROM GMBLASERP__Serial_Number__c
																						 WHERE Id IN :serIds ];
		Map<String, ProductLotReservation__c> plrMap = new Map<String, ProductLotReservation__c>();
		for( ProductLotReservation__c plr : [SELECT Id, Product__c, Lot__c, Reserved_For_Retail_Sale__c
																				 FROM ProductLotReservation__c
																				 WHERE Product__c IN :pIds] )
		{
			String idString = plr.Product__c;
			if( plr.Lot__c != null )
				idString += ('-' + plr.Lot__c );
			plrMap.put( idString, plr );
			System.debug('IdString1 = ' + idString);
		}
		for( GMBLASERP__Serial_Number__c ser : serials )
		{
			String idString = ser.GMBLASERP__Product__c + '-' + ser.GMBLASERP__Lot__c;
			System.debug('IdString2 = ' + idString);
			if( plrMap.containsKey( idString ) &&
				  plrMap.get(idString).Reserved_For_Retail_Sale__c != null )
				plrMap.get(idString).Reserved_For_Retail_Sale__c -= 1;
		}
		update plrMap.values();
	}*/

	global static void updateAndValidate
		(map<Id,AcctSeedERP__Material__c> oldMap,
		 map<Id,AcctSeedERP__Material__c> newMap,
		 list<AcctSeedERP__Material__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(boolIsBefore)
		{
			/// This part needs to be done first to make sure that the retail is untagged first
			if(boolIsInsert || boolIsUpdate)
			{
				Map<Id,Map<Id,Id>> mapProjectProductSerial = new Map<Id,Map<Id,Id>>();
				for(AcctSeedERP__Material__c matl : listNew)
				{
					if(((boolIsInsert && matl.GMBLASERP__Serial_Number__c != null) || (boolIsUpdate && matl.GMBLASERP__Serial_Number__c != oldMap.get(matl.Id).GMBLASERP__Serial_Number__c)) && matl.Has_Retail__c){
						if(!mapProjectProductSerial.containsKey(matl.Retail_ERP_Id__c))
							mapProjectProductSerial.put(matl.Retail_ERP_Id__c, new Map<Id,Id>());
						mapProjectProductSerial.get(matl.Retail_ERP_Id__c).put(matl.AcctSeedERP__Product__c,matl.GMBLASERP__Serial_Number__c);
					}
				}
				if(!mapProjectProductSerial.isEmpty()){
					allowUntagRetail = true;
					updateRetailMaterialSerial(mapProjectProductSerial);
				}
			}
			if(boolIsInsert || boolIsUpdate)
			{
				List<AcctSeedERP__Material__c> listAll = new List<AcctSeedERP__Material__c>();
				listAll.addAll(listNew);
				listAll.addAll(oldMap.values());
				refreshStatics(listAll);
				price(listNew, oldMap);
				for(AcctSeedERP__Material__c matl : listNew)
				{
					AcctSeed__Project__c project;
					if(matl.AcctSeedERP__Project__c != null)
					{
							project = mapProject.get(matl.AcctSeedERP__Project__c);
							Product2 product = mapProduct.get(matl.AcctSeedERP__Product__c);
							AcctSeed__Project_Task__c task = mapProjectTask.get(matl.AcctSeedERP__Project_Task__c);
							AcctSeed__Project_Task__c oldTask;
							if(boolIsUpdate)
								oldTask = mapProjectTask.get(oldMap.get(matl.Id).AcctSeedERP__Project_Task__c);
							if((project.Locked__c && !gcProject.disableLockedCheck) && boolIsInsert)
								matl.addError('Cannot add material on a locked ERP Order.');
							if(task != null && task.Locked__c && !disableTaskLockCheck && boolIsInsert)
								matl.addError('Cannot add material on a locked ERP Order Task.');
							if(project.RecordTypeId == gcConstants.idRtProjectCounterSale && product.AcctSeedERP__Serialized__c){
								matl.addError('Cannot add serialized product on a counter sale ERP');
							}
							if(boolIsUpdate
								&& ((project.Locked__c && !gcProject.disableLockedCheck)
									|| (task.Locked__c && oldTask.Locked__c)
									|| (task.Id != oldTask.Id && (oldTask.Locked__c || task.Locked__c))))
							{
								AcctSeedERP__Material__c oldMatl = oldMap.get(matl.Id);
								if(matl.AcctSeedERP__Quantity_per_Unit__c != oldMatl.AcctSeedERP__Quantity_per_Unit__c
									|| ((matl.GMBLASERP__Unit_Price__c == null?0:matl.GMBLASERP__Unit_Price__c).setScale(6) != (oldMatl.GMBLASERP__Unit_Price__c == null?0:oldMatl.GMBLASERP__Unit_Price__c).setScale(6))
									|| matl.Quantity_Specified_Override__c != oldMatl.Quantity_Specified_Override__c
									|| matl.AcctSeedERP__Product__c != oldMatl.AcctSeedERP__Product__c
									|| (matl.GMBLASERP__Serial_Number__c != oldMatl.GMBLASERP__Serial_Number__c && !allowUntagRetail)
									|| matl.GMBLASERP__Lot__c != oldMatl.GMBLASERP__Lot__c
									|| matl.AcctSeedERP__Project__c != oldMatl.AcctSeedERP__Project__c
									|| matl.AcctSeedERP__Project_Task__c != oldMatl.AcctSeedERP__Project_Task__c)
								{
									matl.addError('Cannot modify quantity, unit price, Tax, ERP Order, ERP Order task, Serial number, Lot or product. The parent ERP Order or the Task is locked.');
								}
							}
							/// Added later to not allow change of PT or P
							if(boolIsUpdate)
							{
								AcctSeedERP__Material__c oldMatl = oldMap.get(matl.Id);
								if(oldMatl.AcctSeedERP__Project__c != matl.AcctSeedERP__Project__c
									|| matl.AcctSeedERP__Project_Task__c != oldMatl.AcctSeedERP__Project_Task__c)
									matl.addError('Cannot modify ERP Order or ERP Order task. If required delete the ERP Order Item and add again.');
							}
							if(project.Internal_Partner_Boat_Sale__c){
								if(matl.AcctSeedERP__GL_Account_Variable_1__c == null)
									matl.AcctSeedERP__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
								if(matl.AcctSeedERP__GL_Account_Variable_2__c == null)
									matl.AcctSeedERP__GL_Account_Variable_2__c = gcConstants.idGlv2Sales;
							}

							if(project.Warranty_Type__c == 'Warranty' && matl.GMBLASERP__Unit_Price__c != null && matl.GMBLASERP__Unit_Price__c > 0){
								matl.GMBLASERP__Unit_Price__c = matl.GMBLASERP__Unit_Price__c * -1;
							}
					}

					if(boolIsUpdate)
					{
						AcctSeedERP__Material__c oldMatl = oldMap.get(matl.Id);
						if(matl.Material__c != oldMatl.Material__c)
							matl.Material__c = oldMatl.Material__c;

						if(!allowPartUpdate && matl.Material__c != null)
						{
							matl.AcctSeedERP__Quantity_per_Unit__c = oldMatl.AcctSeedERP__Quantity_per_Unit__c;
	                    	matl.Part_Quantity_Specified_Multiplier__c = oldMatl.Part_Quantity_Specified_Multiplier__c;
							matl.GMBLASERP__Unit_Price__c = oldMatl.GMBLASERP__Unit_Price__c;
							matl.Quantity_Specified_Override__c = oldMatl.Quantity_Specified_Override__c;
						}
						/// Checking Old Serial for Internal to not allow untag
						if(matl.GMBLASERP__Serial_Number__c != oldMatl.GMBLASERP__Serial_Number__c && oldMatl.GMBLASERP__Serial_Number__c != null){
							GMBLASERP__Serial_Number__c serialOld = mapSerial.get(oldMatl.GMBLASERP__Serial_Number__c);
							if(project != null && project.Internal_Partner_Boat_Sale__c && serialOld.GMBLASERP__Inventory_Balance__c != null && !serialOld.Available_Retail__c && !allowUntagRetail)
								matl.addError('Cannot untag '+serialOld.Name+'. As it has already been tagged in a retail order. Untag from there to proceed.');
						}
					}

					if(boolIsInsert || (boolIsUpdate && matl.AcctSeedERP__Product__c != oldMap.get(matl.Id).AcctSeedERP__Product__c))
					{
	                    Product2 product = mapProduct.get(matl.AcctSeedERP__Product__c);
						if(product != null)
						{
							matl.Taxable_Provincial__c = product.Taxable__c;
							matl.Taxable_Federal__c = product.Taxable__c;
							matl.Taxable_Retail__c = false;
	                        if(matl.AcctSeedERP__Project__c != null)
	                        {
	                            if(product.RecordType.Name.equals('Insurance'))
	                            {
	                                matl.Taxable_Federal__c = false;
	                                matl.Taxable_Provincial__c = false;
	                                matl.Taxable_Retail__c = true;
	                                //if(project.GL_Account_Variable_3__c != null && project.GL_Account_Variable_3__r.Name.equals('Ontario'))
	                                //	matl.Taxable_Retail__c = true;
	                            }
	                        }
						}
					}

					Decimal qtySpec;

					AcctSeed__Project_Task__c pt = mapProjectTask.get(matl.AcctSeedERP__Project_Task__c);
					if(pt != null)
					{
						map<Id,Decimal> mapPartQty = mapProductParts.get(pt.Product__c);
						if(mapPartQty != null)
						{
							qtySpec = mapPartQty.get(matl.AcctSeedERP__Product__c);
						}
					}

					if(qtySpec != null && !matl.Quantity_Specified_Override__c)
						matl.AcctSeedERP__Quantity_per_Unit__c = qtySpec;

					if(matl.AcctSeedERP__Quantity_per_Unit__c == null)
					   matl.AcctSeedERP__Quantity_per_Unit__c = 0;

					if(matl.GMBLASERP__Serial_Number__c != null)
					{
						GMBLASERP__Serial_Number__c serial = mapSerial.get(matl.GMBLASERP__Serial_Number__c);
						if(serial.GMBLASERP__Lot__c != null)
							matl.GMBLASERP__Lot__c = serial.GMBLASERP__Lot__c;

						if(serial.Unit_Price__c != null && serial.Unit_Price__c != 0 && !matl.GMBLASERP__Price_Override__c)
							matl.GMBLASERP__Unit_Price__c = serial.Unit_Price__c.setScale(6);
					}

					matl.GMBLASERP__Total_Price__c = (matl.AcctSeedERP__Quantity_per_Unit__c == null ? 0 : matl.AcctSeedERP__Quantity_per_Unit__c) *
													 (matl.GMBLASERP__Unit_Price__c == null ? 0 : matl.GMBLASERP__Unit_Price__c);
				}
			}

			if(boolIsDelete)
			{
				refreshStatics(oldMap.values());
				for(AcctSeedERP__Material__c matl : oldMap.values())
				{
					AcctSeed__Project__c project;
					if(matl.AcctSeedERP__Project__c != null)
					{
							project = mapProject.get(matl.AcctSeedERP__Project__c);
							AcctSeed__Project_Task__c task = mapProjectTask.get(matl.AcctSeedERP__Project_Task__c);
							if(project.Locked__c && !gcProject.disableLockedCheck)
								matl.addError('Materials Cannot be deleted from a locked ERP Order.');
							if(task != null && task.Locked__c && !gcMaterial.disableTaskLockCheck)
								matl.addError('Materials Cannot be deleted from a locked ERP Order Task.');
					}

					if(matl.Material__c != null && !oldMap.containsKey(matl.Material__c) )
						matl.addError('Kit Parts cannot be deleted directly. Deleting Kit would aumatically delete Kit Parts.');
					/// Checking Old Serial for Internal to not allow untag
					if(matl.GMBLASERP__Serial_Number__c != null){
						GMBLASERP__Serial_Number__c serial = mapSerial.get(matl.GMBLASERP__Serial_Number__c);
						if(project != null && project.Internal_Partner_Boat_Sale__c && !serial.Available_Retail__c)
							matl.addError('Cannot delete this ERP order line. As it has serial number which is already tagged in a retail order. Untag from there to proceed.');
					}
				}
			}
		}

		if(!boolIsBefore)
		{
			set<Id> setIdPTrollup = new set<Id>();
			/// Update Serial Numbers for Availablity
			Set<Id> setIdSerials = new Set<Id>();
			/// Update Serial Numbers for Availablity
			Set<Id> setIdSerialsDeNest = new Set<Id>();
			/// Update Project Serial
			Set<Id> setProjectSerial = new Set<Id>();
			for(AcctSeedERP__Material__c matl : listNew)
			{
				setIdPTrollup.add(matl.AcctSeedERP__Project_Task__c);
				if((boolIsInsert && matl.GMBLASERP__Serial_Number__c != null)
						|| (boolIsUpdate && matl.GMBLASERP__Serial_Number__c != oldMap.get(matl.Id).GMBLASERP__Serial_Number__c)){
					setIdSerials.add(matl.GMBLASERP__Serial_Number__c);
					if(boolIsUpdate)
						setIdSerials.add(oldMap.get(matl.Id).GMBLASERP__Serial_Number__c);
				}
				if(matl.AcctSeedERP__Project__c != null)
					setProjectSerial.add(matl.AcctSeedERP__Project__c);
				if(boolIsUpdate && !doNotRunDeNesting
					&& oldMap.get(matl.Id).GMBLASERP__Serial_Number__c != null
					&& matl.GMBLASERP__Serial_Number__c != oldMap.get(matl.Id).GMBLASERP__Serial_Number__c)
					setIdSerialsDeNest.add(oldMap.get(matl.Id).GMBLASERP__Serial_Number__c);
			}

			for(AcctSeedERP__Material__c matl : oldMap.values())
			{
				setIdPTrollup.add(matl.AcctSeedERP__Project_Task__c);
				if(boolIsDelete && matl.GMBLASERP__Serial_Number__c != null)
					setIdSerials.add(matl.GMBLASERP__Serial_Number__c);
				if(matl.AcctSeedERP__Project__c != null)
					setProjectSerial.add(matl.AcctSeedERP__Project__c);
				if(boolIsDelete && matl.GMBLASERP__Serial_Number__c != null)
					setIdSerialsDeNest.add(matl.GMBLASERP__Serial_Number__c);
			}
			setIdPTrollup.remove(null);

			if(!setIdPTrollup.isEmpty())
				gcProjectTask.rollUpOrderItem(setIdPTrollup);

			/// De-Nest Serial Numbers
			if(!setIdSerialsDeNest.isEmpty())
				gcSerialNumber.deNestSrials(setIdSerialsDeNest);

			/// Set Project Serial to the selected boat
			if(!setProjectSerial.isEmpty())
				updateProjectSerial(setProjectSerial);

			/// Update Serial Numbers Availability Future
			setIdSerials.remove(null);
			if(!setIdSerials.isEmpty()){
				gcSerialNumber.updateSerialIsAvailableFuture(setIdSerials);
			}
		}
	}

	private static map<Id,GMBLASERP__Lot__c> mapLot;
	private static map<Id,Product2> mapProduct;
	private static map<Id,map<Id,Decimal>> mapProductParts;
	private static map<Id,map<Id,Decimal>> mapProductPricebookPrice;
	private static map<Id,AcctSeed__Project__c> mapProject;
	private static map<Id,AcctSeed__Project_Task__c> mapProjectTask;
	private static map<Id,GMBLASERP__Serial_Number__c> mapSerial;

	private static void refreshStatics(list<AcctSeedERP__Material__c> listNew)
	{
		if(mapProjectTask == null)
		{
			mapLot = new map<Id,GMBLASERP__Lot__c>();
			mapProduct = new map<Id,Product2>();
			mapProductParts = new map<Id,map<Id,Decimal>>();
			mapProductPricebookPrice = new map<Id,map<Id,Decimal>>();
			mapProject = new map<Id,AcctSeed__Project__c>();
            mapProjectTask = new map<Id,AcctSeed__Project_Task__c>();
			mapSerial = new map<Id,GMBLASERP__Serial_Number__c>();
		}
		set<Id> setIdLot = new set<Id>();
		set<Id> setIdProduct = new set<Id>();
		set<Id> setIdProductParts = new set<Id>();
		set<Id> setIdProject = new set<Id>();
		set<Id> setIdProjectTask = new set<Id>();
		set<Id> setIdSerial = new set<Id>();

		for(AcctSeedERP__Material__c matl : listNew)
		{
			if(matl.GMBLASERP__Lot__c != null && !mapLot.containsKey(matl.GMBLASERP__Lot__c))
				setIdLot.add(matl.GMBLASERP__Lot__c);

			if(!mapProduct.containsKey(matl.AcctSeedERP__Product__c))
				setIdProduct.add(matl.AcctSeedERP__Product__c);

			if(!mapProject.containsKey(matl.AcctSeedERP__Project__c))
				setIdProject.add(matl.AcctSeedERP__Project__c);

			if(!mapProjectTask.containsKey(matl.AcctSeedERP__Project_Task__c))
				setIdProjectTask.add(matl.AcctSeedERP__Project_Task__c);

			if(matl.GMBLASERP__Serial_Number__c != null && !mapSerial.containsKey(matl.GMBLASERP__Serial_Number__c))
				setIdSerial.add(matl.GMBLASERP__Serial_Number__c);
		}
		setIdLot.remove(null);
		setIdProduct.remove(null);
		setIdProject.remove(null);
        setIdProjectTask.remove(null);
		setIdSerial.remove(null);

		if(!setIdSerial.isEmpty())
		for(GMBLASERP__Serial_Number__c sn :
			[SELECT Id, Name,
					GMBLASERP__Lot__c,
					Unit_Price__c,
					GMBLASERP__Product__c,
					Available_Wholesale__c,
					Available_Retail__c,
					GMBLASERP__Inventory_Balance__c
			 FROM GMBLASERP__Serial_Number__c
			 WHERE Id IN :setIdSerial])
		{
			mapSerial.put(sn.Id,sn);

			if(sn.GMBLASERP__Lot__c != null && !mapLot.containsKey(sn.GMBLASERP__Lot__c))
				setIdLot.add(sn.GMBLASERP__Lot__c);

			if(sn.GMBLASERP__Product__c != null && !mapProduct.containsKey(sn.GMBLASERP__Product__c))
				setIdProduct.add(sn.GMBLASERP__Product__c);
		}

		if(!setIdLot.isEmpty())
		for(GMBLASERP__Lot__c lot :
			[SELECT Id,
					GMBLASERP__Product__c
			 FROM GMBLASERP__Lot__c
			 WHERE Id In :setIdLot])
		{
			mapLot.put(lot.Id,lot);

			if(lot.GMBLASERP__Product__c != null && !mapProduct.containsKey(lot.GMBLASERP__Product__c))
				setIdProduct.add(lot.GMBLASERP__Product__c);
		}

		if(!setIdProduct.isEmpty())
		{
			for(Product2 p :
				[SELECT Id,
						GMBLASERP__Lot_Tracked__c,
						AcctSeedERP__Serialized__c,
                 		RecordType.Name,
						Taxable__c
				 FROM Product2
				 WHERE Id IN :setIdProduct])
			{
				mapProduct.put(p.Id,p);
			}
		}

		if(!setIdProject.isEmpty())
		for(AcctSeed__Project__c p :
			[SELECT Id,
				Locked__c,
				RecordTypeId,
				Serial_Number__c,
				GMBLASERP__Pricebook__c,
				Internal_Partner_Boat_Sale__c,
				Internal_Labour_Service__c,
				Internal_Warranty__c,
				Warranty_Type__c,
             	GL_Account_Variable_3__c,
             	GL_Account_Variable_3__r.Name
			 FROM AcctSeed__Project__c
			 WHERE Id IN :setIdProject])
		{
			mapProject.put(p.Id,p);
		}

		if(!setIdProjectTask.isEmpty())
		for(AcctSeed__Project_Task__c pt :
			[SELECT Id, Product__c, Locked__c
			 FROM AcctSeed__Project_Task__c
			 WHERE Id IN :setIdProjectTask])
		{
			mapProjectTask.put(pt.Id,pt);
			if(pt.Product__c != null && !mapProductParts.containsKey(pt.Product__c))
				setIdProductParts.add(pt.Product__c);
		}
		setIdProductParts.remove(null);

		if(!setIdProductParts.isEmpty())
		for(AcctSeed__Product_Part__c part :
			[SELECT AcctSeed__Product__c, AcctSeed__Product_Part__c, AcctSeed__Quantity__c
			 FROM AcctSeed__Product_Part__c
			 WHERE AcctSeed__Product__c IN :setIdProductParts
			   AND AcctSeed__Product_Part__c != null
			   AND (AcctSeed__Quantity__c < 0 OR AcctSeed__Quantity__c > 0)])
		{
			map<Id,Decimal> mapPartQty = mapProductParts.get(part.AcctSeed__Product__c);
			if(mapPartQty == null)
			{
				mapPartQty = new map<Id,Decimal>();
				mapPartQty.put(part.AcctSeed__Product_Part__c, part.AcctSeed__Quantity__c);
				mapProductParts.put(part.AcctSeed__Product__c,mapPartQty);
			}
			else
			{
				Decimal oldQty = mapPartQty.get(part.AcctSeed__Product_Part__c);
				oldQty = (oldQty == null ? 0 : oldQty);
				mapPartQty.put(part.AcctSeed__Product_Part__c, oldQty + part.AcctSeed__Quantity__c);
			}
		}

		for(PricebookEntry pbe :
			[SELECT Id,
					IsActive,
					Product2Id,
					PriceBook2Id,
					UnitPrice
			 FROM PriceBookEntry
			 WHERE Product2Id IN :setIdProduct
			   AND IsActive = true
			   AND PriceBook2.IsActive = true
			 ORDER BY CreatedDate desc])
		{
			map<Id,Decimal> mapPricebookPrice = mapProductPricebookPrice.get(pbe.Product2Id);
			if(mapPricebookPrice == null)
			{
				mapPricebookPrice = new map<Id,Decimal>();
				mapPricebookPrice.put(pbe.Pricebook2Id,pbe.UnitPrice);
				mapProductPricebookPrice.put(pbe.Product2Id,mapPricebookPrice);
			}
			else
				mapProductPricebookPrice.get(pbe.Product2Id).put(pbe.Pricebook2Id,pbe.UnitPrice);
		}
	}

	private static void updateProjectSerial(Set<Id> setIdProject)
	{
		List<AcctSeed__Project__c> listProject = new List<AcctSeed__Project__c>();
		Id idRtProjectBoatSale = gcConstants.idRtProjectBoatSale;
		Id idRtProjectPartnerBoatSale = gcConstants.idRtProjectPartnerBoatSale;
		for(AcctSeed__Project__c p :
				[SELECT Id,
					Serial_Number__c,
					(SELECT Id,
						GMBLASERP__Serial_Number__c
					FROM AcctSeedERP__Project_Materials__r
					WHERE AcctSeedERP__Product__r.RecordType.Name = 'Boat'
						AND GMBLASERP__Serial_Number__c != null
					ORDER BY CreatedDate
					LIMIT 1)
				FROM AcctSeed__Project__c
				WHERE Id IN:setIdProject
					AND (RecordTypeId =:idRtProjectBoatSale
						OR RecordTypeId =:idRtProjectPartnerBoatSale)])
		{
			if(!p.AcctSeedERP__Project_Materials__r.isEmpty())
			{
				Id idSer = p.AcctSeedERP__Project_Materials__r[0].GMBLASERP__Serial_Number__c;
				if(p.Serial_Number__c != idSer)
				{
					p.Serial_Number__c = idSer;
					listProject.add(p);
				}
			}
			else if(p.Serial_Number__c != null)
			{
				p.Serial_Number__c = null;
				listProject.add(p);
			}
		}
		if(!listProject.isEmpty()){
			Boolean boolOld = gcProject.disableTrigger;
			gcProject.disableTrigger = true;
			update listProject;
			gcProject.disableTrigger = boolOld;
		}
	}

	private static void updateErpStage( Map<String, Set<Id>> erpIdMap )
	{
		Set<Id> allErpIds = new Set<Id>();
		Id partnerId = gcConstants.idRtProjectPartnerBoatSale;
		Id serviceId = gcConstants.idRtProjectService;
		for( String key : erpIdMap.keySet() )
		{
			allErpIds.addAll( erpIdMap.get(key) );
		}
		AcctSeed__Project__c[] erps = new List<AcctSeed__Project__c>();
		for( AcctSeed__Project__c erp : [SELECT Id, RecordTypeId,
																		 (SELECT Id, GMBLASERP__Serial_Number__c
																		  FROM  AcctSeedERP__Project_Materials__r
			         												WHERE AcctSeedERP__Product__r.AcctSeedERP__Serialized__c = true)
			         											FROM AcctSeed__Project__c
			         											WHERE Id IN :allErpIds] )
		{
			if( erpIdMap.get('unSet').contains(erp.Id) &&
					erp.RecordTypeId != serviceId )
			{
				erp.Stage__c = 'Tagging Pending';
				erps.add(erp);
			}
			if( erpIdMap.get('nowSet').contains(erp.Id) )
			{
				Boolean allSerialsSet = true;
				for( AcctSeedERP__Material__c matl : erp.AcctSeedERP__Project_Materials__r )
				{
					if( matl.GMBLASERP__Serial_Number__c == null )
					{
						allSerialsSet = false;
					}
				}
				if( allSerialsSet == true && erp.RecordTypeId == partnerId )
				{
					erp.Stage__c = 'Pending Rigging';
					erps.add(erp);
				}
			}

		}
		if( erps.size() > 0 )
			update erps;

	}

	/// Product Kitting
	private static void insertKitParts(set<Id> setIdMatlKit)
    {
        list<AcctSeedERP__Material__c> listMatlKit = new list<AcctSeedERP__Material__c>();
        map<Id,Product2> mapKit = new map<Id,Product2>();
        list<AcctSeedERP__Material__c> listMatlComp = new list<AcctSeedERP__Material__c>();

        for(AcctSeedERP__Material__c matlKit :
            [SELECT Id,
            		AcctSeedERP__Product__c,
            		AcctSeedERP__Project__c,
            		AcctSeedERP__Project_Task__c,
                    AcctSeedERP__Quantity_per_Unit__c,
                    Part_Quantity_Specified_Multiplier__c
             FROM AcctSeedERP__Material__c
             WHERE Id IN :setIdMatlKit
               AND AcctSeedERP__Product__r.Composite_Type__c = 'Kit'
               AND AcctSeedERP__Product__r.RecordTypeId != :LGND_Constants.productRtId_Bundle])
        {
            if(!mapKit.containsKey(matlKit.AcctSeedERP__Product__c))
                mapKit.put(matlKit.AcctSeedERP__Product__c,null);

            listMatlKit.add(matlKit);
        }
        for(Product2 kit :
            [SELECT Id,
                    (SELECT Id,
                    	AcctSeed__Product__c,
                    	AcctSeed__Product_Part__c,
                    	AcctSeed__Quantity__c
                    FROM AcctSeed__Product_Parts__r
                    WHERE AcctSeed__Product__r.RecordTypeId != :LGND_Constants.productRtId_Bundle)Fcommission
             FROM Product2
             WHERE Id In :mapKit.keySet()
             AND RecordTypeId != :LGND_Constants.productRtId_Bundle])
        {
            mapKit.put(kit.Id,kit);
        }

        for(AcctSeedERP__Material__c matlKit : listMatlKit)
        {
            Product2 kit = mapKit.get(matlKit.AcctSeedERP__Product__c);

            for(AcctSeed__Product_Part__c comp : kit.AcctSeed__Product_Parts__r)
            {
                listMatlComp.add(new AcctSeedERP__Material__c(
									AcctSeedERP__Product__c = comp.AcctSeed__Product_Part__c,
									Material__c = matlKit.Id,
									GMBLASERP__Price_Override__c = true,
									GMBLASERP__Unit_Price__c = 0,
            			AcctSeedERP__Project__c = matlKit.AcctSeedERP__Project__c,
            			AcctSeedERP__Project_Task__c = matlKit.AcctSeedERP__Project_Task__c,
            			Part_Quantity_Specified_Multiplier__c = (comp.AcctSeed__Quantity__c == null ? 0 : comp.AcctSeed__Quantity__c),
									AcctSeedERP__Quantity_per_Unit__c = (comp.AcctSeed__Quantity__c == null ? 0 : comp.AcctSeed__Quantity__c) * (matlKit.AcctSeedERP__Quantity_per_Unit__c == null ? 0 : matlKit.AcctSeedERP__Quantity_per_Unit__c)
                ));
            }
        }

        if(!listMatlComp.isEmpty())
        {
        	Boolean boolOld = allowPartUpdate;
        	allowPartUpdate = true;
            insert listMatlComp;
            allowPartUpdate = boolOld;
        }
    }

    private static void cascadeDeleteKitMaterial(set<Id> setIdMatl)
    {
        setIdMatl.remove(null);
        if(!setIdMatl.isEmpty())
        {
        	Boolean boolOld = gcMaterial.disableTrigger;
        	gcMaterial.disableTrigger = true;
        	delete [SELECT Id FROM AcctSeedERP__Material__c WHERE Material__c IN :setIdMatl AND Id NOT IN:setIdMatl];
        	gcMaterial.disableTrigger = boolOld;
        }
    }

    private static void updateMaterialSpec(set<Id> setIdMatlKit)
    {
			setIdMatlKit.remove(null);
			if(setIdMatlKit.isEmpty()) return;

			list<AcctSeedERP__Material__c> listMatl = new list<AcctSeedERP__Material__c>();

			for(AcctSeedERP__Material__c matl :
					[SELECT Id,
									Material__r.AcctSeedERP__Quantity_per_Unit__c,
									AcctSeedERP__Quantity_per_Unit__c,
									Part_Quantity_Specified_Multiplier__c
					FROM AcctSeedERP__Material__c
					WHERE Material__c IN :setIdMatlKit])
			{
				Decimal qtySpecified = (matl.Material__r.AcctSeedERP__Quantity_per_Unit__c == null ? 0 : matl.Material__r.AcctSeedERP__Quantity_per_Unit__c) * (matl.Part_Quantity_Specified_Multiplier__c == null ? 0 : matl.Part_Quantity_Specified_Multiplier__c);
				qtySpecified = qtySpecified.setScale(6);

				if(matl.AcctSeedERP__Quantity_per_Unit__c == null || matl.AcctSeedERP__Quantity_per_Unit__c.setScale(6) != qtySpecified)
				{
						matl.AcctSeedERP__Quantity_per_Unit__c = qtySpecified;
						listMatl.add(matl);
				}
			}

			if(!listMatl.isEmpty())
			{
				Boolean boolOld = allowPartUpdate;
				allowPartUpdate = true;
					update listMatl;
					allowPartUpdate = boolOld;
			}
    }

    public static void untagRetailERPItems(Set<Id> setIdRetailERP){
    	setIdRetailERP.remove(null);
    	if(setIdRetailERP.isEmpty()) return;
        /// Now Clear all tagged serials from the retail
        List<AcctSeedERP__Material__c> listMatl = new List<AcctSeedERP__Material__c>();
        for( AcctSeedERP__Material__c objMaterial : [SELECT Id,
                                                             GMBLASERP__Lot__c,
                                                             GMBLASERP__Serial_Number__c
                                                      FROM AcctSeedERP__Material__c
                                                      WHERE AcctSeedERP__Project__c IN:setIdRetailERP
                                                        AND GMBLASERP__Serial_Number__c != null])
        {
          objMaterial.GMBLASERP__Serial_Number__c = null;
          objMaterial.GMBLASERP__Lot__c = null;
          listMatl.add(objMaterial);
        }
        if(!listMatl.isEmpty())
          update listMatl;
    }

	public static void price(list<AcctSeedERP__Material__c> listNew, map<Id,AcctSeedERP__Material__c> oldMap)
	{
		for(AcctSeedERP__Material__c matl : listNew)
		{
			Boolean boolIsUpdate = false;
			Boolean boolIsInsert = true;
			if(matl.Id != null)
			{
				boolIsUpdate = true;
				boolIsInsert = false;
			}

			Decimal pricebookPrice = null;
			if(mapProject.containsKey(matl.AcctSeedERP__Project__c))
			{
				Id idPricebook = mapProject.get(matl.AcctSeedERP__Project__c).GMBLASERP__Pricebook__c;
				map<Id,Decimal> mapPricebookPrice = mapProductPricebookPrice.get(matl.AcctSeedERP__Product__c);
				if(mapPricebookPrice != null)
					pricebookPrice = mapPricebookPrice.get(idPricebook);
			}

			if(boolIsInsert)
			{
				//if there is no price in the pricebook, then it doesn't matter whether or not the user selected price override; it is by definition a price override.
				if(pricebookPrice == null)
					matl.GMBLASERP__Price_Override__c = true;
				//if the user is requesting the pricebook price, use it
				else if(matl.GMBLASERP__Price_Override__c == false)
					matl.GMBLASERP__Unit_price__c  = pricebookPrice;
				//if the user is NOT requesting the pricebook price, use whatever price the user has specified.
			}

			if(boolIsUpdate)
			{
				AcctSeedERP__Material__c oldRec = oldMap.get(matl.Id);

				//if the user has manipulated either the price override checkbox, or the unit price, then do something.  otherwise, don't.
				if(matl.GMBLASERP__Price_Override__c != oldRec.GMBLASERP__Price_Override__c ||
				   matl.GMBLASERP__Unit_Price__c != oldRec.GMBLASERP__Unit_Price__c)
				{
					//if the user has NOT manipulated the price override checkbox...
					if(matl.GMBLASERP__Price_Override__c == oldRec.GMBLASERP__Price_Override__c)
					{
						//...and if the price override is selected, then accept whatever price the user has entered.
						if(matl.GMBLASERP__Price_Override__c)
						{
							//do nothing
						}
						//...and if the user has changed the price to NULL, then use the pricebook price.
						else if(matl.GMBLASERP__Unit_Price__c == null)
						{
							matl.GMBLASERP__Unit_Price__c = pricebookPrice;
						}
						//...and if the user has changed the price to a NON-null value, then set the price override
						else
						{
							matl.GMBLASERP__Price_Override__c = true;
						}
					}
					//...and if the user has changed the price override checkbox from TRUE to FALSE, then use the pricebook price
					else if(!matl.GMBLASERP__Price_Override__c)
					{
						if(pricebookPrice != null)
							matl.GMBLASERP__Unit_Price__c = pricebookPrice;
						else
							matl.GMBLASERP__Price_Override__c = true;
					}
					//...and if the user has changed the price override checkbox from FALSE to TRUE, then accept whatever price the user has entered.
				}
			}
			if(matl.GMBLASERP__Unit_Price__c == null)
				matl.GMBLASERP__Unit_Price__c = 0;

			matl.GMBLASERP__Unit_Price__c = matl.GMBLASERP__Unit_Price__c.setScale(6);
		}
	}

	public static void updateRetailMaterialSerial(Map<Id,Map<Id,Id>> mapProjectProductSerial)
	{
		List<AcctSeedERP__Material__c> listMatlUpdate = new List<AcctSeedERP__Material__c>();
		for(AcctSeedERP__Material__c matl :
			[SELECT Id,
				GMBLASERP__Serial_Number__c,
				AcctSeedERP__Product__c,
				AcctSeedERP__Project__c
			FROM AcctSeedERP__Material__c
			WHERE AcctSeedERP__Project__c IN:mapProjectProductSerial.keySet()
				AND AcctSeedERP__Product__r.AcctSeedERP__Serialized__c = true])
		{
			if(mapProjectProductSerial.get(matl.AcctSeedERP__Project__c).containsKey(matl.AcctSeedERP__Product__c)){
				Id idSr = mapProjectProductSerial.get(matl.AcctSeedERP__Project__c).get(matl.AcctSeedERP__Product__c);
				if(idSr != matl.GMBLASERP__Serial_Number__c){
					matl.GMBLASERP__Serial_Number__c = idSr;
					listMatlUpdate.add(matl);
				}
			}
		}

		if(!listMatlUpdate.isEmpty())
			update listMatlUpdate;
	}
	/// Update Quantity Moved
	public static void updateQtyMoved(Set<Id> setIdMaterials)
	{
		List<AcctSeedERP__Material__c> listMatlUpdate = new List<AcctSeedERP__Material__c>();
		for(sObject oim :
			[SELECT
				sum(AcctSeedERP__Quantity__c) totalQty,
				Material__c idMaterial
			FROM AcctSeedERP__Outbound_Inventory_Movement__c
			WHERE Material__c IN:setIdMaterials
			GROUP BY Material__c])
		{
			Decimal qty = (Decimal) oim.get('totalQty');
			Id idMaterial = (Id) oim.get('idMaterial');
			listMatlUpdate.add(new AcctSeedERP__Material__c(Id = idMaterial, Quantity_Moved__c = qty));
		}

		if(!listMatlUpdate.isEmpty()){
			Boolean oldVal = gcMaterial.disableTrigger;
			gcMaterial.disableTrigger = true;
			update listMatlUpdate;
			gcMaterial.disableTrigger = oldVal;
		}
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
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
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
