@isTest
private class LeadSourceSelectorController_mp_test {
  @isTest
  static void getLeadSources() {
    List<String> sources = LeadSourceSelectorController_mp.getLeadSources();
    System.assert(sources.size() > 0);
  }
}
