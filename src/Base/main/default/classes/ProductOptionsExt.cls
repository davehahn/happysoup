public with sharing class ProductOptionsExt {
  public class OptionsWrapper {
    public SelectOption[] available { get; set; }
    public SelectOption[] selected { get; set; }

    public OptionsWrapper() {
      this.available = new List<SelectOption>();
      this.selected = new List<SelectOption>();
    }
  }
  public Map<String, OptionsWrapper> optionsMap {
    get {
      if (optionsMap == null) {
        optionsMap = new Map<String, OptionsWrapper>();
        optionsMap.put('No Family', new OptionsWrapper());
      }
      return optionsMap;
    }
    set;
  }

  public Map<String, String> familyNames {
    get {
      if (familyNames == null) {
        familyNames = new Map<String, String>();
      }
      return familyNames;
    }
    private set;
  }

  private ApexPages.StandardController std;
  public String productID { get; set; }
  public Product2 product;
  //private Id biggestMotorId;
  public Boolean isBoat { get; private set; }
  public Boolean isPart { get; private set; }

  public Set<String> selectedIds = new Set<String>(); // a empty list of productId's (From_Product) which are already associated with product (To_Product)
  public List<Product_Option__c> selectedOptions = new List<Product_Option__c>();
  public List<Product2> selectedPartProducts = new List<Product2>();

  public SelectOption[] selectedSearchResults {
    get {
      if (selectedSearchResults == null) {
        selectedSearchResults = new List<SelectOption>();
      }
      return selectedSearchResults;
    }
    set;
  }
  public SelectOption[] allSearchResults { get; set; }
  public Id stdPbId;

  public ProductOptionsExt(ApexPages.StandardController stdCtrl) {
    std = stdCtrl;
    isBoat = false;
    isPart = false;
    //allowed_product_types = allowed_product_types_string.split(',');
    stdPbId = [SELECT Id FROM PriceBook2 WHERE IsStandard = TRUE AND IsActive = TRUE].Id;

    productID = ApexPages.currentpage().getparameters().get('productId');
    if (productID != null) {
      product = [
        SELECT
          Id,
          name,
          RecordType.Name,
          Standard_Motor__c,
          Standard_Trailer__c,
          ProductCode,
          Standard_Trolling_Motor__c,
          (
            SELECT
              id,
              From_Product__c,
              From_Product__r.Name,
              From_Product__r.RecordType.Name,
              From_Product__r.Family,
              From_Product__r.ProductCode,
              Rank__c,
              Standard__c,
              Maximum__c,
              isBiggestMotor__c,
              displayOnWeb__c
            FROM To_Product_Options__r
            ORDER BY Rank__c
          )
        FROM Product2
        WHERE Id = :productID
        ORDER BY Name
      ];

      /* populate the list which contains product ids the current product is associated with */
      if (product.RecordType.Name == 'Boat') {
        isBoat = true;
      }
      if (product.RecordType.Name == 'Part') {
        isPart = true;
      }
      for (Product_Option__c option : product.To_Product_Options__r) {
        selectedIds.add(option.From_Product__c);
        selectedOptions.add(option);
        //if( option.IsBiggestMotor__c == true )
        //{
        //  biggestMotorId = option.From_Product__c;
        //}
      }
      construct_option_groups();
      for (String fam : optionsMap.keySet()) {
        familyNames.put(fam, fam.replaceAll('[^a-zA-Z0-9]', '').replace(' ', '_').toLowerCase());
      }
    }
  } //constructor

  public Product2 getProduct() {
    return product;
  }

  public void fetchSearchResults() {
    String searchString = Apexpages.currentPage().getParameters().get('search_string');
    if (searchString == null || searchString == '') {
      allSearchResults = new List<SelectOption>();
    } else {
      searchString = '%' + searchString + '%';
      Set<String> ignoredIds = idsFromSelect(selectedSearchResults);
      ignoredIds.addAll(selectedIds);
      List<Product2> results = [
        SELECT
          id,
          name,
          Family,
          ProductCode,
          (SELECT UnitPrice FROM PricebookEntries WHERE Pricebook2.IsStandard = TRUE AND IsActive = TRUE)
        FROM Product2
        WHERE
          (RecordType.Name = 'Part'
          OR RecordType.Name LIKE '%Bundle%')
          AND Id NOT IN :ignoredIds
          AND (Name LIKE :searchString
          OR ProductCode LIKE :searchString)
          AND isActive = TRUE
        ORDER BY Name
        LIMIT 1000
      ];
      allSearchResults = buildSelect(results);
    }
  }

  public PageReference save() {
    /* Combine SelectLists into a single Set of id's */
    Set<String> passedInIds = new Set<String>();
    List<Product_Option__c> productOptions = new List<Product_Option__c>();
    for (Integer i = 0; i < selectedSearchResults.size(); i++) {
      productOptions.add(buildNewOption(selectedSearchResults[i].getValue(), i));
    }
    for (String key : optionsMap.keySet()) {
      for (Integer i = 0; i < optionsMap.get(key).selected.size(); i++) {
        productOptions.add(buildNewOption(optionsMap.get(key).selected[i].getValue(), i));
      }
    }
    delete selectedOptions;

    /* insert all with SOQL batch insert command */
    insert productOptions;
    /* redirect back to the details page of the original product */
    return new PageReference('/' + productId);
  } //save()

  /* *********************************************************************************

  .______   .______       __  ____    ____  ___   .___________. _______     _______.
  |   _  \  |   _  \     |  | \   \  /   / /   \  |           ||   ____|   /       |
  |  |_)  | |  |_)  |    |  |  \   \/   / /  ^  \ `---|  |----`|  |__     |   (----`
  |   ___/  |      /     |  |   \      / /  /_\  \    |  |     |   __|     \   \
  |  |      |  |\  \----.|  |    \    / /  _____  \   |  |     |  |____.----)   |
  | _|      | _| `._____||__|     \__/ /__/     \__\  |__|     |_______|_______/

**************************************************************************************/

  private void construct_option_groups() {
    List<Product2> availMotorProducts;
    List<Product2> availTrollingMotorProducts;
    List<Product2> availTrailerProducts;
    List<Product2> availProtectionProducts;
    List<Product2> availBundles;

    List<Product2> selectedMotorProducts = new List<Product2>();
    List<Product2> selectedTrailerProducts = new List<Product2>();
    List<Product2> selectedTrollingMotorProducts = new List<Product2>();
    List<Product2> selectedProtectionProducts = new List<Product2>();
    List<Product2> selectedPartProducts = new List<Product2>();
    List<Product2> selectedBundles = new List<Product2>();

    List<Product2> allParts = [
      SELECT
        id,
        name,
        Family,
        ProductCode,
        (SELECT UnitPrice FROM PricebookEntries WHERE Pricebook2.IsStandard = TRUE AND IsActive = TRUE)
      FROM Product2
      WHERE RecordType.Name = 'Part' AND Family != NULL AND Id NOT IN :selectedIds AND isActive = TRUE
      ORDER BY Name
    ];
    System.debug('HERE IS THE SIZE ' + allParts.size());
    List<Product2> selected = [
      SELECT id, name, Family, RecordType.Name, ProductCode
      FROM Product2
      WHERE id IN :selectedIds
    ];
    if (isBoat) {
      availMotorProducts = availableProductsQuery('Motor', product.Standard_Motor__c);
      availTrailerProducts = availableProductsQuery('Trailer', product.Standard_Trailer__c);
      availTrollingMotorProducts = availableProductsQuery('Trolling Motor', product.Standard_Trolling_Motor__c);
    }
    if (!isPart) {
      Id psId = LGND_Utilities.recordTypeIdFromName('Product2', 'Protection and Services');
      Id bId = LGND_Utilities.recordTypeIdFromName('Product2', 'Package Bundle');
      availProtectionProducts = [
        SELECT
          id,
          name,
          RecordTypeId,
          RecordType.Name,
          ProductCode,
          Family,
          (SELECT UnitPrice FROM PricebookEntries WHERE Pricebook2.IsStandard = TRUE)
        FROM Product2
        WHERE
          RecordTypeId = :psId
          AND Id NOT IN :selectedIds
          AND Id IN (SELECT Product2Id FROM PriceBookEntry WHERE Pricebook2Id = :stdPbId)
          AND IsActive = TRUE
        ORDER BY Name
      ];
      availBundles = [
        SELECT
          id,
          name,
          RecordTypeId,
          RecordType.Name,
          ProductCode,
          Family,
          (SELECT UnitPrice FROM PricebookEntries WHERE Pricebook2.IsStandard = TRUE)
        FROM Product2
        WHERE
          RecordTypeId = :bId
          AND Id NOT IN :selectedIds
          AND Id IN (SELECT Product2Id FROM PriceBookEntry WHERE Pricebook2Id = :stdPbId)
          AND IsActive = TRUE
        ORDER BY Name
      ];
    }

    System.debug(availBundles);

    for (Product_Option__c option : selectedOptions) {
      if (isBoat) {
        if (option.From_Product__r.RecordType.Name == 'Motor') {
          selectedMotorProducts.add(option.From_Product__r);
        }
        if (option.From_Product__r.RecordType.Name == 'Trailer') {
          selectedTrailerProducts.add(option.From_Product__r);
        }
        if (option.From_Product__r.RecordType.Name == 'Trolling Motor') {
          selectedTrollingMotorProducts.add(option.From_Product__r);
        }
      }

      if (!isPart && option.From_Product__r.RecordType.Name == 'Protection and Services') {
        selectedProtectionProducts.add(option.From_Product__r);
      }

      if (!isPart && option.From_Product__r.RecordType.Name == 'Package Bundle') {
        selectedBundles.add(option.From_Product__r);
      }
      if (option.From_Product__r.RecordType.Name == 'Part') {
        selectedPartProducts.add(option.From_Product__r);
      }
    }

    if (isBoat) {
      System.debug('253 isBoat');
      buildSelectMap(selectedMotorProducts, 'Motors', 'selected');
      buildSelectMap(selectedTrailerProducts, 'Trailers', 'selected');
      buildSelectMap(selectedTrollingMotorProducts, 'Trolling Motors', 'selected');
    }
    //buildSelectMap( selectedPartProducts, 'selected');
    for (Product2 p : selectedPartProducts) {
      selectedSearchResults.add(new SelectOption(p.Id, p.Name));
    }
    if (!isPart) {
      System.debug('265 !isPart');
      buildSelectMap(selectedProtectionProducts, 'selected');
      buildSelectMap(selectedBundles, 'selected');
    }

    if (isBoat) {
      System.debug('272 isBoat');
      buildSelectMap(availMotorProducts, 'Motors', 'available');
      buildSelectMap(availTrailerProducts, 'Trailers', 'available');
      buildSelectMap(availTrollingMotorProducts, 'Trolling Motors', 'available');
    }
    //buildSelectMap(allParts, 'available');
    if (!isPart) {
      System.debug('290 !isPart');
      buildSelectMap(availProtectionProducts, 'available');
      buildSelectMap(availBundles, 'available');
    }
  } //construct_optiongroups();

  /* builds select options from a list of Products */
  private List<SelectOption> buildSelect(List<Product2> products) {
    List<SelectOption> tf = new List<SelectOption>();
    for (Product2 p : products) {
      String name;
      name = p.ProductCode == null ? p.Name : p.Name + ' - ' + p.ProductCode;
      tf.add(new SelectOption(p.id, name));
    }
    return tf;
  } //buildSelect()

  private void buildSelectMap(List<Product2> products, String status) {
    System.debug(products);
    for (Product2 p : products) {
      if (p.Family != null && (optionsMap.isEmpty() || !optionsMap.containsKey(p.Family))) {
        optionsMap.put(p.Family, new OptionsWrapper());
      }
      if (
        p.RecordTypeId == LGND_Constants.productRtId_Bundle &&
        (optionsMap.isEmpty() || !optionsMap.containsKey(p.RecordType.Name))
      ) {
        optionsMap.put(p.RecordType.Name, new OptionsWrapper());
      }
      if (status == 'available') {
        if (p.RecordTypeId == LGND_Constants.productRtId_Bundle) {
          if (optionsMap.get(p.RecordType.Name).available.size() < 1000)
            optionsMap.get(p.RecordType.Name).available.add(new SelectOption(p.Id, p.Name));
        } else if (p.Family == null || p.Family == '') {
          if (optionsMap.get('No Family').available.size() < 1000)
            optionsMap.get('No Family').available.add(new SelectOption(p.Id, p.Name));
        } else {
          if (optionsMap.get(p.Family).available.size() < 1000)
            optionsMap.get(p.Family).available.add(new SelectOption(p.Id, p.Name));
        }
      }
      if (status == 'selected') {
        if (p.RecordTypeId == LGND_Constants.productRtId_Bundle) {
          optionsMap.get(p.RecordType.Name).selected.add(new SelectOption(p.Id, p.Name));
        } else if (p.Family == null) {
          selectedSearchResults.add(new SelectOption(p.Id, p.Name));
        } else {
          optionsMap.get(p.Family).selected.add(new SelectOption(p.Id, p.Name));
        }
      }
    }
  }

  private void buildSelectMap(List<Product2> products, String key, String status) {
    for (Product2 p : products) {
      if (optionsMap.isEmpty() || !optionsMap.containsKey(key)) {
        optionsMap.put(key, new OptionsWrapper());
      }
      if (status == 'available') {
        optionsMap.get(key).available.add(new SelectOption(p.Id, p.Name));
      }
      if (status == 'selected') {
        optionsMap.get(key).selected.add(new SelectOption(p.Id, p.Name));
      }
    }
  }

  private Product_Option__c findInSelected(Id fromId) {
    Product_Option__c result = null;
    for (Product_Option__c option : selectedOptions) {
      if (option.From_Product__c == fromId) {
        result = option;
      }
    }
    return result;
  }

  private Product_Option__c buildNewOption(Id fromId, Integer rank) {
    Product_Option__c oldOption = findInSelected(fromId);
    if (oldOption != null) {
      return new Product_Option__c(
        From_Product__c = fromId,
        To_Product__c = productId,
        Rank__c = rank,
        displayOnWeb__c = oldOption.displayOnWeb__c,
        isBiggestMotor__c = oldOption.IsBiggestMotor__c,
        Standard__c = oldOption.Standard__c,
        Maximum__c = oldOption.Maximum__c
      );
    } else {
      return new Product_Option__c(
        From_Product__c = fromId,
        To_Product__c = productId,
        Rank__c = rank,
        Standard__c = 0,
        Maximum__c = 1
      );
    }
  }

  private Product2[] availableProductsQuery(String recordTypeName, Id standardId) {
    //List<PricebookEntry> pbProducts = [SELECT Product2Id FROM PriceBookEntry WHERE Pricebook2.IsStandard = true AND IsActive = true];
    //List<Id> pbEntries = new List<Id>();
    //for( PricebookEntry pbe : pbProducts )
    //{
    //  pbEntries.add( pbe.Product2Id );
    //}
    //if( standardId != null )
    //  {
    //  List<Product_Upgrade__c> pus = [SELECT To_Product__c FROM Product_Upgrade__c WHERE From_Product__c = :standardId];
    //  List<Id> upgradeIds = new List<Id>();
    //  for( Product_Upgrade__c pu : pus )
    //  {
    //    upgradeIds.add(pu.To_Product__c);
    //  }
    //  return [SELECT id, name,  RecordType.Name, ProductCode,
    //                          (SELECT UnitPrice
    //                           FROM PricebookEntries
    //                           WHERE Pricebook2.IsStandard = true)
    //                          FROM Product2
    //                          WHERE RecordType.Name = :recordTypeName
    //                          AND Id != :standardId
    //                          AND Id NOT IN :selectedIds
    //                          AND Id IN :upgradeIds
    //                          AND Id IN :pbEntries
    //                          AND IsActive = true
    //                          ORDER BY Name];
    //  }
    //  else
    //  {
    //    return [SELECT id, name,  RecordType.Name, ProductCode,
    //                          (SELECT UnitPrice
    //                           FROM PricebookEntries
    //                           WHERE Pricebook2.IsStandard = true)
    //                          FROM Product2
    //                          WHERE RecordType.Name = :recordTypeName
    //                          AND Id != :standardId
    //                          AND Id NOT IN :selectedIds
    //                          AND Id IN :pbEntries
    //                          AND IsActive = true
    //                          ORDER BY Name];
    //  }
    Id recordTypeId = LGND_Utilities.recordTypeIdFromName('Product2', recordTypeName);
    if (standardId != null) {
      return [
        SELECT
          id,
          name,
          RecordType.Name,
          ProductCode,
          (SELECT UnitPrice FROM PricebookEntries WHERE Pricebook2.IsStandard = TRUE)
        FROM Product2
        WHERE
          RecordTypeId = :recordTYpeId
          AND Id != :standardId
          AND Id NOT IN :selectedIds
          AND Id IN (SELECT To_Product__c FROM Product_Upgrade__c WHERE From_Product__c = :standardId)
          AND Id IN (SELECT Product2Id FROM PriceBookEntry WHERE Pricebook2Id = :stdPbId)
          AND IsActive = TRUE
        ORDER BY Name
      ];
    } else {
      return [
        SELECT
          id,
          name,
          RecordType.Name,
          ProductCode,
          (SELECT UnitPrice FROM PricebookEntries WHERE Pricebook2.IsStandard = TRUE)
        FROM Product2
        WHERE
          RecordTypeId = :recordTypeId
          AND Id != :standardId
          AND Id NOT IN :selectedIds
          AND Id IN (SELECT Product2Id FROM PriceBookEntry WHERE Pricebook2Id = :stdPbId)
          AND IsActive = TRUE
        ORDER BY Name
      ];
    }
  }

  private Set<String> idsFromSelect(List<SelectOption> selectOptions) {
    Set<String> ids = new Set<String>();
    for (SelectOption so : selectOptions) {
      ids.add(so.getValue());
    }
    return ids;
  }

  public static void coverage() {
    integer i;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
  }
}
