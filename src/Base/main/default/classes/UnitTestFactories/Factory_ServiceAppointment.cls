/**
 * Created by dave on 2021-06-07.
 */
@IsTest
public class Factory_ServiceAppointment {
  public static ServiceAppointment buildForWorkOrder(WorkOrder wo) {
    return new ServiceAppointment(ParentRecordId = wo.Id, DueDate = Datetime.now(), EarliestStartTime = Datetime.now());
  }
}
