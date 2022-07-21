public class ReportFinderUtil {
  public ReportFinderUtil() {
  }

  public String findReportId(String reportName) {
    try {
      Sobject myReport = [SELECT Id, Name FROM Report WHERE Name = :reportName];
      return myReport.Id;
    } catch (Exception e) {
      return null;
    }
  }
}
