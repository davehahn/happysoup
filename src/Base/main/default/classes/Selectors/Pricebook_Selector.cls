/**
 * Created by dave on 2022-05-26.
 */

public virtual class Pricebook_Selector extends Application_Selector
{

  private final List<String> defaultFields = new List<String>
  {
    'Id',
    'Name',
    'RecordTypeId',
    'RecordType.Name',
    'Sales_Year__c',
    'Version__c'
  };

  public Pricebook_Selector()
  {
    this.sObjectName = 'Pricebook2';
    this.fields = defaultFields;
  }

  public static List<Pricebook2> getDefaultPricebooks(){
    Set<Id> defaultPbIds = Application_Constants.getInstance().activePricebooks.idSet();
    return new Pricebook_Selector()
      .addWhereIdIn( defaultPbIds )
      .query();
  }
}