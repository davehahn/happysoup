public with sharing class BoatRiggingChecklistController {
  public Product2 currentProduct { get; set; }
  public String currentProductName { get; set; }
  public Map<String, List<String>> riggingChecklistItems {
    get {
      if (riggingChecklistItems == null) {
        riggingChecklistItems = new Map<String, List<String>>();
      }
      return riggingChecklistItems;
    }
    private set;
  }

  public String boatSerialNumber {
    get {
      if (boatSerialNumber == null) {
        boatSerialNumber = '';
      }
      return boatSerialNumber;
    }
    private set;
  }

  public String trailerSerialNumber {
    get {
      if (trailerSerialNumber == null) {
        trailerSerialNumber = '';
      }
      return trailerSerialNumber;
    }
    private set;
  }

  public String trollingMotorSerialNumber {
    get {
      if (trollingMotorSerialNumber == null) {
        trollingMotorSerialNumber = '';
      }
      return trollingMotorSerialNumber;
    }
    private set;
  }

  public String ignitionKeyNumber {
    get {
      if (ignitionKeyNumber == null) {
        ignitionKeyNumber = '';
      }
      return ignitionKeyNumber;
    }
    private set;
  }

  public String compartmentKeyNumber {
    get {
      if (compartmentKeyNumber == null) {
        compartmentKeyNumber = '';
      }
      return compartmentKeyNumber;
    }
    private set;
  }

  public BoatRiggingChecklistController() {
    Id objId = ApexPages.currentPage().getParameters().get('Id');
    if (objId != null) {
      String objectType = LGND_Utilities.sObjectNameFromId(objId);
      if (objectType == 'Product2') {
        buildCheckList(objId);
      } else if (objectType == 'GMBLASERP__Serial_Number__c') {
        GMBLASERP__Serial_Number__c serial = [
          SELECT
            Id,
            Compartment_Key_Code__c,
            Ignition_Key_Code__c,
            GMBLASERP__Product__c,
            Name,
            (SELECT Id, Name, GMBLASERP__Product__r.RecordType.Name FROM Nested_Serial_Numbers__r)
          FROM GMBLASERP__Serial_Number__c
          WHERE Id = :objId
        ];
        boatSerialNumber = serial.Name;
        ignitionKeyNumber = serial.Ignition_Key_Code__c;
        compartmentKeyNumber = serial.Compartment_Key_Code__c;
        if (serial.Nested_Serial_Numbers__r.size() > 0) {
          for (GMBLASERP__Serial_Number__c s : serial.Nested_Serial_Numbers__r) {
            if (s.GMBLASERP__Product__r.RecordType.Name == 'Trailer')
              trailerSerialNumber = s.Name;
            if (s.GMBLASERP__Product__r.RecordType.Name == 'Trolling Motor')
              trollingMotorSerialNumber = s.Name;
          }
        }
        buildCheckList(serial.GMBLASERP__Product__c);
      }
    }
  }

  public Boolean getHasRiggingChecklistItems() {
    return riggingChecklistItems.size() > 0 ? true : false;
  }

  public void buildCheckList(Id prodId) {
    currentProduct = [
      SELECT
        Id,
        Name,
        (
          SELECT Id, Rank__c, Checklist_Item__r.Category__c, Checklist_Item__r.Description__c
          FROM Boat_Rigging_Checklist_Maps__r
          ORDER BY Rank__c
        )
      FROM Product2
      WHERE Id = :prodId
    ];
    currentProductName = currentProduct.Name;
    if (currentProduct.Boat_Rigging_Checklist_Maps__r.size() > 0) {
      catagorizeRiggingChecklists();
    }
  }

  private void catagorizeRiggingChecklists() {
    for (Boat_Rigging_Checklist_Map__c item : currentProduct.Boat_Rigging_Checklist_Maps__r) {
      if (!riggingChecklistItems.containsKey(item.Checklist_Item__r.Category__c)) {
        riggingChecklistItems.put(item.Checklist_Item__r.Category__c, new List<String>());
      }
      riggingChecklistItems.get(item.Checklist_Item__r.Category__c).add(item.Checklist_Item__r.Description__c);
    }
  }
}
