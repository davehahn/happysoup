/*
 * MultiselectController synchronizes the values of the hidden elements to the
 * SelectOption lists.
 */
public with sharing class MultiselectController {
  // SelectOption lists for public consumption
  public SelectOption[] leftOptions;
  public SelectOption[] rightOptions { get; set; }
  public Integer leftOptionsCount { get; private set; }

  public void setLeftOptions(SelectOption[] opts) {
    if (leftOptions == null && opts != null) {
      leftOptions = opts;
      System.debug('left Options size = ' + opts.size());
      leftOptionsCount = opts.size();
    }
  }

  public SelectOption[] getLeftOptions() {
    return leftOptions;
  }

  // Parse &-separated values and labels from value and
  // put them in option
  private void setOptions(SelectOption[] options, String value) {
    if (options != null) {
      options.clear();
      String[] parts = value.split('&');
      for (Integer i = 0; i < parts.size() / 2; i++) {
        options.add(
          new SelectOption(
            EncodingUtil.urlDecode(parts[i * 2], 'UTF-8'),
            EncodingUtil.urlDecode(parts[(i * 2) + 1], 'UTF-8')
          )
        );
      }
    }
  }

  // Backing for hidden text field containing the options from the
  // left list
  public String leftOptionsHidden {
    get;
    set {
      leftOptionsHidden = value;
      setOptions(leftOptions, value);
    }
  }

  // Backing for hidden text field containing the options from the
  // right list
  public String rightOptionsHidden {
    get;
    set {
      rightOptionsHidden = value;
      setOptions(rightOptions, value);
    }
  }
}
