/**
 * Created by Tim on 2021-05-03.
 */
//Get Managed Content From Salesforce CMS

public with sharing class CommSharedMC_Controller {
    @AuraEnabled(cacheable=true)
    public static ConnectApi.ManagedContentVersionCollection getManagedContentByContentKeys(String communityId, String[] managedContentIds, Integer pageParam, Integer pageSize, String language, String managedContentType, Boolean showAbsoluteUrl){
        return ConnectApi.ManagedContent.getManagedContentByContentKeys(communityId, managedContentIds, pageParam, pageSize, language, managedContentType, showAbsoluteUrl);
    }
}