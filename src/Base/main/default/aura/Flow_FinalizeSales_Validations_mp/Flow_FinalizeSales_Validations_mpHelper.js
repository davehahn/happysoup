({
	checkForRecordId : function(component)
	{
		console.log('checkForRecordId');
		var recordId = component.get('v.recordId');
		return new Promise( function( resolve, reject )
			{
				if (recordId == null) {
					// component.set('v.step', 'getERP');
					resolve();
				} else {
					reject();
				}
			}
		);
	},

	getERP : function(component)
	{
		console.log('getERP');
		var self = this,
				action = component.get('c.getERP'), la,
				recordId = component.get('v.recordId');
		return new Promise( function( resolve, reject )
			{
				action.setParams({
					"erpId" : recordId
				});
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						resolve(result);
						component.set('v.erp', result);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	},

	checkForExistingJournalEntry : function(component)
	{
		console.log('checkForExistingJournalEntry');
		var self = this,
				action = component.get('c.checkForExistingEntry'), la,
				recordId = component.get('v.recordId');
		return new Promise( function( resolve, reject )
			{
				action.setParams({
					"projectId" : recordId
				});
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						console.log(result);
						component.set('v.DoesJournalEntryExist', result);
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		      	console.log(err);
		        reject(err);
		      })
				);
			}
		);
	},

	checkIfReady : function(component, event)
	{
		console.log('checkIfReady');

		var self = this,
				spinner = component.find('spinner');

		spinner.toggle();

		self.getJournalEntrySettings(component)
		.then(
			$A.getCallback( function( result ) {
				return self.getSalesperson(component);
			}),
      $A.getCallback( function( err ) {
      	LightningUtils.errorToast(err);
      })
		)
		.then(
			$A.getCallback( function( result ) {
				return self.getCustomer(component);
			}),
      $A.getCallback( function( err ) {
      	LightningUtils.errorToast(err);
      })
		)
		.then(
			$A.getCallback( function( result ) {
				return self.getReceipts(component);
			}),
      $A.getCallback( function( err ) {
      	LightningUtils.errorToast(err);
      })
		)
		.then(
			$A.getCallback( function( result ) {
				return self.getBillings(component);
			}),
      $A.getCallback( function( err ) {
      	LightningUtils.errorToast(err);
      })
		)
		.then(
			$A.getCallback( function( result ) {
				return self.getLocation(component);
			}),
      $A.getCallback( function( err ) {
      	LightningUtils.errorToast(err);
      })
		)
		.then(
			$A.getCallback( function( result ) {
				return self.getOrderItems(component);
			}),
      $A.getCallback( function( err ) {
      	LightningUtils.errorToast(err);
      })
		)
		.then(
			$A.getCallback( function( result ) {
				return self.getTradeIns(component);
			}),
      $A.getCallback( function( err ) {
      	LightningUtils.errorToast(err);
      })
		)
		.then(
			$A.getCallback( function( result ) {
				return new Promise( function(resolve, reject){
					self.getTradeInRecordType(component)
					.then(
						$A.getCallback( function( result ) {
							return self.getTradeInERP(component);
						}),
			      $A.getCallback( function( err ) {
			      	LightningUtils.errorToast(err);
			      })
					)
					.then(
						$A.getCallback( function( result ) {

							return self.getInboundInventory(component);
						}),
			      $A.getCallback( function( err ) {
			      	LightningUtils.errorToast(err);
			      })
					)
					.then(
						$A.getCallback( function( result ) {
							resolve();
						}),
			      $A.getCallback( function( err ) {
			      	LightningUtils.errorToast(err);
			      })
					)
				})
			})
		)
		.then(
			$A.getCallback( function( result ) {
				return self.getInsuranceItems(component);
			}),
      $A.getCallback( function( err ) {
      	LightningUtils.errorToast(err);
      })
		)
		.then(
			$A.getCallback( function( result ) {
				return self.getCommissionRecords(component);
			}),
      $A.getCallback( function( err ) {
      	LightningUtils.errorToast(err);
      })
		)
		.then(
			$A.getCallback( function( result ) {
				return self.getPartnerPricebook(component);
			}),
      $A.getCallback( function( err ) {
      	LightningUtils.errorToast(err);
      })
		)
		.then(
			$A.getCallback( function( result ) {
				return self.getMaximumMotor(component);
			}),
      $A.getCallback( function( err ) {
      	LightningUtils.errorToast(err);
      })
		)
		.then(
			$A.getCallback( function( result ) {
				return self.getErpTasks(component);
			}),
      $A.getCallback( function( err ) {
      	LightningUtils.errorToast(err);
      })
		)
		.then(
			$A.getCallback( function( result ) {
				return self.getBoat(component);
			}),
      $A.getCallback( function( err ) {
      	LightningUtils.errorToast(err);
      })
		)
		.then(
			$A.getCallback( function( result ) {
				return self.getNestedItems(component);
			}),
      $A.getCallback( function( err ) {
      	LightningUtils.errorToast(err);
      })
		)
		.then(
			$A.getCallback( function( result ) {
				spinner.toggle();
			}),
      $A.getCallback( function( err ) {
      	LightningUtils.errorToast(err);
      })
		);
	},

	getJournalEntrySettings : function(component)
	{
		console.log('getJournalEntrySettings');
		var self = this,
				action = component.get('c.getJournalEntrySettings'), la;
		return new Promise( function( resolve, reject )
			{
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						console.log('JESETTINGS');
						console.table(result);
						component.set('v.settings', result[0]);
						var tmpSet = component.get('v.settings');
						console.table(tmpSet);
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	},

	getSalesperson : function(component)
	{
		console.log('getSalesperson');
		var self = this,
				action = component.get('c.getSalesperson'), la,
				erp = component.get('v.erp');
		return new Promise( function( resolve, reject )
			{
				action.setParams({
					"userId" : erp.Salesperson__c
				})
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						console.log('SALESPERSON');
						console.table(result);
						component.set('v.Salesperson', result);
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	},

	getCustomer : function(component)
	{
		console.log('getCustomer');
		var self = this,
				action = component.get('c.getCustomer'), la,
				erp = component.get('v.erp');
		return new Promise( function( resolve, reject )
			{
				action.setParams({
					"accountId" : erp.AcctSeed__Account__c
				})
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						console.log('CUSTOMER')
						console.table(result);
						component.set('v.Customer', result);
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	},

	getReceipts : function(component)
	{
		console.log('getReceipts');
		var self = this,
				action = component.get('c.getReceipts'), la,
				customer = component.get('v.Customer');
		return new Promise( function( resolve, reject )
			{
				action.setParams({
					"accountId" : customer.Id
				})
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						console.log('RECEIPTS');
						console.table(result);
						component.set('v.Receipts', result);
						var total = 0.00;
						for (var receipt in result) {
							total += receipt.AcctSeed__Amount__c;
						}
						component.set('v.Total_Cash_Receipts_Value', total);
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	},

	getBillings : function(component)
	{
		console.log('getBillings');
		var self = this,
				action = component.get('c.getBillings'), la,
				customer = component.get('v.Customer'),
				erp = component.get('v.erp'),
				receiptsTotal = component.get('v.Total_Cash_Receipts_Value'),
				total = component.get('v.TotalBillings'),
				owed = component.get('v.BillingsOwedAmount');
		return new Promise( function( resolve, reject )
			{
				action.setParams({
					"accountId" : customer.Id,
					"receiptsTotal" : erp.Grand_Total__c, //receiptsTotal,
					"projectId" : erp.Id
				});
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						console.log('BILLINGS');
						console.log(result);
						component.set('v.Billings', result);
						total = 0.00;
						owed = 0.00;
						for (var i = 0; i < result.length; i++) {
							console.table(result[i]);
							total += result[i].AcctSeed__Total__c;
							owed += result[i].AcctSeed__Balance__c;
						}
						component.set('v.TotalBillings', total);
						component.set('v.BillingsOwedAmount', owed);
						if (total - erp.Grand_Total__c > -0.1 && total - erp.Grand_Total__c < 0.01) {
							component.set('v.BillingsMatchTotal', true);
						}
						console.log('OWED: ' + owed);
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		      	console.log('BILLINGS ERROR');
		      	console.log(err);
		        reject(err);
		      })
				);
			}
		);
	},

	getLocation : function(component)
	{
		console.log('getLocation');
		var self = this,
				action = component.get('c.getLocation'), la,
				erp = component.get('v.erp');
		return new Promise( function( resolve, reject )
			{
				action.setParams({
					"locationId" : erp.GL_Account_Variable_1__c
				});
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						console.log(result);
						component.set('v.Location', result);
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	},

	getOrderItems : function(component)
	{
		console.log('getOrderItems');
		var self = this,
				action = component.get('c.getOrderItems'), la,
				erp = component.get('v.erp'),
				f_5000a = component.get('v.f_5000a');
		return new Promise( function( resolve, reject )
			{
				action.setParams({
					"erpId" : erp.Id
				});
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						console.log('ORDER ITEMS');
						console.log(result);
						component.set('v.OrderItems', result);
						for (var i = 0; i < result.length; i++) {
							console.log(result[i]);
							if (result[i].Product_Record_Type__c == 'Boat' || result[i].Product_Record_Type__c == 'Trailer') {
								f_5000a += result[i].GMBLASERP__Total_Price__c;
							}
							if (result[i].AcctSeedERP__Quantity_Allocated__c < result[i].AcctSeedERP__Quantity_Per_Unit__c
								  && !result[i].No_WIP__c) {
								component.set('v.NoItemsLeftToWIP', false);
							}
						}
						// component.set('v.f_5000a', f_5000a);
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	},

	getMaximumMotor : function(component)
	{
		console.log('getMaximumMotor');
		var self = this,
				action = component.get('c.getMaximumMotor'), la,
				erp = component.get('v.erp'),
				pb = component.get('v.PartnerPricebook');
		return new Promise( function( resolve, reject )
			{
				action.setParams({
					"erpId" : erp.Id,
					"pbId" : pb[0].Id
				});
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						console.log('MAXIMUM MOTOR');
						console.log(result);
						component.set('v.MaximumMotor', result);
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	},

	getTradeIns : function(component)
	{
		console.log('getTradeIns');
		var self = this,
				action = component.get('c.getTradeIns'), la,
				erp = component.get('v.erp');
		return new Promise( function( resolve, reject )
			{
				action.setParams({
					"oppId" : erp.AcctSeed__Opportunity__c
				});
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						// component.set('v.TradeIns', result);
						// var totalTrades = 0.00;
						// for (var tradein in result) {
						// 	totalTrades += tradein.Total_Value__c;
						// }
						// component.set('v.TotalTradeInValue', totalTrades);
						// resolve(result);
						console.log(result);
						var totalTrades = 0.00;
						for (var i = 0; i < result.length; i++) {
							console.log(result[i].GMBLASERP__Total_Price__c);
							totalTrades += result[i].GMBLASERP__Total_Price__c;
						}
						component.set('v.TotalTradeInValue', totalTrades * -1);
						console.log('TOTAL TRADE IN VALUE: ' + totalTrades);
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	},

	getTradeInRecordType : function(component)
	{
		console.log('getTradeInRecordType');
		var self = this,
				action = component.get('c.getTradeInRecordType'), la;
		return new Promise( function( resolve, reject )
			{
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						component.set('v.TradeInRecordType', result);
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	},

	getTradeInERP : function(component)
	{
		console.log('getTradeInERP');
		var self = this,
				erp = component.get('v.erp'),
				recType = component.get('v.TradeInRecordType'),
				action = component.get('c.getTradeInERP'), la;
		return new Promise( function( resolve, reject )
			{
				console.log('recTypeId: ' + recType.Id);
				console.log('oppId: ' + erp.AcctSeed__Opportunity__c);
				action.setParams({
					"oppId" : erp.AcctSeed__Opportunity__c,
					"recTypeId" : recType.Id
				});
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						console.log('TRADEIN');
						console.log(result);
						// component.set('v.TotalTradeInValue', result.Grand_Total__c);
						component.set('v.TradeInERP', result);
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	},

	getInboundInventory : function(component)
	{
		console.log('getInboundInventory');
		var self = this,
				tradein = component.get('v.TradeInERP'),
				TotalTradeInValue = component.get('v.TotalTradeInValue'),
				action = component.get('c.getInboundInventory'), la;
		return new Promise( function( resolve, reject ) {
			if (tradein != null) {
				console.log('ERMAGERD NOT NULL???');
				action.setParams({
					"erpId" : tradein.Id
				});
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						console.log('INBOUND');
						console.log(result);
						component.set('v.InboundInventory', result);
						var total = 0.00;
						for (var i = 0; i < result.length; i++) {
							total += result[i].GMBLASERP__Inventory_GL_Amount__c
						}
						component.set('v.TotalInboundValue', total);
						if (total <= TotalTradeInValue) {
							self.setTradeInToComplete(component).then(
								$A.getCallback( function( result ) {
									resolve(result);
								}),
					      $A.getCallback( function( err ) {
					        reject(err);
					      })
							);
						} else {
							component.set('v.TradeInValuesMatch', false);
							resolve(result);
						}
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			} else {
				console.log('OMG NULL YOU GUYS');
				resolve();
			}
		});
	},

	setTradeInToComplete : function(component)
	{
		console.log('setTradeInToComplete');
		var self = this,
				tradein = component.get('v.TradeInERP'),
				action = component.get('c.setTradeInToComplete'), la;
		return new Promise( function( resolve, reject )
			{
				action.setParams({
					"erpId" : tradein.Id
				});
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	},

	getInsuranceItems : function(component)
	{
		console.log('getInsuranceItems');
		var self = this,
				erp = component.get('v.erp'),
				f_5210 = component.get('v.f_5210_CostOfLifeAndDisabilityInsurance'),
				f_5200 = component.get('v.f_5200_CostOfProductProtection'),
				action = component.get('c.getInsuranceItems'), la;
		return new Promise( function( resolve, reject )
			{
				action.setParams({
					"erpId" : erp.Id
				});
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						console.log('INSURANCE ITEMS');
						console.log(result);
						// for (var item in result) {
						// 	if (item.Product_Record_Type__c == 'Insurance') {
						// 		f_5210 += item.GMBLASERP__Total_Price__c;
						// 	}
						// 	else if (item.Product_Record_Type__c == 'Protection and Services') {
						// 		f_5200 += item.GMBLASERP__Total_Price__c;
						// 	}
						// }
						for (var i = 0; i < result.length; i++) {
							if (result[i].Product_Record_Type__c == 'Insurance') {
								f_5210 += result[i].GMBLASERP__Total_Price__c / 2;
							}
							else if (result[i].Product_Record_Type__c == 'Protection and Services') {
								f_5200 += 0.00; //result[i].GMBLASERP__Total_Price__c / 2;
							}
						}
						component.set('v.f_5210_CostOfLifeAndDisabilityInsurance', parseFloat( f_5210.toFixed(2) ) );
						component.set('v.f_5200_CostOfProductProtection', parseFloat( f_5200.toFixed(2) ) );
						component.set('v.f_2190', parseFloat( f_5210.toFixed(2) ) );
						component.set('v.f_2180', parseFloat( f_5200.toFixed(2) ) );
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	},

	getCommissionRecords : function(component)
	{
		console.log('getCommissionRecords');
		var self = this,
				f_2300a = component.get('v.f_2300a'),
				f_2300a_who = component.get('v.f_2300a_who'),
				f_2300b = component.get('v.f_2300b'),
				f_2300b_who = component.get('v.f_2300b_who'),
				f_2300e = component.get('v.f_2300e'),
				f_2300e_who = component.get('v.f_2300e_who'),
				f_5420a = component.get('v.f_5420a'),
				f_5420b = component.get('v.f_5420b'),
				f_2300c,
				f_2300d,
				action = component.get('c.getCommissionRecords'), la,
				erp = component.get('v.erp'),
				isBalanced = false;
		return new Promise( function( resolve, reject )
			{
				action.setParams({
					"erpId" : erp.Id
				})
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						console.log(result);
						component.set('v.CommissionRecords', result);
						for (var i = 0; i < result.length; i++) {
							console.log('COMMISSION RECORD');
							console.log(result[i]);
							for (var x = 0; x < result[i].payments.length; x++) {
								if (result[i].payments[x].CommissionRecordType__c == 'Retail Sales') {
									f_2300a = result[i].payments[x].PaymentAmount__c;
									f_2300a_who = result[i].payments[x].Owner__c;
									f_5420b += result[i].payments[x].PaymentAmount__c;
								}
								else if (result[i].payments[x].CommissionRecordType__c == 'Business Office') {
									f_2300e = result[i].payments[x].PaymentAmount__c;
									f_2300e_who = result[i].payments[x].Owner__c;
									f_5420a += result[i].payments[x].PaymentAmount__c;
								}
								else {
									f_2300b = result[i].payments[x].PaymentAmount__c;
									f_2300b_who = result[i].payments[x].Owner__c;
									f_5420b += result[i].payments[x].PaymentAmount__c;
								}
							}
							if (result[i].record.ReviewedBy__c == null) component.set('v.ReviewedByAccounting', false);
							if (result[i].record.ApprovedBy__c == null) component.set('v.ApprovedByAccounting', false);
							if (result[i].record.AcceptedBy__c == null) component.set('v.AcceptedBySalesperson', false);
						}
						component.set('v.f_2300a', f_2300a);
						component.set('v.f_2300a_who', f_2300a_who);
						component.set('v.f_2300b', f_2300b);
						component.set('v.f_2300b_who', f_2300b_who);
						component.set('v.f_2300e', f_2300e);
						component.set('v.f_2300e_who', f_2300e_who);
						component.set('v.f_5420a', f_5420a);
						component.set('v.f_5420b', f_5420b);

						// Managers
						f_2300c = (f_2300a + f_2300b) * 0.25;
						f_2300d = f_2300e * 0.25;
						component.set('v.f_2300c', parseFloat( f_2300c.toFixed(2) ) );
						component.set('v.f_2300d', parseFloat( f_2300d.toFixed(2) ) );
						component.set('v.f_2300c_hint', parseFloat( f_2300c.toFixed(2) ) );
						component.set('v.f_2300d_hint', parseFloat( f_2300d.toFixed(2) ) );

						if ( ( f_5420a + f_5420b ) == ( f_2300a + f_2300b + f_2300c + f_2300d + f_2300e ) ) {
							isBalanced = true;
						}
						component.set('v.isCommissionBalanced', isBalanced);

						resolve(result);
					}),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	},

	getPartnerPricebook : function(component)
	{
		console.log('getPartnerPricebook');
		var self = this,
				pbId = component.get('v.selectedPricebook'),
				action = component.get('c.getPartnerPricebook'), la;
		return new Promise( function( resolve, reject )
			{
				action.setParams({
					"pbId" : pbId
				});
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						console.log(result);
						component.set('v.PartnerPricebook', result);
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	},

	getErpTasks : function(component)
	{
		console.log('getErpTasks');
		var self = this,
				erp = component.get('v.erp'),
				action = component.get('c.getErpTasks'), la;
		return new Promise( function( resolve, reject )
			{
				action.setParams({
					"erpId" : erp.Id
				});
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						component.set('v.Tasks', result);
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	},

	getNestedItems : function(component)
	{
		console.log('getNestedItems');
		var self = this,
				erp = component.get('v.erp'),
				pb = component.get('v.PartnerPricebook'),
				maxMotor = component.get('v.MaximumMotor')[0],
				JESettings = component.get('v.settings')[0],
				f_1120 = component.get('v.f_1120'),
				f_1125 = component.get('v.f_1125'),
				//f_1130 = component.get('v.f_1130'),
				//f_1131 = component.get('v.f_1131'),
				f_4000 = component.get('v.f_4000'),
				f_5000a = component.get('v.f_5000a'),
				action = component.get('c.getNestedItems'), la;
		console.log(maxMotor);
		return new Promise( function( resolve, reject )
			{
				action.setParams({
					"sernoId" : erp.Serial_Number__c,
					"pbId" : pb[0].Id
				});
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						console.log('NESTED ITEMS');
						console.table(result);
						console.log('JESettings');
						console.table(JESettings);
						result.forEach(function(item) {
							console.log(item);
							if (item.entry != null) {
								if (item.serialNumber.Product_Record_Type__c == 'Motor') {
								  console.log('DAVES CHANGES HERE !!!!!!!!!!!!!!!!');
									console.log('unitPrice(' + item.serialNumber.GMBLASERP__Product__r.AcctSeed__Unit_Cost__c + ') x Line1125__c(' + JESettings.Line1125__c + ')');
									f_1125 += item.serialNumber.GMBLASERP__Product__r.AcctSeed__Unit_Cost__c * (JESettings.Line1125__c / 100);
								} else if (item.serialNumber.Product_Record_Type__c == 'Boat') {
									f_4000 += item.entry.UnitPrice;
								} else if (item.serialNumber.Product_Record_Type__c == 'Trailer') {
									f_4000 += item.entry.UnitPrice;
								} else {
									// Do nothing?
								}
							}
						});
						// if (maxMotor !== undefined) {
						// 	if (maxMotor.entry != null) {
						// 		f_1130 += maxMotor.entry.UnitPrice * (JESettings.Line1130__c / 100);
						// 		f_1131 += maxMotor.entry.UnitPrice * (JESettings.Line1131__c / 100);
						// 	}
						// }
						component.set('v.f_1125', f_1125);
						// component.set('v.f_1130', f_1130);
						// component.set('v.f_1131', f_1131);
						//component.set('v.f_5600', (f_1120 + f_1125 + f_1130 + f_1131) );
						component.set('v.f_5600', (f_1120 + f_1125) );
						// component.set('v.f_4000', f_4000);
						// component.set('v.f_5000b', (f_4000 - f_5000a) );
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	},

	getBoat : function(component)
	{
		console.log('getBoat');
		var self = this,
				erp = component.get('v.erp'),
				pb = component.get('v.PartnerPricebook'),
				f_4000 = component.get('v.f_4000'),
				action = component.get('c.getBoat'), la;
		return new Promise( function( resolve, reject )
			{
				action.setParams({
					"productId" : erp.Boat_Product__c,
					"pbId" : pb[0].Id
				});
				la = new LightningApex( this, action );
				la.fire()
		    .then(
					$A.getCallback( function( result ) {
						f_4000 += result.UnitPrice;
						// component.set('v.f_4000', f_4000);
						component.set('v.Boat', result);
						resolve(result);
		      }),
		      $A.getCallback( function( err ) {
		        reject(err);
		      })
				);
			}
		);
	}
})