/**
 * Created by legend on 2020-03-05.
 */

public with sharing class BoatAppraisal_Ext {
  public String signatureId { get; private set; }

  public BoatAppraisal_Ext(ApexPages.StandardController ctr) {
    Id recordId = ctr.getId();
    try {
      signatureId = [SELECT Id FROM Attachment WHERE ParentId = :recordId AND Name = 'CustomerAppraisalSignature.png']
      .Id;
    } catch (Exception e) {
      signatureId = null;
    }
  }
}
