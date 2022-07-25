({
  getRegistrations: function (component, event) {
    console.log("helper.getRegistrations");
    var action = component.get("c.getDetailedRegistrations"),
      orderField = component.get("v.sortField"),
      orderDir = component.get("v.sortDir"),
      perPage = component.get("v.perPage"),
      pageNum = component.get("v.pageNumber"),
      pageOptions = component.get("v.pageOptions"),
      recordCount = component.get("v.recordCount"),
      pageCount = recordCount / perPage,
      filter = component.get("v.selectedList"),
      sernoFilter = component.get("v.sernoFilter");

    if (recordCount % perPage > 0) {
      pageCount++;
    }

    if (pageNum > pageCount) {
      pageNum = pageCount;
    }

    action.setParams({
      orderField: orderField,
      orderDir: orderDir,
      perPage: perPage,
      pageNum: pageNum,
      filter: filter,
      sernoFilter: sernoFilter
    });
    action.setCallback(this, function (response) {
      this.renderResults(response, component);
    });
    $A.enqueueAction(action);
  },

  renderResults: function (response, component) {
    var data = JSON.parse(response.getReturnValue()),
      pageOptions = [],
      pageNumber = component.get("v.pageNumber");

    component.set("v.Registrations", data);
    component.set("v.totalPages", data[0].pageCount);

    for (var i = 0; i < data[0].pageCount; i++) {
      pageOptions.push(i + 1);
    }
    component.set("v.pageOptions", pageOptions);
    component.set("v.recordCount", data[0].recordCount);
  },

  setLocalStorage: function (component, event) {
    var pageNumber = component.get("v.pageNumber"),
      perPage = component.get("v.perPage");

    // pageNumber
    if (localStorage.pageNumber === undefined) {
      localStorage.pageNumber = pageNumber;
    } else {
      if (Number.isInteger(parseInt(localStorage.pageNumber))) {
        component.set("v.pageNumber", parseInt(localStorage.pageNumber));
      } else {
        component.set("v.pageNumber", 1);
      }
    }

    // perPage
    if (localStorage.perPage === undefined) {
      localStorage.perPage = perPage;
    } else {
      component.set("v.perPage", parseInt(localStorage.perPage));
    }
  }
});
