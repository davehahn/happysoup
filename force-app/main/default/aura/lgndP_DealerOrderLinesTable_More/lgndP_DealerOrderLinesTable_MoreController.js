({
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