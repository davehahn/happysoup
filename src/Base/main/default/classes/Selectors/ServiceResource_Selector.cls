/**
 * Created by dave on 2020-12-09.
 */

public virtual class ServiceResource_Selector extends Application_Selector
{

  private final List<String> defaultFields = new List<String>
  {
    'Id',
    'IsActive',
    'FSL__GanttLabel__c',
    'Name',
    'LocationId',
    'RelatedRecordId'
  };

  public ServiceResource_Selector()
  {
    this.sObjectName = 'ServiceResource';
    this.fields = defaultFields;
  }

  public static ServiceResource getById( Id recordId )
  {
    ServiceResource_Selector selector = new ServiceResource_Selector();
    selector.addWhereIdIn( new Set<Id>{recordId} );
    return (ServiceResource)selector.query()[0];
  }
}