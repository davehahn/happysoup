({
  loadPartners: function (component) {
    var action = component.get("c.fetchPartners");
    return new LightningApex(this, action).fire();
  },

  filterData: function (component) {
    var records = component.get("v.allPartners"),
      nameString = component.get("v.filterName"),
      showLegend = component.get("v.includeLegendStores"),
      prov = component.get("v.filterProv");

    records = records
      .reduce(function (res, rec) {
        if (nameString !== undefined && nameString !== null && nameString.length > 0) {
          if (rec.title.includes(nameString)) res.push(rec);
        } else res.push(rec);
        return res;
      }, [])
      .reduce(function (res, rec) {
        if (prov !== "all") {
          if (rec.location.State == prov) res.push(rec);
        } else res.push(rec);
        return res;
      }, [])
      .reduce(function (res, rec) {
        if (!showLegend) {
          if (!rec.isLegend) res.push(rec);
        } else res.push(rec);
        return res;
      }, []);
    component.set("v.mapMarkers", records);
  }
});
