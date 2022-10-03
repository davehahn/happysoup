/**
 * Created by dave on 2022-05-26.
 */

public virtual class Pricebook_Selector extends Application_Selector {
  private final List<String> defaultFields = new List<String>{
    'Id',
    'Name',
    'RecordTypeId',
    'RecordType.Name',
    'Sales_Year__c',
    'Version__c'
  };

  public Pricebook_Selector() {
    this.sObjectName = 'Pricebook2';
    this.fields = defaultFields;
  }

  public static Pricebook2 getById( Id pbId ){
    return (Pricebook2)new Pricebook_Selector().addWhereIdIn( new Set<Id>{pbId} ).query()[0];
  }

  public static List<Pricebook2> getDefaultPricebooks() {
    Set<Id> defaultPbIds = Application_Constants.getInstance().activePricebooks.idSet();
    return new Pricebook_Selector().addWhereIdIn(defaultPbIds).query();
  }

  public static List<Pricebook2> allByRecordTypeIds(Set<Id> rtIds) {
    return new Pricebook_Selector().addWhereIdInField(rtIds, 'RecordTypeId').query();
  }
}
