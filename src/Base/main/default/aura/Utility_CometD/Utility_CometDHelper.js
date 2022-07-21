/**
 * Created by dave on 2020-09-14.
 */

({
  connect: function (component) {
    const isConnected = component.get("v.isConnected");
    return new Promise((resolve, reject) => {
      if (isConnected) {
        resolve(component.get("v.cometd"));
      } else {
        console.log("setting up new connections COMETD");
        const sessionId = component.get("v.sessionId");
        const url = window.location.protocol + "//" + window.location.hostname + "/cometd/49.0/";
        var cometd = new window.org.cometd.CometD();

        cometd.configure({
          url: url,
          requestHeaders: { Authorization: "OAuth " + sessionId },
          appendMessageTypeToURL: false
        });

        cometd.websocketEnabled = false;

        cometd.handshake(
          $A.getCallback(function (status) {
            if (status.successful) {
              // Successfully connected to the server.
              // Now it is possible to subscribe or send messages
              console.log("Successfully connected to server");
              console.log(cometd);
              component.set("v.cometd", cometd);
              component.set("v.isConnected", true);
              resolve(cometd);
            } else {
              /// Cannot handshake with the server, alert user.
              console.error("Error in handshaking: " + JSON.stringify(status));
            }
          })
        );
      }
    });
  }
});
