public with sharing class BoatBuilderOptionSelect {

  public Integer startNum { get; set; }
  public Integer endNum { get; set; }

    public BoatBuilderOptionSelect() {

    }

  public List<SelectOption> getOptionsFromRange() {
    List<SelectOption> selectOptions = new List<SelectOption>();
    for(Integer i=startNum; i <= endNum; i++) {
      selectOptions.add( new SelectOption(String.valueOf(i), String.valueOf(i)) );
    }
    return selectOptions;
  }

  public Map<Integer,String> getOptionsFromRangeHtml() {
    Map<Integer, String> selectOptions = new Map<Integer, String>();
    for(Integer i=startNum; i <= endNum; i++) {
      selectOptions.put(i, String.valueOf(i));
    }
    return selectOptions;
  }
}