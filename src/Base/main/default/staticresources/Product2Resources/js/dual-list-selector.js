(function($, window, documnet, undefined) {

  window.DualListSelector = {

    init: function(productId)
    {
      this.productId = productId;
      this.setupEventHandlers.call(this);
    },

    setupEventHandlers: function()
    {
      var dls = this;

      /* jQueryUI Sortable on active list items */
      $('.sortable').sortable({
        revert: true,
        cancel: 'a.actionLink',
        items: '> li:not(.new):not(.editing)',
        stop: function(event, ui) {
          dls.Handlers.sort.call(dls, ui.item[0]);
        }
      });

      $('ul.item-list').on('click', 'a.actionLink', function(e) {
        e.preventDefault();
        var $this = $(this),
             action = $this.data('action');
        if(  $this.parent('li').hasClass('busy') || $this.hasClass('disabled') ) return false;
        $this.parent('li').addClass('busy');
        $this.children('i').removeClass().addClass('fa fa-spinner fa-spin');
        dls.Handlers[action].call( dls,  $this );
      })

      .on('click', 'a.editItem', function(e) {
        e.preventDefault();
        var $this = $(this);
        if( $this.parent('li').hasClass('ui-sortable-helper')
            || $this.parent('li').hasClass('busy') ) return false;
        dls.Handlers.editItem.call(dls, $this);
      })

      .on('keyup', 'input', function(e) {
        var $this = $(this),
            $saveLink = $this.siblings('a.saveItem:first'),
            $cancelLink = $this.siblings('a.cancelLink:first'),
            code = e.keyCode || e.which;

        if( $this.val() != '' )
        {
          $saveLink.removeClass('disabled');
        }
        else
        {
          $saveLink.addClass('disabled');
        }
        if( code === 13 ) $saveLink.click();
        if( code === 27 ) $cancelLink.click();

      });

      $('.createItem').on('click', function(e) {
        e.preventDefault();
        var $this = $(this),
            category,
            $activeList;

        if( $this.hasClass('disabled') ) return false;

        $this.addClass('disabled');
        category = $this.data('category'),
        $activeList = $this.parent('h3').siblings('ul.item-list:first');
        dls.Handlers.create.call(dls, $activeList, category);
      });

    },


    /*********************** Handlers ***************************/

    Handlers: {

      sort: function(list_ele)
      {
        var dls = this,
            $list = $(list_ele).parent();

        $list.addClass('busy');
        dls.Model.saveSortOrder.call(dls, createListData( $list.children('li:not(.new)') ) )
        .then( function() {
          $list.removeClass('busy');
        })
        .fail( function(message) {
          alert(message);
        });
      },/* /sort */

      addItem: function( $addLink )
      {
        var dls = this,
            data = {},
            lineItemData = {},
            $item,
            activeListId = $addLink.closest('ul').data('drop-target'),
            $activeList = $('#'+activeListId);

        data.Product__c = dls.productId;
        data.Checklist_Item__c = $addLink.data('item-id');
        data.Rank__c = $activeList.children('li').length + 1;

        lineItemData.linkAction = 'removeItem';
        lineItemData.item_id = data.Checklist_Item__c;

        dls.Model.setItemActive.call(dls, data)
        .then( function(result) {
          lineItemData.lineText = result.Checklist_Item__r.Description__c;
          lineItemData.map_id = result.Id;
          appendItemToList( $activeList, $addLink.parent('li'), lineItemData);
        })
        .fail( function(message) {
          alert(message);
        });
      },/* /addItem */

      create: function( $ul, category )
      {
        var dls = this,
            $item = buildNewLineItem( category );
        $ul.append( $item );
        $ul = $('#'+$ul.attr('id'));
        $ul.animate({
          scrollTop: $ul.prop("scrollHeight")
        },
        500, function() {
          $item.children('input').focus();
        });
      },

      saveItem: function( $createLink )
      {
        var dls = this,
            $item,
            lineItemData = {},
            mapData = {};
            itemData = {};

        itemData.Category__c = $createLink.data('category');
        itemData.Description__c = $createLink.siblings('input:first').val();
        mapData.Product__c = dls.productId;
        mapData.Rank__c = $createLink.closest('ul').children('li').length;

        lineItemData.lineText = itemData.Description__c;
        lineItemData.linkAction = 'removeItem';

        dls.Model.saveItem.call(dls, itemData, mapData)
        .then( function(result) {
          lineItemData.map_id = result.map_id;
          lineItemData.item_id = result.item_id;
          $item = buildLineItem( lineItemData );
          $createLink.parent('li').replaceWith( $item );
          $item.closest('ul').siblings('h3').children('.createItem').removeClass('disabled');
          setTimeout( function() { $item.removeClass('added') }, 200);
        })
        .fail( function(message) {
          alert(message);
        });
      },

      updateItem: function( $updateLink )
      {
        console.log('update Item');
        var dls = this,
            data = {},
            $li = $updateLink.parent('li'),
            $origLi = $li.data('original-li');

        data.Id = $updateLink.data('item-id');
        data.Description__c = $li.children('input:first').val();

        dls.Model.updateItem.call(dls, data)
        .then( function(result) {
          console.log(result)
          $origLi.addClass('added')
          .children('a.editItem:first')[0].innerText = result.Description__c;
          $li.replaceWith( $origLi );
          setTimeout( function() { $origLi.removeClass('added') }, 200);
        })
        .fail( function(message) {
          alert(message);
        });
      },/* /updateItem */

      editItem: function( $editLink )
      {
        var dls = this,
            $editForm = buildEditLineItem( $editLink );

        $editLink.parent('li').replaceWith( $editForm );
        $editForm.children('input:first').focus();
      },/* /editItem */

      cancelItem: function( $cancelLink )
      {
        $cancelLink.closest('ul').siblings('h3').children('.createItem').removeClass('disabled');
        $cancelLink.parent('li').remove();
      },

      cancelUpdate: function( $cancelUpdateLink )
      {
        console.log('cancel update');
        var $li = $cancelUpdateLink.parent('li'),
             $origLi = $li.data('original-li');

        $li.replaceWith( $origLi );
      }, /* /cancel update */

      removeItem: function( $removeLink )
      {
        var dls = this,
            $item,
            lineItemData = {},
            deleteId = $removeLink.parent('li').data('checklist-map-id'),
            availableListId = $removeLink.closest('ul').data('drop-target'),
            $availableList = $('#'+availableListId);

        lineItemData.map_id = '';
        lineItemData.item_id = $removeLink.data('item-id');
        lineItemData.lineText = $removeLink.parent('li')[0].innerText;
        lineItemData.linkAction = 'addItem';

        dls.Model.removeActiveItem.call(dls, deleteId)
        .then( function() {
          appendItemToList( $availableList, $removeLink.parent('li'), lineItemData);
        })
        .fail( function(message) {
          alert(message);
        });
      }/* /removeItem */

    },/* /Handlers */

    /************************* Model ***************************/

    Model: {

      saveSortOrder: function(data)
      {
        var dls = this,
            dfd = new $.Deferred();

        BoatRiggingChecklist_Controller.updateItemOrder(JSON.stringify(data), function(result, event) {
          dls.Model.responseHandler( dfd, result, event );
        } );
        return dfd.promise();
      },/* /saveSortOrder */

      setItemActive: function(data)
      {
        var dls = this,
            dfd = new $.Deferred();

        BoatRiggingChecklist_Controller.createChecklistMap(JSON.stringify(data), function(result, event) {
          dls.Model.responseHandler( dfd, result, event );
        });
        return dfd.promise();
      },/* /addItem */

      removeActiveItem: function( deleteId )
      {
        var dls = this,
            dfd = new $.Deferred();

        BoatRiggingChecklist_Controller.removeChecklistMap( deleteId, function(result, event) {
          dls.Model.responseHandler( dfd, result, event );
        });
        return dfd.promise();
      },/* /removeActiveItem */

      saveItem: function( itemData, mapData )
      {
        var dls = this,
            dfd = new $.Deferred();
        BoatRiggingChecklist_Controller.createItem( JSON.stringify(itemData), JSON.stringify(mapData), function(result, event) {
          dls.Model.responseHandler(dfd, result, event);
        });
        return dfd.promise();
      },/* /saveItem */

      updateItem: function( data )
      {
        console.log(data);
        var dls = this;
            dfd = new $.Deferred();
        BoatRiggingChecklist_Controller.updateItem( JSON.stringify(data), function(result, event) {
          dls.Model.responseHandler(dfd, result, event);
        });
        return dfd.promise();
      }, /* /updateItem */

      responseHandler: function(dfd, result, event)
      {
        if( event.status )
        {
          dfd.resolve(result);
        }
        else
        {
          message = event.message.indexOf('Logged in?') !== -1 ?
            ' Your session has expired.  Please refresh your browser and log in.' :
            event.message;
          dfd.reject(message);
        }
      }/* /responseHandler */

    }/* /Model */

  }


  /******************** Utility Function ************************/

  function createListData($items)
  {
    var data = [];
    $items.each( function(index, item) {
      var $item = $j(item);
      data.push( {
        Id: $item.data('checklist-map-id'),
        Rank__c: index
      });
    });
    return data;
  }

  function buildLineItem(lineItemData)
  {
    var $li = $('<li></li>'),
        $link = $('<a href="#" class="actionLink"></a>'),
        $details,
        $icon = $('<i class="fa"></i>'),
        lineClass = {'addItem': {'line': 'removed', 'icon': 'fa-arrow-right'},
                     'removeItem': {'line': 'added', 'icon': 'fa-close'} };

    if( lineItemData.linkAction === 'addItem' )
    {
      $details = $('<div></div>');
    }
    if( lineItemData.linkAction === 'removeItem')
    {
      $details = $('<a href="#" class="editItem"></a>');
      $details.attr('data-item-id', lineItemData.item_id);
    }
    $details.html(lineItemData.lineText);

    $icon.addClass( lineClass[lineItemData.linkAction].icon );

    $link.attr('data-item-id', lineItemData.item_id)
    .attr('data-action', lineItemData.linkAction)
    .append( $icon );

    $li.addClass( lineClass[lineItemData.linkAction].line )
    .attr('data-checklist-map-id', lineItemData.map_id)
    .append( $details )
    .append($link);
    return $li;
  }

  function buildNewLineItem( category )
  {
    var $li = $('<li></li>'),
        $input = $('<input type="text" placeholder="Add new item ..."></input>'),
        $cancelLink = $('<a href="#" class="cancelLink actionLink"><i class="fa fa-close"></i></a>'),
        $saveLink = $('<a href="#" class="saveItem actionLink disabled"><i class="fa fa-check"></i></a>');

    $cancelLink.attr('data-action', 'cancelItem');
    $saveLink.attr('data-action', 'saveItem')
    .attr('data-category', category);

    $li.addClass('new')
    .append( $input )
    .append( $cancelLink )
    .append( $saveLink );

    return $li;
  }

  function buildEditLineItem( $editLink )
  {
    var $li = $('<li></li>'),
        $input = $('<input type="text"></input>'),
        $cancelLink = $('<a href="#" class="cancelLink actionLink"><i class="fa fa-close"></i></a>'),
        $saveLink = $('<a href="#" class="saveItem actionLink"><i class="fa fa-check"></i></a>');

    $cancelLink.attr('data-action', 'cancelUpdate');

    $saveLink.attr('data-action', 'updateItem')
    .attr('data-item-id', $editLink.data('item-id') );
    $input.val( $editLink[0].innerText );

    $li.attr('data-checklist-map-id', $editLink.parent('li').data('checklist-map-id') )
    .addClass('editing')
    .data('original-li', $editLink.parent('li') )
    .append($input)
    .append($cancelLink)
    .append($saveLink);
    return $li;
  }

  function appendItemToList( $ul, $oldLI, lineItemData)
  {
    $oldLI.slideUp();
    $item = buildLineItem( lineItemData );
    $ul.append( $item );
    $ul = $('#'+$ul.attr('id'));
    $ul.animate({
      scrollTop: $ul.prop("scrollHeight")
    },
    500, function() {
      $item.removeClass();
      $oldLI.remove();
    });
  }


})(jQuery.noConflict(), window, document)
