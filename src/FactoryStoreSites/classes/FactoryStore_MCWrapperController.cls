/**
 * Created by Tim on 2021-04-26.
 */

public with sharing class FactoryStore_MCWrapperController {

    @AuraEnabled(cacheable=true)
    public static List<ConnectApi.ManagedContentVersion> initMethod(String contentType, String contentKey){
        System.debug('contentKey init: ' + contentKey);
        MCController mcController = new MCController(contentType, contentKey);
        return mcController.results;
    }

    public class MCController{
        @AuraEnabled public String managedContentIdsStr { get; set; }
        @AuraEnabled public String topicNamesStr { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        @AuraEnabled public String communityId { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public List<String> keys { get; set; }
        @AuraEnabled public Boolean hasKey { get; set; }
        @AuraEnabled public List<ConnectApi.ManagedContentVersion> results { get; set; }

        public MCController(String contentType, String contentKey){
            System.debug('contentkey: ' + contentKey);
            type = contentType;
            keys = new List<String>{contentKey};
            hasKey = (contentKey != null) ? true : false;
            communityId = Network.getNetworkId();
            getMCContent();
        }

        public void getMCContent() {
            String language = 'en_US';
            List<String> contentKeys = new List<String>();
            System.debug('keys: ' + keys);
            System.debug('keys.size: ' + keys.size());
            if(hasKey){
                contentKeys = keys;
            }
            try{
                System.debug('contentType3: ' + type);
                ConnectApi.ManagedContentVersionCollection contentList = ConnectApi.ManagedContent.getManagedContentByContentKeys(communityId, contentKeys, 0, 25, language, type, false);
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