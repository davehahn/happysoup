public class PostCashReceiptFromFlow
{
    @InvocableMethod(label='Post Cash Receipt' description='Specify a record ID that needs be posted.')
    public static void postCashReceipt(List<String> CashReceiptId)  {

        AcctSeed__Cash_Receipt__c[] receipts = [SELECT Id, AcctSeed__Account__c, AcctSeed__Amount__c, AcctSeed__Payment_Reference__c FROM AcctSeed__Cash_Receipt__c WHERE Id = :CashReceiptId];

        AcctSeed.PostResult[] postResults = AcctSeed.CashReceiptPostService.postCashReceipts(receipts);


        for (AcctSeed.PostResult theResult : postResults) {
            if (theResult.isSuccess) {
                System.debug('Successfully posted billing: ' + theResult.id);
            }
            else {
                System.debug('Error posting billing ' + theResult.id);
                for (AcctSeed.PostResult.PostErrorResult errorResult: theResult.errors) {
                    System.debug('Error status code ' + errorResult.statusCode);
                    System.debug('Error message ' + errorResult.message);
                }
            }
        }

    }
}