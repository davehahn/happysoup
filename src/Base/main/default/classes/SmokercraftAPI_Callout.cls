public with sharing class SmokercraftAPI_Callout {
  public class SmokerAPIException extends Exception {
  }

  private static final String domain = 'https://sl-web-portal.smokercraftinc.com';
  private static final String addIncident = '/incident_api/InsertIncident.aspx';
  private static final String createRegistration = '/warranty_api/InsertRegistration.aspx';
  private static final String partnerId = 'DT';
  public static final String dealerNumber = '800795';

  public static void submitClaimToSmokercraft(Id erpId) {
    AcctSeed__Project__c erp = fetchERP(erpId);
    EmailComponentController ecc = new EmailComponentController();
    ecc.recordId = erpId;
    EmailComponentController.warrantyRecoverable warrantyRecoverable = ecc.getCaseEmailDetails();
    String data = buildSubmitForWarrantyData(warrantyRecoverable);
    HttpResponse response = doAPISubmit(data, addIncident);
    Dom.Document responseBody = response.getBodyDocument();
    Dom.XMLNode xmlResponse = responseBody.getRootElement();
    String statusCode = xmlResponse.getChildElement('STATUSCODE', null).getText();

    if (statusCode == '200') {
      String incidentId = xmlResponse.getChildElement('RESPONSE', null).getText();
      erp.Supplier_Claim_Number__c = incidentId;
      Boolean o = gcProject.disableTrigger;
      gcProject.disableTrigger = true;
      update erp;
      gcProject.disableTrigger = o;
    } else {
      handleApiError(responseBody, data, erp.Name);
    }
  }

  //  public static void registerBoatToSmoker(Id registrationId)
  //  {
  //    registerBoatToSmoker(fetchRegistration(registrationId));
  //  }

  //  public static void registerBoatToSmoker(Registration__c reg)
  //  {
  //    if (!reg.SerialNumber__r.IsRegisteredWithSupplier__c)
  //    {
  //      if (doRegistrationSubmit(reg))
  //      {
  //        update new GMBLASERP__Serial_Number__c(
  //          Id = reg.SerialNumber__c,
  //          RegisteredWithSupplierDate__c = DateTime.now(),
  //          IsRegisteredWithSupplier__c = true
  //        );
  //      }
  //    }
  //  }

  //  public static Boolean doRegistrationSubmit(Registration__c reg)
  //  {
  //    String data = buildSubmitForRegistration(reg);
  //    HttpResponse response = doAPISubmit( data, createRegistration);
  //    Dom.Document responseBody = response.getBodyDocument();
  //    Dom.XMLNode xmlResponse = responseBody.getRootElement();
  //    String statusCode = xmlResponse.getChildElement('STATUSCODE', null).getText();
  //    if (statusCode == '200')
  //    {
  //      return true;
  //    }
  //    //handleApiError( responseBody, data, reg.SerialNumber__r.Name );
  //    return false;
  //  }

  public static Map<String, String> registerSerialNumber(String data, String serialNumber) {
    Map<String, String> result = new Map<String, String>();
    HttpResponse response = doAPISubmit(data, createRegistration);
    Dom.Document responseBody = response.getBodyDocument();
    System.debug('SMOKER RESPONSE: ' + response);
    Dom.XMLNode xmlResponse = responseBody.getRootElement();
    String statusCode = xmlResponse.getChildElement('STATUSCODE', null).getText();
    if (statusCode == '200') {
      result.put('status', 'success');
    } else {
      result.put('status', 'error');
      if (Test.isRunningTest())
        result.put('errorMessage', 'Test Error');
      else
        result.put('errorMessage', buildErrorString(responseBody, data, serialNumber));
    }
    return result;
  }

  //  @TestVisible
  //  private static Registration__c fetchRegistration( Id regId )
  //  {
  //    try {
  //      return Registration_Selector.allById( new Set<Id>{regId} )[0];
  //    }
  //    catch( Exception e )
  //    {
  //      throw new SmokerAPIException('Could not find Registration using supplied Id - ' + regId );
  //    }
  //  }

  @TestVisible
  private static AcctSeed__Project__c fetchERP(Id erpId) {
    return [SELECT Id, Name, Grand_Total__c, Warranty_Case__c FROM AcctSeed__Project__c WHERE Id = :erpId];
  }

  private static String buildSubmitForWarrantyData(EmailComponentController.warrantyRecoverable warrantyRecoverable) {
    String incNotes = buildIncidentNotes(warrantyRecoverable);
    String data = 'hin=' + warrantyRecoverable.serialNumber + '&';
    data += 'partner_id=' + partnerId + '&';
    data += 'notes=' + incNotes.replaceAll('[|&|]', 'and') + '&';
    data += 'dealer_number=' + dealerNumber + '&';
    data += 'contact_name=' + warrantyRecoverable.customerName + '&';
    data += 'contact_phone=' + warrantyRecoverable.customerPhone + '&';
    data += 'contact_email=' + warrantyRecoverable.customerEmail;
    return data;
  }

  //  private static String buildSubmitForRegistration( Registration__c reg )
  //  {
  //    String data = '';
  //    data += 'hin=' + reg.SerialNumber__r.Name + '&';
  //    data += 'dealer_number=' + dealerNumber +'&';
  //    data += 'dealer_seq=0&';
  //    data += 'cust_name=' + EncodingUtil.urlEncode(reg.Account__r.Name, 'UTF-8') + '&';
  //    data += 'cust_address=' + EncodingUtil.urlEncode(reg.Account__r.BillingStreet, 'UTF-8') + '&';
  //    data += 'cust_city=' + EncodingUtil.urlEncode(reg.Account__r.BillingCity, 'UTF-8') + '&';
  //    data += 'cust_state=' + EncodingUtil.urlEncode(reg.Account__r.BillingStateCode, 'UTF-8') + '&';
  //    data += 'cust_zip=' + EncodingUtil.urlEncode(reg.Account__r.BillingPostalCode, 'UTF-8') + '&';
  //    data += 'cust_country=' + EncodingUtil.urlEncode(reg.Account__r.BillingCountry, 'UTF-8') + '&';
  //    data += 'cust_email=' + EncodingUtil.urlEncode( reg.Account__r.PersonEmail, 'UTF-8') + '&';
  //    data += 'age=' + reg.Account__r.Current_Age__pc + '&';
  //    data += 'kids=' + reg.Account__r.Number_of_Children__c + '&';
  //    if( reg.Delivery_Date__c != null )
  //      data += 'purchase_date=' + reg.Delivery_Date__c.format('MM/dd/yyyy') + '&';
  //    else if( reg.Registered_Date__c != null )
  //      data += 'purchase_date=' + reg.Registered_Date__c.format('MM/dd/yyyy') + '&';
  //    else
  //      data += 'purchase_date=' + reg.CreatedDate.format('MM/dd/yyyy') + '&';
  //    //not used at this time
  //    data += 'email_ok=' + '1';
  ////    data += 'income=80000&';
  ////    data += 'prior_boat=0&';
  ////    data += 'use=fishing&';
  ////    data += 'activity=fun&';
  ////    data += 'where=home&';
  ////    data += 'stored=0&';
  ////    data += 'other_b4=0';
  //    return data;
  //  }

  private static String buildIncidentNotes(EmailComponentController.warrantyRecoverable warrantyRecoverable) {
    String rDate = warrantyRecoverable.purchaseDate == null ? '' : warrantyRecoverable.purchaseDate.format();
    String contactAddress = buildContactAddress(warrantyRecoverable);
    Map<String, String> partsAndLabor = buildPartsAndLabour(warrantyRecoverable);
    User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId()];
    String result = '';
    if (warrantyRecoverable.supplierClaimNumber != null) {
      result +=
        'THIS IS A RESUBMISSION FOR LEGEND BOATS CLAIM: ' +
        warrantyRecoverable.supplierClaimNumber +
        '\r\n\r\n';
    }
    result += partsAndLabor.get('description') + '\r\n';
    result += '---- PARTS: \r\n' + partsAndLabor.get('parts') + '\r\n';
    result += '---- LABOR HOURS: ' + partsAndLabor.get('laborHours') + '\r\n';
    result += '---- LABOR RATE: ' + partsAndLabor.get('laborRate') + '\r\n';
    result += '---- FREIGHT: ' + partsAndLabor.get('freight') + '\r\n';
    result += '---- TOTAL PRICE: ' + warrantyRecoverable.total + '\r\n';
    result += '---- LEGEND BOATS CLAIM NUMBER: ' + warrantyRecoverable.claimNumber + '\r\n';
    result += '---- FORM SUBMITTED BY: ' + currentUser.Name + ' at ' + currentUser.Email + '\r\n';
    result += '---- CUSTOMER: \r\n' + warrantyRecoverable.customerName + '\r\n' + contactAddress + '\r\n';
    result += '---- PURCHASE DATE: ' + rDate + '\r\n';
    return result;
  }

  private static String buildContactAddress(EmailComponentController.warrantyRecoverable warrantyRecoverable) {
    String result = '';
    result += warrantyRecoverable.customerStreet + '\r\n';
    result += warrantyRecoverable.customerCity + '\r\n';
    result += warrantyRecoverable.customerState + '\r\n';
    result += warrantyRecoverable.customerCountry + '\r\n';
    result += warrantyRecoverable.customerPostalCode + '\r\n';
    return result;
  }

  private static Map<String, String> buildPartsAndLabour(
    EmailComponentController.warrantyRecoverable warrantyRecoverable
  ) {
    Map<String, String> result = new Map<String, String>();
    String description = '';
    Decimal freight = 0;
    Decimal lhours = 0;
    Decimal lRate = 0;
    Decimal gTotal = 0;
    String parts = '';
    for (EmailComponentController.ClaimDetail cd : warrantyRecoverable.claimDetails) {
      description += cd.description;
      if (cd.correction != null)
        description += ', ' + cd.correction;

      if (cd.labourLines.size() > 0) {
        Decimal lt = 0;
        for (EmailComponentController.PartLine pl : cd.labourLines) {
          lt += pl.quantity;
          lRate = pl.unitCost;
          lHours += pl.quantity;
        }
        description += ' (' + String.valueOf(lt) + ') ';
      }
      description += '\r\n';

      freight += cd.freightTotal;

      for (EmailComponentController.PartLine pl : cd.partLines) {
        parts += '\r\n';
        parts += pl.quantity + ' ';
        parts += pl.productCode;
        parts += ' (' + pl.productName + ')';
        String cost = String.valueOf(pl.total);
        parts += ' with net cost $' + cost;
      }

      for (EmailComponentController.PartLine pl : cd.subletLines) {
        parts += '\r\n';
        parts += pl.quantity + ' ';
        parts += pl.productCode;
        parts += ' (' + pl.productName + ')';
        parts += ' with net cost $' + pl.total;
      }
    }

    result.put('parts', parts);
    result.put('laborHours', String.valueOf(lHours));
    result.put('laborRate', String.valueOf(lRate));
    result.put('freight', String.valueOf(freight));
    result.put('description', description);
    return result;
  }

  private static HttpResponse doAPISubmit(String data, String actionURL) {
    Http http = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndpoint(domain + actionURL);
    request.setMethod('POST');
    //request.setHeader('Content-Type', 'application/x-www-form-urlenco‌​ded');
    request.setBody(data);
    return http.send(request);
  }

  private static void handleApiError(Dom.Document responseBody, String data, String recordName) {
    throw new SmokerAPIException(buildErrorString(responseBody, data, recordName));
  }

  private static String buildErrorString(Dom.Document responseBody, String data, String recordName) {
    Dom.XMLNode xmlResponse = responseBody.getRootElement();
    String statusCode = xmlResponse.getChildElement('STATUSCODE', null).getText();
    String error = xmlResponse.getChildElement('RESPONSEERROR', null).getText();
    String body = 'There was an error submitting ' + recordName + '  to the Supplier \r\n';
    body += 'Responded with StatusCode ' + statusCode + '\r\n';
    body += 'ERROR = ' + error + '\r\n';
    body += 'DATA DUMP: \r\n';
    body += data;
    System.debug('Smoker Callout ERROR');
    System.debug(body);
    return body;
  }
}
