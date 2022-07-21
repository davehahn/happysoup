public with sharing class LGND_Store {
  //public class LGND_StoreException extends Exception {}

  public String Name { get; set; }
  public String Province { get; set; }
  public String Street { get; set; }
  public String City { get; set; }
  public String PostalCode { get; set; }
  public String Phone { get; set; }
  public String TollFree { get; set; }
  public String Fax { get; set; }

  public LGND_Store(String store) {
    store = determineStore(store);
    Map<String, LGND_Store__c> stores = LGND_Store__c.getAll();
    if (stores.containsKey(store)) {
      this.Name = stores.get(store).Name;
      this.Province = stores.get(store).Province__c;
      this.City = stores.get(store).City__c;
      this.Street = stores.get(store).Street__c;
      this.PostalCode = stores.get(store).PostalCode__c;
      this.Phone = stores.get(store).Phone__c;
      this.TollFree = stores.get(store).TollFree__c;
      this.Fax = stores.get(store).Fax__c;
    }
  }

  public String getAddress() {
    return this.Street + ' - ' + this.City + ', ' + this.Province + ' - ' + this.PostalCode;
  }

  private static String determineStore(String store) {
    if (store == null)
      return 'Whitefish';
    if (store.toLowerCase().contains('barrie'))
      return 'Barrie';
    if (store.toLowerCase().contains('whitefish'))
      return 'Whitefish';
    if (store.toLowerCase().contains('montreal'))
      return 'Montreal';
    //throw new LGND_StoreException('An unexceptable store has been specified');
    return 'Whitefish';
  }
}
