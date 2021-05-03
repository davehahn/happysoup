app.directive("popoverHtmlUnsafePopup", function (ngForceConfig) {
  return {
    restrict: "EA",
    replace: true,
    scope: { title: "@", content: "@", placement: "@", animation: "&", isOpen: "&" },
    templateUrl: ngForceConfig.resourceUrl + "/templates/popover/popover-html-unsafe-popup.html"
  };
})

.directive("popoverHtmlUnsafe", [ "$tooltip", function ($tooltip) {
  return $tooltip("popoverHtmlUnsafe", "popover", "click");
}]);
