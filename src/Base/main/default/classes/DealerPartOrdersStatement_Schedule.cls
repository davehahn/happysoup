/* ----------------------------------------------------------------------------

	Contributors: Mario
	Last Modified By: Mario
	Created: July 30, 2018
	Last Modified: July 30, 2018

---------------------------------------------------------------------------- */

global class DealerPartOrdersStatement_Schedule implements Schedulable {
  global void execute(SchedulableContext sc) {
    DealerPartOrdersStatement_Batch b = new DealerPartOrdersStatement_Batch();
    Database.executeBatch(b, 200);
  }
}
