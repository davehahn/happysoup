public with sharing class OpportunityExt_RetailCounterSale {
  public String displayLanguage { get; set; }

  public OpportunityExt_RetailCounterSale(ApexPages.StandardController std) {
    displayLanguage = 'English';
  }

  public List<SelectOption> getLanguageOptions() {
    List<SelectOption> result = new List<SelectOption>();
    result.add(new SelectOption('English', 'English'));
    result.add(new SelectOption('French', 'French'));
    return result;
  }
}
