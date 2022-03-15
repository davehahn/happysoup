/**
 * Created by dave on 2020-12-08.
 */

public virtual class ServiceAppointment_Selector extends Application_Selector
{

  private final List<String> defaultFields = new List<String>
  {
    'Id',
    'ParentRecordId',
    'ParentRecordType',
    'ParentRecord.Name',
    'ServiceTerritoryId',
    'AccountId'
  };

  public ServiceAppointment_Selector()
  {
    this.sObjectName = 'ServiceAppointment';
    this.fields = defaultFields;
  }

  public static List<ServiceAppointment> allById( Set<Id> recordIds )
  {
    return new ServiceAppointment_Selector()
      .addWhereIdIn( recordIds )
      .query();
  }


  public static Map<Id, ServiceAppointment> allByWorkOrderId_asMap( Id woId )
  {
    ServiceAppointment_Selector selector = new ServiceAppointment_Selector();
    selector.addWhere( 'ParentRecordId = \'' + woId +'\'' );
    return new Map<Id, ServiceAppointment>(
      (List<ServiceAppointment>)selector.query()
    );
  }
}