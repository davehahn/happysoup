@isTest
public class BoatTestFactory {
  static AcctSeed__GL_Account__c revenueAccount;
  static AcctSeed__GL_Account__c expenseAccount;
  static AcctSeed__GL_Account__c inventoryAccount;

  static Id stdPBId = Test.getStandardPricebookId();

  private static List<String> partTypes;// = new Set<String>( partTypesString.split(',') );

  private Set<String> feeTypes = new Set<String>{'Bank Registration PPSA Fee',
                                                'Documentation Fee',
                                                'Freight',
                                                'License Fee',
                                                'Rigging and Preparation',
                                                'Tire Stewardship Fee'};

  private Set<String> protectionTypes = new Set<String>{'Extended Warranty', 'Service Contract'};

  static {
    List<AcctSeed__GL_Account__c> glAccts = new List<AcctSeed__GL_Account__c>();
    revenueAccount = new AcctSeed__GL_Account__c(Name='Test Revenue Account',
                                                 AcctSeed__Active__c = true,
                                                 AcctSeed__Type__c = 'Revenue');
    expenseAccount = new AcctSeed__GL_Account__c(Name='Test Expense Account',
                                                 AcctSeed__Active__c = true,
                                                 AcctSeed__Type__c = 'Expense');
    inventoryAccount = new AcctSeed__GL_Account__c(Name='Test Inventory Account',
                                                 AcctSeed__Active__c = true,
                                                 AcctSeed__Sub_Type_1__c = 'Assets',
                                                 AcctSeed__Type__c = 'Balance Sheet');
    glAccts.add(revenueAccount);
    glAccts.add(expenseAccount);
    glAccts.add(inventoryAccount);
    insert glAccts;

    List<String> fams = LGND_Utilities.getPicklistValues('Product2', 'Family');
    partTypes = new List<String>();
    for( Integer i=0; i<5; i++)
    {
      partTypes.add( fams.get(i) );
    }
  }


  /* ----------------------------------------------------------------------------------------------------
      .______    __    __   __   __       _______   _______ .______          _______.
      |   _  \  |  |  |  | |  | |  |     |       \ |   ____||   _  \        /       |
      |  |_)  | |  |  |  | |  | |  |     |  .--.  ||  |__   |  |_)  |      |   (----`
      |   _  <  |  |  |  | |  | |  |     |  |  |  ||   __|  |      /        \   \
      |  |_)  | |  `--'  | |  | |  `----.|  '--'  ||  |____ |  |\  \----.----)   |
      |______/   \______/  |__| |_______||_______/ |_______|| _| `._____|_______/

  ----------------------------------------------------------------------------------------------------*/

  public List<Product2> buildFullBoats(Integer count, Pricebook2 pb, String family){
    List<Pricebook2> pbs = new List<Pricebook2>();
    pbs.add(pb);
    return buildFullBoats(count, pbs, family);
  }

  public List<Product2> buildFullBoats(Integer count, Id pbId, String family){
    List<Id> pbIds = new List<Id>();
    pbIds.add(pbId);
    return buildFullBoats(count, pbIds, family);
  }

  public List<Product2> buildFullBoats(Integer count, List<Pricebook2> pbs, String family){
    List<Id> pbIds = new List<Id>();
    for( Pricebook2 pb : pbs )
    {
      pbIds.add(pb.Id);
    }
    return buildFullBoats(count, pbIds, family);
  }

  public List<Product2> buildFullBoats(Integer count, List<Id> pbIds, String family){

    // build 10 Standard Motor/Trailer/Trolling Motor
    //Id pbId = pb == null ? null : pb.Id;
    //Id pbId = pb == null ? stdPB.Id : pb.Id;
    List<Product2> motors = buildTestProducts(10, 'Motor', null);
    motors = insertAndCreatePricebookEntries(motors, pbIds);
    List<Product2> trailers = buildTestProducts(10, 'Trailer', null);
    trailers = insertAndCreatePricebookEntries(trailers, pbIds);
    List<Product2> trolling_motors = buildTestProducts(10, 'Trolling Motor', null);
    trolling_motors = insertAndCreatePricebookEntries(trolling_motors, pbIds);
    // build 5 of each part family
    List<Product2> parts = buildTestPartsForEachFamily(10);
    List<Product2> fees = buildTestProductsForEach(10, 'Fees', feeTypes);
    List<Product2> protectionProducts = buildTestProtectionForEachFamily(2);
    parts = insertAndCreatePricebookEntries(parts, pbIds);
    fees = insertAndCreatePricebookEntries(fees, pbIds);
    protectionProducts = insertAndCreatePricebookEntries(protectionProducts, pbIds);
    Map<String, List<Product2>> sortedPartsMap = sortPartsByFamily(parts);
    Map<String, List<Product2>> sortedFeesMap = sortProductsByFamily(fees, feeTypes);
    Map<String, List<Product2>> sortedProtectionMap = sortProtectionByFamily(protectionProducts);
    //build the boat objects using standard motor/trailer/trolling [0] in the above lists
    List<Product2> boats = buildTestProducts(count, 'Boat', family);
    for( Product2 boat : boats ){
      //set standard equipment
      boat.Standard_Motor__c = motors[0].Id;
      boat.Standard_Trailer__c = trailers[0].Id;
      boat.Standard_Trolling_Motor__c = trolling_motors[0].Id;
    }
    boats = insertAndCreatePricebookEntries(boats, pbIds);

    // build Upgrades for all motors/trailers/trolling motors where from_product is [0] and to_product is the rest
    List<Product_Upgrade__c> allUpgrades = new List<product_Upgrade__c>();
    allUpgrades.addAll( buildUpgrades( trolling_motors[0].Id, trolling_motors) );
    allUpgrades.addAll( buildUpgrades( motors[0].Id, motors) );
    allUpgrades.addAll( buildUpgrades( trailers[0].Id, trailers) );
    insert allUpgrades;
    // now build the Product Costs for everything
    buildAndInsertProductCosts(pbIds, allUpgrades);

    //build Options for everything
    List<Product_Option__c> allOptions = new List<Product_Option__c>();
    List<Product_Fee_Map__c> feeMaps = new List<Product_Fee_Map__c>();
    List<Product_Fee_Amount__c> feeAmounts = new List<Product_Fee_Amount__c>();
    List<Product_Feature_Map__c> featureMaps = new List<Product_Feature_Map__c>();
    List<Feature__c> features = buildAllFeatures(10);
    insert features;
    List<Legend_Gallery_Image__c> marketingImages = buildAndInsertMarketingImages(5);
    List<Legend_Gallery_Image_Map__c> prodImages = new List<Legend_Gallery_Image_Map__c>();

    for( Product2 fee : fees )
    {
      for(Id pbId : pbIds)
      {
        feeAmounts.add( new Product_Fee_Amount__c(
            Price_Book__c = pbId,
            Fee_Product__c = fee.Id,
            Province__c = 'Ontario',
            Amount__c = 100
          )
        );
      }
    }


    for( Product2 boat : boats )
    {
      for(Product2 motor : motors ){
        if(boat.Standard_Motor__c != motor.Id){
          allOptions.add( new Product_Option__c(
            To_Product__c = boat.Id,
            From_Product__c = motor.Id
            )
          );
        }
      }
      allOptions[0].isBiggestMotor__c = true;
      for(Product2 trailer : trailers ){
        if(boat.Standard_Trailer__c != trailer.Id){
          allOptions.add( new Product_Option__c(
            To_Product__c = boat.Id,
            From_Product__c = trailer.Id
            )
          );
        }
      }
      for(Product2 trolling_motor : trolling_motors ){
        if(boat.Standard_Trolling_Motor__c != trolling_motor.Id){
          allOptions.add( new Product_Option__c(
            To_Product__c = boat.Id,
            From_Product__c = trolling_motor.Id
            )
          );
        }
      }
       // add 2 of each fee type to the boat
      for(String fType : feeTypes)
      {
        feeMaps.add( new Product_Fee_Map__c(
          Parent_Product__c = boat.Id,
          Fee_Product__c = sortedFeesMap.get(fType)[0].Id
          )
        );
        feeMaps.add( new Product_Fee_Map__c(
          Parent_Product__c = boat.Id,
          Fee_Product__c = sortedFeesMap.get(fType)[1].Id
          )
        );
      }

      for( Feature__c f : features )
      {
        featureMaps.add( new Product_Feature_Map__c (
          Product_Id__c = boat.Id,
          Feature_Id__c = f.Id
          )
        );
      }
      for( Legend_Gallery_Image__c mi : marketingImages )
      {
        prodImages.add( new Legend_Gallery_Image_Map__c(
          Parent_Object_Id__c = boat.Id,
          Legend_Gallery_Image__c = mi.Id
          )
        );
      }
      boat.Legend_Gallery_Image__c = marketingImages[0].Id;
    }
    //add 1 'Trailering and Covers' option to each motor and 1 extended warranty
   // List<String> pts = partTypesString.split(',');
    List<Product2> covers = sortedPartsMap.get( partTypes[0] );
    List<Product2> hardware = sortedPartsMap.get( partTypes[1] );
    List<Product2> warranty = sortedProtectionMap.get('Extended Warranty');
    List<Product2> contracts = sortedProtectionMap.get('Service Contract');
    for( Product2 motor : motors ){
      allOptions.add( new Product_Option__c(
          To_Product__c = motor.Id,
          From_Product__c = covers[0].Id,
          Standard__c = 0,
          Maximum__c = 1
        )
      );
      allOptions.add( new Product_Option__c(
          To_Product__c = motor.Id,
          From_Product__c = warranty[0].Id,
          Standard__c = 0,
          Maximum__c = 1
        )
      );
    }
    //add 1 'Trailering and Covers' option to each trailer
    for( Product2 trailer : trailers ){
      allOptions.add( new Product_Option__c(
          To_Product__c = trailer.Id,
          From_Product__c = covers[1].Id,
          Standard__c = 0,
          Maximum__c = 1
        )
      );
    }
    //add 1 'Hardware' option to each trolling_motor
    for( Product2 trolling_motor : trolling_motors ){
      allOptions.add( new Product_Option__c(
          To_Product__c = trolling_motor.Id,
          From_Product__c = hardware[0].Id,
          Standard__c = 0,
          Maximum__c = 1
        )
      );
    }
    //add 3 off each product family parts for each boat and 1 service contract
    for( Integer i=0;i<boats.size();i++){
      allOptions.add( new Product_Option__c(
          To_Product__c = boats[i].Id,
          From_Product__c = contracts[0].Id,
          Standard__c = 0,
          Maximum__c = 1
        )
      );
      for( String pt: partTypes ){
        for( Integer ii=3;ii<6;ii++){
          allOptions.add( new Product_Option__c(
              To_Product__c = boats[i].Id,
              From_Product__c = sortedPartsMap.get(pt)[ii].Id,
              Standard__c = 0,
              Maximum__c = 1
            )
          );
          //we will add 3 suboption just once though
          if( i == 0 ){
            for(Integer iii=6;iii<9;iii++){
              allOptions.add( new Product_Option__c(
                  To_Product__c = sortedPartsMap.get(pt)[ii].Id,
                  From_Product__c = sortedPartsMap.get(pt)[iii].Id,
                  Standard__c = 0,
                  Maximum__c = 1
                )
              );
            }
          }
        }
      }
    }
    insert allOptions;
    insert feeMaps;
    insert feeAmounts;
    insert featureMaps;
    insert prodImages;
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    update boats;
    gcProduct.disableTrigger = orig;
    buildAndInsertSampleRetailSale(boats);
    return boats;
  }

  public List<Product2> buildTestProducts(Integer count, String recordType, String family){
    Id rtId = recordTypeIdFromString(recordType);
    List<Product2> products = new List<Product2>();
    for(Integer i=0; i<count; i++){
      products.add( buildTestProduct( 'Test_'+recordType+'-'+Crypto.getRandomLong(), rtId, family) );
    }
    return products;
  }

  public Product2 buildTestProduct(String name, Id recordTypeId, String family){
    Set<Id> serializedProducts = new Set<Id>{
      LGND_constants.productRtId_Boat,
      LGND_constants.productRtId_Motor,
      LGND_constants.productRtId_Trailer,
      LGND_constants.productRtId_TrollingMotor
    };
    Boolean serialized = serializedProducts.contains( recordTypeId );
    return new Product2(name = name,
                        recordTypeId = recordTypeId,
                        family = family,
                        AcctSeedERP__Serialized__c = serialized,
                        GMBLASERP__Lot_Tracked__c = serialized,
                        AcctSeed__Inventory_Type__c = 'Purchased',
                        AcctSeed__Accounting_Type__c = 'Taxable_Product',
                        AcctSeed__Expense_GL_Account__c = expenseAccount.Id,
                        AcctSeed__Inventory_GL_Account__c = inventoryAccount.Id,
                        AcctSeed__Revenue_GL_Account__c = revenueAccount.Id,
                        AcctSeed__Unit_Cost__c = 100.00,
                        isActive = true);
  }

  public List<Feature__c> buildAllFeatures(Integer count) {
    Set<String> categories = new Set<String>();
    Schema.DescribeFieldResult featureCategory = Feature__c.Category__c.getDescribe();
    for( Schema.PickListEntry ple : featureCategory.getPicklistValues() ){
      String cat = ple.getLabel();
      categories.add( cat );
    }
    List<Feature__c> features = new List<Feature__c> ();
    for( String cat : categories ){
      features.addAll( buildFeatures(count, cat) );
    }
    return features;
  }

   /*
  builds and returns a List of features
  count = number of features to create
  */
  public List<Feature__c> buildFeatures(Integer count, String category) {
    List<Feature__c> features = new List<Feature__c>();
    for(Integer i = 0; i < count; i++){
      Feature__c f = new Feature__c(description__c = 'This is number ' + Crypto.getRandomLong() + ' test description', Category__c = category);
      features.add(f);
    }
    return features;
  }

  /*-----------------------------------------------------------------------------------------------------
         __  .__   __.      _______. _______ .______     .___________.    _______.
        |  | |  \ |  |     /       ||   ____||   _  \    |           |   /       |
        |  | |   \|  |    |   (----`|  |__   |  |_)  |   `---|  |----`  |   (----`
        |  | |  . `  |     \   \    |   __|  |      /        |  |        \   \
        |  | |  |\   | .----)   |   |  |____ |  |\  \----.   |  |    .----)   |
        |__| |__| \__| |_______/    |_______|| _| `._____|   |__|    |_______/

  ------------------------------------------------------------------------------------------------------*/
	public List<Product2> insertFullTestBoats(Integer count, Pricebook2 pb){
    List<Pricebook2> pbs = new List<Pricebook2>();
    pbs.add(pb);
    return buildFullBoats(count, pbs, null);
  }

  public List<Product2> insertFullTestBoats(Integer count, Id pbId){
    List<Id> pbIds = new List<Id>();
    pbIds.add(pbId);
    return buildFullBoats(count, pbIds, null);
  }

  public List<Product2> insertFullTestBoats(Integer count, String family){
    List<Pricebook2> pbs = new List<Pricebook2>();
    return buildFullBoats(count, pbs, family);
  }

  public List<Product2> insertFullTestBoats(Integer count, Pricebook2 pb, String family){
    List<Pricebook2> pbs = new List<Pricebook2>();
    if(pb != null)
      pbs.add(pb);
    return buildFullBoats(count, pbs, family);
  }

  public List<Product2> insertFullTestBoats(Integer count, List<Pricebook2> pbs, String family){
    return buildFullBoats(count, pbs, family);
  }

  public List<Product2> insertTestProducts(Integer count, String recordType, List<Pricebook2> pbs){
      List<Product2> products = buildTestProducts(count, recordType, null);
      List<Id> pbIds = new List<Id>();
      for( Pricebook2 pb : pbs )
      {
        pbIds.add(pb.Id);
      }
      return insertAndCreatePricebookEntries(products, pbIds);
  }

  public List<Product2> insertTestProducts(Integer count, String recordType){
      List<Product2> products = buildTestProducts(count, recordType, null);
      List<Id> pbIds = new List<Id>();
      return insertAndCreatePricebookEntries(products, pbIds);
  }

  public List<Product2> insertTestProducts(Integer count, String recordType, Pricebook2 pb){
      List<Product2> products = buildTestProducts(count, recordType, null);
      List<Id> pbIds = new List<Id>();
      if( pb != null )
        pbIds.add(pb.Id);
      return insertAndCreatePricebookEntries(products, pbIds);
  }

  /*------------------------------------------------------------------------------------------------------
      .______   .______       __  ____    ____  ___   .___________. _______     _______.
      |   _  \  |   _  \     |  | \   \  /   / /   \  |           ||   ____|   /       |
      |  |_)  | |  |_)  |    |  |  \   \/   / /  ^  \ `---|  |----`|  |__     |   (----`
      |   ___/  |      /     |  |   \      / /  /_\  \    |  |     |   __|     \   \
      |  |      |  |\  \----.|  |    \    / /  _____  \   |  |     |  |____.----)   |
      | _|      | _| `._____||__|     \__/ /__/     \__\  |__|     |_______|_______/

  ------------------------------------------------------------------------------------------------------*/

  private static Id recordTypeIdFromString(String record_type){
    Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Product2;
    Map<String,Schema.RecordTypeInfo> Product2RecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
    return Product2RecordTypeInfo.get(record_type).getRecordTypeId();
  }

  private List<Product2> insertAndCreatePricebookEntries(List<Product2> products,
                                                         List<Id> pbIds){
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert products;
    gcProduct.disableTrigger = orig;
    Set<Id> productIds = new Set<Id>();
    for(Product2 p : products)
    {
      productIds.add(p.Id);
    }
    PricebookEntry[] standardPBEntries = [SELECT Id, Product2Id
                                            FROM PricebookEntry
                                            WHERE Product2Id IN :productIds
                                            AND Pricebook2Id = :stdPBId];
    Set<Id> productIdWithStandardPriceSet = new Set<id>();
    for(PricebookEntry pb : standardPBEntries)
    {
      productIdWithStandardPriceSet.add(pb.Product2Id);
    }
    List<PricebookEntry> pbEntries = new List<PricebookEntry>();
    Decimal price = 100;

    for( Product2 p : products ){
      if( !productIdWithStandardPriceSet.contains(p.Id) )
      {
        pbEntries.add( new PricebookEntry(
          pricebook2Id = stdPBId,
          product2id = p.Id,
          unitprice = price,
          isActive = true
        ));
      }
      if( pbIds != null && pbIds.size() > 0 )
      {
        for( Id pbId : pbIds )
        {
          if( pbId != stdPBId )
          {
            pbEntries.add( new PricebookEntry(
              pricebook2Id = pbId,
              product2id = p.Id,
              unitprice = price,
              isActive = true
              )
            );
          }
        }
      }
      //price += 100;
    }
    insert pbEntries;
    return products;
  }

  private List<Product2> buildTestProductsForEach(Integer count, String record_type, Set<String> types){
    List<Product2> products = new List<Product2>();
    for( String family : types ){
      products.addAll( buildTestProducts(count, record_type, family) );
    }
    return products;
  }

  private List<Product2> buildTestPartsForEachFamily(Integer count){
    List<Product2> parts = new List<Product2>();
    for( String family : partTypes ){
      parts.addAll( buildTestProducts(count, 'Part', family) );
    }
    return parts;
  }

  private List<Product2> buildTestProtectionForEachFamily(Integer count){
    List<Product2> parts = new List<Product2>();
    for( String family : protectionTypes ){
      parts.addAll( buildTestProducts(count, 'Protection and Services', family) );
    }
    return parts;
  }

  private List<Product_Upgrade__c> buildUpgrades(String fromId, List<Product2> toProducts){
    List<Product_upgrade__c> upgrades = new List<Product_Upgrade__c>();
    Decimal cost = 10;
    for( Product2 p : toProducts ){
      if( fromId != p.Id ){
        upgrades.add( new Product_Upgrade__c(
            From_Product__c = fromId,
            To_Product__c = p.Id,
            Price__c = cost
          )
        );
        //cost += 10;
      }
    }
    return upgrades;
  }

  private List<Legend_Gallery_Image__c> buildAndInsertMarketingImages(Integer count)
  {
    List<Legend_Gallery_Image__c> mImages = new List<Legend_Gallery_Image__c>();
    List<AWS_S3_Object__c> s3Objects = new List<AWS_S3_Object__c>();
    List<Legend_Gallery_Image_Version__c> versions = new List<Legend_Gallery_Image_Version__c>();

    for(Integer i=0; i<count; i++)
    {
      s3Objects.add( new AWS_S3_Object__c(
        File_Name__c = 'Test image ' + String.valueOf(i)
        )
      );
    }
    insert s3Objects;
    for( AWS_S3_Object__c s3 : s3Objects )
    {
      mImages.add( new Legend_Gallery_Image__c(
        Active_S3_Object__c = s3.Id,
        Object_Type__c = 'Product2',
        ENG_Description__c = 'test description english',
        FR_Description__c = 'Test description french'
        )
      );
    }
    insert mImages;
    for( Legend_Gallery_Image__c img : mImages )
    {
      versions.add( new Legend_Gallery_Image_Version__c(
        AWS_S3_Object__c = img.Active_S3_Object__c,
        Legend_Gallery_Image__c = img.Id
        )
      );
    }
    insert versions;
    return mImages;
  }

  private void  buildAndInsertProductCosts( List<Id> pbIds,
                                            List<Product_Upgrade__c> allUpgrades)
  {
    if( pbIds != null && pbIds.size() > 0 )
    {
      List<Product_Upgrade_Cost__c> costs = new List<Product_Upgrade_Cost__c>();

      for( Product_Upgrade__c pu : allUpgrades )
      {
        for(Id pbId : pbIds)
        {
          costs.add( new Product_Upgrade_Cost__c (
              Product_Upgrade__c = pu.Id,
              Price_Book__c = pbId,
              Cost__c = 10.00
            )
          );
        }
      }
      insert costs;
    }
  }

  private List<Product2> allProductsByFamily(List<Product2> products, String family){
    List<Product2> results = new List<Product2>();
    for( Product2 p : products ){
      if( p.Family == family){
        results.add(p);
      }
    }
    return results;
  }

   private Map<String, List<Product2>> sortProductsByFamily(List<Product2> products, Set<String> families){
    Map<String, List<Product2>> results = new Map<String, List<Product2>>();
    for( String family : families ){
      results.put( family, allProductsByFamily(products, family) );
    }
    return results;
  }

  private Map<String, List<Product2>> sortPartsByFamily(List<Product2> parts){
    Map<String, List<Product2>> results = new Map<String, List<Product2>>();
    for( String family : partTypes ){
      results.put( family, allProductsByFamily(parts, family) );
    }
    return results;
  }

  private Map<String, List<Product2>> sortProtectionByFamily(List<Product2> parts){
    Map<String, List<Product2>> results = new Map<String, List<Product2>>();
    for( String family : protectionTypes ){
      results.put( family, allProductsByFamily(parts, family) );
    }
    return results;
  }

  private void buildAndInsertSampleRetailSale(List<Product2> boats)
  {
    Map<Id, Product2> boatMap = new MAp<Id, Product2>(boats);
    List<Boat_Sample_Retail_Sale__c> sampleSales = new List<Boat_Sample_Retail_Sale__c>();
    List<Boat_Sample_Retail_Sale_Example_Product__c> exampleProducts = new List<Boat_Sample_Retail_Sale_Example_Product__c>();
    for( Product2 b : boats )
    {
      sampleSales.add( new Boat_Sample_Retail_Sale__c(
        Boat__c = b.Id
        )
      );
    }
    insert sampleSales;
    for( Boat_Sample_Retail_Sale__c ss : sampleSales )
    {
      Product2 boat = boatMap.get(ss.Boat__c);
      if( boat.To_Product_Options__r != null && boat.To_Product_Options__r.size() > 0 )
      {
        exampleProducts.add( new Boat_Sample_Retail_Sale_Example_Product__c(
          Sample_Retail_Sale__c = ss.Id,
          Product_Option__c = boat.To_Product_Options__r[0].Id
          )
        );
      }
    }
    insert exampleProducts;
  }

}