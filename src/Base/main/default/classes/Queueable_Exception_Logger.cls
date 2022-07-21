/**
 * Created by dave on 2021-06-17.
 */

public class Queueable_Exception_Logger {
  public String moduleName;
  public String stackTrace;
  public String className;
  public String methodName;
  public String type;
  public String cause;
  public Integer lineNumber;
  public String message;
  public String initialInputType;
  public String initialInputJSON;

  public void log(Exception ex) {
    try {
      readException(ex);
      writeObject();
    } catch (Exception e) {
      //      new Queueable_Exception_Logger()
      //        .setModule('Queueable_Exception_Logger')
      //        .log( e );
      System.debug(e.getMessage());
    }
  }

  public Queueable_Exception_Logger setModule(String name) {
    this.moduleName = name;
    return this;
  }

  public Queueable_Exception_Logger setInitialInputType(String type) {
    this.initialInputType = type;
    return this;
  }

  public Queueable_Exception_Logger setInitialInput(Object input) {
    this.initialInputJSON = JSON.serialize(input);
    return this;
  }

  private void readException(Exception ex) {
    try {
      String stackTraceString = ex.getStackTraceString().substringBefore('\n');

      this.className = stackTraceString.substringAfter('.').substringBefore('.');

      this.methodName = stackTraceString.substringBefore(':').substringAfter(className).substringAfter('.');

      this.lineNumber = ex.getLineNumber();
      this.stackTrace = ex.getStackTraceString();
      this.type = ex.getTypeName();
      this.cause = String.valueOf(ex.getCause());
      this.message = ex.getMessage();
    } catch (Exception e) {
      //      new Queueable_Exception_Logger()
      //        .setModule('Queueable_Exception_Logger')
      //        .log( e );
      System.debug(e.getMessage());
    }
  }

  private void writeObject() {
    try {
      insert new Queueable_Exception_Log__c(
        Cause__c = this.cause,
        Class_Name__c = this.className,
        Initial_Input_JSON__c = this.initialInputJSON,
        Initial_Input_Type__c = this.initialInputType,
        Line_Number__c = this.lineNumber,
        Message__c = this.message,
        Method_Name__c = this.methodName,
        Module_Name__c = this.moduleName,
        Stack_Trace__c = this.stackTrace,
        Type__c = this.type
      );
    } catch (Exception e) {
      //      new Queueable_Exception_Logger()
      //        .setModule('Queueable_Exception_Logger')
      //        .log( e );
      System.debug(e.getMessage());
    }
  }
}
