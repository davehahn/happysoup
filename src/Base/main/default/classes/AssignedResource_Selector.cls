/**
 * Created by dave on 2020-12-08.
 */

public virtual class AssignedResource_Selector extends Application_Selector {
  private final List<String> defaultFields = new List<String>{
    'Id',
    'ServiceCrewId',
    'ServiceCrew.Name',
    'ServiceAppointmentId',
    'ServiceResourceId',
    'ServiceResource.Name',
    'ServiceResource.FSL__GanttLabel__c',
    'ServiceResource.LocationId',
    'ServiceResource.Location.Name',
    'ServiceResource.Location.LocationType',
    'ServiceResource.ResourceType',
    'ServiceResource.RelatedRecordId',
    'ServiceResource.RelatedRecord.Name'
  };

  public AssignedResource_Selector() {
    this.sObjectName = 'AssignedResource';
    this.fields = defaultFields;
  }

  public static List<AssignedResource> allByServiceAppointmentIds(Set<Id> saIds) {
    AssignedResource_Selector selector = new AssignedResource_Selector();
    selector.addWhereIdInField(saIds, 'ServiceAppointmentId');
    return selector.query();
  }
}
