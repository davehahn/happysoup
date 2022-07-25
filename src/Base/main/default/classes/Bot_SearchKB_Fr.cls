public with sharing class Bot_SearchKB_Fr {
  /** Invocable Method */
  @InvocableMethod(label='Search FAQ Fr')
  public static List<Bot_SearchKB.FAQSearchOutput> searchFAQ(List<Bot_SearchKB.FAQSearchInput> faqSearchInput) {
    Bot_SearchKB bot = new Bot_SearchKB('french');
    return bot.executeSearch(faqSearchInput);
  }
}
