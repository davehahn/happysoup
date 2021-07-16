/**
 * Created by Tim on 2021-04-26.
 */

public with sharing class FactoryStore_MCWrapperController {

    @AuraEnabled(cacheable=true)
    public static List<ConnectApi.ManagedContentVersion> initMethod(String contentType, String getTopics){
        System.debug('topics init: ' + getTopics);
        MCController mcController = new MCController(contentType, getTopics);
        return mcController.results;
    }

    public class MCController{
        @AuraEnabled public String managedContentIdsStr { get; set; }
        @AuraEnabled public String topicNamesStr { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        @AuraEnabled public String communityId { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public List<String> topics { get; set; }
        @AuraEnabled public List<ConnectApi.ManagedContentVersion> results { get; set; }

        public MCController(String contentType, String getTopics){
            System.debug('topics: ' + topics);
            type = contentType;
            topics = new List<String>{getTopics};
            communityId = Network.getNetworkId();
            getMCContent();
        }

        public void getMCContent() {
            String language = 'en_US';
            try{
                System.debug('contentType3: ' + type);
                ConnectApi.ManagedContentVersionCollection contentList = ConnectApi.ManagedContent.getManagedContentByTopics(communityId, topics, 0, 25, language, type, true);
                results = contentList.items;
            }
            catch(ConnectApi.ConnectApiException e){
                errorMessage = e.getMessage();
                System.debug('Error Message: ' + e);
                ApexPages.addMessages(e);
                results = new List<ConnectApi.ManagedContentVersion>();
            }
        }
    }
}