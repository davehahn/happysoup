/**
 * Created by dave on 2019-10-15.
 */

public with sharing class SupplierRegistration {
  public class SupplierRegistration_Exception extends Exception {
  }

  public List<Registration_Helper.RegistrationWrapper> regWrappers;

  public SupplierRegistration(Set<Id> regIds) {
    this.regWrappers = new List<Registration_Helper.RegistrationWrapper>();
    for (Registration__c r : Registration_Selector.allById(regIds)) {
      this.regWrappers.add(new Registration_Helper.RegistrationWrapper(r));
    }
  }

  public SupplierRegistration(List<Registration_Helper.RegistrationWrapper> regWrappers) {
    this.regWrappers = regWrappers;
  }

  public List<Result> execute() {
    List<Result> results = new List<Result>();
    for (Registration_Helper.RegistrationWrapper wrapper : this.regWrappers) {
      System.debug(wrapper.supplierRegistrationClass);
      if (
        wrapper.supplierRegistrationClass != null &&
        wrapper.registeredToCustomer &&
        !wrapper.serialRegisteredWithSupplier
      ) {
        SupplierRegistrationInterface regI = (SupplierRegistrationInterface) Type.forName(
            wrapper.supplierRegistrationClass
          )
          .newInstance();
        results.add(regI.execute(wrapper));
      }
    }
    return results;
  }

  public class Result {
    public String status;
    public String errorMessage;
    public Registration_Helper.RegistrationWrapper wrapper;

    public Result() {
    }
  }

  public interface SupplierRegistrationInterface {
    Result execute(Registration_Helper.RegistrationWrapper input);
  }
}
