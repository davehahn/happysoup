#parse("Apex File Header.cls")

public virtual class ${NAME} extends Application_Selector 
{

  private final List<String> defaultFields = new List<String>{
  
  };
  
  public ${NAME}()
  {
    this.sObjectName = '${SOBJECT}';
    this.fields = defaultFields;
  }
}