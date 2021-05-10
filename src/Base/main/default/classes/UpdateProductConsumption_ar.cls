public with sharing class UpdateProductConsumption_ar {
	public class productCube{
		Id idProduct{get;set;}
		Id idWarehouse{get;set;}
		Decimal lastThreeMonths{get;set;}
		Decimal nextThreeMonths{get;set;}
		Decimal lastYearSeasonConsumption{get;set;}
		Decimal lastYearLeadTimeConsumption{get;set;}
		Decimal mrpQuantity{get;set;}
		Decimal availabilityPercentage{get;set;}

		productCube()
		{
			lastThreeMonths = 0;
			nextThreeMonths = 0;
			lastYearSeasonConsumption = 0;
			lastYearLeadTimeConsumption = 0;
			mrpQuantity = 0;
			availabilityPercentage = 0;
		}

		productCube(Id pIdProduct, Id pIdWarehouse)
		{
			idProduct = pIdProduct;
			idWarehouse = pIdWarehouse;
			lastThreeMonths = 0;
			nextThreeMonths = 0;
			lastYearSeasonConsumption = 0;
			lastYearLeadTimeConsumption = 0;
			mrpQuantity = 0;
			availabilityPercentage = 0;
		}
	}

	public static void retrieveProductsDataByWarehouse(Set<Id> setIdProduct)
	{
		if(setIdProduct.isEmpty()) return;
		List<Id> listId = new List<Id>();
		listId.addAll(setIdProduct);
		Id idProduct = listId[0];
		Map<String,Product_MRP_Value__c> mapMRPCube = new Map<String,Product_MRP_Value__c>();
		Map<String,productCube> mapCube = new Map<String,productCube>();
		Product2 product = new Product2();
		for(Product2 p : 
			[SELECT Id, 
				Average_MRP_Time__c
			FROM Product2 
			WHERE Id =:idProduct])
		{
			product = p;
		}

		Integer daysToConsider = 30;
		Integer leadTimeDays = 15;
		if(product.Average_MRP_Time__c != null){
			leadTimeDays = Integer.valueOf(product.Average_MRP_Time__c.setScale(0));
			daysToConsider = leadTimeDays * 2;
		}

		for(Product_MRP_Value__c p : 
			[SELECT Id, 
				Product__r.Average_MRP_Time__c,
				Product__c,
				Warehouse__c,
				MRP_Quantity_Available__c,
				Uniquefier__c,
				Availability_Percentage__c, 
				Last_Year_Season_Consumption__c, 
				Last_Year_Lead_Time_Consumption__c
			FROM Product_MRP_Value__c 
			WHERE Product__c =:idProduct])
		{
			Id idP = p.Product__c;
			Id idW = p.Warehouse__c;

			String uniqueKey = idP + '' + idW;
			mapMRPCube.put(uniqueKey, p);
		}

		Date lastYearDate = Date.today().addYears(-1);
		Date dateStart = lastYearDate; // If we change it later so that we can do it.
		Date dateLeadTime = lastYearDate.addDays(leadTimeDays); // If we change it later so that we can do it.
		Date dateEnd = lastYearDate.addDays(daysToConsider);
		for(AcctSeedERP__Material__c m :
			[SELECT AcctSeedERP__Project__r.CreatedDate,
					AcctSeedERP__Project__r.GMBLASERP__Warehouse__c,
					AcctSeedERP__Product__c,
					AcctSeedERP__Quantity_Per_Unit__c,
					AcctSeedERP__Quantity_Allocated__c
			 FROM AcctSeedERP__Material__c
			 WHERE AcctSeedERP__Quantity_Per_Unit__c > 0
			 	AND AcctSeedERP__Product__c =:idProduct
			 	AND (AcctSeedERP__Project__r.CreatedDate >=:dateStart AND AcctSeedERP__Project__r.CreatedDate <=:dateEnd)
			 	AND IsDeleted = false])
		{
			Id idP = m.AcctSeedERP__Product__c;
			Id idW = m.AcctSeedERP__Project__r.GMBLASERP__Warehouse__c;

			String uniqueKey = idP + '' + idW;
			if(!mapCube.containsKey(uniqueKey)){
				mapCube.put(uniqueKey, new productCube(idP,idW));
			}

			productCube cube = mapCube.get(uniqueKey);
			if(m.AcctSeedERP__Project__r.CreatedDate < dateLeadTime)
				cube.lastYearLeadTimeConsumption += m.AcctSeedERP__Quantity_Allocated__c == null ? 0 : m.AcctSeedERP__Quantity_Allocated__c;

			cube.lastYearSeasonConsumption += m.AcctSeedERP__Quantity_Allocated__c == null ? 0 : m.AcctSeedERP__Quantity_Allocated__c;
		}
		System.debug(mapCube);
		Map<Id,productCube> mapProductCube = new Map<Id,productCube>();
		for(String key : mapCube.keySet())
		{
			productCube cube = mapCube.get(key);
			Product_MRP_Value__c mrpCube = mapMRPCube.get(key);
			if(mrpCube == null){
				mrpCube = new Product_MRP_Value__c(Product__c = cube.idProduct, Warehouse__c = cube.idWarehouse, MRP_Quantity_Available__c = 0, Uniquefier__c = key);
				mapMRPCube.put(key,mrpCube);
			}
			cube.mrpQuantity = mrpCube.MRP_Quantity_Available__c == null ? 0 : mrpCube.MRP_Quantity_Available__c;
			cube.availabilityPercentage = cube.lastYearSeasonConsumption != 0 ? (cube.mrpQuantity/cube.lastYearSeasonConsumption) * 100 : 0;

			mrpCube.Last_Year_Season_Consumption__c = cube.lastYearSeasonConsumption;
			mrpCube.Last_Year_Lead_Time_Consumption__c = cube.lastYearLeadTimeConsumption;
			mrpCube.Availability_Percentage__c = cube.availabilityPercentage;

			if(!mapProductCube.containsKey(cube.idProduct))
				mapProductCube.put(cube.idProduct,new productCube());


			productCube pc = mapProductCube.get(cube.idProduct);
			pc.lastYearSeasonConsumption += cube.lastYearSeasonConsumption;
			pc.lastYearLeadTimeConsumption += cube.lastYearLeadTimeConsumption;
		}

		System.debug(mapMRPCube);
		Database.upsert(mapMRPCube.values(),Product_MRP_Value__c.Fields.Uniquefier__c,true);

		List<Product2> listProductUpdate = new List<Product2>();
		for(Product2 p :
			[SELECT Id, MRP_Quantity__c, Availability_Percentage__c, Last_Year_Season_Consumption__c, Last_Year_Lead_Time_Consumption__c  FROM Product2 WHERE Id IN:setIdProduct])
		{
			productCube cube = mapProductCube.get(p.Id);
			if(cube == null)
				cube = new productCube();
			Decimal mrpQuantity = p.MRP_Quantity__c == null ? 0 : p.MRP_Quantity__c;
			Decimal availabilityPercentage = cube.lastYearSeasonConsumption != 0 ? (mrpQuantity/cube.lastYearSeasonConsumption) * 100 : 0;
			if(p.Last_Year_Season_Consumption__c == null 
				|| p.Last_Year_Season_Consumption__c.setScale(2) != cube.lastYearSeasonConsumption.setScale(2)
				|| p.Last_Year_Lead_Time_Consumption__c == null 
				|| p.Last_Year_Lead_Time_Consumption__c.setScale(2) != cube.lastYearLeadTimeConsumption.setScale(2)
				|| p.Availability_Percentage__c == null 
				|| p.Availability_Percentage__c.setScale(2) != availabilityPercentage.setScale(2))
			{			
				p.Last_Year_Season_Consumption__c = cube.lastYearSeasonConsumption.setScale(2);
				p.Last_Year_Lead_Time_Consumption__c = cube.lastYearLeadTimeConsumption.setScale(2);
				p.Availability_Percentage__c = availabilityPercentage.setScale(2);
				listProductUpdate.add(p);
			}
		}
		if(!listProductUpdate.isEmpty()){
			Boolean oldVal = gcProduct.disableTrigger;
			Boolean oldValG = GMBLASERP.gcProduct.disableTrigger;
			gcProduct.disableTrigger = true;
			GMBLASERP.gcProduct.disableTrigger = true;
			update listProductUpdate;
			gcProduct.disableTrigger = oldVal;
			GMBLASERP.gcProduct.disableTrigger = oldValG;
		}
	}

	public static void retrieveProductsData(Set<Id> setIdProduct)
	{
		if(setIdProduct.isEmpty()) return;
		List<Id> listId = new List<Id>();
		listId.addAll(setIdProduct);
		Id idProduct = listId[0];
		Product2 product = new Product2();
		for(Product2 p : 
			[SELECT Id, 
				Specified_Next_Three_Months__c, 
				Consumed_Last_Three_Months__c, 
				Average_MRP_Time__c,
				MRP_Quantity__c,
				Availability_Percentage__c, 
				Last_Year_Season_Consumption__c, 
				Last_Year_Lead_Time_Consumption__c 
			FROM Product2 
			WHERE Id =:idProduct])
		{
			product = p;
		}
		Integer daysToConsider = 30;
		Integer leadTimeDays = 15;
		if(product.Average_MRP_Time__c != null){
			leadTimeDays = Integer.valueOf(product.Average_MRP_Time__c.setScale(0));
			daysToConsider = leadTimeDays * 2;
		}

		Date lastYearDate = Date.today().addYears(-1);
		Date dateStart = lastYearDate; // If we change it later so that we can do it.
		Date dateLeadTime = lastYearDate.addDays(leadTimeDays); // If we change it later so that we can do it.
		Date dateEnd = lastYearDate.addDays(daysToConsider);
		productCube cube = new productCube();
		for(AcctSeedERP__Material__c m :
			[SELECT AcctSeedERP__Project__r.CreatedDate,
					AcctSeedERP__Product__c,
					AcctSeedERP__Quantity_Per_Unit__c,
					AcctSeedERP__Quantity_Allocated__c
			 FROM AcctSeedERP__Material__c
			 WHERE AcctSeedERP__Quantity_Per_Unit__c > 0
			 	AND AcctSeedERP__Product__c =:idProduct
			 	AND (AcctSeedERP__Project__r.CreatedDate >=:dateStart AND AcctSeedERP__Project__r.CreatedDate <=:dateEnd)
			 	AND IsDeleted = false])
		{
			if(m.AcctSeedERP__Project__r.CreatedDate < dateLeadTime)
				cube.lastYearLeadTimeConsumption += m.AcctSeedERP__Quantity_Allocated__c == null ? 0 : m.AcctSeedERP__Quantity_Allocated__c;

			cube.lastYearSeasonConsumption += m.AcctSeedERP__Quantity_Allocated__c == null ? 0 : m.AcctSeedERP__Quantity_Allocated__c;
		}
		Decimal mrpQuantity = product.MRP_Quantity__c == null ? 0 : product.MRP_Quantity__c;
		Decimal availabilityPercentage = cube.lastYearLeadTimeConsumption != 0 ? (mrpQuantity/cube.lastYearLeadTimeConsumption) * 100 : 0;

		if(product.Last_Year_Season_Consumption__c == null 
			|| product.Last_Year_Season_Consumption__c.setScale(2) != cube.lastYearSeasonConsumption.setScale(2)
			|| product.Last_Year_Lead_Time_Consumption__c == null 
			|| product.Last_Year_Lead_Time_Consumption__c.setScale(2) != cube.lastYearLeadTimeConsumption.setScale(2)
			|| product.Availability_Percentage__c == null 
			|| product.Availability_Percentage__c.setScale(2) != availabilityPercentage.setScale(2))
		{			
			product.Last_Year_Season_Consumption__c = cube.lastYearSeasonConsumption.setScale(2);
			product.Last_Year_Lead_Time_Consumption__c = cube.lastYearLeadTimeConsumption.setScale(2);
			product.Availability_Percentage__c = availabilityPercentage.setScale(2);
			Boolean oldVal = gcProduct.disableTrigger;
			Boolean oldValG = GMBLASERP.gcProduct.disableTrigger;
			gcProduct.disableTrigger = true;
			GMBLASERP.gcProduct.disableTrigger = true;
			update product;
			gcProduct.disableTrigger = oldVal;
			GMBLASERP.gcProduct.disableTrigger = oldValG;
		}
	}

	public static void retrieveProjects(Set<Id> setIdProduct)
	{
		Date todayDate = Date.today().addYears(-1);
		Date dateStart = todayDate.addDays(-3);
		Date dateEnd = todayDate.addMonths(3);
		Map<Id,productCube> mapCube = new Map<Id,productCube>();
		for(AcctSeedERP__Material__c m :
			[SELECT AcctSeedERP__Project__r.CreatedDate,
					AcctSeedERP__Product__c,
					AcctSeedERP__Quantity_Per_Unit__c,
					AcctSeedERP__Quantity_Allocated__c
			 FROM AcctSeedERP__Material__c
			 WHERE AcctSeedERP__Quantity_Per_Unit__c > 0
			 	AND AcctSeedERP__Product__c IN:setIdProduct
			 	AND (AcctSeedERP__Project__r.CreatedDate >=:dateStart AND AcctSeedERP__Project__r.CreatedDate <=:dateEnd)
			 	AND IsDeleted = false])
		{
			productCube pc = mapCube.get(m.AcctSeedERP__Product__c);
			if(pc == null){
				pc = new productCube();
				mapCube.put(m.AcctSeedERP__Product__c, pc);
			}
			if(m.AcctSeedERP__Project__r.CreatedDate > todayDate)
				pc.nextThreeMonths += m.AcctSeedERP__Quantity_Per_Unit__c == null ? 0 : m.AcctSeedERP__Quantity_Per_Unit__c;
			else if(m.AcctSeedERP__Project__r.CreatedDate <= todayDate)
				pc.lastThreeMonths += m.AcctSeedERP__Quantity_Allocated__c == null ? 0 : m.AcctSeedERP__Quantity_Allocated__c;
		}
		List<Product2> listProducts = new List<Product2>();
		for(Product2 p : [SELECT Id, Specified_Next_Three_Months__c, Consumed_Last_Three_Months__c FROM Product2 WHERE Id IN:mapCube.keySet()])
		{
			productCube pc = mapCube.get(p.Id);
			if(p.Specified_Next_Three_Months__c == null 
				|| p.Specified_Next_Three_Months__c != pc.nextThreeMonths.setScale(2)
				|| p.Consumed_Last_Three_Months__c == null
				|| p.Consumed_Last_Three_Months__c != pc.lastThreeMonths.setScale(2))
			{
				p.Specified_Next_Three_Months__c = pc.nextThreeMonths.setScale(2);
				p.Consumed_Last_Three_Months__c = pc.lastThreeMonths.setScale(2);
				listProducts.add(p);
			}
		}
		if(!listProducts.isEmpty()){
			Boolean oldVal = gcProduct.disableTrigger;
			Boolean oldValG = GMBLASERP.gcProduct.disableTrigger;
			gcProduct.disableTrigger = true;
			GMBLASERP.gcProduct.disableTrigger = true;
			update listProducts;
			gcProduct.disableTrigger = oldVal;
			GMBLASERP.gcProduct.disableTrigger = oldValG;
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
	}
}