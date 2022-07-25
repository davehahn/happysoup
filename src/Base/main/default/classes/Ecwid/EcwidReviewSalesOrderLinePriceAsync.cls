public without sharing class EcwidReviewSalesOrderLinePriceAsync implements Queueable {
  private List<AcctSeedERP__Sales_Order_Line__c> sales_order_lineitem_list;

  public EcwidReviewSalesOrderLinePriceAsync(Map<String, List<sObject>> input_map) {
    sales_order_lineitem_list = (List<AcctSeedERP__Sales_Order_Line__c>) input_map.get('salesorderitems');
  }

  public void execute(QueueableContext context) {
    processRequest();
  }

  @TestVisible
  private void processRequest() {
    //Get comma saperator list of user id from custom metadata:
    Id userId = '0054z000008RnWYAA0';

    String body = 'Need to review UnitPrice for below Sales Line Item:';

    List<FeedItem> chatter_post_list = new List<FeedItem>();
    for (AcctSeedERP__Sales_Order_Line__c sol : sales_order_lineitem_list) {
      body += 'Sales Order Line Item: ' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + sol.Id;
      FeedItem post = new FeedItem();
      post.ParentId = userID;
      post.Body = body;
      post.Type = 'TextPost';
      chatter_post_list.add(post);
    }

    insert chatter_post_list;
  }
}
