public with sharing class Bot_SearchKB_Eng {
  /** Invocable Method */
  @InvocableMethod(label='Search FAQ Eng')
  public static List<Bot_SearchKB.FAQSearchOutput> searchFAQ(List<Bot_SearchKB.FAQSearchInput> faqSearchInput) {
    Bot_SearchKB bot = new Bot_SearchKB('english');
    return bot.executeSearch(faqSearchInput);
  }
}
