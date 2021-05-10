public class ProductBoatExt {

	public class upgradeWrapper{

		public String cost { get; set; }
		public String optionId { get; set; }
		public Boolean isBiggestMotor { get; set; }
		public Boolean displayOnWeb { get; set; }
		public Decimal d_cost { get; set; }
		public String productName { get; set; }
		public Id productId { get; set; }
		public Id productUpgradeId { get; set; }
		public Id upgradeCostId { get; set; }

		public upgradeWrapper(Product2 prod, Map<Id, Product_Upgrade_Cost__c> costMap, Product_Option__c option )
		{
			this.productName = prod.Name;
			this.productId = prod.Id;
			this.d_cost = null;
			this.optionId = option.Id;
			this.isBiggestMotor = option.isBiggestMotor__c;
			this.displayOnWeb = option.displayOnWeb__c;
			if( prod.To_Product_Upgrades__r.size() > 0 )
			{
				//we have an upgrade so now working need to find the cost
				this.productUpgradeId = prod.To_Product_Upgrades__r[0].Id;
				if( costMap.containsKey( prod.To_Product_Upgrades__r[0].Id) )
				{
					this.d_cost = costMap.get( prod.To_Product_Upgrades__r[0].Id).Cost__c;
					this.cost = String.valueOf( this.d_cost );
					this.upgradeCostId = costMap.get( prod.To_Product_Upgrades__r[0].Id).Id;
				}
				else
				{
					this.cost = 'Set Upgrade Cost';
				}
			}
			//no upgrades so use the price in the pricebook
			else
			{
				if( prod.PricebookEntries.size() > 0 )
				{
					this.d_cost = prod.PricebookEntries[0].UnitPrice;
					this.cost = String.valueOf( this.d_cost ) + ' (Sale Price)';
				}
				else
				{
					this.cost = 'Price has not been set in selected Pricebook';
				}
			}
		}

	}

	public class optionWrapper {
		public String productNumber {get; set; }
		public String productName {get; set; }
		public Decimal max {get; set; }
		public Decimal standard {get; set; }
		public String Id {get; set; }
		public Boolean displayOnWeb {get; set; }

		public optionWrapper( Product_Option__c option )
		{
			this.Id = option.Id;
			this.displayOnWeb = option.displayOnWeb__c;
			this.max = option.Maximum__c;
			this.standard = option.Standard__c;
			this.productName = option.From_Product__r.Name;
			this.productNumber = option.From_Product__r.ProductCode == null ? '-' : option.From_Product__r.ProductCode;
		}
	}

	 private ApexPages.StandardController std;

	 public final Id recordId;
	 public final Product2 currentProduct;
	 public final Pricebook2[] availablePricebooks;
	 public String selectedPb { get; set; }
	 public List<Product_Option__c> productOptions {get; private set;}
	 public Map<String, List<upgradeWrapper>> productUpgradeMap { get; set; }


	 //public Map<String, List<Product_Option__c>> productOptionsMap {
		//get {
		//		if( productOptionsMap == null ){
		//				productOptionsMap = new Map<String, List<Product_Option__c>>();
		//		}
		//		return productOptionsMap;
		//}
		//private set;
	 //}

	  public Map<String, List<optionWrapper>> productOptionsMap {
		get {
				if( productOptionsMap == null ){
						productOptionsMap = new Map<String, List<optionWrapper>>();
				}
				return productOptionsMap;
		}
		private set;
	 }

	 public Map<String, String> familyNames {
	 	get {
	 		if( familyNames == null )
	 		{
	 			familyNames = new MAp<String, String>();
	 		}
	 		return familyNames;
	 	}
	 	private set;
	 }

	public Map<String, List<String>> productFeatures { get {
	 	if( productFeatures == null)
	 	{
	 		productFeatures = new Map<String, List<String>>();
	 	}
	 	return productFeatures;
	 	} private set;
	}

 	public Map<String, Product_Option__c> upgradeIds { get; set; }
 	public Set<String> standardProductIds;
 	public Map<String, String> upgradeRecordTypes { get; private set; }
 	public Map<String, Boolean> upgradeTabRenderer { get; set; }


	 /* ++++++++++++++++++++ CONSTRUCTOR +++++++++++++++++++++++ */



		public ProductBoatExt(ApexPages.StandardController stdCtrl) {
			std=stdCtrl;
			recordId = std.getId(); //ID of the Product record we are working on - will be null if new Product record
			Set<id> pbRTids = new Set<Id>{
				LGND_Utilities.recordTypeIdFromName('Pricebook2', 'Sales'),
				LGND_Utilities.recordTypeIdFromName('Pricebook2', 'Dealer')
			};
			availablePricebooks = [SELECT Id, Name FROM Pricebook2 WHERE isActive = true AND RecordTypeId IN : pbRTids];
			upgradeRecordTypes = new Map<String, String>{'Motor' => 'motor', 'Trailer' => 'trailer', 'Trolling Motor' => 'trolling_motor'};
			selectedPb = [SELECT Id
										FROM Pricebook2
										WHERE Id = :Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c].Id;

			if(recordId != null){
					currentProduct = [SELECT Id,
																	 Name,
																	 Standard_Motor__c,
																	 Standard_Trailer__c,
																	 Standard_Trolling_motor__c,
																	 (SELECT Feature_ID__r.Description__c, Feature_ID__r.Category__c
																			FROM Product_Feature_Maps__r ORDER BY Rank__c),
																	 (SELECT Id,
																					 From_Product__r.Name,
																					 From_Product__r.Family,
																					 From_Product__r.ProductCode,
																					 From_Product__r.RecordType.Name,
																					 isBiggestMotor__c,
																					 displayOnWeb__c,
																					 Maximum__c,
																					 Standard__c,
																					 Rank__c
																		FROM To_Product_Options__r
																		ORDER BY Rank__c),
																	 (SELECT Id, Fee_Product__r.Name, Fee_Product__r.Id
																		 FROM Parent_Product_Fee_Maps__r)
																	 FROM Product2
																	 WHERE Id = :recordId];
					productOptions = currentProduct.To_Product_Options__r;
					setStandardProductIds();
					catagorizeOptions();
					for(String fam : productOptionsMap.keySet() )
		      {
		        familyNames.put(fam, fam.replaceAll('[^a-zA-Z0-9]', '').replace(' ', '_').toLowerCase() );
		      }
					if(currentProduct.Product_Feature_Maps__r.size() > 0){
							catagorizeFeatures();
					}
					//if( currentProduct.Boat_Rigging_Checklist_Maps__r.size() > 0 )
					//{
					//	catagorizeRiggingChecklists();
					//}
			}
		}

		/* ++++++++++++++++++++++++++++ RENDERER HELPERS ++++++++++++++++++++++++++ */
		public Boolean getRenderMotorUpgrades()
		{
			return productUpgradeMap == null ? false :
				productUpgradeMap.get('Motor').size() > 0 ? true : false;
		}

		public Boolean getRenderTrailerUpgrades()
		{
			return productUpgradeMap == null ? false :
				productUpgradeMap.get('Trailer').size() > 0 ? true : false;
		}

		public Boolean getRenderTrollingMotorUpgrades()
		{
			return productUpgradeMap == null ? false :
				productUpgradeMap.get('Trolling Motor').size() > 0 ? true : false;
		}

		public Boolean getHasFeatures()
		{
			return productFeatures.size() > 0 ? true : false;
		}

		//public Boolean getHasRiggingChecklistItems()
		//{
		//	return riggingChecklistItems.size() > 0 ? true : false;
		//}

		private void setUpgradeTabRenderer()
		{
			upgradeTabRenderer = new Map<String, Boolean>();
			for( String rt : upgradeRecordTypes.keySet() )
			{
				upgradeTabRenderer.put( rt, false );
				if( productUpgradeMap.containsKey( rt ) && productUpgradeMap.get(rt).size() > 0 )
				{
					upgradeTabRenderer.put( rt, true );
				}
			}
		}
		/* ========================= /RENDERER HELPERS =========================== */




		public PageReference editFeatures() {
				return new PageReference('/apex/ProductFeatureSelect?Id=' + recordId);
		}

		public SelectOption[] getPricebookOptions()
		{
			List<SelectOption> options = new List<SelectOption>();
			for(Pricebook2 pb : availablePricebooks )
			{
				options.add( new SelectOption(pb.Id, pb.Name) );
			}
			return options;
		}

		public void pricebookChanged()
		{
			selectedPb = ApexPages.currentPage().getParameters().get('pricebookId');
			buildUpgradeOptions();
		}





		//************** PRIVATE METHODS  *********************//

		private void setStandardProductIds()
		{
				standardProductIds = new Set<String>();
				standardProductIds.add( currentProduct.Standard_Motor__c );
				standardProductIds.add( currentProduct.Standard_Trailer__c );
				standardProductIds.add( currentProduct.Standard_Trolling_Motor__c );
		}

		private void catagorizeOptions() {
			System.debug('%%%%%%%%%%%%%%%%%%%%%%%%%%%%% - catagorizeOptions()' );
			upgradeIds = new Map<String, Product_Option__c>();

			for(Product_Option__c option : productOptions) {
				if( upgradeRecordTypes.keySet().contains( option.From_Product__r.RecordType.Name ) ) {
						upgradeIds.put(option.From_Product__r.Id, option);
				}
				else if( option.From_Product__r.RecordType.name == 'Protection and Services')
				{
					addToOptionsMap(option);
				}
				else {//if( partTypes.contains(option.From_Product__r.Family) ){
						addToOptionsMap(option);
				}
			}
			buildUpgradeOptions();
		}

		private void buildUpgradeOptions() {
			System.debug('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% - buildUpgradeOptions()');
			/* initialize/empty all holding variables */
			productUpgradeMap = new Map<String, List<upgradeWrapper>>();
			for( String rt : upgradeRecordTypes.keySet())
			{
				productUpgradeMap.put(rt, new List<upgradeWrapper>() );
			}

			if( !upgradeIds.isEmpty() )
			{
				List<Product2> upgradeItems =  [SELECT Id, Name, RecordType.Name,
								(SELECT UnitPrice FROM PricebookEntries WHERE Pricebook2Id = :selectedPb),
								(SELECT Id, Price__c FROM To_Product_Upgrades__r WHERE From_Product__c IN :standardProductIds )
								FROM Product2 WHERE Id IN :upgradeIds.keyset()];
				List<Id> productUpgradeIds = new List<Id>();
				for( Product2 p : upgradeItems)
				{
					if( p.To_Product_Upgrades__r.size() > 0 )
					{
						productUpgradeIds.add( p.To_product_Upgrades__r[0].Id );
					}
				}
				List<Product_Upgrade_Cost__c> upgradeCosts = [SELECT Id, Product_Upgrade__c, Cost__c
																				 								FROM Product_Upgrade_Cost__c
																				 								WHERE Price_book__c = :selectedPb
																												AND Product_Upgrade__c IN : productUpgradeIds];
				//a Map of <Product_Upgrade__c, Product_Ipgrade_Cost__c>
				Map<Id, Product_Upgrade_Cost__c> costMap = new Map<Id, Product_Upgrade_Cost__c>();
				for( Product_Upgrade_Cost__c puc : upgradeCosts )
				{
					costMap.put( puc.Product_Upgrade__c, puc );
				}
				//create upgrade wrappers
				for( Product2 p : upgradeItems )
				{
					if( productUpgradeMap.containsKey( p.RecordType.Name) )
					{
						productUpgradeMap.get( p.RecordType.Name ).add( new upgradeWrapper( p, costMap, upgradeIds.get(p.Id) ) );
					}
				}
				sortUpgradesByCost();
			}
			setUpgradeTabRenderer();
		}

		private void addToOptionsMap(Product_Option__c option){
			String pFamily = option.From_Product__r.Family == null ? 'Misc Parts' : option.From_Product__r.Family;
			if( !productOptionsMap.containsKey(pFamily) )
			{
					//productOptionsMap.put(pFamily, new List<Product_Option__c>() );
					productOptionsMap.put(pFamily, new List<optionWrapper>() );
			}
			productOptionsMap.get(pFamily).add(new optionWrapper(option) );
		}

		private void catagorizeFeatures() {
			//initProductFeatures();
			for( Product_Feature_Map__c pfm : currentProduct.Product_Feature_Maps__r ){
				if( !productFeatures.containsKey( pfm.Feature_ID__r.Category__c ) ){
					productFeatures.put( pfm.Feature_ID__r.Category__c, new List<String>() );
				}
				productFeatures.get(pfm.Feature_ID__r.Category__c).add(pfm.Feature_ID__r.Description__c);
			}
		}
		private void sortUpgradesByCost()
		{
			for(String key : productUpgradeMap.keySet() )
			{
				productUpgradeMap.put(key, sortedByCost( productUpgradeMap.get(key) ) );
			}
		}

		private List<upgradeWrapper> sortedByCost(List<upgradeWrapper> upgrades){
				List<upgradeWrapper> sorted = new List<upgradeWrapper>();
				Integer lowest = null;
				while(upgrades.size() > 0){
						for(Integer i=0; i< upgrades.size(); i++)
						{
								//if(upgrades[i].To_Product_Upgrades__r.size() > 0){
										if(lowest == null){
												lowest = i;
										//} else if( upgrades[lowest].To_Product_Upgrades__r.size() == 0){
										//		lowest = i;
										} else if( upgrades[i].d_cost <  upgrades[lowest].d_cost ){
												lowest = i;
										}
								//} else if (upgrades[i].PricebookEntries.size() > 0){
								//		if(lowest == null){
								//				lowest = i;
								//		} else if( upgrades[i].PricebookEntries[0].UnitPrice < upgrades[lowest].PricebookEntries[0].UnitPrice){
								//				lowest = i;
								//		}
								//} else if ( upgrades[i].PricebookEntries.size() == 0 ){
								//		upgrades.remove(i);
								//}
						}
						if(lowest == null){
								for(Integer i=0; i<upgrades.size(); i++){
										sorted.add(upgrades[i]);
										upgrades.remove(i);
								}
						} else {
								sorted.add(upgrades[lowest]);
								upgrades.remove(lowest);
								lowest = null;
						}
				}
				return sorted;
		}

}