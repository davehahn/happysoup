@isTest
public class Factory_Campaign {
  public static Campaign createCampaign(String name) {
    Campaign c = new Campaign();
    c.Name = name;
    c.StartDate = System.today();
    c.EndDate = System.today();
    insert c;
    return c;
  }
}
