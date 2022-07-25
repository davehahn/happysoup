/**
 * Created by dave on 2022-03-02.
 */

public class FSL_Constants {
  private static FSL_Constants__c constants {
    get {
      if (constants == null) {
        constants = FSL_Constants__c.getOrgDefaults();
      }
      return constants;
    }
    set {
    }
  }

  public static String getServiceTerritoryWholeSale() {
    return constants.Service_Territory_Wholesale__c;
  }
}
