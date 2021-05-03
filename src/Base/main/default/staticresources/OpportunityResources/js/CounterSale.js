 (function($, document, window, undefined){
    function SelectedItems()
    {
      this.items = [];
    }

    SelectedItems.prototype = {
      constructor: SelectedItems,
      addItem: function(item)
      {
        var i = new SelectedItem(item);
        this.items.push( i );
        return i;
      },
      removeItem: function(rowId){
        var index;
        $.each(this.items, function(idx, item) {
          if( item.RowId === rowId )
          {
            index = idx;
          }
        });
        if(index != null)
        {
          //this.items.splice(index, 1);
          this.items[index].Quantity = 0;
        }
      },
      findFeeItems: function()
      {
        var fees = [];
        $.each(this.items, function(idx, item) {
          if( item.productRecordType.toLowerCase() === 'fees' )
          {
            fees.push(item);
          }
        });
        return fees;
      },
      findItem: function(fieldName, fieldValue)
      {
        var result;
        $.each(this.items, function(idx, item) {
          if( item[fieldName] === fieldValue )
          {
            result = item;
          }
        });
        return result;
      },
      JSONitems: function()
      {
        //clone item array
        var withoutRowId = JSON.parse( JSON.stringify(this.items) );
        $.each( withoutRowId, function(idx, item) {
          delete item['RowId'];
          delete item['isTaxable'];
          delete item['productRecordType'];
        });
        return JSON.stringify( withoutRowId );
      }
    }

    function SelectedItem(wrapper){
      var genRowId = function() {
        var chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz'.split(''),
            str = '';

        for (var i = 0; i < 8; i++) {
          str += chars[Math.floor(Math.random() * chars.length)];
        }
        return str;
      }

      this.Id = wrapper.lineItemId;
      this.OpportunityId = wrapper.opportunityId;
      this.Quantity = wrapper.quantity;
      this.ListPrice = wrapper.listPrice;
      this.UnitPrice = wrapper.unitPrice;
      this.pricebookEntryId = wrapper.pricebookEntryId;
      this.Description = wrapper.name;
      this.RowId = genRowId();
      this.isTaxable = wrapper.isTaxableProduct;
      this.productRecordType = wrapper.productRecordType;
    }

    SelectedItem.prototype.constructor = SelectedItem;


    var sis = new SelectedItems(),
        $acctSearchField = $('input[data-sf-field="FirstName"]'),
        acctSearchActive = false,
        $requiredAccountFields = $('.acct_Fields .requiredInput input'),
        $productSection = $('#productSection'),
        $productSearchField = $('#productSearch'),
        $pricebook = $('#priceBook'),
        $pTable = $('#selectedProducts'),
        $saleTotal = $('#saleTotal'),
        $taxTotal = $('#taxTotal'),
        $editTaxRate = $('#editTaxRate'),
        $taxForm = $('#taxForm'),
        taxRate = function(){
          var v =  $('#taxRate').val() ?  $('#taxRate').val() : 0;
          return parseFloat( v ) / 100;
        };

    Handlebars.registerHelper('feeSelectOption', function(opt, selected) {
      var option = '<option value="' + opt +'"';
      if( opt === selected )
      {
        option += ' selected="true"';
      }
      option += '>' + opt + '</option>';
      return new  Handlebars.SafeString(option);
    });

    Handlebars.registerHelper('availableFees', function(fees) {
      return new Handlebars.SafeString( CounterSale.feeTemplates.availableFees( {fees: fees} ) );
    });

    Handlebars.registerHelper('toCurrency', function(price) {
      return new Handlebars.SafeString( '$ ' + price.toFixed(2) );
    });

    window.CounterSale = {

      opportunityId: null,
      uiEnv: 'classic',
      currentTaxRate: null,
      taxationProvince: null,
      taxOverRide: null,
      provincialTaxRates: null,
      feeTemplates: null,
      feesByProvince: null,

      addPageError: function( message ) {
        var $errorBox = $('#error-box');
        if( $errorBox.length > 0 )
        {
          $errorBox.html( message );
        }
        else
          $errorBox = $('<div></div>')
            .prop('id', 'error-box').addClass('alert-box alert')
            .html( message )
            .insertBefore( $('.acct_Fields') );
      },

      triggerHandlers: {
        closeFeesModel: function()
        {
          var $modal = $('#feeModal'),
              $content = $('#feeContent'),
              $overlay = $('.modalOverlay');

          $modal.removeClass('open');
          $overlay.removeClass('open');
          $content.off('change', 'input[type="checkbox"]')
          .off('keyup', '.feeFilter')
          $('#addFeeBtn').off('click');

          setTimeout( function() {
            $overlay.remove();
            $modal.removeClass('loaded');
            $content.children().remove();
          }, 500);
        },

        openFeesModal: function()
        {
          var $modal = $('#feeModal'),
              $content = $('#feeContent'),
              $overlay = $('<div class="modalOverlay"></div>');

          $modal.addClass('open');
          $modal.after($overlay);
          $overlay.addClass('open').on('click', function(e) {
            e.preventDefault();
            CounterSale.triggerHandlers.closeFeesModel();
          });
          CounterSale.productFunctions.fetchFees()
          .then( function(result) {
            $modal.addClass('loaded');
            CounterSale.feesByProvince = result;
            setTimeout( function() {
              $content.html( CounterSale.feeTemplates.feeContent(
                { provinces: Object.keys(result),
                  province: CounterSale.taxationProvince,
                  provinceFees: result[CounterSale.taxationProvince] }
              ) );
              CounterSale.triggerHandlers.enableFeeSelector($content);
            }, 500)
          })
          .fail( function(message) {
            $modal.addClass('loaded');
          });
        },

        enableFeeSelector: function($content)
        {
          var $provSelect = $content.find('select:first'),
              $btn = $content.find('a.fd_button'),
              $feeTableContent = $content.find('table:first');
              updateTableContent = function(fees)
              {
                $feeTableContent.html(
                  CounterSale.feeTemplates.availableFees(
                    { fees: fees }
                  )
                );
              }

          $provSelect.on('change', function() {
            var prov = $(this).val();
            CounterSale.triggerHandlers.updateTaxInfo(prov);
            updateTableContent( CounterSale.feesByProvince[ CounterSale.taxationProvince ] );
            $('.feeFilter').val('');
          });


          $content.on('change', 'input[type="checkbox"]', function() {
            $(this).closest('tr').toggleClass('selected');
          })
          .on('keyup', '.feeFilter', function() {
            var val = $(this).val(),
                result = new Object();
            $.each( CounterSale.feesByProvince[CounterSale.taxationProvince], function(key, fee) {
              if( fee.name.toLowerCase().includes(val.toLowerCase()) )
              {
                result[key] = fee;
              }
            });
            updateTableContent(result);
          })
          $('#addFeeBtn').on('click', function(e) {
            e.preventDefault();
            var selected = [];
            $feeTableContent.find('input[type="checkbox"]:checked').each( function(idx, ele) {
              selected.push( CounterSale.feesByProvince[CounterSale.taxationProvince][$(ele).data('fee-ammount-id')] );
            });
            if( selected.length > 0 )
            {
              $.each(selected, function(idx, fee) {
                CounterSale.productFunctions.addItemToTable(fee);
                CounterSale.triggerHandlers.closeFeesModel();
              });
            }
          });

        },

        editTaxRate: function($link)
        {
          var pos = $link.position(),
              w = $link.outerWidth();

          if( $taxForm.is(':visible') )
          {
            $taxForm.hide();
            CounterSale.triggerHandlers.cleanUpTaxForm();
          }
          else
          {
            $taxForm.css({'top': pos.top -88, 'left': pos.left + w +17}).show();
            CounterSale.triggerHandlers.taxFormFunctionality($link);
          }
        },

        cleanUpTaxForm: function()
        {
          $('[data-id="provTaxSelect"]').off('change');
          $('[data-id="taxOverRide"]').off('change');
          $('#updateTaxes').off('click');

        },

        taxFormFunctionality: function($link)
        {
          var prov,
              $overRide = $('[data-id="taxOverRide"]'),
              $input = $('#totalTaxRate');
          //set the disables
          $('[data-is-disabled]').each( function(idx, ele) {
            if( $(ele).data('is-disabled'))
            {
              $(ele).attr('disabled', 'true');
            }
          });
          //Select On Change
          $('[data-id="provTaxSelect"]').on('change', function(e) {
            prov = $(this).val();
            if( !CounterSale.taxOverRide )
            {
              $input.val( CounterSale.provincialTaxRates[ prov ] );
            }
            //CounterSale.taxationProvince =  $(this).val();
          });
          //tax Over ride checkbox
          $overRide.on('change', function() {
            var $this = $(this),
                prov = $('[data-id="provTaxSelect"]').val();
            if( $this.is(':checked') )
            {
              $input.removeAttr('disabled').data('is-disabled', 'false');
              CounterSale.taxOverRide = true;
            }
            else
            {
              $input.attr('disabled', 'true').data('is-disabled', 'true')
              .val( CounterSale.provincialTaxRates[prov]);
              CounterSale.taxOverRide = false;
            }
          });

           //update button
          $('#updateTaxes').on('click', function(e) {
            e.preventDefault();
            CounterSale.triggerHandlers.updateTaxInfo(prov);
          })
        },

        updateTaxInfo: function(prov)
        {
          var $select = $('[data-id="provTaxSelect"]'),
              $overRide = $('[data-id="taxOverRide"]'),
              $input = $('#totalTaxRate');
          if( typeof(prov) !== 'undefined' && prov !== CounterSale.taxationProvince )
          {
            CounterSale.taxationProvince = prov;
            CounterSale.productFunctions.removeFeesFromTable();
          }
          //if the passed in province == $select value then we came from the edit tax form
          //else we came from the add fees form
          if( typeof(prov) === 'undefined' || prov === $select.val() )
          {
            CounterSale.currentTaxRate = $('#totalTaxRate').val();
            $editTaxRate.html('(' + CounterSale.currentTaxRate +'%)').click();
            CounterSale.triggerHandlers.productTableChanged();
          }
          if( typeof(prov) !== 'undefined' && prov !== $select.val() )
          {
            $select.val(prov);
            if( !CounterSale.taxOverRide )
            {
              CounterSale.currentTaxRate = CounterSale.provincialTaxRates[prov];
              $editTaxRate.html('(' + CounterSale.currentTaxRate +'%)');
              CounterSale.triggerHandlers.productTableChanged();
            }
          }
        },

        /*

          @param $(<input></input>)

          fire this when quantity field is changed on the product table
          the table row has data -sale-amount(int), -taxable-product(bool) {if the product is taxable}, -tax-amount

          this data needs to be recalculated, then we fire the productTableChanged event to update totals

        */
        tableFieldChanged: function( value, rowId, fieldName ){
          var $row =  $('#'+rowId),
              selectedItem = sis.findItem('RowId', rowId);
          if( selectedItem )
          {
            selectedItem[fieldName] = value;
            $row.find('.total').html('$ ' + (selectedItem.Quantity * selectedItem.UnitPrice).toFixed(2) );
          }
          CounterSale.triggerHandlers.productTableChanged();
        }, // ***** quantityFieldChanged


        /*
          We fire this when ever anything needs to get recalculated on the products table
        */
        productTableChanged: function(){
          var $rows = $pTable.children('tbody').children('tr'),
            tRate = CounterSale.currentTaxRate / 100,
            taxTotal = 0,
            total = 0;
          switch( $rows.length ){
            case 0:
              $pricebook.removeAttr('disabled');
              break;
            case 1:
              $pricebook.attr('disabled', 'disabled');
              break;
            default:
              break;
          }
          $.each(sis.items, function( key, item ){
            total += item.Quantity * item.UnitPrice;
            if(item.isTaxable)//if( $('#'+key).data('is-taxable-product') === true )
            {
              taxTotal += item.Quantity * item.UnitPrice * tRate;
            }
          });
          $taxTotal.html( taxTotal.toFixed(2) );
          $saleTotal.html( (total + taxTotal).toFixed(2) );

        } // ***** /productTableChanged

      }, // ***** /triggerHandlers

      accountFunctions: {

        search: function(queryString){
          if( acctSearchActive ) return false;

          var self,
          $iconContainer = $acctSearchField.parent('.columns').next('.columns').children('span'),
          origIcon = $iconContainer.html();
          acctSearchActive = true;
          CounterSale.accountFunctions.clearFormFields();
          selectedAccount = null;
          $iconContainer.html('<i class="fa fa-spin fa-spinner"></i>');
          return $.Deferred( function() {
            self = this;
            RetailCounterSaleController.accountSearch(queryString, function(events,result){
              acctSearchActive = false;
              $iconContainer.html(origIcon);
              if(result.statusCode === 200){
                self.resolve(result.result);
              }
            })
          });
        },  // *********** /search

        populateAccountData: function( account )
        {
          CounterSale.accountFunctions.clearFormFields();
          $('.acctField[data-sf-field!="FirstName"]').each(function(idx, ele) {
            var $ele = $(ele);
            if( $ele.is('input') || $ele.is('select') )
            {
              $ele.val( account[ $ele.data('sf-field') ] );
            }
            if( $ele.is('span') )
            {
              $ele.find('select:first').val( account[ $ele.data('sf-field') ] );
            }
            if( $ele.data('sf-field') === 'BillingCountryCode' )
              $ele.trigger('change');
          });
        },

        clearFormFields: function()
        {
          $('.acctField[data-sf-field!="FirstName"]').each( function(idx, ele) {
            var $ele = $(ele);
            if( $ele.is('span') )
            {
              $ele.find('select:first').val('');
            }
            else
            {
              $ele.val('');
            }
          });
        },

        selectAccount: function(account){
          CounterSale.accountFunctions.clearFormFields();

          $('.acctField').each(function(idx, ele) {
            var $ele = $(ele);
            if( $ele.is('input') || $ele.is('select') )
            {
              $ele.val( account[ $ele.data('sf-field') ] )
              .trigger('change');
            }
            if( $ele.is('span') )
            {
              $ele.find('select:first').val( account[ $ele.data('sf-field') ] )
              .trigger('change');
            }

          });
          // focus on product search field
          $productSearchField.focus();
          //show the add Fees button
          $('#addFees').show();
        }, // ******** /selectAccount

        collapseForm: function()
        {
          $('#acctFields').slideUp();
          $('a[href="#acctFields"]').addClass('collapsed');
        },
        expandForm: function()
        {
          $('#acctFields').slideDown();
          $('a[href="#acctFields"]').removeClass('collapsed');
        }

      }, // *********** /accountFunctions

      productFunctions: {

        search: function(queryString){
          var self,
          indc = $('#searchInd'),
          pricebookId = $pricebook.val();
          indc.show();
          return $.Deferred( function() {
            self = this;
            RetailCounterSaleController.productSearch(queryString, pricebookId, function(events,result){
              indc.hide();
              if(result.statusCode === 200){
                self.resolve(result.result);
              }
            });
          });
        }, // ***** / search

        fetchFees: function()
        {
          var dfd = new $.Deferred(),
              pricebookId = $pricebook.val();

          RetailCounterSaleController.fetchFees( pricebookId, function(result, event) {
            if( event.status )
            {
              dfd.resolve( result == null || result.length === 0 ? null : result);
            }
            else
            {
              dfd.reject(event.message);
            }
          });
          return dfd.promise();
        },

        removeFeesFromTable: function()
        {
          var feeItems = sis.findFeeItems();

          $.each(feeItems, function(idx, item) {
            $('#'+item.RowId).find('a.removeProduct').click();
          });
        },

        populateProductDetails: function(result){
          var handleResult = function(check, fieldResult, $field){
            if(check){
              $field.html(fieldResult)
              .closest('.resultC').show();
            }
            else {
              $field.html('')
              .closest('.resultC').hide();
            }
          },
          $container = $('.detailsContainer');

          if(result){
            $container.show();
            handleResult( result.name, result.name, $('#name') );
            handleResult( result.productCode, result.productCode, $('#code') );
            handleResult( result.ProductRecordType, result.ProductRecordType, $('#type') );
            handleResult( result.productFamily, result.productFamily, $('#family') );
            handleResult( result.description, result.description, $('#description') );
            handleResult( result.unitPrice, result.unitPrice.toFixed(2), $('#price') );
          }
          else {
             $container.hide();
          }
        }, // ***** /populateProductDetails

        selectProduct: function(item){
          CounterSale.productFunctions.addItemToTable(item);
        }, // ***** /selectProduct

        addItemToTable: function( wrapper ){
          var $row,
              rowTotal = wrapper.unitPrice * wrapper.quantity,
              selectedItem = sis.findItem('pricebookEntryId', wrapper.pricebookEntryId);
          if( !$pTable.is(":visible") ){
            $pTable.show();
          }
          if( selectedItem &&
              selectedItem.Quantity > 0 &&
              (typeof(wrapper.name) === 'undefined' || wrapper.name.toLowerCase().indexOf( 'labour') < 0 ) &&
              (typeof(wrapper.nameFR) === 'undefined' || wrapper.nameFR.toLowerCase().indexOf( 'travail') < 0 ) &&
              (typeof(wrapper.productRecordType) =='undefined' || wrapper.productRecordType != 'Fees')
            )
          {

            $row = $('#'+selectedItem.RowId );
            selectedItem.Quantity += 1;
            $row.find('input:first').val( selectedItem.Quantity ).trigger('change');
          }
          else
          {
            selectedItem = sis.addItem( wrapper );
            $row = $('<tr></tr>').attr('id', selectedItem.RowId).data('is-taxable-product', wrapper.isTaxableProduct);
            var $removeLink = $('<a></a>').prop('href', '#').addClass('removeProduct').append( $('<i></i>').addClass('fa fa-times') ),
                $nameCell,
                $viewChildrenLink = $('<a href="#" class="view_children"></a>')
                .html( $('<i class="fa fa-chevron-up"></i>') ),
                $quantityCell =  $('<td></td>').append( $('<input></input>').attr('type', 'number').data('field-name','Quantity').val(wrapper.quantity) ),
                $retailPriceCell = $('<td class="text-only"></td>').html( '$ ' + wrapper.listPrice.toFixed(2) ) ,
                $salePriceInput = $('<input></input>').attr('type', 'text').data('field-name','UnitPrice').val( wrapper.unitPrice.toFixed(2) ),
                $salePriceCell =  $('<td></td>').append( $('<i></i>').addClass('fa fa-dollar') ).append( $salePriceInput ),
                $totalCell = $('<td class="text-only"></td>').addClass('total').html( '$ ' + rowTotal.toFixed(2));

            $nameCell =  $('<td class="text-only"></td>').append( $removeLink );
            /*
              Check to see if this is a labour product
              If it is we allow a step of 0.25 in quantity
              to allow for 15 minute steps in labour charging
              PROBABLY WANT TO FIND A BETTER WAY TO DO THIS
            */
            if( wrapper.name.toLowerCase().indexOf( 'labour') > -1 )
            {
              $quantityCell.find('input').attr('step', 0.25);
            }
            if(wrapper.isKit)
            {
              $nameCell.append( $viewChildrenLink )
              .append( $('<span></span>').html( wrapper.productCode ) )
              .append( $('<span></span>').html( wrapper.name ) )
              .append( CounterSale.productFunctions.buildKitComponentsView(wrapper.kitComponents) );
              $viewChildrenLink.on('click', function(e) {
                e.preventDefault()
                $(this).toggleClass('open')
                .siblings('.kit-contents').toggleClass('collapsed');
              })
            }
            else
            {
              $nameCell .append( $('<span></span>').html( wrapper.productCode ) )
              .append( $('<span></span>').html( wrapper.name ) );
            }

            $row.append( $nameCell )
              .append( $quantityCell )
              .append( $retailPriceCell )
              .append( $salePriceCell )
              .append( $totalCell );

            $pTable.find('tbody:first').append($row);

          }
          CounterSale.triggerHandlers.productTableChanged();
        }, // ***** /addItemToTable

        buildKitComponentsView: function(components)
        {
          var $container = $('<div class="kit-contents collapsed"></div>'),
              $table = $('<table></table>'),
              buildRow = function(comp) {
                var $tr = $('<tr></tr>');
                $tr.append( $('<td></td>').html( comp.From_Product__r.Name ) )
                .append( $('<td></td>').html( comp.Standard__c ) );
                return $tr;
              };
          $.each( components, function(idx, comp) {
            $table.append( buildRow( comp ) );
          })
          $container.append( $table );
          return $container;
        }// ********* /buildKitComponentsView

      }, // ***** /productFunctions

      validators: {

        accountForm: function(){
          var valid = false;
          $requiredAccountFields.each( function(index, ele){
            valid = ( ele.value === null || ele.value === '' ) ? false : true;
          });
          if( valid === true )
          {
            $productSection.show();
          }
          else
          {
            $productSection.hide();
          }

        }
      } // ***** /validators

    }

    $editTaxRate.on('click', function(e) {
      e.preventDefault();
      CounterSale.triggerHandlers.editTaxRate($(this));
    })

    $acctSearchField.legendForceComboBox({
      idFieldName: 'Id',
      textFieldName: 'Name',
      searchFunction: function(queryString){
        return CounterSale.accountFunctions.search(queryString);
      },
      quickSelectHandler: function(result)
      {
        CounterSale.accountFunctions.populateAccountData(result);
      },
      selectHandler: function(objectId, text, object){
        CounterSale.accountFunctions.selectAccount(object);
      },
      clearFormFields: function()
      {
        CounterSale.accountFunctions.clearFormFields();
      }
    });

    $('.acct_Fields input:not("#acct_FirstName")').on('change', function(){
      CounterSale.validators.accountForm();
    });


    $productSearchField.legendForceComboBox({
      idFieldName: 'id',
      textFieldName: 'name',
      searchFunction: function(queryString){
        return CounterSale.productFunctions.search(queryString);
      },
      quickSelectHandler: function(result){
        CounterSale.productFunctions.populateProductDetails(result);
      },
      selectHandler: function(objectId, text, object){
        CounterSale.productFunctions.selectProduct( object );
        //$('#pricebook')
        //closeDetailsContainer();
        $(this).val('');
      },
      onClose: function() {
       $('.detailsContainer').hide();
      }
    });

    $pTable.on({
      keypress: function(e){
        var code = (event.keyCode ? event.keyCode : event.which);
        if (!(
            (code >= 48 && code <= 57) //numbers
            || (code == 46) //period
        )
        || (code == 46 && $(this).val().indexOf('.') != -1)
       )
        e.preventDefault();
      },
      keyup: function(e){
        if( [38, 40].indexOf( e.keyCode ) < 0 ){
          var $this = $(this),
            v = $this.val(),
            fieldName = $this.data('field-name'),
            rowId = $this.closest('tr').attr('id');

          if( ( isNaN( v ) || v === '' || v < 0 ) && ( $this.attr('step') === undefined ) ){
            $(this).val('');
            v = 0;
          }

          CounterSale.triggerHandlers.tableFieldChanged( v, rowId, fieldName );
        }
      },
      change:  function(e){
        var $this = $(this),
            v = $this.val(),
            fieldName = $this.data('field-name'),
            rowId = $this.closest('tr').attr('id');
        if( isNaN( v ) || v === '' || v < 0 ){
          $(this).val(0);
          v = 0;
        }
        CounterSale.triggerHandlers.tableFieldChanged( v, rowId, fieldName );
      }
    }, 'input');

    $('#taxRate').on({
      keypress: function(e){
        var code = (event.keyCode ? event.keyCode : event.which);
        if (!(
            (code >= 48 && code <= 57) //numbers
            || (code == 46) //period
        )
        || (code == 46 && $(this).val().indexOf('.') != -1)
       )
        e.preventDefault();
      },
      keyup: function(e){
        if( [38, 40].indexOf( e.keyCode ) < 0 ){
          var v = $(this).val();
          if( isNaN( v ) || v === '' || v < 0 ){
            $(this).val('');
          }
          CounterSale.triggerHandlers.productTableChanged();
        }
      },
      change: function(e){
        var v = $(this).val();
        if( isNaN( v ) || v === '' || v < 0 ){
          $(this).val('');
        }
        CounterSale.triggerHandlers.productTableChanged();
      }
    });

    $('#selectedProducts').on('click', '.removeProduct', function(e) {
      e.preventDefault();
      var $row = $(this).closest('tr'),
          rowId = $row.attr('id');

      sis.removeItem(rowId);
      $row.remove();
      CounterSale.triggerHandlers.tableFieldChanged(0, rowId, 'Quantity')
    });

    /* SAVE BUTTON CLICK HANDLER */
    $('.saveBtn').on('click', function(e){
      e.preventDefault();
      var account = {},
          oppData = {};

      oppData.Id = CounterSale.opportunityId;
      oppData.Pricebook2Id = $pricebook.val();
      oppData.Payment_Method__c = $("[id*='paymentMethod']").val();
      oppData.TaxationProvince__c = CounterSale.taxationProvince;
      oppData.TaxOverRide__c = CounterSale.taxOverRide;
      oppData.TaxOverRideRate__c = CounterSale.currentTaxRate;

      $('#ajaxInd').show();
      $('.acctField').each(function(index, ele){
        var $ele = $(ele),
            field = $ele.data('sf-field'),
            fieldValue = $ele.val();
        if( $ele.is('input') || $ele.is('select') ){
          fieldValue = field === 'Id' && fieldValue == '' ? null : fieldValue;
          account[ field ] = fieldValue;
        }
        if( $ele.is('span') ) {
          account[ field ] = $ele.find('select:first').val();
        }
      });
      if( oppData.Payment_Method__c === '' || oppData.Payment_Method__c === null || typeof( oppData.Payment_Method__c) === 'undefined')
      {
        CounterSale.addPageError( "Please select a payment method!" );
        $('#ajaxInd').hide();
      }
      else if( $.isEmptyObject(sis.items) )
      {
        CounterSale.addPageError( "Please add at least on product to the sale!" );
        $('#ajaxInd').hide();
      }
      else
      {
        console.log(sis.JSONitems());
        RetailCounterSaleController.createSale( JSON.stringify(account),
                                                     sis.JSONitems(),
                                                     JSON.stringify(oppData),
                                                     function(events, result){
          if(result.statusCode === 200)
          {
            if( CounterSale.uiEnv === 'classic' )
            {
              window.top.location.href = result.result;
            }
            else
            {
              sforce.one.navigateToURL(result.result);
            }
          }
          else
          {
            CounterSale.addPageError( result.message );
            $('#ajaxInd').hide();
          }
        });
      }

    });

    $('#addFees').on('click', function(e) {
      e.preventDefault();
      CounterSale.triggerHandlers.openFeesModal();
    });

    $('a[href="#acctFields"]').on('click', function(e) {
      e.preventDefault();
      var $this = $(this);
      if($this.hasClass('collapsed') )
      {
        CounterSale.accountFunctions.expandForm();
      }
      else
      {
        CounterSale.accountFunctions.collapseForm();
      }
    });

    $productSearchField.on('focus', function(e) {
      CounterSale.accountFunctions.collapseForm();
    });

  })(jQuery.noConflict(), document, window);












