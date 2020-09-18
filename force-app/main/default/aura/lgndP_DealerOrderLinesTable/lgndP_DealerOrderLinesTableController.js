({
  onRender: function( component, event, helper )
  {
    const boats = component.get('v.boats');
    let rows = document.querySelectorAll('td[data-label="Item Name"]');
    rows.forEach( row =>
    {
      if( row.children.length > 0 )
      {
        if(row.children[row.children.length - 1].classList.contains('kit-item') )
        {
          for( let i=0; i<row.children.length; i++ )
          {
            row.children[i].classList.add('last-kit-item');
          }
        }
      }
    });
  },

  handleTableAction: function( component, event, helper )
  {
    var menuSelection = event.getParam("value").split(':'),
        action = menuSelection[0],
        groupId = menuSelection[1],
        evt;
    if( action === 'delete' )
    {
      evt = component.getEvent('deleteEvent');
      evt.setParams({
        groupId: groupId,
        itemType: menuSelection[2]
      })
      .fire();
    }
    else
    {
      evt = component.getEvent('actionEvent');
        evt.setParams({
        id: groupId,
        action: action
      })
      .fire();
    }
  }
})