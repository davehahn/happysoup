({
  doInit : function(component, event, helper)
  {
    console.log( 'parts form doinit');
    helper.inConsole( component )
    .then( (response) => {
      component.set("v.inConsoleView", response );
      console.log(`We are in a console view ${response}`);
      return helper.doInit(component);
    })
    .then(
      $A.getCallback( function( result ) {
        console.log( 'dealerPartsOrderFormController INIT');
        console.log( result );
        component.set("v.lstProdFamily", result.productFamily);
        component.set("v.boatModel", result.boatModel);
        component.set('v.activePriceBookId', result.activePriceBookId );
        component.set('v.internalPoNumber', result.partnerReference );
        var matList = result.materialList;
        console.log(matList)
        //if(matList.length > 0)
        // {
        //   for(var record in matList)
        //   {
        //       var div = document.createElement('div');
        //       div.innerHTML = matList[record].matImgUrl;
        //       var firstImage = div.getElementsByTagName('img')[0];
        //       var rawImgSrc = firstImage ? firstImage.getAttribute("src") : "";
        //       matList[record].matImgUrl = rawImgSrc;
        //   }
        component.set("v.materials", matList);
        helper.calOrderTotal(component);
      }),
      $A.getCallback( function( err ) {
        console.log( 'error here?');
        LightningUtils.errorToast( err );
      })
    );
  },

  toggleCreateForm: function(component, event) {
      document.querySelector(".forceListViewManager").style.display= "none";
      var createForm = component.find('createForm');
      $A.util.toggleClass(createForm, 'slds-hide');
      var createButton = component.find('newButton');
      $A.util.toggleClass(createButton, 'slds-hide');
  },

  toggleFilterMenu: function( component, event, helper )
  {
    var filter = component.find('filter-container'),
        mask = component.find('menu-mask');
    $A.util.toggleClass(filter, 'is-slide-menu-open');
    $A.util.toggleClass(mask, 'is-slide-menu-open');
  },

  toggleCart: function( component, event, helper )
  {
    var cart = component.find('cart-container'),
        mask = component.find('menu-mask');
    $A.util.toggleClass(cart, 'is-slide-menu-open');
    $A.util.toggleClass(mask, 'is-slide-menu-open');
  },

  closeMenus: function( component, event, helper )
  {
    // var eles = document.querySelectorAll('.is-slide-menu-open');
    // for( var i=0; i<eles.length; i++ )
    // {
    //   eles[i].classList.remove('is-slide-menu-open');
    // }
    console.log('CLOSE MENUS');
    var filter = component.find('filter-container'),
        cart = component.find('cart-container'),
        mask = component.find('menu-mask');
    $A.util.removeClass(filter, 'is-slide-menu-open');
    $A.util.removeClass(cart, 'is-slide-menu-open');
    $A.util.removeClass(mask, 'is-slide-menu-open');
  },

  searchKeyChange : function(component, event, helper) {
    helper.searchKeyChangeHelper(component);
  },

  getProductsFromBoat : function(component, event, helper) {
    helper.searchKeyChangeHelper(component);
  },

  SelctCheckbox : function(component, event, helper) {
    helper.searchKeyChangeHelper(component);
  },

  searchKeyOnEnter : function(component, event, helper) {
    if(event.getParams().keyCode != 37 && event.getParams().keyCode != 38 && event.getParams().keyCode != 39 && event.getParams().keyCode != 40) {
        helper.searchKeyChangeHelper(component);
    }
  },

  materialChanged: function( component )
  {
      var materials = component.get('v.materials');
      component.set('v.isSaveable', materials !== null && materials.length > 0 );
  },

  addToList : function(component, event, helper) {
    helper.addToListHelper(component, event);
  },

  createSalesforcePart: function( component, event, helper )
  {
    var recordId = event.currentTarget.dataset.recordId,
        modal = component.find("product-create-modal"),
        form = component.find("product-form");

    $A.createComponent(
      "c:lgnd_QuickPartsCreate",
      {
        "aura:id": "productCreateForm",
        recordId: recordId,
        componentContext: 'modal'
      },
      function(compo){
        if( form.isValid() )
        {
          var body = form.get("v.body");
          body.push(compo);
          form.set("v.body", body);
          $A.util.removeClass(modal, 'slds-hide');
        }
      }
    );
  },

  handlePartCreatedInSalesforceSuccess: function( component, event, helper )
  {
    var pId = event.getParam('productId'),
        spinner = component.find('spinner');
    spinner.toggle();
    helper.closeProductModal( component );
    helper.fetchNewlyCreatedProduct( component, pId )
    .then(
      $A.getCallback( function( result ) {
        helper.addItemToCartList( component, result );
        component.set('v.searchKey', '');
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
      spinner.toggle();
    }))

  },

  removeFromList : function(component, event, helper) {
    helper.removeFromListHelper(component, event);
  },

  showBinLocations: function( component, event, helper )
  {
    var recordId = event.currentTarget.dataset.recordId,
        modal = component.find("location-modal"),
        details = component.find("location-modal-details");

    $A.createComponent(
      "c:Product_BinLocations_dh",
      {
        recordId: recordId
      },
      function(compo){
        if (details.isValid())
        {
          var body = details.get("v.body");
          body.push(compo);
          details.set("v.body", body);
          $A.util.removeClass(modal, 'slds-hide');
        }
      }
    );
  },

  closeProductModal: function( component, event, helper )
  {
    helper.closeProductModal( component );
  },

  closeBinLocationsModal: function( component )
  {
    var modal = component.find("location-modal"),
        details = component.find("location-modal-details");
    $A.util.addClass( modal, 'slds-hide');
    details.set('v.body', []);
  },

  closePoNumberModal: function( component )
  {
    var modal = component.find("po-number-modal");
    $A.util.addClass( modal, 'slds-hide');
  },

  addPoNumber: function( component )
  {
    var modal = component.find("po-number-modal");
    $A.util.removeClass( modal, 'slds-hide');
  },

  submit : function(component, event, helper) {
    var spinner = component.find('spinner');
    spinner.toggle();
    helper.submitHelper(component, false)
    .then(
      $A.getCallback( function( erpId ) {
        LightningUtils.showToast('success', 'Success', 'Thank you for placing an order with Legend Boats');
        helper.returnToDetails( component, erpId );
      }),
      $A.getCallback( function(err) {
        spinner.toggle();
          helper.showMessageHelper(false, component, err)
      })
    )
  },

  submitAsDraft : function(component, event, helper) {
    var spinner = component.find('spinner');
    spinner.toggle();
    helper.submitHelper(component, true)
    .then(
      $A.getCallback( function( erpId ) {
        helper.returnToDetails( component, erpId );
      }),
      $A.getCallback( function(err) {
        spinner.toggle();
        helper.showMessageHelper(false, component, err)
      })
    );
  },

  selectAccount: function( component, event, helper )
  {
    component.set('v.isSelectingAccount', true);
  },

  cancelAccountSelection: function( component )
  {
    component.set('v.isSelectingAccount', false);
  },

  handlePersonAccountSelected: function( component, event, helper )
  {
    var accountId = event.getParam("accountId"),
        spinner = component.find('spinner');

    spinner.toggle();
    helper.submitRetail( component, accountId )
    .then(
      $A.getCallback( function( erpId ) {
        helper.returnToDetails( component, erpId );
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
      spinner.toggle();
    }));
  },

  multiplyQuanPdts : function(component, event, helper) {
    helper.multiplyQuanPdtsHelper(component, event);
  },

  cancelReload : function(component, event, helper) {
   //helper.cancelReloadHelper(component, event);
    var erpOrderId = component.get('v.erpOrderId');
    if( $A.util.isEmpty( erpOrderId ) )
      helper.returnToList();
    else
    {
      var action = $A.get('e.force:navigateToSObject');
      action.setParams({
        "recordId": erpOrderId
      })
      .fire();
    }
  },

  // loadMore : function(component, event) {
  //     $(".loadMoreFamily").css("display", "none");
  //     var elements = $(".testClass");
  //     var len = elements.length;
  //     for (var i = 0; i < len; i++){
  //         $(".testClass")[0].className = "";
  //     }
  // },

    closeWindow : function(component,event,helper)
    {
        $A.util.addClass(component.find("MyModalSec"),"HideModelBox") ;
    },
    addProduct : function(component, event, helper){
        helper.addProductHelper(component, event) ;
    }

    /*hideSpinner : function (component, event, helper) {
        var spinner = component.find('spinner');
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : false });
        evt.fire();
    },
    showSpinner : function (component, event, helper) {
        var spinner = component.find('spinner');
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : true });
        evt.fire();
    },*/
  /*openModalDialog : function(component, event, helper) {
    helper.openModalDialogHelper(component, event);
  },
    showMessage : function(component, event, helper) {
    helper.showMessageHelper(component, event);
  },*/
})