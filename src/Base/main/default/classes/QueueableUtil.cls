/**
 * Created by dave on 2019-08-08.
 */

public class QueueableUtil implements Queueable, Database.AllowsCallouts {
  Queueable[] payload;
  static QueueableUtil self;

  QueueableUtil(Queueable item) {
    payload = new Queueable[] { item };
  }

  public static Id enqueueJob(Queueable item) {
    if(!System.isQueueable()) {
      return System.enqueueJob(new QueueableUtil(item));
    } else {
      self.payload.add(item);
      return null;
    }
  }

  public void execute(QueueableContext context) {
    self = this;
    payload.remove(0).execute(context);
    if(!payload.isEmpty()) {
      System.enqueueJob(this);
    }
  }
}