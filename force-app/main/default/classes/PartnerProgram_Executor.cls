/**
 * Created by dave on 2020-09-08.
 */

public class PartnerProgram_Executor
{
  public class PartnerProgram_Exception Extends Exception{}

  public void execute( PartnerProgram_Service.DealerOrderWrapper wrapper)
  {
    if( wrapper.isFactoryStore )
    {
      publishEvent( wrapper, 'success' );
    }
    else
    {
      if (!Test.isRunningTest())
      {
        new Promise(new PartnerProgram_Coop())
          .then(new PartnerProgram_Kickstart_Booking())
          .then(new PartnerProgram_7for7())
          .then(new PartnerProgram_Volume())
          .then(new PartnerProgram_PontoonVol())
          .then(new PartnerProgram_Cash())
          .error(new PartnerProgram_ErrorHandler())
          .done(new PartnerProgram_DoneHandler())
          .execute(wrapper);
      }
    }
  }

  public static void publishEvent( PartnerProgram_Service.DealerOrderWrapper wrapper,
                                   String status )
  {
    Partner_Program_Event__e evt = new Partner_Program_Event__e(
      Status__c = status,
      DealerOrderId__c = wrapper.dealerOrderId,
      Result__c = JSON.serialize( wrapper.result )
    );
    EventBus.publish( evt );
  }


  public class PartnerProgram_DoneHandler implements Promise.Done
  {
    public void done( Object incomingObject )
    {
      System.debug( 'Partner Program Executor Complete');
      PartnerProgram_Service.DealerOrderWrapper wrapper = (PartnerProgram_Service.DealerOrderWrapper)incomingObject;
      System.debug( wrapper.result );
      PartnerProgram_Executor.publishEvent( wrapper, 'success' );
    }
  }

  public class PartnerProgram_ErrorHandler implements Promise.Error
  {
    public Object error( Exception e )
    {
      System.debug( 'PartnerProgram_Executor received the following exception ' + e.getMessage() + '\n\n' + e.getStackTraceString() );
      throw new PartnerProgram_Exception( 'PartnerProgram_Executor received the following exception ' + e.getMessage() + '\n\n' + e.getStackTraceString() );
    }
  }
}