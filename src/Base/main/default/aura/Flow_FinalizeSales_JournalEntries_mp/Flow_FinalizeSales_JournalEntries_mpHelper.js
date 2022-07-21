({
  getInitialData: function (component) {
    console.log("getInitialData");
    var self = this;

    self.checkForExistingEntry(component);

    self.getNames(component);
  },

  getNames: function (component) {
    console.log("getNames");
    var self = this,
      f_2300a_who = component.get("v.f_2300a_who"),
      f_2300b_who = component.get("v.f_2300b_who"),
      f_2300c_who = component.get("v.f_2300c_who"),
      f_2300d_who = component.get("v.f_2300d_who"),
      f_2300e_who = component.get("v.f_2300e_who"),
      name;
    if (f_2300a_who != null && f_2300a_who != "") {
      self.getUserName(f_2300a_who, component).then(
        $A.getCallback(function (result) {
          component.set("v.f_2300a_who_name", result.name);
          component.set("v.f_2300a_who_glv4", result.glv4);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
    }
    if (f_2300b_who != null && f_2300b_who != "") {
      self.getUserName(f_2300b_who, component).then(
        $A.getCallback(function (result) {
          component.set("v.f_2300b_who_name", result.name);
          component.set("v.f_2300b_who_glv4", result.glv4);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
    }
    if (f_2300c_who != null && f_2300c_who != "") {
      self.getUserName(f_2300c_who, component).then(
        $A.getCallback(function (result) {
          component.set("v.f_2300c_who_name", result.name);
          component.set("v.f_2300c_who_glv4", result.glv4);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
    }
    if (f_2300d_who != null && f_2300d_who != "") {
      self.getUserName(f_2300d_who, component).then(
        $A.getCallback(function (result) {
          component.set("v.f_2300d_who_name", result.name);
          component.set("v.f_2300d_who_glv4", result.glv4);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
    }
    if (f_2300e_who != null && f_2300e_who != "") {
      self.getUserName(f_2300e_who, component).then(
        $A.getCallback(function (result) {
          component.set("v.f_2300e_who_name", result.name);
          component.set("v.f_2300e_who_glv4", result.glv4);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
    }
  },

  checkForExistingEntry: function (component) {
    var self = this,
      projectId = component.get("v.erpId"),
      action = component.get("c.checkForExistingEntry"),
      la;
    action.setParams({
      projectId: projectId
    });
    la = new LightningApex(this, action);
    la.fire().then(
      $A.getCallback(function (result) {
        component.set("v.journalEntryMade", result);
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  getUserName: function (userId, component) {
    console.log("getUserName");
    var self = this,
      action = component.get("c.getUserName"),
      la;
    action.setParams({
      userId: userId
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  validateLines: function (component) {
    console.log("validateLines");
    var self = this,
      entries;
    return new Promise(function (resolve, reject) {
      self.buildEntries(component).then(
        $A.getCallback(function (result) {
          entries = result;
          console.log(entries);
          resolve(entries);
        }),
        $A.getCallback(function (err) {
          reject(err);
        })
      );
    });
  },

  buildEntries: function (component) {
    console.log("buildEntries");
    self = this;
    return new Promise(function (resolve, reject) {
      var credits = component.get("v.debit_lines"),
        debits = component.get("v.credit_lines"),
        f_1120 = component.get("v.f_1120"),
        f_1125 = component.get("v.f_1125"),
        //f_1130			= component.get('v.f_1130'),
        //f_1131			= component.get('v.f_1131'),
        f_2180 = component.get("v.f_2180"),
        f_2190 = component.get("v.f_2190"),
        f_2195 = component.get("v.f_2195"),
        f_2300a = component.get("v.f_2300a"),
        f_2300b = component.get("v.f_2300b"),
        f_2300c = component.get("v.f_2300c"),
        f_2300d = component.get("v.f_2300d"),
        f_2300e = component.get("v.f_2300e"),
        //f_4000 			= component.get('v.f_4000'),
        //f_4100 			= component.get('v.f_4100'),
        f_5600 = component.get("v.f_5600"),
        //f_5000a 		= component.get('v.f_5000a'),
        //f_5000b 		= component.get('v.f_5000b'),
        f_5200a = component.get("v.f_5200_CostOfProductProtection"),
        f_5200b = component.get("v.f_5200_Premium"),
        f_5210 = component.get("v.f_5210_CostOfLifeAndDisabilityInsurance"),
        //f_5380 			= component.get('v.f_5380'),
        f_5420a = component.get("v.f_5420a"),
        f_5420b = component.get("v.f_5420b"),
        f_2300a_who = component.get("v.f_2300a_who"),
        f_2300b_who = component.get("v.f_2300b_who"),
        f_2300c_who = component.get("v.f_2300c_who"),
        f_2300d_who = component.get("v.f_2300d_who"),
        f_2300e_who = component.get("v.f_2300e_who"),
        f_2300a_who_glv4 = component.get("v.f_2300a_who_glv4"),
        f_2300b_who_glv4 = component.get("v.f_2300b_who_glv4"),
        f_2300c_who_glv4 = component.get("v.f_2300c_who_glv4"),
        f_2300d_who_glv4 = component.get("v.f_2300d_who_glv4"),
        f_2300e_who_glv4 = component.get("v.f_2300e_who_glv4"),
        entries = [],
        a = false,
        b = false,
        c = false,
        d = false,
        e = false,
        f = false,
        g = false,
        h = component.get("v.addedLinesBalance"),
        balance = false;

      console.log("checking balances");
      //a = ( ( (f_1125*1) + (f_1130*1) + (f_1131*1) + (f_1120*1) ) == f_5600 );
      a = Math.round(f_1125 * 1 + f_1120 * 1) == Math.round(f_5600);
      b =
        Math.round(f_5420a * 1 + f_5420b * 1) ==
        Math.round(f_2300a * 1 + f_2300b * 1 + f_2300c * 1 + f_2300d * 1 + f_2300e * 1);
      c = true; //( Math.round(f_5380*1) == Math.round(f_4100*1) );
      d = Math.round(f_5210 * 1) == Math.round(f_2190 * 1);
      e = Math.round(f_5200a * 1) == Math.round(f_2180 * 1);
      f = Math.round(f_5200b * 1) == Math.round(f_2195 * 1);
      g = true; //( Math.round( (f_5000a*1) + (f_5000b*1) ) == Math.round(f_4000*1) );
      balance = a && b && c && d && e && f && g && h;
      console.log("a:" + a + ",b:" + b + ",c:" + c + ",d:" + d + ",e:" + e + ",f:" + f + ",g:" + g + ",h:" + h);
      console.log(f_5420a * 1 + f_5420b * 1);
      console.log(f_2300a * 1 + f_2300b * 1 + f_2300c * 1 + f_2300d * 1 + f_2300e * 1);
      console.log("balanced? " + balance);

      if (!balance) {
        console.log("attempting to reject");
        resolve(false);
        console.log("failed to reject");
      }

      console.log("hey");

      entries.push({
        accountNumber: "1120",
        amount: f_1120,
        entryType: "debit"
      });
      entries.push({
        accountNumber: "1125",
        amount: f_1125,
        entryType: "debit"
      });
      // entries.push({
      // 	"accountNumber" : "1130",
      // 	"amount" : f_1130,
      // 	"entryType" : "debit"
      // });
      // entries.push({
      // 	"accountNumber" : "1131",
      // 	"amount" : f_1131,
      // 	"entryType" : "debit"
      // });
      entries.push({
        accountNumber: "2180",
        amount: f_2180,
        entryType: "credit"
      });
      entries.push({
        accountNumber: "2190",
        amount: f_2190,
        entryType: "credit"
      });
      entries.push({
        accountNumber: "2195",
        amount: f_2195,
        entryType: "credit"
      });
      entries.push({
        accountNumber: "2300",
        amount: f_2300a,
        who: f_2300a_who_glv4,
        entryType: "credit"
      });
      entries.push({
        accountNumber: "2300",
        amount: f_2300b,
        who: f_2300b_who_glv4,
        entryType: "credit"
      });
      entries.push({
        accountNumber: "2300",
        amount: f_2300c,
        who: f_2300c_who_glv4,
        entryType: "credit"
      });
      entries.push({
        accountNumber: "2300",
        amount: f_2300d,
        who: f_2300d_who_glv4,
        entryType: "credit"
      });
      entries.push({
        accountNumber: "2300",
        amount: f_2300e,
        who: f_2300e_who_glv4,
        entryType: "credit"
      });
      // entries.push({
      // 	"accountNumber" : "4000",
      // 	"amount" : f_4000,
      // 	"entryType" : "credit"
      // });
      // entries.push({
      // 	"accountNumber" : "4100",
      // 	"amount" : f_4100,
      // 	"entryType" : "credit"
      // });
      entries.push({
        accountNumber: "5600",
        amount: f_5600,
        entryType: "credit"
      });
      // entries.push({
      // 	"accountNumber" : "5000",
      // 	"amount" : f_5000a,
      // 	"entryType" : "debit"
      // });
      // entries.push({
      // 	"accountNumber" : "5000",
      // 	"amount" : f_5000b,
      // 	"entryType" : "debit"
      // });
      entries.push({
        accountNumber: "5200",
        amount: f_5200a,
        entryType: "debit"
      });
      entries.push({
        accountNumber: "5200",
        amount: f_5200b,
        entryType: "debit"
      });
      entries.push({
        accountNumber: "5210",
        amount: f_5210,
        entryType: "debit"
      });
      // entries.push({
      // 	"accountNumber" : "5380",
      // 	"amount" : f_5380,
      // 	"entryType" : "debit"
      // });
      entries.push({
        accountNumber: "5420",
        amount: f_5420a,
        entryType: "debit"
      });
      entries.push({
        accountNumber: "5420",
        amount: f_5420b,
        entryType: "debit"
      });

      for (var i = 0; i < debits.length; i++) {
        entries.push({
          accountNumber: debits[i][0],
          amount: debits[i][2],
          entryType: "debit"
        });
      }

      for (var i = 0; i < credits.length; i++) {
        entries.push({
          accountNumber: credits[i][0],
          amount: credits[i][2],
          entryType: "credit"
        });
      }

      resolve(entries);
    });
  },

  createJournalEntry: function (component, entries) {
    console.log("createJournalEntry");
    var self = this,
      action = component.get("c.createJournalEntry"),
      la,
      erpId = component.get("v.erpId");
    return new Promise(function (resolve, reject) {
      action.setParams({
        entries: JSON.stringify(entries),
        projectId: erpId
      });
      console.log(JSON.stringify(entries));
      la = new LightningApex(this, action);
      la.fire().then(
        $A.getCallback(function (result) {
          resolve(result);
        }),
        $A.getCallback(function (err) {
          reject(err);
        })
      );
    });
  },

  getGLV4: function (component, whoId) {
    var action = component.get("c.getGLV4"),
      la;
    return new Promise(function (resolve, reject) {
      action.setParams({
        whoId: whoId
      });
      la = new LightningApex(this, action);
      la.fire().then(
        $A.getCallback(function (result) {
          resolve(result);
        }),
        $A.getCallback(function (err) {
          reject(err);
        })
      );
    });
  },

  synchronize: function (component) {
    var f_1120 = parseFloat(component.get("v.f_1120")),
      f_1125 = parseFloat(component.get("v.f_1125")),
      //f_1130			= parseFloat( component.get('v.f_1130') ),
      //f_1131			= parseFloat( component.get('v.f_1131') ),
      f_2180 = parseFloat(component.get("v.f_2180")),
      f_2190 = parseFloat(component.get("v.f_2190")),
      f_2195 = parseFloat(component.get("v.f_2195")),
      f_2300a = parseFloat(component.get("v.f_2300a")),
      f_2300b = parseFloat(component.get("v.f_2300b")),
      f_2300c = parseFloat(component.get("v.f_2300c")),
      f_2300c_hint,
      f_2300d = parseFloat(component.get("v.f_2300d")),
      f_2300d_hint,
      f_2300e = parseFloat(component.get("v.f_2300e")),
      f_4000 = parseFloat(component.get("v.f_4000")),
      f_4100 = parseFloat(component.get("v.f_4100")),
      f_5600 = parseFloat(component.get("v.f_5600")),
      f_5000a = parseFloat(component.get("v.f_5000a")),
      f_5000b = parseFloat(component.get("v.f_5000b")),
      f_5200a = parseFloat(component.get("v.f_5200_CostOfProductProtection")),
      f_5200b = parseFloat(component.get("v.f_5200_Premium")),
      f_5210 = parseFloat(component.get("v.f_5210_CostOfLifeAndDisabilityInsurance")),
      f_5380 = parseFloat(component.get("v.f_5380")),
      f_5420a = parseFloat(component.get("v.f_5420a")),
      f_5420b = parseFloat(component.get("v.f_5420b")),
      isBalanced = false;

    f_2300c_hint = Math.round((f_2300a + f_2300b) * 0.25 * 100) / 100;
    f_2300d_hint = Math.round(f_2300e * 0.25 * 100) / 100;

    //component.set('v.f_5600', 			parseFloat( (f_1125 + f_1130 + f_1131 + f_1120).toFixed(2) ) );
    component.set("v.f_5600", parseFloat((f_1125 + f_1120).toFixed(2)));
    component.set("v.f_2300c_hint", parseFloat(f_2300c_hint.toFixed(2)));
    component.set("v.f_2300d_hint", parseFloat(f_2300d_hint.toFixed(2)));
    component.set("v.f_5420a", parseFloat((f_2300d + f_2300e).toFixed(2)));
    component.set("v.f_5420b", parseFloat((f_2300a + f_2300b + f_2300c).toFixed(2)));
    component.set("v.f_4100", parseFloat(f_5380.toFixed(2)));
    component.set("v.f_2190", parseFloat(f_5210.toFixed(2)));
    component.set("v.f_2180", parseFloat(f_5200a.toFixed(2)));
    component.set("v.f_2195", parseFloat(f_5200b.toFixed(2)));
    component.set("v.f_4000", parseFloat((f_5000a + f_5000b).toFixed(2)));

    /* WHY AM I DOING THIS AGAIN? Isn't it redundant? So glad you asked. For some reason, failure to
		   refresh these variables leads to radical miscalculation when comparing some debits and
		   credits on initial load (and only on initial load). I don't know why. But this fixes it.
		   COME AT ME, BRO. COME AT ME. */
    f_1120 = parseFloat(component.get("v.f_1120"));
    f_1125 = parseFloat(component.get("v.f_1125"));
    f_2180 = parseFloat(component.get("v.f_2180"));
    f_2190 = parseFloat(component.get("v.f_2190"));
    f_2195 = parseFloat(component.get("v.f_2195"));
    f_2300a = parseFloat(component.get("v.f_2300a"));
    f_2300b = parseFloat(component.get("v.f_2300b"));
    f_2300c = parseFloat(component.get("v.f_2300c"));
    f_2300d = parseFloat(component.get("v.f_2300d"));
    f_2300e = parseFloat(component.get("v.f_2300e"));
    f_4000 = parseFloat(component.get("v.f_4000"));
    f_4100 = parseFloat(component.get("v.f_4100"));
    f_5600 = parseFloat(component.get("v.f_5600"));
    f_5000a = parseFloat(component.get("v.f_5000a"));
    f_5000b = parseFloat(component.get("v.f_5000b"));
    f_5200a = parseFloat(component.get("v.f_5200_CostOfProductProtection"));
    f_5200b = parseFloat(component.get("v.f_5200_Premium"));
    f_5210 = parseFloat(component.get("v.f_5210_CostOfLifeAndDisabilityInsurance"));
    f_5380 = parseFloat(component.get("v.f_5380"));
    f_5420a = parseFloat(component.get("v.f_5420a"));
    f_5420b = parseFloat(component.get("v.f_5420b"));

    console.log(f_5420a + f_5420b - (f_2300a + f_2300b + f_2300c + f_2300d + f_2300e));
    console.log(f_2300a + f_2300b + f_2300c + f_2300d + f_2300e - (f_5420a + f_5420b));

    if (
      f_5420a + f_5420b - (f_2300a + f_2300b + f_2300c + f_2300d + f_2300e) < 0.01 &&
      f_2300a + f_2300b + f_2300c + f_2300d + f_2300e - (f_5420a + f_5420b) < 0.01
    ) {
      isBalanced = true;
    }
    component.set("v.isCommissionBalanced", isBalanced);
  }
});
