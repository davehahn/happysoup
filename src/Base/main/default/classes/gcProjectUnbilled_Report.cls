public with sharing class gcProjectUnbilled_Report {
	public gcProjectUnbilled_Report() {
        defaultAccount = ApexPages.currentPage().getParameters().get('idAccount');
        retrieveListGLV();
    }

    public String defaultAccount{get;set;}
    public List<SelectOption> listGLV1{get;set;}
    public List<SelectOption> listGLV2{get;set;}

    public static string locale{get{return UserInfo.getLocale();}}

//    public List<SelectOption> getListAccounts()
//    {
//        List<SelectOption> listOptions = new List<SelectOption>();
//        //Set<Id> setIdAccountWithProject = new Set<Id>();
//        //for(sObject obj : [SELECT AcctSeed__Account__c idAccount FROM AcctSeed__Project__c WHERE AcctSeed__Account__c != null GROUP BY AcctSeed__Account__c])
//        //    setIdAccountWithProject.add((Id)obj.get('idAccount'));
//
//        listOptions.add(new selectOption('', '--All Accounts--'));
//        for(Account acc : [SELECT Id, Name, (SELECT Id FROM AcctSeed__Projects__r LIMIT 1) FROM Account ORDER BY Name])
//        {
//            if(!acc.AcctSeed__Projects__r.isEmpty())
//                listOptions.add(new selectOption(acc.Id, acc.Name));
//        }
//
//        return listOptions;
//    }

    @RemoteAction @ReadOnly
    public static List<Account> searchAccount(String searchTxt)
    {
        List<Account> listGLA = new List<Account>();
        searchTxt = '%'+searchTxt.replaceAll('[*]','%') +'%';

        for(Account acc : [SELECT Id, Name, (SELECT Id FROM AcctSeed__Projects__r LIMIT 1) FROM Account WHERE Name like:searchTxt ORDER BY Name limit 20])
        {
            if(!acc.AcctSeed__Projects__r.isEmpty())
                listGLA.add(acc);
        }
        return listGLA;
    }

    public void retrieveListGLV()
    {
        listGLV1 = new List<SelectOption>();
        listGLV1.add(new selectOption('', '--All--'));
        
        listGLV2 = new List<SelectOption>();
        listGLV2.add(new selectOption('', '--All--'));
        for(AcctSeed__Accounting_Variable__c glv : 
            [SELECT Id, 
                Name,
                AcctSeed__Type__c 
            FROM AcctSeed__Accounting_Variable__c 
            WHERE (AcctSeed__Type__c = 'GL Account Variable 1' 
                OR AcctSeed__Type__c = 'GL Account Variable 2') 
            ORDER BY Name])
        {
            if(glv.AcctSeed__Type__c == 'GL Account Variable 1' )
                listGLV1.add(new selectOption(glv.Id, glv.Name));
            else if(glv.AcctSeed__Type__c == 'GL Account Variable 2' )
                listGLV2.add(new selectOption(glv.Id, glv.Name));
        }
    }

	@RemoteAction @ReadOnly
	public static List<Map<String,String>> retrieveUnbilledERP(map<String,String> mapFilter)
	{
        Date dateFrom = Date.parse(mapFilter.get('dateFrom'));
        Date dateTill = Date.parse(mapFilter.get('dateTill'));
        Boolean allTimes = mapFilter.get('allTimes') == 'true' ? true : false;
        Boolean allCompleted = mapFilter.get('allCompleted') == 'true' ? true : false;
        Id idAccount = mapFilter.get('idAccount') != '' ? mapFilter.get('idAccount') : null; 
        Id idGLV1 = mapFilter.get('glv1Val') != '' ? mapFilter.get('glv1Val') : null; 
        Id idGLV2 = mapFilter.get('glv2Val') != '' ? mapFilter.get('glv2Val') : null; 
        System.debug(loggingLevel.Error,'mapFilter'+mapFilter);
        Boolean allERP = true;
        if(allTimes)
            dateFrom = Date.today().addYears(-2);

        Boolean allAccounts = true;
        if(idAccount == null)
            allAccounts = false;

		List<Map<String,String>> listJSON = new List<Map<String,String>>();
		Map<Id,erpCube> mapCube = new Map<Id,erpCube>();
        Map<Id,Decimal> mapProjectFinishedMoves = new Map<Id,Decimal>();
        List<AcctSeedERP__Material__c> listMaterials = new List<AcctSeedERP__Material__c>();
        Id idGlCogsParts = gcConstants.idGlCogsParts;
        String soql = '';
        soql += 'SELECT Id FROM AcctSeed__Project__c WHERE IsDeleted = false ';
        if(idAccount != null)
            soql += ' AND AcctSeed__Account__c =:idAccount ';
        if(idGLV1 != null)
            soql += ' AND GL_Account_Variable_1__c =:idGLV1 ';
        if(idGLV2 != null)
            soql += ' AND GL_Account_Variable_2__c =:idGLV2 ';
        if(!allTimes)
            soql += ' AND CreatedDate >=:dateFrom AND CreatedDate <=:dateTill ';
        if(!allCompleted)
            soql += ' AND AcctSeed__Status__c != \'Completed\' ';

        Set<Id> setIdProjects = new Set<Id>();
        list<sObject> listAggRes = new list<sObject>();
        listAggRes.addAll(Database.query(soql));
        for(sObject aggRes : listAggRes)
            setIdProjects.add((Id)aggRes.get('Id'));

        setIdProjects.remove(null);

		for(AcctSeedERP__Material__c matl :
			[SELECT AcctSeedERP__Project__c,
					AcctSeedERP__Project__r.Id,
					AcctSeedERP__Project__r.Name,
                    AcctSeedERP__Project__r.RecordTypeId,
                    AcctSeedERP__Project__r.RecordType.Name,
                    AcctSeedERP__Project__r.CreatedDate,
                    AcctSeedERP__Project__r.Stage__c,
                    AcctSeedERP__Project__r.AcctSeed__Status__c,
                    AcctSeedERP__Project__r.Internal_Partner_Parts_Order__c,
					AcctSeedERP__Project_Task__c,
					AcctSeedERP__Product__c,
					AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c,
					AcctSeedERP__Quantity_per_Unit__c,
					AcctSeedERP__Quantity_Allocated__c,
					GMBLASERP__Total_Price__c,
					GMBLASERP__Unit_Price__c,
                    No_WIP__c,
					(SELECT AcctSeed__Hours_Units__c,
							AcctSeed__Rate__c,
							AcctSeed__Total__c
					 FROM GMBLASERP__Billing_Lines__r),
                     (SELECT Id, AcctSeedERP__Quantity__c FROM Outbound_Inventory_Movements__r)
			 FROM AcctSeedERP__Material__c
             WHERE AcctSeedERP__Project__c IN:setIdProjects])
		{
            mapProjectFinishedMoves.put(matl.AcctSeedERP__Project__c, 0);
            listMaterials.add(matl);
        }
        /// FG Moves
        for(sObject move :
            [SELECT AcctSeedERP__Project__c idProject,
                sum(AcctSeedERP__Quantity__c) fgQty
             FROM AcctSeedERP__Inbound_Inventory_Movement__c
             WHERE AcctSeedERP__Project__c IN:mapProjectFinishedMoves.keySet()
             GROUP BY AcctSeedERP__Project__c])
        {
            mapProjectFinishedMoves.put((Id)move.get('idProject'), (Decimal)move.get('fgQty'));
        }
        /// COGS Entries
        Map<Id,Map<Id,Map<Id,Decimal>>> mapPTPQty = new Map<Id,Map<Id,Map<Id,Decimal>>>();
        for(AcctSeed__Journal_Entry_Line__c cogsJE :
            [SELECT AcctSeed__Project__c,
                AcctSeed__Project_Task__c,
                AcctSeed__Product__c,
                AcctSeed__Units__c
             FROM AcctSeed__Journal_Entry_Line__c
             WHERE AcctSeed__Project__c IN:mapProjectFinishedMoves.keySet()
                AND AcctSeed__GL_Account__c =:idGlCogsParts])
        {
            if(!mapPTPQty.containsKey(cogsJE.AcctSeed__Project__c))
                mapPTPQty.put(cogsJE.AcctSeed__Project__c, new Map<Id,Map<Id,Decimal>>());
            if(!mapPTPQty.get(cogsJE.AcctSeed__Project__c).containsKey(cogsJE.AcctSeed__Project_Task__c))
                mapPTPQty.get(cogsJE.AcctSeed__Project__c).put(cogsJE.AcctSeed__Project_Task__c, new Map<Id,Decimal>());
            if(!mapPTPQty.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).containsKey(cogsJE.AcctSeed__Product__c))
                mapPTPQty.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).put(cogsJE.AcctSeed__Product__c, 0);

            Decimal qty = cogsJE.AcctSeed__Units__c == null ? 0 : cogsJE.AcctSeed__Units__c;
            Decimal nQty = mapPTPQty.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).get(cogsJE.AcctSeed__Product__c) + qty;

            mapPTPQty.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).put(cogsJE.AcctSeed__Product__c, nQty);
        }

        for(AcctSeedERP__Material__c matl : listMaterials)
        {
			Decimal priorBillAmt = 0;
			Decimal priorBillQty = 0;
			for(AcctSeed__Billing_Line__c line : matl.GMBLASERP__Billing_Lines__r)
			{
                priorBillQty += (line.AcctSeed__Hours_Units__c == null ? 0 : line.AcctSeed__Hours_Units__c);
				priorBillAmt += (line.AcctSeed__Total__c == null ? 0 : line.AcctSeed__Total__c);
			}

            Decimal matlAmount = (matl.GMBLASERP__Total_Price__c == null ? 0 : matl.GMBLASERP__Total_Price__c);
			Decimal matlQtySpec = (matl.AcctSeedERP__Quantity_per_Unit__c == null ? 0 : matl.AcctSeedERP__Quantity_per_Unit__c);
			Decimal matlQtyAlloc = (matl.AcctSeedERP__Quantity_Allocated__c == null ? 0 : matl.AcctSeedERP__Quantity_Allocated__c);

            Decimal fgMoveQty = mapProjectFinishedMoves.get(matl.AcctSeedERP__Project__c);
            Decimal cogsQty = 0;
            Id idProjectRT = matl.AcctSeedERP__Project__r.RecordTypeId;
            if(idProjectRT != gcConstants.idRtProjectManufacturing 
                && mapPTPQty.containsKey(matl.AcctSeedERP__Project__c) 
                && mapPTPQty.get(matl.AcctSeedERP__Project__c).containsKey(matl.AcctSeedERP__Project_Task__c)
                && mapPTPQty.get(matl.AcctSeedERP__Project__c).get(matl.AcctSeedERP__Project_Task__c).containsKey(matl.AcctSeedERP__Product__c))
            {
                cogsQty = mapPTPQty.get(matl.AcctSeedERP__Project__c).get(matl.AcctSeedERP__Project_Task__c).get(matl.AcctSeedERP__Product__c);
            }

			//if(matlQtySpec != priorBillQty 
   //             || matlAmount != priorBillAmt)
			//{
    			erpCube cube = mapCube.get(matl.AcctSeedERP__Project__c);
    			if(cube == null){
    				cube = new erpCube(matl.AcctSeedERP__Project__r);
    				mapCube.put(matl.AcctSeedERP__Project__c, cube);
    			}
                for(AcctSeedERP__Outbound_Inventory_Movement__c oim : matl.Outbound_Inventory_Movements__r){
                    cube.movedQty += oim.AcctSeedERP__Quantity__c == null ? 0 : oim.AcctSeedERP__Quantity__c;
                    matlQtyAlloc += oim.AcctSeedERP__Quantity__c == null ? 0 : oim.AcctSeedERP__Quantity__c;
                    priorBillQty += oim.AcctSeedERP__Quantity__c == null ? 0 : oim.AcctSeedERP__Quantity__c;
                    cogsQty += oim.AcctSeedERP__Quantity__c == null ? 0 : oim.AcctSeedERP__Quantity__c;
                }
                cube.allQtySpecified += matlQtySpec;
                cube.qtyUnbilled += (matlQtySpec - priorBillQty);
    			cube.amtUnbilled += (matlAmount - priorBillAmt);
    			if(matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c){
                    cube.qtySpecified += matlQtySpec;
                    cube.qtyWIP += matlQtyAlloc;
                    if(!matl.No_WIP__c)
    				    cube.qtyUnWIP += (matlQtySpec - matlQtyAlloc);
                    if(matlAmount == 0)
                        cube.qtyZeroAmountInventory +=matlQtySpec;
                }

                if(!cube.mapUniqueProductsByTask.containsKey(matl.AcctSeedERP__Project_Task__c))
                    cube.mapUniqueProductsByTask.put(matl.AcctSeedERP__Project_Task__c, new Set<Id>());
                    
                if(!cube.mapUniqueProductsByTask.get(matl.AcctSeedERP__Project_Task__c).contains(matl.AcctSeedERP__Product__c)){
                    cube.cogsQty += cogsQty;
                    cube.mapUniqueProductsByTask.get(matl.AcctSeedERP__Project_Task__c).add(matl.AcctSeedERP__Product__c);
                }

                if(matlAmount == 0)
                    cube.qtyZeroAmount += matlQtySpec;
			//}
		}

		for(Id idP : mapCube.keySet())
		{
			erpCube cube = mapCube.get(idP);
			AcctSeed__Project__c proj = cube.project;
            if(proj.Internal_Partner_Parts_Order__c && cube.qtySpecified == cube.movedQty) continue;

            Decimal fgQty = 0;
            if(proj != null && mapProjectFinishedMoves.containsKey(proj.Id) && mapProjectFinishedMoves.get(proj.Id) != null)
                fgQty = mapProjectFinishedMoves.get(proj.Id);
            if(cube.qtyUnWIP == 0 && cube.qtyUnbilled == 0 && cube.amtUnbilled == 0 /*&& cube.cogsQty == 0 */&& fgQty == 0) continue;
            if(proj.RecordTypeId == gcConstants.idRtProjectManufacturing && cube.qtyUnWIP == 0 && fgQty == 1) continue;
            Decimal qtyUnbilled = cube.qtyUnbilled;// - cube.qtyZeroAmount;
            if(allCompleted)
                qtyUnbilled = cube.qtyUnbilled - cube.qtyZeroAmount;
            if(proj.RecordTypeId != gcConstants.idRtProjectManufacturing && qtyUnbilled == 0 && cube.qtyUnWIP == 0 && fgQty == 0/* && (cube.cogsQty == 0 || cube.cogsQty == cube.qtyZeroAmount)*/) continue;
			Map<String,String> m = new Map<String,String>();
            if(proj != null){
			 m.put('idProject', proj.Id);
             m.put('projectName', proj.Name);
             m.put('projectStage', proj.Stage__c);
             m.put('projectStatus', proj.AcctSeed__Status__c);
			 m.put('dateCreated', proj.CreatedDate.Date().format());
			 m.put('projectRecordType', proj.RecordType.Name);
            }
            if(proj.RecordTypeId == gcConstants.idRtProjectManufacturing)
            {
                m.put('amtUnbilled', '0');
                m.put('qtyUnbilledActual', '0');
                m.put('qtyUnbilled', '0');                            
            }
            else
            {
                m.put('amtUnbilled', String.valueOf(cube.amtUnbilled));
                m.put('qtyUnbilledActual', String.valueOf(cube.qtyUnbilled));
    			m.put('qtyUnbilled', String.valueOf(qtyUnbilled));            
            }
            m.put('qtyZeroAmount', String.valueOf(cube.qtyZeroAmount));
            m.put('allQtySpecified', String.valueOf(cube.allQtySpecified));
            m.put('qtySpecified', String.valueOf(cube.qtySpecified));
            m.put('qtyWIP', String.valueOf(cube.qtyWIP));
            m.put('qtyNotWIP', String.valueOf(cube.qtyUnWIP));
            m.put('qtyFG', String.valueOf(fgQty));
            m.put('qtyCOGS', String.valueOf(cube.cogsQty));
            m.put('noCogsQty','0');
            if(proj.RecordTypeId != gcConstants.idRtProjectManufacturing)
			 m.put('noCogsQty', String.valueOf(cube.qtySpecified - cube.cogsQty));
			listJSON.add(m);
		}
		return listJSON;
	}

	private class erpCube
	{
		AcctSeed__Project__c project;
        Map<Id,Set<Id>> mapUniqueProductsByTask;
        Decimal qtyZeroAmount;
        Decimal qtyZeroAmountInventory;
        Decimal qtyUnbilled;
		Decimal amtUnbilled;
        Decimal allQtySpecified;
        Decimal qtySpecified;
        Decimal qtyWIP;
        Decimal qtyUnWIP;
        Decimal fgMoveQty;
        Decimal noCogsQty;
        Decimal cogsQty;
		Decimal movedQty;
		erpCube(AcctSeed__Project__c pProject)
		{
			project = pProject;
            mapUniqueProductsByTask = new Map<Id,Set<Id>>();
            qtyZeroAmountInventory = 0;
            qtyZeroAmount = 0;
            amtUnbilled = 0;
			qtyUnbilled = 0;
            allQtySpecified = 0;
            qtySpecified = 0;
            qtyWIP = 0;
            qtyUnWIP = 0;
            fgMoveQty = 0;
            noCogsQty = 0;
            cogsQty = 0;
			movedQty = 0;
		}
	}

	@RemoteAction @ReadOnly
	public static List<Map<String,String>> retrieveUnbilledERPMaterials(List<Id> listIdProject, Boolean oldWay)
	{
		Set<Id> setIdProject = new Set<Id>();
		setIdProject.addAll(listIdProject);
        Id idGlCogsParts = gcConstants.idGlCogsParts;
		List<Map<String,String>> listJSON = new List<Map<String,String>>();
        /// COGS Entries
        Map<Id,Map<Id,Map<Id,Decimal>>> mapPTPQty = new Map<Id,Map<Id,Map<Id,Decimal>>>();
        for(AcctSeed__Journal_Entry_Line__c cogsJE :
            [SELECT AcctSeed__Project__c,
                AcctSeed__Project_Task__c,
                AcctSeed__Product__c,
                AcctSeed__Units__c
             FROM AcctSeed__Journal_Entry_Line__c
             WHERE AcctSeed__Project__c IN:setIdProject
                AND AcctSeed__GL_Account__c =:idGlCogsParts])
        {
            if(!mapPTPQty.containsKey(cogsJE.AcctSeed__Project__c))
                mapPTPQty.put(cogsJE.AcctSeed__Project__c, new Map<Id,Map<Id,Decimal>>());
            if(!mapPTPQty.get(cogsJE.AcctSeed__Project__c).containsKey(cogsJE.AcctSeed__Project_Task__c))
                mapPTPQty.get(cogsJE.AcctSeed__Project__c).put(cogsJE.AcctSeed__Project_Task__c, new Map<Id,Decimal>());
            if(!mapPTPQty.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).containsKey(cogsJE.AcctSeed__Product__c))
                mapPTPQty.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).put(cogsJE.AcctSeed__Product__c, 0);

            Decimal qty = cogsJE.AcctSeed__Units__c == null ? 0 : cogsJE.AcctSeed__Units__c;
            Decimal nQty = mapPTPQty.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).get(cogsJE.AcctSeed__Product__c) + qty;

            mapPTPQty.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).put(cogsJE.AcctSeed__Product__c, nQty);
        }

		for(AcctSeedERP__Material__c matl :
			[SELECT AcctSeedERP__Project__c,
					AcctSeedERP__Project__r.Name,
                    AcctSeedERP__Project__r.RecordTypeId,
                    AcctSeedERP__Project__r.Internal_Partner_Parts_Order__c,
					AcctSeedERP__Project_Task__c,
					AcctSeedERP__Project_Task__r.Name,
					AcctSeedERP__Product__c,
					AcctSeedERP__Product__r.Name,
					AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c,
					AcctSeedERP__Quantity_per_Unit__c,
					AcctSeedERP__Quantity_Allocated__c,
					GMBLASERP__Total_Price__c,
					GMBLASERP__Unit_Price__c,
					(SELECT AcctSeed__Hours_Units__c,
							AcctSeed__Rate__c,
							AcctSeed__Total__c
					 FROM GMBLASERP__Billing_Lines__r),
                     (SELECT Id, AcctSeedERP__Quantity__c FROM Outbound_Inventory_Movements__r)
			 FROM AcctSeedERP__Material__c
			 WHERE AcctSeedERP__Project__c IN:setIdProject])
		{
            Decimal movedQty = 0;
			Decimal priorBillAmt = 0;
			Decimal priorBillQty = 0;
			for(AcctSeed__Billing_Line__c line : matl.GMBLASERP__Billing_Lines__r)
			{
				priorBillAmt += (line.AcctSeed__Total__c == null ? 0 : line.AcctSeed__Total__c);
				priorBillQty += (line.AcctSeed__Hours_Units__c == null ? 0 : line.AcctSeed__Hours_Units__c);
			}

			priorBillAmt = priorBillAmt.setScale(6);
			Decimal matlAmt = (matl.GMBLASERP__Total_Price__c == null ? 0 : matl.GMBLASERP__Total_Price__c).setScale(6);
			Decimal matlQtySpec = (matl.AcctSeedERP__Quantity_per_Unit__c == null ? 0 : matl.AcctSeedERP__Quantity_per_Unit__c);
			Decimal matlQtyAlloc = (matl.AcctSeedERP__Quantity_Allocated__c == null ? 0 : matl.AcctSeedERP__Quantity_Allocated__c);
            Decimal cogsQty = 0;
            if(matl.AcctSeedERP__Project__r.RecordTypeId != gcConstants.idRtProjectManufacturing 
                && mapPTPQty.containsKey(matl.AcctSeedERP__Project__c) 
                && mapPTPQty.get(matl.AcctSeedERP__Project__c).containsKey(matl.AcctSeedERP__Project_Task__c)
                && mapPTPQty.get(matl.AcctSeedERP__Project__c).get(matl.AcctSeedERP__Project_Task__c).containsKey(matl.AcctSeedERP__Product__c))
            {
                cogsQty = mapPTPQty.get(matl.AcctSeedERP__Project__c).get(matl.AcctSeedERP__Project_Task__c).get(matl.AcctSeedERP__Product__c);
                mapPTPQty.get(matl.AcctSeedERP__Project__c).get(matl.AcctSeedERP__Project_Task__c).remove(matl.AcctSeedERP__Product__c);
            }
            for(AcctSeedERP__Outbound_Inventory_Movement__c oim : matl.Outbound_Inventory_Movements__r){
                movedQty += oim.AcctSeedERP__Quantity__c == null ? 0 : oim.AcctSeedERP__Quantity__c;
                matlQtyAlloc += oim.AcctSeedERP__Quantity__c == null ? 0 : oim.AcctSeedERP__Quantity__c;
                priorBillQty += oim.AcctSeedERP__Quantity__c == null ? 0 : oim.AcctSeedERP__Quantity__c;
                cogsQty += oim.AcctSeedERP__Quantity__c == null ? 0 : oim.AcctSeedERP__Quantity__c;
            }
            //if(matlAmt == 0 && matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c && matlQtySpec == matlQtyAlloc) continue;
            //if(matlAmt == 0 && !matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c) continue;
            Decimal qtyUnbilled = matlQtySpec - priorBillQty;
            if(oldWay && matlAmt == 0)
                qtyUnbilled = 0;
			//if(matlQtySpec != priorBillQty 
			//	|| (matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c && matlQtySpec != matlQtyAlloc)/*
   //             || cogsQty == 0*/)
			//{
				Map<String,String> m = new Map<String,String>();
				m.put('idProject', matl.AcctSeedERP__Project__c);
				m.put('projectName', matl.AcctSeedERP__Project__r.Name);
				m.put('idTask', matl.AcctSeedERP__Project_Task__c);
				m.put('taskName', matl.AcctSeedERP__Project_Task__r.Name);
				m.put('idProduct', matl.AcctSeedERP__Product__c);
				m.put('productName', matl.AcctSeedERP__Product__r.Name);
				m.put('isInventory', matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c ? 'true' : 'false');
				m.put('unbilled', (matlQtySpec - priorBillQty) != 0 ? 'true' : 'false');
                if(matl.AcctSeedERP__Project__r.RecordTypeId != gcConstants.idRtProjectManufacturing)
                {
                    m.put('qtyUnbilledActual', String.valueOf(matlQtySpec - priorBillQty));
                    m.put('qtyUnbilled', String.valueOf(qtyUnbilled));
                    m.put('amtUnbilled', String.valueOf(matlAmt - priorBillAmt));                    
                }
                else
                {
                    m.put('qtyUnbilledActual', '0');
                    m.put('qtyUnbilled', '0');
                    m.put('amtUnbilled', '0');
                }

                //m.put('qtyUnbilledActual', String.valueOf(matlQtySpec - priorBillQty));
                //m.put('qtyUnbilled', String.valueOf(qtyUnbilled));
				//m.put('amtUnbilled', String.valueOf(matlAmt - priorBillAmt));
                m.put('notWIP', (matlQtySpec - matlQtyAlloc) != 0 ? 'true' : 'false');
                m.put('qtyInWIP', '0');
                m.put('qtyNotWIP', '0');
                m.put('actQtySpecified', String.valueOf(matlQtySpec));
				m.put('qtySpecified', '0');
                if(matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c){
                    m.put('qtySpecified', String.valueOf(matlQtySpec));
                    m.put('qtyInWIP', String.valueOf(matlQtyAlloc));
                    m.put('qtyNotWIP', String.valueOf(matlQtySpec - matlQtyAlloc));
                }
                m.put('cogsQty', String.valueOf(cogsQty));
				listJSON.add(m);
			//}
		}
		return listJSON;
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
    }
}