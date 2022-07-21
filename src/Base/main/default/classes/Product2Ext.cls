public with sharing class Product2Ext {
  private ApexPages.StandardController stdCtrl;

  @TestVisible
  private Product2 product;
  public List<String> fieldNames;
  public Id cloneId;
  public Boolean renderDeepCloneButton {
    get {
      if (renderDeepCloneButton == null) {
        renderDeepCloneButton = false;
      }
      return renderDeepCloneButton;
    }
    set;
  }

  public Product2Ext(ApexPages.StandardController controller) {
    this.stdCtrl = controller;
    fieldNames = fieldsToAdd();
    if (!test.isRunningTest()) {
      stdCtrl.addFields(fieldNames);
    }
    this.product = (Product2) stdCtrl.getRecord();
    cloneId = ApexPages.currentPage().getParameters().get('cloneId');
    if (cloneId != null) {
      renderDeepCloneButton = true;
      cloneFields();
    } else {
      RecordType rt = [SELECT id, Name FROM RecordType WHERE Name = 'Boat'];
      this.product.RecordType = rt;
    }
  }

  public PageReference save() {
    return stdCtrl.save();
  }

  public PageReference cancel() {
    return cloneId == null ? new PageReference('/o1t/o') : new PageReference('/' + cloneId);
  }

  public PageReference saveWithOptions() {
    this.product = (Product2) stdCtrl.getRecord();
    insert this.product;
    PageReference returnPage = new ApexPages.StandardController(this.product).view();
    List<Product_Option__c> clonedOptions = cloneInOptions();
    List<Product_Feature_Map__c> clonedFeatures = cloneInFeatures();
    List<Product_Fee_Map__c> clonedFees = cloneInFees();
    List<AcctSeed__Product_Part__c> clonedProductParts = cloneInProductParts();
    LIst<Boat_Rigging_Checklist_Map__c> clonedChecklistMaps = cloneInRiggingChecklist();
    if (clonedOptions.size() > 0) {
      try {
        insert clonedOptions;
      } catch (Exception e) {
        handleException(e);
      }
    }
    if (clonedFeatures.size() > 0) {
      try {
        insert clonedFeatures;
      } catch (Exception e) {
        handleException(e);
      }
    }
    if (clonedFees.size() > 0) {
      try {
        insert clonedFees;
      } catch (Exception e) {
        handleException(e);
      }
    }
    //
    if (clonedProductParts.size() > 0) {
      try {
        insert clonedProductParts;
      } catch (Exception e) {
        handleException(e);
      }
    }
    if (clonedChecklistMaps.size() > 0) {
      try {
        insert clonedChecklistMaps;
      } catch (Exception e) {
        handleException(e);
      }
    }
    return returnPage;
  }

  private void handleException(Exception e) {
    String msg = e.getMessage();
    integer pos;

    // if its field validation, this will be added to the messages by default
    if (-1 == (pos = msg.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION, '))) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
    }
  }

  private List<String> fieldsToAdd() {
    Set<String> fieldNamesTest = new Set<String>();
    List<String> fNames = new List<String>();
    Map<String, Schema.FieldSet> FsMap = Schema.SObjectType.Product2.fieldSets.getMap();
    for (Schema.Fieldset fs : FsMap.values()) {
      for (Schema.FieldSetMember f : fs.getFields()) {
        if (!fieldNamesTest.contains(f.getFieldPath())) {
          fieldNamesTest.add(f.getFieldPath());
          fNames.add(f.getFieldPath());
        }
      }
    }
    return fNames;
  }

  private void cloneFields() {
    String queryString = 'SELECT ';
    for (String field : fieldNames) {
      queryString += field + ',';
    }
    if (queryString.endsWith(',')) {
      queryString = queryString.substring(0, queryString.lastIndexOf(','));
    }
    queryString += ' FROM Product2 WHERE ID = \'' + cloneId + '\'';
    System.debug(queryString);
    Product2 orig = (Product2) database.query(queryString);
    for (String field : fieldNames) {
      product.put(field, orig.get(field));
    }
  }

  private List<Product_Option__c> cloneInOptions() {
    List<Product_Option__c> newOptions = new List<Product_Option__c>();
    List<Product_Option__c> options = [
      SELECT
        Id,
        Standard__c,
        Maximum__c,
        From_Product__c,
        displayOnWeb__c,
        Available_Online__c,
        IsBiggestMotor__c,
        Rank__c,
        Step__c
      FROM Product_Option__c
      WHERE To_Product__c = :cloneId
    ];
    Set<Id> standardEquip = new Set<Id>();
    standardEquip.add(this.product.Standard_Motor__c);
    standardEquip.add(this.product.Standard_Trailer__c);
    standardEquip.add(this.product.Standard_Trolling_Motor__c);

    for (Product_Option__c opt : options) {
      if (!standardEquip.contains(opt.From_Product__c)) {
        newOptions.add(
          new Product_Option__c(
            To_Product__c = this.product.Id,
            Standard__c = opt.Standard__c,
            Maximum__c = opt.Maximum__c,
            From_Product__c = opt.From_Product__c,
            displayOnWeb__c = opt.displayOnWeb__c,
            Available_Online__c = opt.Available_Online__c,
            IsBiggestMotor__c = opt.IsBiggestMotor__c,
            Rank__c = opt.Rank__c,
            Step__c = opt.Step__c
          )
        );
      }
    }
    return newOptions;
  }

  private List<Product_Feature_Map__c> cloneInFeatures() {
    List<Product_Feature_Map__c> newFeatures = new List<Product_Feature_Map__c>();
    Product2 p = (Product2) stdCtrl.getRecord();
    List<Product_Feature_Map__c> features = [
      SELECT Id, Rank__c, Feature_Id__c
      FROM Product_Feature_Map__c
      WHERE Product_Id__c = :cloneId
    ];

    for (Product_Feature_Map__c pfm : features) {
      newFeatures.add(
        new Product_Feature_Map__c(Product_Id__c = p.Id, Rank__c = pfm.Rank__c, Feature_Id__c = pfm.Feature_Id__c)
      );
    }
    return newFeatures;
  }

  private List<Product_Fee_Map__c> cloneInFees() {
    List<Product_Fee_Map__c> newFees = new List<Product_Fee_Map__c>();
    Product2 p = (Product2) stdCtrl.getRecord();
    List<Product_Fee_Map__c> fees = [
      SELECT Id, Rank__c, Fee_Product__c
      FROM Product_Fee_Map__c
      WHERE Parent_Product__c = :cloneId
    ];

    for (Product_Fee_Map__c fm : fees) {
      newFees.add(
        new Product_Fee_Map__c(Parent_Product__c = p.Id, Rank__c = fm.Rank__c, Fee_Product__c = fm.Fee_Product__c)
      );
    }
    return newFees;
  }

  private List<AcctSeed__Product_Part__c> cloneInProductParts() {
    List<AcctSeed__Product_Part__c> result = new List<AcctSeed__Product_Part__c>();
    List<AcctSeed__Product_Part__c> existingPPs = [
      SELECT Id, AcctSeed__Quantity__c, AcctSeed__Product_Part__c
      FROM AcctSeed__Product_Part__c
      WHERE AcctSeed__Product__c = :this.cloneId
    ];
    for (AcctSeed__Product_Part__c pp : existingPPs) {
      result.add(
        new AcctSeed__Product_Part__c(
          AcctSeed__Quantity__c = pp.AcctSeed__Quantity__c,
          AcctSeed__Product_Part__c = pp.AcctSeed__Product_Part__c,
          AcctSeed__Product__c = this.product.Id
        )
      );
    }
    return result;
  }

  private List<Boat_Rigging_Checklist_Map__c> cloneInRiggingChecklist() {
    List<Boat_Rigging_Checklist_Map__c> result = new List<Boat_Rigging_Checklist_Map__c>();
    List<Boat_Rigging_Checklist_Map__c> existing = [
      SELECT Id, Checklist_Item__c, Rank__c
      FROM Boat_Rigging_Checklist_Map__c
      WHERE Product__c = :this.cloneId
    ];
    for (Boat_Rigging_Checklist_Map__c checklistMap : existing) {
      result.add(
        new Boat_Rigging_Checklist_Map__c(
          Product__c = this.product.Id,
          Checklist_Item__c = checklistMap.Checklist_Item__c,
          Rank__c = checklistMap.Rank__c
        )
      );
    }
    return result;
  }
}
