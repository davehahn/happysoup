/**
 * Created by Tim on 2021-05-10.
 */

public with sharing class CommSharedURL_Controller {
  @AuraEnabled(Cacheable=true)
  public static ConnectApi.Community fetchCommunityDetails(String communityId) {
    ConnectApi.Community myCommunity = ConnectApi.Communities.getCommunity(communityId);
    return myCommunity;
  }
}
