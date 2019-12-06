public with sharing class Bot_SearchKB
{

  /** Inputs */
  public class FAQSearchInput{
    @InvocableVariable(required=true)
    public String sKeyword;
  }

  /** Outputs */
  public class FAQSearchOutput{
    @InvocableVariable(required=true)
    public String sFAQSearchResult;
  }

  public String language;
  public String emptyResponse;

  public Bot_SearchKB( String lang )
  {
    switch on lang {
      when 'english' {
        this.language = 'en_US';
        this.emptyResponse = 'No results found.';
      }
      when 'french' {
        this.language = 'fr';
        this.emptyResponse = 'Aucun résultat trouvé.';
      }
    }
  }

  public List<FAQSearchOutput> executeSearch( List<FAQSearchInput> faqSearchInput )
  {
    String sArticleBaseUrl = getCommunityArticleBaseUrl();
    String sKeyword = faqSearchInput[0].sKeyword;

    // Build the SOSL query
    String sQuery = 'FIND \'' + sKeyword +
      '\' IN ALL FIELDS RETURNING KnowledgeArticleVersion(Id, Title, UrlName WHERE PublishStatus = \'Online\' AND Language = \''+ this.language +'\' AND IsVisibleInPkb = true ) WITH SNIPPET (target_length=255) LIMIT 3';

    // Perform the SOSL search
    Search.SearchResults searchResults = Search.find(sQuery);

    // Use search results to get the list of articles
    List<Search.SearchResult> articlelist = searchResults.get('KnowledgeArticleVersion');

    String sFAQSearchResult = '';

    // Loop through all the articles to get article info
    for (Search.SearchResult searchResult : articlelist)
    {
      KnowledgeArticleVersion article = (KnowledgeArticleVersion) searchResult.getSObject();
      String sArticleSummary = summarizeArticleForBot(sArticleBaseUrl, article);
      sFAQSearchResult = sFAQSearchResult + sArticleSummary;
    }

    if (sFAQSearchResult == '') sFAQSearchResult = this.emptyResponse;

    // Build the output structure containing the results
    List<FAQSearchOutput> faqSearchOutputs = new List<FAQSearchOutput>();
    FAQSearchOutput faqSearchOutput = new FAQSearchOutput();
    faqSearchOutput.sFAQSearchResult = sFAQSearchResult;
    faqSearchOutputs.add(faqSearchOutput);
    return faqSearchOutputs;
  }

  /** Helper method that summarizes the article */
  private String summarizeArticleForBot(String sArticleBaseUrl,
                                        KnowledgeArticleVersion article)
  {
    String sSummary, sURL;
    sURL = sArticleBaseUrl + article.UrlName;

    sSummary = 'Article: ' + article.Title + '\n'+
      'URL: ' + sURL + '\n\n';

    return sSummary;
  }

  /** Helper method to get the base URL for the community */
  private String getCommunityArticleBaseUrl()
  {
    // Gets the network for your community
    // TO DO: Replace 'MY_COMMUNITY_NAME' with the name of your community!
    List<Network> communityNetworks =
    [SELECT Id FROM Network WHERE Name ='Legend Help Center'];

    String sArticleBaseUrl = '';
    if (communityNetworks.size()>0)
    {
      Network communityNetwork = communityNetworks[0];
      String sLoginUrl = Network.getLoginUrl(communityNetwork.id);
      sArticleBaseUrl = sLoginUrl.replace('/login', '/article/');
    }
    return sArticleBaseUrl;
  }
}