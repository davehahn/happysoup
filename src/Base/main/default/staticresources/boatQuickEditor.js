(function($, window, document) {

	window.BoatQuickEdit = {

		init: function () {

			$('.optionLink').each(function () {
	          var $this = $(this);
	          $this.quickBox({
	            boxPos: 'right',
	            title: 'Edit Availbe Option',
		            content: BoatQuickEdit.Builders.optionForm,
	            onBoxOpen: BoatQuickEdit.Observers.optionForm
	          });
	        });

	        $('.upgradeEditLink').each(function () {
	          BoatQuickEdit.Observers.editUpgradeLink( $(this) );
	        });

	        $('.upgradeCreateLink').each(function () {
	          var $this = $(this);
	          $this.quickBox({
	            boxPos: 'left',
	            title: "Set Upgrade Cost",
	            content: BoatQuickEdit.Builders.upgradeCreateForm,
	            onBoxOpen: BoatQuickEdit.Observers.upgradeForm
	          });
	        });

		},
		Observers: {},
		Builders: {},
		Utilities: {}

	}


})(jQuery, window, document, undefined);


(function($) {

// ***************** BUILDERS *********************//


	BoatQuickEdit.Builders = {

		optionForm: function () {
			var $this = $(this),
		      editId = $this.attr('data-editId'),
		      $content,
		      d_self,
		      $form ;
		    return $.Deferred( function() {
		      	d_self = this;
		      	BoatRemoter.editOptionDetails(editId,function(results, events) {
			        $content = $('<div></div>'),
			        $form = $('<form></form>').attr('id', 'optionForm'),
			        $details = $('<div></div>').addClass('option_details'),
			        $submit = $('<input type="submit" value="Save" class="btn" />'),
			        $s_input = $('<div></div>').addClass('field'),
			        $m_input = $s_input.clone(),
			        $step_input = $s_input.clone();

			        $details.html('<span>' + results.From_Product__r.Name + '</span>');
			        $s_input.append($("<label for='Standard__c'>Standard:</label>"))
			          .append($("<input></input>").attr({type: 'number',
			                                              class: 'focus',
			                                              id: 'Standard__c',
			                                              name: 'Standard__c',
			                                              step: 'any',
			                                              required: true,
			                                              value: results.Standard__c
			                                            })
			          );
			        $m_input.append($("<label for='Maximum__c'>Maximum:</label>"))
			          .append($("<input></input>").attr({type: 'number',
			                                              class: 'focus',
			                                              id: 'Maximum__c',
			                                              name: 'Maximum__c',
			                                              step: 'any',
			                                              required: true,
			                                              value: results.Maximum__c
			                                            })
			          );
			        $step_input.append($("<label for='Step__c'>Step:</label>"))
              			          .append($("<input></input>").attr({type: 'number',
              			                                              class: 'focus',
              			                                              id: 'Step__c',
              			                                              name: 'Step__c',
              			                                              step: 'any',
              			                                              required: false,
              			                                              value: results.Step__c
              			                                            })
              			          );
			        $form.append($("<input />").attr({type: 'hidden', id: 'Id', name: 'Id', value: results.Id}))
			           .append($s_input)
			           .append($m_input)
			           .append($step_input)
			           .append($submit);
			        $content.append($details).append($form);
			        d_self.resolve($content);
		      	});
		    });
		},//optionForm

		upgradeEditForm: function() {
			var $this = $(this),
	          editId = $this.attr('data-edit-id'),
	          $content,
	          d_self;

	      return $.Deferred( function() {
					var d_self = this;
					BoatRemoter.fetchEditUpgradeDetails(editId, function(results, events) {
						$content = BoatQuickEdit.Utilities.upgradeForm(results);
						d_self.resolve($content);
					});
	      });

		},//upgradeEditForm

		upgradeCreateForm: function() {
			var $this = $(this),
					 $content,
	         d_self,
					 productUpgradeCost = {};


	    productUpgradeCost.Price_Book__c = $this.attr('data-price-book-id');
	    productUpgradeCost.Product_Upgrade__c = $this.attr('data-product-upgrade-id');

	    return $.Deferred( function() {
				var d_self = this;
				BoatRemoter.newProductUpgradeCost( JSON.stringify(productUpgradeCost), function(results, events) {
					$content = BoatQuickEdit.Utilities.upgradeForm(results);
					d_self.resolve($content);
				});
	    });

		}//upgradeCreateForm

	}//Builders





	// ***************** OBSERVERS *************************//

	BoatQuickEdit.Observers = {

		editUpgradeLink:  function($link) {
			$link.quickBox({
				boxPos: 'left',
				title: "Edit Upgrade Cast",
				content: BoatQuickEdit.Builders.upgradeEditForm,
				onBoxOpen: BoatQuickEdit.Observers.upgradeForm
	        });
		},//editUpgradeLinks


		optionForm:  function() {
			var $form = $('#optionForm'),
		      $this = $(this); //which is the link from the qEditBox plugin
		    $('input[type="number"]:first').focus();
		    $form.on("submit", function(e) {
				e.preventDefault();
				var data = $form.serialize();
  			$this.quickBox('showIndicator');
  			console.log(data);
				BoatRemoter.updateOptionDetails(data, function(results, events){
					var $row = $this.closest('tr');
					$row.find('.Standard__c').html(results.Standard__c);
					$row.find('.Maximum__c').html(results.Maximum__c);
					$row.find('.Step__c').html(results.Step__c);
					$this.quickBox('removeIndicator');
					$this.quickBox('closeBox');
				});
		    });

		},// optionFrom

		upgradeForm: function() {
			var $form = $('#UpgradeForm'),
	          $this = $(this);

      $('input.focus').focus();
      $form.on('submit', function(e) {
				e.preventDefault();
				var data = $form.find(':input').serializeArray(),
					upgradeCostObject = {};

				upgradeCostObject.Id = data[0].value;
				upgradeCostObject.Cost__c = data[1].value;
				upgradeCostObject.Price_Book__c = data[2].value;
				upgradeCostObject.Product_Upgrade__c = data[3].value;

       	$this.quickBox('showIndicator');

       	//Dont allow a blank cost
				if( typeof(Cost__c) == 'undefined' || Cost__c == null || Cost__c == '') {
					$this.quickBox('removeIndicator');
					displayError('Price Can Not Be Blank');
					return false;
				}
				if($form.data('mode') == 'edit'){
					BoatRemoter.updateCost( JSON.stringify( upgradeCostObject ), function (results, events) {

						if(results == null){
							//displayError("Price is Not A Valid Format");
							$this.quickBox('removeIndicator');
							return false;
						}
						$this.html('$ ' + results.Cost__c.toFixed(2));
						$this.quickBox('removeIndicator');
						$this.quickBox('closeBox');
					});
				}
				if($form.data('mode') == 'create'){
					delete upgradeCostObject.Id;
					BoatRemoter.updateCost( JSON.stringify( upgradeCostObject ), function(results, events) {
						if(results == null){
							//displayError("Price is Not A Valid Format");
							$this.quickBox('removeIndicator');
							return false;
						}
						var $newLink = $('<a></a>');

						$newLink.attr({href: '#', 'data-edit-id': results.Id, class: 'upgradeEditLink'})
						.html('$ ' + results.Cost__c.toFixed(2));
						BoatQuickEdit.Observers.editUpgradeLink($newLink);
						$this.quickBox('removeIndicator');
						$this.quickBox('closeBox');
						$this.parent().html($newLink);
					});
				}
	    });
		}//upgradeForm

	}// Observers


	//********************* UTILITIES *************************//

	BoatQuickEdit.Utilities = {

		upgradeForm: function(results) {

        var $content = $('<div></div>'),
          formMode = results.Id ? 'edit' : 'create',
          $form = $('<form></form>').attr('id', 'UpgradeForm'),
          $details = $('<div></div>').addClass('upgrade_details'),
          $input = $('<div></div>').addClass('field'),
          $submit = $('<input type="submit" value="Save" class="btn" />');


        $details.html("Upgrade From: <span>"
          + results.Product_Upgrade__r.From_Product__r.Name
          + "</span><br /> To: <span>"
          + results.Product_Upgrade__r.To_Product__r.Name
          +"</span></div>");

        $('#qEditContainer').removeClass('edit create').addClass(formMode);
        $input.append($("<label for='Cost__c'>Cost:</label>"))
          .append($("<input />").attr({type: 'number',
                                        class: 'focus',
                                        id: 'Cost__c',
                                        name: 'Cost__c',
                                        step: 'any',
                                        required: true,
                                        value: results.Cost__c ? results.Cost__c.toFixed(2) : ''
                                      })
          );

        $form.append($("<input />").attr({type: 'hidden', id: 'Id', name: 'Id', value: results.Id}))
          .append($input)
          .append($("<input />").attr({ type: 'hidden',
          														  id: 'Price_Book__c',
          														  name: 'Price_Book__c',
          														  value: results.Price_Book__c
          														})
          )
          .append($("<input />").attr({ type: 'hidden',
          															id: 'Product_Upgrade__c',
          															name: 'Product_Upgrade__c',
          															value: results.Product_Upgrade__c
          														})
          )
          .append($submit)
          .data('mode', formMode);
        $content.append($details)
        .append($form);

        return $content;
        }

	}

})(jQuery);
