({
  inConsole: function (component) {
    var workspaceAPI = component.find("workspace");
    return new Promise((resolve, reject) => {
      workspaceAPI
        .isConsoleNavigation()
        .then(function (response) {
          resolve(response);
        })
        .catch(function (error) {
          reject(error);
        });
    });
  }
});
