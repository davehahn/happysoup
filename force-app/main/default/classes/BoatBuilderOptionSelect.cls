public with sharing class BoatBuilderOptionSelect {

  public Decimal startNum { get; set; }
  public Decimal endNum { get; set; }
  public Decimal optionStep { get; set; }

    public BoatBuilderOptionSelect() {

    }

  public List<SelectOption> getOptionsFromRange() {
    List<SelectOption> selectOptions = new List<SelectOption>();
    if( isWholeNumber( endNum ) || optionStep != null )
    {
      optionStep = optionStep == null ? 1 : optionStep;
      for (Decimal i = startNum; i <= endNum; i+=optionStep)
      {
        selectOptions.add(new SelectOption(String.valueOf(i), String.valueOf(i)));
      }
    }
    else
    {
      selectOptions.add(new SelectOption(String.valueOf(startNum), String.valueOf(startNum)));
      selectOptions.add(new SelectOption(String.valueOf(endNum), String.valueOf(endNum)));
    }
    return selectOptions;
  }

  public Map<Decimal,String> getOptionsFromRangeHtml() {
    Map<Decimal, String> selectOptions = new Map<Decimal, String>();
    if( isWholeNumber( endNum ) || optionStep != null )
    {
      optionStep = optionStep == null ? 1 : optionStep;
      for (Decimal i = startNum; i <= endNum; i+=optionStep)
      {
        selectOptions.put(i, String.valueOf(i));
      }
    }
    else
    {
      selectOptions.put(startNum, String.valueOf(startNum));
      selectOptions.put(endNum, String.valueOf(endNum));
    }
    return selectOptions;
  }

  private Boolean isWholeNumber( Decimal value )
  {
    return ( value - value.round(System.RoundingMode.FLOOR) ) == 0;
  }
}