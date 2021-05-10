public with sharing class OpportunityDispatcher {

  private final ApexPages.StandardController controller;
  public final Id oppId;

  //public String rId {get; set;}
  //public String retURL {get; set;}
  //public String saveNewURL {get; set;}
  //public String rType {get; set;}
  //public String cancelURL {get; set;}
  //public String ent {get; set;}
  //public String confirmationToken {get; set;}



	public OpportunityDispatcher( ApexPAges.StandardController ctr) {
		this.controller = ctr;
    this.oppId = this.controller.getId();

    //rId = ApexPages.currentPage().getParameters().get('id');
    //retURL = ApexPages.currentPage().getParameters().get('retURL');
    //rType = ApexPages.currentPage().getParameters().get('RecordType');
    //cancelURL = ApexPages.currentPage().getParameters().get('cancelURL');
    //ent = ApexPages.currentPage().getParameters().get('ent');
    //confirmationToken = ApexPages.currentPage().getParameters().get('_CONFIRMATIONTOKEN');
    //saveNewURL = ApexPages.currentPage().getParameters().get('save_new_url');
	}

  public PageReference viewRedir() {
    PageReference view;
    if( oppId != null )
    {
      Opportunity o = [SELECT Id, RecordType.Name
                       FROM Opportunity
                       WHERE Id = :oppId ];

      if( o.RecordType.Name == 'Retail Counter Sale')
      {
        view = Page.Opportunity_CounterSaleView;
        view.getParameters().put('id', oppId);

      }
      else
      {
        //
        String theme = UserInfo.getUiThemeDisplayed();
        if( theme == 'Theme4d' )
        {
          view = new PageReference('/' + oppId);
        }
        else
        {
          view = Page.Opportunity_Detail;
          view.getParameters().put('id', oppId);
        }
      }
    }
    else
    {
      view = new PageReference('/006');
    }
    view.getParameters().put('nooverride', '1');
    view.setRedirect(true);
    return view;

  }

  public PageReference editRedirect() {
    PageReference edit;
    if( oppId != null )
    {
      Opportunity o = [SELECT Id, RecordType.Name
                       FROM Opportunity
                       WHERE Id = :oppId ];

      if( o.RecordType.Name == 'Retail Counter Sale')
      {
        edit= Page.RetailCounterSalesTool;
        edit.getParameters().put('id', oppId);
        //edit.getParameters().put('retURL', retURL);

      }
      else
      {
       edit = new PageReference('/'+oppId+'/e');
      }
    }
    else
    {
      edit = new PageReference('/006');
    }
     edit.getParameters().put('nooverride', '1');
     edit.setRedirect(true);
    return edit;
  }

  public PageReference configuratorRedir()
  {
    PageReference pr;
    if( oppId != null )
    {
      User currentUser = [SELECT Id, Name, Profile.Name
                     FROM User
                     WHERE Id = :UserInfo.getUserId()];

      //Let check to see if the opportunity is locked
      Set<String> statuses = new Set<String>{'Pending', 'Approved'};
      List<Processinstance> pi = [SELECT Id, Status
                            FROM Processinstance
                            WHERE TargetObjectId = :oppId
                            AND Status IN :statuses];
      CustomPermissionsReader cpr = new CustomPermissionsReader();
      if( pi.isEmpty() || cpr.hasPermission('CanEditLockedOpportunity') )
      {
        pr = Page.BoatConfigurator;
        pr.getParameters().put('opportunity_id', oppId);
        pr.getParameters().put('nooverride', '1');
        pr.setRedirect(true);
      }
      else
      {
        pr = Page.BoatConfigurator_View;
        pr.getParameters().put('opportunity_id', oppId);
        pr.getParameters().put('nooverride', '1');
        pr.setRedirect(true);
      }

    }
    return pr;
  }


}