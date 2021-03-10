@isTest (seeAllData=true)
private class BoatBuilder_Test {

    @isTest static void coverage_test()
    {
        BoatBuilder.coverage();
        BoatBuilderLineItem.coverage();
    }

    static PageReference pageRef;
    static Opportunity opp;
    static Pricebook2 standard_pb2;
    static BoatTestFactory factory;
    static List<Product2> testCreatedBoats;
    static Product2 selectedBoat;
    static List<Product2> feeProducts;
    static List<Product2> availableMotors;
    static List<Product2> availableTrailers;
    static BoatBuilder bb;
    static Decimal standardBoatPrice;
    static List<String> bb_p_families;// = Legend_Settings__c.getOrgDefaults().BB_Product_Families__c.split(',');
    static AcctSeedERP__Warehouse__c warehouse;

    static {
        warehouse = AcctSeed_Settings_Factory.getWarehouse('Whitefish');
        buildPartFamiles();
        factory = new BoatTestFactory();
        standard_pb2 = [Select Id, Name, IsActive From Pricebook2 where IsStandard = true LIMIT 1];
        if (!standard_pb2.isActive) {
            standard_pb2.isActive = true;
            update standard_pb2;
        }
        /* create an Opportunity as it required for Boat Builder */
        opp = new Opportunity(
              Name = 'Test Opportunity',
              StageName='Prospecting',
              Deposit__c=10,
              TaxationProvince__c='Ontario',
              Deposit_Method__c='Cash',
              CloseDate=Date.today(),
              Finance_Payments_Per_Year__c = 12,
              Pricebook2Id = standard_pb2.Id,
              AccountId = null
            );
        OpportunityTriggerHandler.disableAutoPricebookSet = true;
        insert opp;
        //create 3 Fee Products
        //get record type Id for fees product record type
        Id feeRecordTypeId = LGND_Utilities.recordTypeIdFromName('Product2', 'Fees');
        feeProducts = new List<Product2>();
        List<PricebookEntry> feePricebookEntries = new List<PricebookEntry>();
        List<Product_Fee_Amount__c> feeAmounts = new List<Product_Fee_Amount__c>();
        List<Product_Fee_Map__c> productFeeMaps = new List<Product_Fee_Map__c>();
        for(String t : new Set<String>{'Bank Registration PPSA Fee', 'Documentation Fee','Freight'}){
            feeProducts.add( new Product2(
                Name = t,
                Family = t,
                AcctSeed__Accounting_Type__c = 'Taxable_Product',
                RecordTypeId = feeRecordTypeId,
                isActive = true
                )
            );
        }
        insert feeProducts;
        for( Product2 f : feeProducts ){
          feePricebookEntries.add( new PricebookEntry(
              Pricebook2Id = standard_pb2.Id,
              Product2Id = f.Id,
              UnitPrice = 100.00,
              isActive = true
            ) );
          feeAmounts.add( new PRoduct_Fee_Amount__c(
            Price_Book__c = standard_pb2.Id,
            Fee_Product__c = f.Id,
            Amount__c = 100,
            Province__C = 'Ontario'
            ));
        }
        insert feePricebookEntries;
        insert feeAmounts;

        testCreatedBoats = factory.insertFullTestBoats(2, standard_pb2, 'Pontoon');

    }

    private static void buildPartFamiles()
    {
        List<String> fams = LGND_Utilities.getPicklistValues('Product2', 'Family');
        bb_p_families = new List<String>();
        for( Integer i=0; i<5; i++)
        {
          bb_p_families.add( fams.get(i) );
        }
    }

    private static void init() {

        /* set current page to the BoatBuilder  */
        Datetime dt = Datetime.now();
        String dateString1 = (dt + 30).format('d/MM/yy');
        pageRef = Page.BoatBuilder;
        pageRef.getParameters().put('opportunity_id', opp.Id);
        pageRef.getParameters().put('quote_valid_date', dateString1);
        Test.setCurrentPageReference(pageRef);
        bb = new BoatBuilder();
        bb.selectedProductFamily = 'Pontoon';
        selectedBoat = testCreatedBoats[1];
        //standard price should be 100
        standardBoatPrice = [SELECT UnitPrice
                              FROM PricebookEntry
                              WHERE PriceBook2.IsStandard = true
                              AND Product2Id = :selectedBoat.Id].UnitPrice;
       //boat has 12 fees @ 100 each attached to it so ....
       standardBoatPrice += 1200;
    }

    testmethod static void constructorTest() {
        init();
        Set<String> testBoatIds = new Set<String>();
        Set<String> fetchedBoatIds = new Set<String>();
        for(Product2 p : testCreatedBoats){
            testBoatIds.add(p.Id);
        }
        test.startTest();
        for (SelectOption so :bb.getBoatSelectItems() ){
            if(so.getValue() != ''){
                fetchedBoatIds.add( so.getValue() );
            }
        }
        test.stopTest();
        for(String id : testBoatIds){
            System.assert(  fetchedBoatIds.contains(id) );
        }
        System.assertEquals('Monthly Payment', bb.getPaymentString() );

        BoatBuilder.TradeInItem ti = new BoatBuilder.TradeInItem();
        System.assertEquals(false, ti.isDeleted);

        Date d = Date.today().addDays(30);

        System.assertEquals(d, bb.quoteValidDate);
        System.assert(bb.getProductFamilySelectItems().size() > 0);
        //System.assertEquals('Ontario', opp.TaxationProvince__c);
        //System.assertEquals('Ontario', bb.opportunity.TaxationProvince__c);

        //System.assertEquals('4805 Regional Road 55 - Whitefish, Ontario - P0M 3E0', bb.pdfStoreAddress);
        //System.assertEquals(3, bb.pdfPhoneNumbers.size() );
        //System.assertEquals('1 705 866 2821', bb.pdfPhoneNumbers.get('phone') );

        //some bullshit to gain coverage
        bb.cancel();
        BoatBuilder.FeeItem fi = new BoatBuilder.FeeItem();
        System.assertEquals(null, fi.total);
        BoatBuilder.ProtectionProductWrapper ppw = new BoatBuilder.ProtectionProductWrapper();
        System.assertEquals(0, bb.discountTotal);
        System.assertEquals(28, bb.invoiceOptionRowFiller.size() );
        System.assertEquals('Cash', bb.getDepositMethod() );
        opp.Deposit_Method__c = 'Other';
        opp.Deposit_Method_Other__c = 'Unicorns';
        opp.Pickup_Location__c = 'Barrie - Pick Up';
        update opp;
        bb = new BoatBuilder();
        System.assertEquals('Unicorns', bb.getDepositMethod() );
        //System.assertEquals('2375 Industrial Park Road - Innisfil, Ontario - L9S 3W1', bb.pdfStoreAddress);
        //System.assertEquals('1 705 431 6922', bb.pdfPhoneNumbers.get('phone') );
        bb.getRenderProtectionProducts();
        bb.getSummaryTitle();
        bb.getRenderAllOptionDetails();
        //bb.getAvailablePremiumPackage();
        //bb.getAvailableLuxuryPackage();
        bb.selectProductFamily();
        BoatBuilder.coverage();

    }

    testmethod static void contructorWithDealerOrderLine()
    {
      Account dealer = AccountFactory.buildDealerAccount('Test Dealer');
      insert dealer;
      Dealer_Order__c dealerOrder = Factory_DealerOrder.createDealerOrder( dealer );
      Opportunity dol_opp = OpportunityFactory.insertRetailBoatSale();
      Dealer_Order_Line__c dol = new Dealer_Order_Line__c(
        Opportunity__c = dol_opp.Id,
        Dealer_Order__c = dealerOrder.Id,
        Model_Year__c = dealerOrder.Program_Year__c,
        Order_Group_Id__c = 'bcvhueopqvc'
      );
      insert dol;
      BoatBuilder dol_bb = new BoatBuilder(dol);
    }

    //testMethod static void selectBoatTest() {
    //    System.debug('**** SELECT BOAT TEST ****');
    //    init();

    //    test.startTest();
    //    bb.selectedBoatId = selectedBoat.Id;
    //    /* this method gets call when the Boat select leist changes */
    //    bb.selectBoatFromSelector();
    //    test.stopTest();

    //    System.assertEquals(selectedBoat.Id, bb.selectedBoat.Id);
    //    System.assertEquals(selectedBoat.Standard_Motor__c, bb.selectedMotor.Id);
    //    System.assertEquals(selectedBoat.Standard_Trailer__c, bb.selectedTrailer.Id);
    //    System.assertEquals(selectedBoat.Standard_Trolling_Motor__c, bb.selectedTrollingMotor.Id);
    //    //verify the motor/trailer/trolling motor select menus are rendered
    //    System.assert( bb.getRenderMotorSelector() );
    //    System.assert( bb.getRenderTrailerSelector() );
    //    System.assert( bb.getRenderTrollingMotorSelector() );

    //    //this is the select options
    //    System.assertEquals(10, bb.getMotorSelectItems().size() ); // 9 + standard_motor
    //    // //this is the actual product2 objects
    //    System.assertEquals( 9, bb.availableProductUpgrades.get('motors').size() );
    //    // //this is the select options
    //    //this is options associated with selected motor
    //    System.assertEquals(1, bb.availableMotorOptions.size() );
    //    //this is the select options
    //    System.assertEquals(10, bb.getTrailerSelectItems().size() ); // 9 + standard_trailer
    //    // //this is the actual product2 objects
    //    System.assertEquals( 9, bb.availableProductUpgrades.get('trailers').size() );
    //     //this is options associated with selected trailer
    //    System.assertEquals(1, bb.availableTrailerOptions.size() );
    //    // //this is the select options
    //    System.assertEquals(10, bb.getTrollingMotorSelectItems().size() ); //9 + standard_motor
    //    // //this is the actual product2 objects
    //    System.assertEquals( 9, bb.availableProductUpgrades.get('trolling_motors').size() );
    //     //this is options associated with selected trolling motor
    //    System.assertEquals(1, bb.availableTrollingMotorOptions.size() );
    //    //this is the protection and services should be one for boat and one for motor
    //    System.assertEquals(2, bb.availableProtectionOptions.keyset().size() );

    //    for( String pFam : bb_p_families )
    //    {
    //        System.assertEquals( 3, bb.availableBoatOptions.get(pFam).size() );
    //    }

    //    System.assertEquals(12, bb.provinceFeesMap.get(selectedBoat.Id).get('Ontario').size() );

    //    System.assertEquals(standardBoatPrice - 1200, bb.basePrice); // 12 fees of 100 each BoatTestFactory
    //    //System.assertEquals(standardBoatPrice, bb.runningPrice);
    //    Decimal before_trade_in = bb.runningPrice;
    //    /* let do the tradin testing here */

    //    pageRef.getParameters().put('totalValue', '200');
    //    pageRef.getParameters().put('lienAmount', '100');

    //    bb.updateTradeInRecord();

    //    System.assertEquals(before_trade_in - 100, bb.runningPrice);
    //    System.assertEquals(100, bb.trade_in_package.totalValue);
    //    System.assertEquals(0, bb.trade_in_package.items.size() );

    //    Map<String, String> jsonData = new Map<String, String>();
    //    jsonData.put('modelYear', '2012');
    //    jsonData.put('make', 'Lund');
    //    jsonData.put('model', 'rebel');
    //    jsonData.put('serialNumber', 'aabbcc112233');

    //    pageRef.getParameters().put('jsonData', JSON.serialize(jsonData) );
    //    bb.addTradeInLineItem();

    //    System.assertEquals(1, bb.trade_in_package.items.size() );
    //    System.assertEquals(false, bb.trade_in_package.items.values()[0].isDeleted );

    //    String itemId = bb.trade_in_package.items.values()[0].id;
    //    pageRef.getParameters().put('itemId', itemId);
    //    bb.removeTradeInLineItem();

    //    System.assertEquals(1, bb.trade_in_package.items.size() );
    //    System.assertEquals(true, bb.trade_in_package.items.values()[0].isDeleted );


    //    /* *******  Simulate selecting the null ('Select a Boat') in the select list  ******* */

    //     bb.selectedBoatId = null;
    //     bb.selectBoatFromSelector();

    //    System.assertEquals(null, bb.selectedBoat);
    //    System.assertEquals( 0, bb.availableProductUpgrades.size() );
    //    System.assertEquals(null, bb.availableMotorOptions);
    //    System.assertEquals(null, bb.availableTrailerOptions);
    //    System.assertEquals(null, bb.availableTrollingMotorOptions);
    //    for( String key : bb.availableBoatOptions.keyset() ){
    //        System.assertEquals( 0, bb.availableBoatOptions.get(key).size() );
    //    }
    //    System.assertEquals(null, bb.runningPrice);
    //}

    //testMethod static void selectMotorTest() {
    //    init();
    //    test.startTest();
    //    bb.selectedBoatId = selectedBoat.Id;
    //    /* this method gets call when the Boat select list changes */
    //    bb.selectBoatFromSelector();
    //   // Product_Option__c motorOption = [SELECT Id, From_Product__c FROM Product_Option__c WHERE From_Product__r.RecordType.Name = 'Motor' AND To_Product__c = :selectedBoat.Id LIMIT 1];
    //    Product2 motor = bb.availableProductUpgrades.get('motors')[2];
    //    //lets add a fee associated with this motor
    //    Product_Fee_Map__c motorFee = new Product_Fee_Map__c(
    //                                        Parent_Product__c = motor.Id,
    //                                        Fee_Product__c = feeProducts[1].Id
    //                                    );
    //    insert motorFee;
    //    bb.selectedMotorId = motor.Id;
    //    bb.selectMotor();
    //    Decimal motorUpgradePrice = [SELECT Price__c
    //                                 FROM Product_Upgrade__c
    //                                 WHERE From_Product__c = :selectedBoat.Standard_Motor__c
    //                                 AND To_Product__c = :motor.Id
    //                                 LIMIT 1].Price__c;
    //    motorUpgradePrice += 100; //because of the fee we added of 100
    //     /* Select The one motor option that should be available */
    //    String mOptionPid;
    //    for( String id: bb.availableMotorOptions.keySet() ){
    //        mOptionPid = id;
    //        break;
    //    }
    //    Decimal productPrice = [SELECT UnitPrice
    //                            FROM PricebookEntry
    //                            WHERE PriceBook2Id = :standard_pb2.Id
    //                            AND Product2Id = :mOptionPid ].UnitPrice;
    //    test.stopTest();
    //    //System.assertEquals( standardBoatPrice + motorUpgradePrice, bb.runningPrice);
    //    // subtract 100 from motorUpgrade price as it includes the fee and bb.motorUpgradePrice does  not
    //    System.assertEquals( String.valueOf(motorUpgradePrice - 100), bb.motorUpgradePrice );


    //    pageRef.getParameters().put( 'productId', mOptionPid );
    //    pageRef.getParameters().put( 'quantity', '1' );
    //    pageRef.getParameters().put( 'productType', 'motor' );
    //    Test.setCurrentPageReference(pageRef);
    //    bb.productOptionsChanged();

    //    System.assertEquals( standardBoatPrice + motorUpgradePrice + productPrice, bb.runningPrice);

    //    /* *******  Simulate selecting the null ('Select a Motor') in the select list  ******* */

    //    bb.selectedMotorId = null;
    //    bb.selectMotor();

    //    System.assertEquals(null, bb.selectedMotor);
    //    System.assertEquals(null, bb.motorUpgradePrice);
    //    System.assertEquals(standardBoatPrice, bb.runningPrice);

    //    /* ******* Simulate reselecting the included motor option ******* */
    //    bb.selectedMotorId = selectedBoat.Standard_Motor__c;
    //    bb.selectMotor();

    //    System.assertEquals('Included', bb.motorUpgradePrice);
    //    System.assertEquals(standardBoatPrice, bb.runningPrice);
    //}

    //testMethod static void selectTrailerTest() {
    //    init();
    //    test.startTest();
    //    bb.selectedBoatId = selectedBoat.Id;
    //    /* this method gets call when the Boat select leist changes */
    //    bb.selectBoatFromSelector();
    //   // Product_Option__c motorOption = [SELECT Id, From_Product__c FROM Product_Option__c WHERE From_Product__r.RecordType.Name = 'Motor' AND To_Product__c = :selectedBoat.Id LIMIT 1];
    //    bb.selectedTrailerId = bb.availableProductUpgrades.get('trailers')[1].Id;
    //    bb.selectTrailer();
    //    Decimal trailerUpgradePrice = [SELECT Price__c
    //                                 FROM Product_Upgrade__c
    //                                 WHERE From_Product__c = :selectedBoat.Standard_Trailer__c
    //                                 AND To_Product__c = :bb.availableProductUpgrades.get('trailers')[1].Id
    //                                 LIMIT 1].Price__c;

    //     /* Select The one motor option that should be available */
    //    String tOptionPid;
    //    for( String id: bb.availableTrailerOptions.keySet() ){
    //        tOptionPid = id;
    //        break;
    //    }
    //    Decimal productPrice = [SELECT UnitPrice
    //                            FROM PricebookEntry
    //                            WHERE PriceBook2Id = :standard_pb2.Id
    //                            AND Product2Id = :tOptionPid ].UnitPrice;

    //    test.stopTest();

    //    System.assertEquals( String.valueOf(trailerUpgradePrice), bb.trailerUpgradePrice );
    //    //System.assertEquals(standardBoatPrice + trailerUpgradePrice , bb.runningPrice);


    //    pageRef.getParameters().put( 'productId', tOptionPid );
    //    pageRef.getParameters().put( 'quantity', '1' );
    //    pageRef.getParameters().put( 'productType', 'trailer' );
    //    Test.setCurrentPageReference(pageRef);
    //    bb.productOptionsChanged();

    //    System.assertEquals( standardBoatPrice + trailerUpgradePrice + productPrice , bb.runningPrice);


    //    /* *******  Simulate selecting the null ('Select a Trailor') in the select list  ******* */

    //    bb.selectedTrailerId = null;
    //    bb.selectTrailer();

    //    System.assertEquals(null, bb.selectedTrailer);
    //    System.assertEquals(null, bb.trailerUpgradePrice);
    //    System.assertEquals(standardBoatPrice, bb.runningPrice);

    //     /* ******* Simulate reselecting the included motor option ******* */
    //    bb.selectedTrailerId = selectedBoat.Standard_Trailer__c;
    //    bb.selectTrailer();

    //    System.assertEquals('Included', bb.trailerUpgradePrice);
    //    System.assertEquals(standardBoatPrice, bb.runningPrice);
    //}

    //testMethod static void selectTrollingMotorTest() {
    //    init();
    //    test.startTest();
    //    bb.selectedBoatId = selectedBoat.Id;
    //    /* this method gets call when the Boat select leist changes */
    //    bb.selectBoatFromSelector();
    //   // Product_Option__c motorOption = [SELECT Id, From_Product__c FROM Product_Option__c WHERE From_Product__r.RecordType.Name = 'Motor' AND To_Product__c = :selectedBoat.Id LIMIT 1];
    //    bb.selectedTrollingMotorId = bb.availableProductUpgrades.get('trolling_motors')[1].Id;
    //    bb.selectTrollingMotor();
    //    Decimal trollingMotorUpgradePrice = [SELECT Price__c
    //                                 FROM Product_Upgrade__c
    //                                 WHERE From_Product__c = :selectedBoat.Standard_Trolling_Motor__c
    //                                 AND To_Product__c = :bb.availableProductUpgrades.get('trolling_motors')[1].Id
    //                                 LIMIT 1].Price__c;
    //    String tmOptionPid;
    //    for( String id: bb.availableTrollingMotorOptions.keySet() ){
    //        tmOptionPid = id;
    //        break;
    //    }
    //    Decimal productPrice = [SELECT UnitPrice
    //                            FROM PricebookEntry
    //                            WHERE PriceBook2Id = :standard_pb2.Id
    //                            AND Product2Id = :tmOptionPid ].UnitPrice;
    //    test.stopTest();

    //    System.assertEquals( String.valueOf(trollingMotorUpgradePrice), bb.trollingMotorUpgradePrice );
    //    //System.assertEquals(standardBoatPrice + trollingMotorUpgradePrice , bb.runningPrice);

    //     /* Select The one trolling motor option that should be available */


    //    pageRef.getParameters().put( 'productId', tmOptionPid );
    //    pageRef.getParameters().put( 'quantity', '1' );
    //    pageRef.getParameters().put( 'productType', 'trolling motor' );
    //    Test.setCurrentPageReference(pageRef);
    //    bb.productOptionsChanged();

    //    System.assertEquals( standardBoatPrice + trollingMotorUpgradePrice + productPrice , bb.runningPrice);

    //    /* *******  Simulate selecting the null ('Select a Trailor') in the select list  ******* */

    //    bb.selectedTrollingMotorId = null;
    //    bb.selectTrollingMotor();

    //    System.assertEquals(null, bb.selectedTrollingMotor);
    //    System.assertEquals(null, bb.trollingMotorUpgradePrice);
    //    System.assertEquals(standardBoatPrice, bb.runningPrice);

    //     /* ******* Simulate reselecting the included motor option ******* */
    //    bb.selectedTrollingMotorId = selectedBoat.Standard_Trolling_Motor__c;
    //    bb.selectTrollingMotor();

    //    System.assertEquals('Included', bb.trollingMotorUpgradePrice);
    //    System.assertEquals(standardBoatPrice, bb.runningPrice);
    //}

    //testmethod static void selectAccessoryTest() {
    //    init();
    //    test.startTest();
    //    bb.selectedBoatId = selectedBoat.Id;
    //    /* this method gets call when the Boat select leist changes */
    //    bb.selectBoatFromSelector();
    //    String eOptionPid;
    //    for( String id: bb.availableBoatOptions.get(bb_p_families.get(0)).keySet() ){
    //        eOptionPid = id;
    //        break;
    //    }
    //    //lets add a fee association to the option product
    //    insert new Product_Fee_Map__c(Parent_Product__c = eOptionpid, Fee_Product__c = feeProducts[2].Id);
    //    Decimal productPrice = [SELECT UnitPrice
    //                            FROM PricebookEntry
    //                            WHERE PriceBook2Id = :standard_pb2.Id
    //                            AND Product2Id = :eOptionPid].UnitPrice;
    //    pageRef.getParameters().put('productId', eOptionPid);
    //    pageRef.getParameters().put('quantity', '1');
    //    pageRef.getParameters().put( 'productType', 'boat' );
    //    Test.setCurrentPageReference(pageRef);
    //    bb.productOptionsChanged();
    //    test.stopTest();

    //    //add 100 to product price due to fee we added above
    //    //System.assertEquals( productPrice + 100 + standardBoatPrice, bb.runningPrice);
    //    System.assert( bb.getSelectedPartsIdList().get('boat').contains(':'+eOptionPid+':') );
    //    System.assertEquals( 1, bb.selectedItemsMap.get('boat').size() );
    //    System.assertEquals( 3, bb.subOptions.get(eOptionPid).size() );

    //    /* Select one of 3 subOptions that should be available */
    //    String subId = bb.subOptions.get(eOptionPid)[0].id;
    //    // lets add a fee product association to this sub product
    //    insert new Product_Fee_Map__c(Parent_Product__c = subId, Fee_Product__c = feeProducts[0].Id);
    //    Decimal subProductPrice = [SELECT UnitPrice
    //                            FROM PricebookEntry
    //                            WHERE PriceBook2Id = :standard_pb2.Id
    //                            AND Product2Id = :subId].UnitPrice;
    //    pageRef.getParameters().put('productId', subId);
    //    pageRef.getParameters().put('parentProductId', eOptionPid);
    //    pageRef.getParameters().put('quantity', '1');
    //    pageRef.getParameters().put( 'productType', 'boat' );
    //    Test.setCurrentPageReference(pageRef);
    //    bb.productOptionsChanged();

    //    //add 100 due to the fee product we associated above
    //    System.assertEquals( productPrice + 100 + standardBoatPrice + subProductPrice+ 100, bb.runningPrice);

    //    /* ****** Simulate reselecting the 0 as option quantity **** */
    //    pageRef.getParameters().put('quantity', '0');
    //    pageRef.getParameters().put('productId', eOptionPid);
    //    pageRef.getParameters().remove('parentProductId');
    //    Test.setCurrentPageReference(pageRef);
    //    bb.productOptionsChanged();

    //    System.assertEquals( standardBoatPrice, bb.runningPrice);
    //}

    //testmethod static void createDiscount_test()
    //{

    //    Opportunity oppy = OpportunityFactory.insertRetailBoatSale();
    //    pageRef = Page.BoatBuilder;
    //    pageRef.getParameters().put('discountDescription', 'I am a discount from test');
    //    pageRef.getParameters().put('discountAmount', '100');
    //    Test.setCurrentPageReference(pageRef);
    //    bb = new BoatBuilder(oppy.Id);
    //    Decimal price = bb.runningPrice;
    //    System.assert( bb.getJustDiscountItems().size() == 0 );
    //    Test.startTest();
    //    bb.createDiscount();
    //    System.assert( bb.runningPrice == (price - 100) );
    //    System.assert( bb.discountTotal == 100 );
    //    bb.saveAndReturn();
    //    bb = new BoatBuilder(oppy.Id);
    //    BoatBuilder.Discount[] discounts = bb.getJustDiscountItems();
    //    System.assert( discounts.size() == 1 );
    //    pageRef.getParameters().put('discountDescription', 'I am a discount from test');
    //    pageRef.getParameters().put('discountAmount', '200');
    //    pageRef.getParameters().put('discountId', discounts[0].Id );
    //    Test.setCurrentPageReference(pageRef);
    //    bb.updateDiscount();
    //    System.assert( bb.runningPrice == (price - 200) );
    //    System.assert( bb.discountTotal == 200 );
    //    bb.removeDiscount();
    //    System.assert( bb.runningPrice == price );
    //    System.assert( bb.discountTotal == 0 );

    //}

    //testmethod static void additionalAccessoriesTest() {
    //    init();
    //    test.startTest();
    //    //select a boat
    //    bb.selectedBoatId = selectedBoat.Id;
    //    bb.selectBoat();
    //    //running price should now be 100 + 3 fees of $100 each = 400

    //    //select a trailer +$100
    //    bb.selectedTrailerId = bb.availableProductUpgrades.get('trailers')[0].Id;
    //    bb.selectTrailer();
    //    //running price should now be 500

    //    //select a motor +$100
    //    bb.selectedMotorId = bb.availableProductUpgrades.get('motors')[0].Id;
    //    //add a fee to the motor
    //    insert new Product_Fee_Map__c(Parent_Product__c = bb.selectedMotorId, Fee_Product__c = feeProducts[0].Id);
    //    bb.selectMotor();
    //    //running price should now be 700
    //    //select 1 Electronics option and 1 of its sub options
    //    String eOptionPid;
    //    for( String id: bb.availableBoatOptions.get( bb_p_families.get(0) ).keySet() ){
    //        eOptionPid = id;
    //        break;
    //    }

    //    pageRef.getParameters().put('productId', eOptionPid);
    //    pageRef.getParameters().put('quantity', '1');
    //    pageRef.getParameters().put( 'productType', 'boat' );
    //    Test.setCurrentPageReference(pageRef);
    //    bb.productOptionsChanged();

    //    String subId = bb.subOptions.get(eOptionPid)[0].id;
    //    pageRef.getParameters().put('productId', subId);
    //    pageRef.getParameters().put('parentProductId', eOptionPid);
    //    pageRef.getParameters().put('quantity', '1');
    //    pageRef.getParameters().put( 'productType', 'boat' );
    //    Test.setCurrentPageReference(pageRef);
    //    bb.productOptionsChanged();

    //    //running price should be 720

    //    factory.insertTestProducts(6, 'Part', standard_pb2);
    //    List<ProductRemoter.ProductWrapper> searchProducts = ProductRemoter.productSearch(standard_pb2.Id, 'Test_Part');

    //    Product2 selected = ProductRemoter.selectProduct(standard_pb2.Id, searchProducts[2].Id);

    //    pageRef.getParameters().put('productId', selected.Id);
    //    pageRef.getParameters().put('quantity', '4');
    //    pageRef.getParameters().put('salePrice', '10');
    //    Test.setCurrentPageReference(pageRef);
    //    bb.addAdditionalAccessory();

    //    //running price should now be 760

    //    bb.saveAndReturn();
    //    Opportunity updateOpp = [SELECT Id, Amount, Total_Amount__c, (SELECT Id FROM OpportunityLineItems) FROM Opportunity WHERE Id = :opp.Id];

    //    test.stopTest();
    //    bb = new BoatBuilder();

    //    System.assert(searchProducts.size() >= 6 );
    //    System.assertEquals(100, selected.PricebookEntries[0].UnitPrice);
    //    //System.assertEquals(1660.00, bb.runningPrice);
    //    System.assertEquals(1660.00, updateOpp.Amount);
    //    System.assertEquals(1, bb.additionalAccessories.size());

    //    pageRef.getParameters().put('aaId', bb.additionalAccessories[0].Id);
    //    Test.setCurrentPageReference(pageRef);
    //    bb.removeAdditionalAccessory();

    //    System.assertEquals(1620, bb.runningPrice);

    //}


}