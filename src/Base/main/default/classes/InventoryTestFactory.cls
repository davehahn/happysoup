/* Any methods starting with 'build' does just that it simply builds and returns the object or List of Objects
   and it your reponsibility to insert it/them in your test if need be
   Any method starting with 'insert'  builds inserts and returns the object or list of objects
*/


@isTest
public class InventoryTestFactory {
  static AcctSeed__GL_Account__c revenueAccount;
  static AcctSeed__GL_Account__c expenseAccount;
  static AcctSeed__GL_Account__c inventoryAccount;

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
  }

  /*
  returns a List of Product2 objects where count equals how many object to build
  and record_type equals the record_type of Product to build (Boat, Motor, Trailer, Part ....)
  */
  public List<Product2> buildTestProducts(Integer count, String record_type) {
    Id rtId = recordIdFromType(record_type);
    Set<String> serializedRTs = new Set<String>{'Boat', 'Trailer', 'Trolling Motor', 'Motor'};
    List<Product2> products = new List<Product2>();
    for(Integer i = 0; i < count; i++){
      Product2 p = new Product2(name = 'InventoryTestxxx999ddd' + record_type + Crypto.getRandomLong(),
                                recordTypeId = rtId,
                                AcctSeedERP__Serialized__c = serializedRTs.contains( record_type ),
                                GMBLASERP__Lot_Tracked__c = serializedRTs.contains( record_type ),
                                Can_be_Nest__c = record_type == 'Boat',
                                Can_be_Nested__c = record_type != 'Boat',
                                AcctSeed__Inventory_Product__c = true,
                                AcctSeed__Inventory_Type__c = 'Purchased',
                                AcctSeed__Accounting_Type__c = 'Taxable_Product',
                                AcctSeed__Expense_GL_Account__c = expenseAccount.Id,
                                AcctSeed__Inventory_GL_Account__c = inventoryAccount.Id,
                                AcctSeed__Revenue_GL_Account__c = revenueAccount.Id,
                                AcctSeed__Unit_Cost__c = 100.00,
                                ProductCode = 'pcode-' + LGND_Utilities.generateRandomString(6),
                                isActive = true);
      products.add(p);
    }
    return products;
  }

  public static List<Product2> insertTestProductsWithStandardPricebookEntries(Integer count, String record_type) {
    Id rtId = recordIdFromType(record_type);
    List<Product2> products = new List<Product2>();
    for(Integer i = 0; i < count; i++){
      Product2 p = new Product2(name = 'InventoryTestxxx999ddd' + record_type + Crypto.getRandomLong(),
                                recordTypeId = rtId,
                                AcctSeed__Inventory_Type__c = 'Purchased',
                                AcctSeed__Accounting_Type__c = 'Taxable_Product',
                                AcctSeed__Expense_GL_Account__c = expenseAccount.Id,
                                AcctSeed__Inventory_GL_Account__c = inventoryAccount.Id,
                                AcctSeed__Revenue_GL_Account__c = revenueAccount.Id,
                                AcctSeed__Unit_Cost__c = 100.00,
                                isActive = true);
      products.add(p);
    }
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert products;
    gcProduct.disableTrigger = orig;
    insertStandardPBEntries(products);
    return products;
  }

  private static void insertStandardPBEntries(List<Product2> prods)
  {
    List<PricebookEntry> pbes = new List<PricebookEntry>();
    //Pricebook2 standardPb = getStandardPricebook();
    for( Product2 p : prods )
    {
      pbes.add( new PricebookEntry(
          Product2Id = p.Id,
          Pricebook2Id = Test.getStandardPricebookId(),
          isActive = true,
          UseStandardPrice= false,
          UnitPrice = 100
        )
      );
    }
    insert pbes;
  }

  public List<Product2> buildTestProducts(Integer count, String record_type, String family) {
    Id rtId = recordIdFromType(record_type);
    Set<String> serializedRTs = new Set<String>{'Boat', 'Trailer', 'Trolling Motor', 'Motor'};
    List<Product2> products = new List<Product2>();
    for(Integer i = 0; i < count; i++){
      Product2 p = new Product2(name = 'InventoryTestxxx999ddd' + family + Crypto.getRandomLong(),
                                recordTypeId = rtId,
                                isActive = true,
                                AcctSeedERP__Serialized__c = serializedRTs.contains( record_type ),
                                GMBLASERP__Lot_Tracked__c = serializedRTs.contains( record_type ),
                                Can_be_Nest__c = record_type == 'Boat',
                                Can_be_Nested__c = record_type != 'Boat',
                                AcctSeed__Inventory_Product__c = true,
                                AcctSeed__Inventory_Type__c = 'Purchased',
                                AcctSeed__Accounting_Type__c = 'Taxable_Product',
                                AcctSeed__Expense_GL_Account__c = expenseAccount.Id,
                                AcctSeed__Inventory_GL_Account__c = inventoryAccount.Id,
                                AcctSeed__Revenue_GL_Account__c = revenueAccount.Id,
                                AcctSeed__Unit_Cost__c = 100.00,
                                Family = family);
      products.add(p);
    }
    return products;
  }

 /* builds inserts and returns products with a standard price entry */
  /* use this method to build anything but Parts */
  public List<Product2> insertTestProducts(Integer count, String record_type) {
    List<Product2> products = buildTestProducts(count, record_type);
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert products;
    gcProduct.disableTrigger = orig;
    List<PricebookEntry> pbEntries = new List<PricebookEntry>();
    Decimal price = 100;
    for(Product2 p : products){
      PricebookEntry pb = new PricebookEntry();
      pb.pricebook2Id = Test.getStandardPricebookId();
      pb.product2id = p.id;
      pb.unitprice = price;
      pb.isactive = true;
      pbEntries.add(pb);
      price += 100;
    }
    insert pbEntries;
    return products;
  }

  /* builds inserts and returns products with a standard price entry */
  /* use this method to build Parts (record_type = 'Part') and pass in
     family (ie accessory) */
  public List<Product2> insertTestProducts(Integer count, String record_type, String family) {
    List<Product2> products = buildTestProducts(count, record_type, family);
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert products;
    gcProduct.disableTrigger = orig;
    List<PricebookEntry> pbEntries = new List<PricebookEntry>();
    Decimal price = 100;
    for(Product2 p : products){
      PricebookEntry pb = new PricebookEntry();
      pb.pricebook2Id = Test.getStandardPricebookId();
      pb.product2id = p.id;
      pb.unitprice = price;
      pb.isactive = true;
      pbEntries.add(pb);
      price += 100;
    }
    insert pbEntries;
    return products;
  }

  /*
  builds and returns a boat object (Product2 with record_type = 'Boat')
  with a standardTrailer and a standardMotor
  */
  public Product2 buildTestBoat() {
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    Product2 motor = buildTestProducts(1, 'Motor')[0];
    Product2 trailer = buildTestProducts(1, 'Trailer')[0];
    Product2 trolling_motor = buildTestProducts(1, 'Trolling Motor')[0];
    System.debug( motor );
    insert motor;
    insert trailer;
    insert trolling_motor;
    Product2 boat = buildTestProducts(1, 'Boat')[0];
    boat.put('Standard_Trailer__c', trailer.Id);
    boat.put('Standard_Motor__c', motor.Id);
    boat.put('Standard_Trolling_Motor__c', trolling_motor.Id);
    gcProduct.disableTrigger = orig;
    return boat;
  }

 /*
  builds and returns a list of boat objects (Product2 with record_type = 'Boat')
  size equal to "count", each with the same standardTrailer and a standardMotor
  */
  public List<Product2> buildTestBoats(Integer count) {
    Product2 motor = buildTestProducts(1, 'Motor')[0];
    Product2 trailer = buildTestProducts(1, 'Trailer')[0];
    insert motor;
    insert trailer;
    List<Product2> boats = buildTestProducts(count, 'Boat');
    for(Product2 boat: boats){
      boat.put('Standard_Trailer__c', trailer.Id);
      boat.put('Standard_Motor__c', motor.Id);
    }
    return boats;
  }

   /* Build Insert and return a boat object with Pricebook entries for
     boat, standard_trailer and standard_motor
  */
  //public List<Product2> insertTestBoatsWithAllPriceBookEntries(Integer count,PriceBook2 standardPb) {
  //  Product2 motor = insertTestProducts(1, 'Motor')[0];
  //  Product2 trailer = insertTestProducts(1, 'Trailer')[0];
  //  Product2 trolling_motor = insertTestProducts(1, 'Trolling Motor')[0];
  //  Fee_Class__c fee_class = new Fee_Class__c(
  //    Name = 'Test Fee Class'
  //  );
  //  insert fee_class;
  //  List<FeeAmount__c> feeAmounts = new List<FeeAmount__c>();
  //  for(Integer i=0; i<4; i++){
  //    feeAmounts.add(  new FeeAmount__c(
  //      FeeClass__c = fee_class.Id,
  //      Name = 'test' + String.valueOf(i) + ' Amount',
  //      Amount__c = 100 )
  //    );
  //  }
  //  insert feeAmounts;
  //  List<PriceBookEntry> pbEntries = new List<PriceBookEntry>();
  //  Integer stdPrice = 12000;
  //  List<Product2> boats = buildTestProducts(count, 'Boat');
  //  for(Product2 boat: boats){
  //    boat.put('Standard_Trailer__c', trailer.Id);
  //    boat.put('Standard_Motor__c', motor.Id);
  //    boat.put('Standard_Motor__c', motor.Id);
  //    boat.put('Standard_Trolling_Motor__c', trolling_motor.Id);
  //    boat.put('Fee_Class__c', fee_class.Id);
  //  }
  //  insert boats;
  //  for(Product2 boat : boats){
  //    PricebookEntry pb = new PricebookEntry();
  //    pb.pricebook2Id = standardPb.id;
  //    pb.product2id = boat.id;
  //    pb.unitprice = stdPrice;
  //    pb.isactive = true;
  //    pbEntries.add(pb);
  //    stdPrice += 1000; // just for the hell of it
  //  }
  //  insert pbEntries;
  //  return boats;
  //}



  /*
  builds, INSERTS and returns a boat object with as many features as the passed in
  variable "feature_count" for each Feature category found in the picklist values
  */
  public Product2 insertTestBoatWithFeatures(Integer featureCount) {
    Product2 boat = buildTestBoat();
    insert boat;
    List<Feature__c> features = buildAllFeatures(featureCount);
    insert features;
    List<Product_Feature_Map__c> maps = new List<Product_Feature_Map__c>();
    for( Feature__c f: features ) {
      Product_Feature_Map__c m = new Product_Feature_Map__c(Product_Id__c = boat.Id, Feature_Id__c = f.Id);
      maps.add(m);
    }
    insert maps;
    return boat;
  }

  /* builds boats with following specs:
      - boat standard price starts at 12000 and increments 1000 for every aditional boat
      - 8 motor upgrades cost starting at 100 and incrementing 100 for every upgrade
      - 2 trailer upgrades cost starting at 100 and incrementing 100 for every upgrade
      - 5 trailer upgrades cost starting at 100 and incrementing 100 for every upgrade
      - 5 safety, hardware,  accessories, price starting at 100 increment by 100 each. Each has max of 4 and first has one included
      - 5 hardware, price starting at 100 increment by 100 each. Each has max of 4 and first has one included
  */
  //public List<Product2> insertFullTestBoats(Integer count, PriceBook2 standardPb) {
  //  List<Product2> boats = insertTestBoatsWithAllPriceBookEntries(count, standardPb);
  //  //insert boats;
  //  List<Product_Option__c> allOptions = new List<Product_Option__c>();
  // // List<PriceBookEntry> pbEntries = new List<PriceBookEntry>();
  //  //Integer stdPrice = 12000;

  //  for(Product2 boat : boats){

  //    /* build 8 Motor upgrade options for each boat */
  //    List<Product_Option__c> m_options = buildMotorOptions( boat, 8 );
  //    for(Product_Option__c opt : m_options){
  //      allOptions.add(opt);
  //    }
  //    /* build 2 Trailer upgrade options for each boat */
  //    List<Product_Option__c> t_options = buildTrailerOptions( boat, 2 );
  //     for(Product_Option__c opt : t_options){
  //      allOptions.add(opt);
  //    }
  //    /* build 5 Trolling Motor upgrade options for each boat */
  //    List<Product_Option__c> tm_options = buildTrollingMotorOptions( boat, 5 );
  //    for(Product_Option__c opt : tm_options){
  //      allOptions.add(opt);
  //    }
  //    insert allOptions;
  //    allOptions.clear();
  //    /* build the 15 Product Upgrade for the above options */
  //    Integer loopCount = 0;
  //    List<Product_Upgrade__c> upgrades = new List<Product_Upgrade__c>();
  //    for(Product_Option__c o: m_options){
  //      upgrades.add( buildProductUpgrade( boat.Standard_Motor__c,
  //                                         o.From_Product__c,
  //                                         Decimal.valueOf((100 + (100 * loopCount ))) )
  //                                       );
  //      loopCount++;
  //    }
  //    loopCount = 0;
  //    for(Product_Option__c o: t_options){
  //      upgrades.add( buildProductUpgrade( boat.Standard_Trailer__c,
  //                                         o.From_Product__c,
  //                                         Decimal.valueOf((100 + (100 * loopCount ))) )
  //                                       );
  //      loopCount++;
  //    }
  //    loopCount = 0;
  //    for(Product_Option__c o: tm_options){
  //      upgrades.add( buildProductUpgrade( boat.Standard_Trolling_Motor__c,
  //                                         o.From_Product__c,
  //                                         Decimal.valueOf((100 + (100 * loopCount ))) )
  //                                       );
  //      loopCount++;
  //    }
  //    insert upgrades;
  //    /* Build 5 options  for all types*/
  //    //List<Product2> accessories = insertTestProducts(5, 'Part', 'Accessories');
  //    List<Product2> hardware = insertTestProducts(5, 'Part', 'Hardware');
  //    List<Product2> graphics = insertTestProducts(5, 'Part', 'Graphics ans Decals');
  //    List<Product2> fAndE = insertTestProducts(5, 'Part', 'Fun and Entertainment');
  //    List<Product2> pontoonCovers = insertTestProducts(5, 'Part', 'Pontoon Covers');
  //    List<Product2> safety = insertTestProducts(5, 'Part', 'Safety');
  //    List<Product2> seating = insertTestProducts(5, 'Part', 'Seating');
  //    List<Product2> trailering = insertTestProducts(5, 'Part', 'Trailering and Covers');
  //    Integer inc = 1;
  //    // for(Product2 p : accessories){
  //    //   Product_Option__c po = new Product_Option__c();
  //    //   po.Standard__c = inc;
  //    //   po.Maximum__c = 4;
  //    //   po.From_Product__c = p.Id;
  //    //   po.To_Product__c = boat.Id;
  //    //   allOptions.add(po);
  //    //   inc = 0;
  //    // }
  //    inc = 1;
  //    for(Product2 p : hardware){
  //      Product_Option__c po = new Product_Option__c();
  //      po.Standard__c = inc;
  //      po.Maximum__c = 4;
  //      po.From_Product__c = p.Id;
  //      po.To_Product__c = boat.Id;
  //      allOptions.add(po);
  //      inc = 0;
  //    }
  //    inc = 1;
  //    for(Product2 p : graphics){
  //      Product_Option__c po = new Product_Option__c();
  //      po.Standard__c = inc;
  //      po.Maximum__c = 4;
  //      po.From_Product__c = p.Id;
  //      po.To_Product__c = boat.Id;
  //      allOptions.add(po);
  //      inc = 0;
  //    }
  //    inc = 1;
  //    for(Product2 p : fAndE){
  //      Product_Option__c po = new Product_Option__c();
  //      po.Standard__c = inc;
  //      po.Maximum__c = 4;
  //      po.From_Product__c = p.Id;
  //      po.To_Product__c = boat.Id;
  //      allOptions.add(po);
  //      inc = 0;
  //    }
  //    inc = 1;
  //    for(Product2 p : pontoonCovers){
  //      Product_Option__c po = new Product_Option__c();
  //      po.Standard__c = inc;
  //      po.Maximum__c = 4;
  //      po.From_Product__c = p.Id;
  //      po.To_Product__c = boat.Id;
  //      allOptions.add(po);
  //      inc = 0;
  //    }
  //    inc = 1;
  //    for(Product2 p : safety){
  //      Product_Option__c po = new Product_Option__c();
  //      po.Standard__c = inc;
  //      po.Maximum__c = 4;
  //      po.From_Product__c = p.Id;
  //      po.To_Product__c = boat.Id;
  //      allOptions.add(po);
  //      inc = 0;
  //    }
  //    inc = 1;
  //    for(Product2 p : seating){
  //      Product_Option__c po = new Product_Option__c();
  //      po.Standard__c = inc;
  //      po.Maximum__c = 4;
  //      po.From_Product__c = p.Id;
  //      po.To_Product__c = boat.Id;
  //      allOptions.add(po);
  //      inc = 0;
  //    }
  //    inc = 1;
  //    for(Product2 p : trailering){
  //      Product_Option__c po = new Product_Option__c();
  //      po.Standard__c = inc;
  //      po.Maximum__c = 4;
  //      po.From_Product__c = p.Id;
  //      po.To_Product__c = boat.Id;
  //      allOptions.add(po);
  //      inc = 0;
  //    }
  //    insert allOptions;
  //    allOptions.clear();
  //  }
  //  //insert pbEntries;
  //  return boats;

  //}

  public List<Product2> insertTestBoats(Integer count){
    List<Product2> boats = buildTestBoats(count);
    insert boats;
    Pricebook2 pbook = [Select Id, Name, IsActive From Pricebook2 where IsStandard = true LIMIT 1];
    if (!pbook.isActive) {
        pbook.isActive = true;
        update pbook;
    }

    List<PricebookEntry> pbEntries = new List<PriceBookEntry>();
    for(Product2 boat : boats){
      PriceBookEntry pbe = new PriceBookEntry(Pricebook2Id = pbook.id,
                                              Product2Id = boat.Id,
                                              UnitPrice = 10000,
                                              isActive = true,
                                              UseStandardPrice = false);
      pbEntries.add(pbe);
    }
    insert pbEntries;
    return boats;
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

  public List<Boat_Rigging_Checklist_Map__c> insertFullRiggingChecklistForBoat(Id boatId, Integer count)
  {
    List<Boat_Rigging_Checklist_Map__c> result = new List<Boat_Rigging_Checklist_Map__c>();
    List<Boat_Rigging_Checklist_Item__c> items = buildAllRiggingChecklistItems( count );
    insert items;
    //Set up the Rank__c value
    Map<String,Integer> countMap = new Map<String, Integer>();
    Schema.DescribeFieldResult category = Boat_Rigging_Checklist_Item__c.Category__c.getDescribe();
    for( Schema.PickListEntry ple : category.getPicklistValues() )
    {
      countMap.put( ple.getLabel(), 1);
    }
    for( Boat_Rigging_Checklist_Item__c i : items )
    {
      Integer rank = countMap.get( i.Category__c );
      result.add( new Boat_Rigging_Checklist_Map__c (
        Product__c = boatId,
        Checklist_Item__c = i.Id,
        Rank__c = rank
        )
      );
      countMap.put( i.Category__c, rank + 1);
    }

    insert result;
    return result;
  }

  public List<Boat_Rigging_Checklist_Item__c> buildAllRiggingChecklistItems( Integer count )
  {
    List<Boat_Rigging_Checklist_Item__c> items = new List<Boat_Rigging_Checklist_Item__c>();
    Schema.DescribeFieldResult category = Boat_Rigging_Checklist_Item__c.Category__c.getDescribe();
    for( Schema.PickListEntry ple : category.getPicklistValues() )
    {
      items.addAll( buildRiggingChecklistItemsForCategory( ple.getLabel(), count) );
    }
    return items;
  }

  public List<Boat_Rigging_Checklist_Item__c> buildRiggingChecklistItemsForCategory( String category, Integer count)
  {
    List<Boat_Rigging_Checklist_Item__c> result = new List<Boat_Rigging_Checklist_Item__c>();
    for( Integer i=0; i<count; i++)
    {
      result.add( new Boat_Rigging_Checklist_Item__c(
        Category__c = category,
        Description__c = 'Test checklist Item number ' + String.valueOf(i)
        )
      );
    }
    return result;
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

  public Product_Upgrade__c buildProductUpgrade() {
    List<Product2> motors = buildTestProducts(2, 'Motor');
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert motors;
    gcProduct.disableTrigger = orig;
    Product2 fromMotor = motors[0];
    Product2 toMotor = motors[1];
    Product_Upgrade__c pu = new Product_Upgrade__c(From_Product__c = fromMotor.Id,
                                                  To_Product__c = ToMotor.Id,
                                                  Price__c = 1500);
    return pu;
  }

  public Product_Upgrade_Cost__c buildUpgradeAndCostForStdPB()
  {
    Product_Upgrade__c pu = buildProductUpgrade();
    insert pu;
    Pricebook2 stdPB = [SELECT Id FROM Pricebook2 WHERE isStandard = true];
    return new Product_Upgrade_Cost__c( Product_Upgrade__c = pu.Id,
                                        Price_Book__c = stdPB.Id,
                                        Cost__c = 100);
  }

  public Product_Upgrade__c buildProductUpgrade(Id fromProduct, Id toProduct, Decimal price) {
    Product_Upgrade__c pu = new Product_Upgrade__c(From_Product__c = fromProduct,
                                                  To_Product__c = ToProduct,
                                                  Price__c = price);
    return pu;
  }

  public List<Product_Option__c> buildPartOptions(Product2 boat, Integer count, String part_type) {
    List<Product2> parts = buildTestProducts(count, 'Part');
    for(Product2 p: parts){
      p.put('Family', part_type);
    }
    insert parts;

    List<Product_Option__c> opts = new List<Product_Option__c>();
    for(Product2 p: parts){
      Product_Option__c po = new Product_Option__c(From_Product__c = p.Id,
                                                   To_Product__c = boat.Id);
      opts.add(po);
    }
    return opts;
  }

  public List<Product_Option__c> buildMotorOptions(Product2 boat, Integer count) {
    List<Product2> motors = insertTestProducts(count, 'Motor');
    //insert motors;

    List<Product_Option__c> opts = new List<Product_Option__c>();
    for(Product2 m: motors){
      Product_Option__c po = new Product_Option__c(From_Product__c = m.Id,
                                                   To_Product__c = boat.Id);
      opts.add(po);
    }
    return opts;
  }

  public List<Product_Option__c> buildTrollingMotorOptions(Product2 boat, Integer count) {
    List<Product2> tmotors = insertTestProducts(count, 'Trolling Motor');
    //insert motors;

    List<Product_Option__c> opts = new List<Product_Option__c>();
    for(Product2 tm: tmotors){
      Product_Option__c po = new Product_Option__c(From_Product__c = tm.Id,
                                                   To_Product__c = boat.Id);
      opts.add(po);
    }
    return opts;
  }

  public List<Product_Option__c> buildTrailerOptions(Product2 boat, Integer count) {
    List<Product2> trailers = insertTestProducts(count, 'Trailer');
    //insert trailers;

    List<Product_Option__c> opts = new List<Product_Option__c>();
    for(Product2 t: trailers){
      Product_Option__c po = new Product_Option__c(From_Product__c = t.Id,
                                                   To_Product__c = boat.Id);
      opts.add(po);
    }
    return opts;
  }

  //************ Private Methods ****************/

  private static Id recordIdFromType(String record_type){
    Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Product2;
    Map<String,Schema.RecordTypeInfo> Product2RecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
    return Product2RecordTypeInfo.get(record_type).getRecordTypeId();
  }

  //private static PriceBook2 getStandardPricebook() {
  //  Pricebook2 standard = [Select Id, Name, IsActive From Pricebook2 where IsStandard = true LIMIT 1];
  //  if (!standard.isActive) {
  //      standard.isActive = true;
  //      update standard;
  //  }
  //  return standard;
  //}

}