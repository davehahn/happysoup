public with sharing class ProductUpgrades {
  public class dataWrapper {
    public String To_Product_Id { get; set; }
    public String From_Product_Id { get; set; }
    public String Pricebook_Id { get; set; }
    public Decimal Cost { get; set; }

    public dataWrapper() {
    }
  }

  static final Pricebook2[] pricebooks;
  public final Id FromProductId;
  public final Product2 FromProduct { get; private set; }
  static Set<String> upgradeRecordTypes;
  public Map<String, Boolean> renderMap { get; set; }
  // public Id selectedMotorPriceBookId { get; set; }
  //public Id selectedMotorId { get; set; }
  public Map<String, List<Product2>> productsMap;
  public Map<String, List<Product_Upgrade__c>> upgradeMap { get; set; }
  public Map<String, Id> selectedIdMap { get; set; }
  public Map<String, Id> selectedPbIdMap { get; set; }

  static {
    Set<id> pbRTids = new Set<Id>{
      LGND_Utilities.recordTypeIdFromName('Pricebook2', 'Sales'),
      LGND_Utilities.recordTypeIdFromName('Pricebook2', 'Dealer')
    };
    pricebooks = [SELECT Id, Name FROM Pricebook2 WHERE RecordTypeId IN :pbRTids];
    upgradeRecordTypes = new Set<String>{ 'Motor', 'Trailer', 'Trolling Motor' };
  }

  public ProductUpgrades(ApexPages.StandardController controller) {
    FromProductId = ApexPages.currentPage().getParameters().get('from_product_id');
    if (FromProductId != null) {
      try {
        FromProduct = [SELECT Id, Name, RecordType.Name FROM Product2 WHERE Id = :FromProductId];
      } catch (Exception e) {
      }
    }
    setUpRenderMap();
    setIntialSelectedPriceBooks();
    setInitialProducts();
    setInitialUpgrades();
  }

  private void setUpRenderMap() {
    renderMap = new Map<String, Boolean>();
    for (String rt : upgradeRecordTypes) {
      Boolean renderResult = FromProduct == null ? true : FromProduct.RecordType.Name == rt ? true : false;
      renderMap.put(rt, renderResult);
    }
  }

  /* +++++++++++++++++ Render helper methods +++++++++++++ */

  public Boolean getHasMotorProducts() {
    return selectedIdMap.containsKey('Motor') && selectedIdMap.get('Motor') != null ? true : false;
  }

  public Boolean getHasTrailerProducts() {
    return selectedIdMap.containsKey('Trailer') && selectedIdMap.get('Trailer') != null ? true : false;
  }

  public Boolean getHasTrollingMotorProducts() {
    return selectedIdMap.containsKey('Trolling Motor') && selectedIdMap.get('Trolling Motor') != null ? true : false;
  }

  /* ================= Render helper methods ============== */

  /* +++++++++++++++++ GETTER For Selects ++++++++++++++++ */
  public SelectOption[] getPricebookSelectOptions() {
    List<SelectOption> options = new List<SelectOption>();
    for (Pricebook2 pb : pricebooks) {
      options.add(new SelectOption(pb.Id, Pb.Name));
    }
    return options;
  }

  public SelectOption[] getMotorSelectOptions() {
    return buildProductSelectOption('Motor');
  }

  public SelectOption[] getNewMotorSelectOptions() {
    return buildNewProductSelectOption('Motor');
  }

  public SelectOption[] getTrailerSelectOptions() {
    return buildProductSelectOption('Trailer');
  }

  public SelectOption[] getNewTrailerSelectOptions() {
    return buildNewProductSelectOption('Trailer');
  }

  public SelectOption[] getTrollingMotorSelectOptions() {
    return buildProductSelectOption('Trolling Motor');
  }

  public SelectOption[] getNewTrollingMotorSelectOptions() {
    return buildNewProductSelectOption('Trolling Motor');
  }
  /* ================ GETTER For Selects ============== */

  /* +++++++++++++++++ GETTER For Upgreades +++++++++++++++ */
  public Product_Upgrade__c[] getMotorUpgrades() {
    return upgradeMap.get('Motor');
  }

  public Product_Upgrade__c[] getTrailerUpgrades() {
    return upgradeMap.get('Trailer');
  }

  public Product_Upgrade__c[] getTrollingMotorUpgrades() {
    return upgradeMap.get('Trolling Motor');
  }
  /* ================ GETTER For Upgrades ================ */

  /* ++++++++++++++++++ Change Handler For Parent Product Select +++++++ */
  public void motorSelectChanged() {
    updateUpgradeMap('Motor');
  }

  public void trailerSelectChanged() {
    updateUpgradeMap('Trailer');
  }

  public void trollingMotorSelectChanged() {
    updateUpgradeMap('Trolling Motor');
  }
  /* ================== Change Handler For Parent Product Select =========== */

  /* ++++++++++++++++++ Change Handler For Pricebook Select ++++++++++++++++ */
  public void motorPbChanged() {
    handlePbChange('Motor');
  }

  public void trailerPbChanged() {
    handlePbChange('Trailer');
  }

  public void trollingMotorPbChanged() {
    handlePbChange('Trolling Motor');
  }
  /* ======================== Change Handler For Pricebook Select ================ */

  /* +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
  /* +++                                                                         +++ */
  /* +++          REMOTE METHODS                                                 +++ */
  /* +++                                                                         +++ */
  /* +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */

  @RemoteAction
  public static Product_Upgrade_Cost__c updateCost(String jsonData) {
    Product_Upgrade_Cost__c puc = (Product_Upgrade_Cost__c) JSON.deserialize(jsonData, Product_Upgrade_Cost__c.class);
    if (puc.Cost__c == null) {
      delete puc;
      return null;
    }
    {
      upsert puc;
      return puc;
    }
  }

  @RemoteAction
  public static Product_Upgrade_Cost__c createCost(String jsonData) {
    dataWrapper dw = (dataWrapper) JSON.deserialize(jsonData, dataWrapper.class);
    Product_Upgrade__c pu;
    try {
      pu = [
        SELECT Id
        FROM Product_Upgrade__c
        WHERE From_Product__c = :dw.From_Product_Id AND To_Product__c = :dw.To_Product_Id
      ];
    } catch (Exception e) {
      pu = new Product_Upgrade__c(From_Product__c = dw.From_Product_Id, To_Product__c = dw.To_Product_Id);
      insert pu;
    }

    Product_Upgrade_Cost__c puc = new Product_Upgrade_Cost__c(
      Product_Upgrade__c = pu.Id,
      Price_Book__c = dw.Pricebook_Id,
      Cost__c = dw.Cost
    );
    insert puc;
    return [
      SELECT Id, Cost__c, Price_Book__c, Product_Upgrade__r.To_Product__r.Name
      FROM Product_Upgrade_Cost__c
      WHERE Id = :puc.Id
    ];
  }

  /* +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
  /* +++                                                                         +++ */
  /* +++          PRIVATES                                                       +++ */
  /* +++                                                                         +++ */
  /* +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */

  private void handlePbChange(String rt) {
    productsMap.put(rt, new List<Product2>());
    for (Product2 p : fetchProducts(new Set<String>{ rt }, selectedPbIdMap.get(rt))) {
      productsMap.get(rt).add(p);
    }
    if (FromProduct != null && FromProduct.RecordType.Name == rt) {
      selectedIdMap.put(rt, FromProduct.Id);
    } else if (productsMap.get(rt).size() > 0) {
      selectedIdMap.put(rt, productsMap.get(rt)[0].Id);
    } else {
      selectedIdMap.put(rt, null);
    }
    updateUpgradeMap(rt);
  }

  private void updateUpgradeMap(String rt) {
    upgradeMap.put(rt, fetchUpgrades(selectedIdMap.get(rt), selectedPbIdMap.get(rt)));
    //upgradeMap.put( rt, new List<Product_Upgrade__c>() );
    //System.debug('******************************* - ' + selectedIdMap);
    //Product_Upgrade__c[] upgrades = fetchUpgrades( new List<Id>{selectedIdMap.get(rt)},
    //                                     selectedPbIdMap.get(rt)
    //                                   );
    //if( !selectedIdMap.containsKey(rt) || selectedIdMap.get(rt) != '')
    //{
    //  for( Product_Upgrade__c pu : upgrades )
    //  {

    //    upgradeMap.get(rt).add(pu);

    //  }
    //}
  }

  private SelectOption[] buildProductSelectOption(String recordType) {
    SelectOption[] options = new List<SelectOption>();
    if (FromProduct != null && FromProduct.RecordType.Name == recordType) {
      options.add(new SelectOption(FromProduct.Id, FromProduct.Name));
    } else {
      for (Product2 p : productsMap.get(recordType)) {
        String l = p.Name + ' - ( ' + p.From_Product_Upgrades__r.size() + ' )';
        options.add(new SelectOption(p.Id, l));
      }
    }
    return options;
  }

  private SelectOption[] buildNewProductSelectOption(String recordType) {
    SelectOption[] options = new List<SelectOption>();
    options.add(new SelectOption('', 'Select a ' + recordType));
    Set<Id> pIds = new Set<id>();
    for (Product_Upgrade__c pu : upgradeMap.get(recordType)) {
      pIds.add(pu.To_Product__c);
    }

    for (Product2 p : productsMap.get(recordType)) {
      if (!pIds.contains(p.Id) && p.Id != selectedIdMap.get(recordType)) {
        options.add(new SelectOption(p.Id, p.Name));
      }
    }
    return options;
  }

  private void setIntialSelectedPriceBooks() {
    selectedPbIdMap = new Map<String, Id>();
    for (String r : upgradeRecordTypes) {
      selectedPbIdMap.put(r, pricebooks[0].Id);
    }
  }

  private void setInitialProducts() {
    productsMap = new Map<String, List<Product2>>();
    for (String r : upgradeRecordTypes) {
      productsMap.put(r, new List<Product2>());
    }
    for (Product2 p : fetchProducts(upgradeRecordTypes, pricebooks[0].Id)) {
      productsMap.get(p.RecordType.Name).add(p);
    }
  }

  private void setInitialUpgrades() {
    selectedIdMap = new Map<String, Id>();
    upgradeMap = new Map<String, List<Product_Upgrade__c>>();
    if (FromProduct != null) {
      selectedIdMap.put(FromProduct.RecordType.Name, FromProduct.Id);
      upgradeMap.put(FromProduct.RecordType.Name, new List<Product_Upgrade__c>());
    } else {
      for (String r : upgradeRecordTypes) {
        selectedIdMap.put(r, productsMap.get(r)[0].Id);
        upgradeMap.put(r, new List<Product_Upgrade__c>());
      }
    }
    Product_Upgrade__c[] upgrades = fetchUpgrades(selectedIdMap.values(), pricebooks[0].Id);
    for (Product_Upgrade__c pu : upgrades) {
      if (upgradeMap.containsKey(pu.To_Product__r.RecordType.Name))
        upgradeMap.get(pu.To_Product__r.RecordType.Name).add(pu);
    }
  }

  private List<Product_Upgrade__c> fetchUpgrades(List<Id> selectedIds, Id pbId) {
    return [
      SELECT
        Id,
        To_Product__r.Name,
        To_Product__r.RecordType.Name,
        (SELECT Id, Cost__c FROM Product_Upgrade_Costs__r WHERE Price_Book__c = :pbId)
      FROM Product_Upgrade__c
      WHERE From_Product__c IN :selectedIds
      ORDER BY To_Product__r.Name DESC
    ];
  }

  private List<Product_Upgrade__c> fetchUpgrades(Id selectedId, Id pbId) {
    return [
      SELECT
        Id,
        To_Product__r.Name,
        To_Product__r.RecordType.Name,
        (SELECT Id, Cost__c FROM Product_Upgrade_Costs__r WHERE Price_Book__c = :pbId)
      FROM Product_Upgrade__c
      WHERE From_Product__c = :selectedId
      ORDER BY To_Product__r.Name DESC
    ];
  }

  private Product2[] fetchProducts(Set<String> recordTypes, Id pricebookId) {
    Set<String> rts = FromProduct == null ? recordTypes : new Set<String>{ FromProduct.RecordType.Name };
    System.debug('rts = ' + rts);
    return [
      SELECT Id, Name, RecordType.Name, (SELECT Id FROM From_Product_Upgrades__r)
      FROM Product2
      WHERE
        RecordType.Name IN :rts
        AND isActive = TRUE
        AND Id IN (
          SELECT Product2Id
          FROM PricebookEntry
          WHERE Pricebook2Id = :pricebookId AND Product2.RecordType.Name IN :rts
        )
      ORDER BY Name DESC
    ];
  }
}
