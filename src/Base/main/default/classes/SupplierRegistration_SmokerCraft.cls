/**
 * Created by dave on 2019-10-15.
 */

public with sharing class SupplierRegistration_SmokerCraft implements SupplierRegistration.SupplierRegistrationInterface {
  public SupplierRegistration_SmokerCraft() {
  }

  public SupplierRegistration.Result execute(Registration_Helper.RegistrationWrapper wrapper) {
    System.debug('SupplierRegistration_SmokerCraft wrapper = ' + wrapper);
    SupplierRegistration.Result registrationResult = new SupplierRegistration.Result();
    registrationResult.wrapper = wrapper;
    Map<String, String> result = SmokercraftAPI_Callout.registerSerialNumber(
      buildSubmitString(wrapper),
      wrapper.serialNumber
    );
    if (result.get('status') == 'success') {
      registrationResult.status = 'success';
    } else {
      registrationResult.status = 'error';
      registrationResult.errorMessage = result.get('errorMessage');
    }
    return registrationResult;
  }

  private String buildSubmitString(Registration_Helper.RegistrationWrapper wrapper) {
    String data = '';
    data += 'hin=' + wrapper.serialNumber + '&';
    data += 'dealer_number=' + SmokercraftAPI_Callout.dealerNumber + '&';
    data += 'dealer_seq=0&';
    if (wrapper.toAccount.Name != null)
      data += 'cust_name=' + EncodingUtil.urlEncode(wrapper.toAccount.Name, 'UTF-8') + '&';
    if (wrapper.toAccount.BillingStreet != null)
      data += 'cust_address=' + EncodingUtil.urlEncode(wrapper.toAccount.BillingStreet, 'UTF-8') + '&';
    if (wrapper.toAccount.BillingCity != null)
      data += 'cust_city=' + EncodingUtil.urlEncode(wrapper.toAccount.BillingCity, 'UTF-8') + '&';
    if (wrapper.toAccount.BillingStateCode != null)
      data += 'cust_state=' + EncodingUtil.urlEncode(wrapper.toAccount.BillingStateCode, 'UTF-8') + '&';
    if (wrapper.toAccount.BillingPostalCode != null)
      data += 'cust_zip=' + EncodingUtil.urlEncode(wrapper.toAccount.BillingPostalCode, 'UTF-8') + '&';
    if (wrapper.toAccount.BillingCountry != null)
      data += 'cust_country=' + EncodingUtil.urlEncode(wrapper.toAccount.BillingCountry, 'UTF-8') + '&';
    if (wrapper.toAccount.PersonEmail != null)
      data += 'cust_email=' + EncodingUtil.urlEncode(wrapper.toAccount.PersonEmail, 'UTF-8') + '&';
    data += 'age=' + wrapper.toAccount.Current_Age__pc + '&';
    data += 'kids=' + wrapper.toAccount.Number_of_Children__c + '&';
    if (wrapper.deliveryDate != null)
      data += 'purchase_date=' + wrapper.deliveryDate.format('MM/dd/yyyy') + '&';
    else if (wrapper.registeredDate != null)
      data += 'purchase_date=' + wrapper.registeredDate.format('MM/dd/yyyy') + '&';
    else
      data += 'purchase_date=' + wrapper.createDate.format('MM/dd/yyyy') + '&';
    //not used at this time
    data += 'email_ok=' + '1';
    //    data += 'income=80000&';
    //    data += 'prior_boat=0&';
    //    data += 'use=fishing&';
    //    data += 'activity=fun&';
    //    data += 'where=home&';
    //    data += 'stored=0&';
    //    data += 'other_b4=0';
    return data;
  }
}
