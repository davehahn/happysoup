/**
 * Created by dave on 2020-12-09.
 */

public class ServiceResource_Service {
  public Id recordId { get; set; }

  private ServiceResource record {
    get {
      if (record == null) {
        record = ServiceResource_Selector.getById(this.recordId);
      }
      return record;
    }
    private set;
  }

  private List<ProductItem> myInventory {
    get {
      if (myInventory == null) {
        myInventory = ProductItem_Selector.allByLocationWithQuantity(this.record.LocationId);
      }
      return myInventory;
    }
    private set;
  }

  public ServiceResource_Service(Id recordId) {
    this.recordId = recordId;
  }

  public ServiceResource getRecord() {
    return this.record;
  }

  public List<ProductItem> getMyInventory() {
    return this.myInventory;
  }
}
