({
	initNewService : function( component )
  {
    var action = component.get('c.initNewService' ), la;
    la = new LightningApex( this, action );
    return la.fire();
	},

  storeTask: function( component )
  {
    var tasks = component.get('v.tasks'),
        taskNumber = component.get('v.currentTaskNumber'),
        task = {
          name: component.get('v.currentTaskName'),
          estimate: component.get('v.currentTaskTimeEstimate'),
          complaint: component.get('v.currentTaskComplaint'),
        };

    if( ( task.name !== undefined &&  task.name !== null ) ||
        ( task.complaint !== undefined && task.complaint != null ) )
    {
      if( taskNumber === undefined || taskNumber === null )
      {
        task.number = tasks.length + 1;
        tasks.push(task);
      }
      else
      {
        task.number = taskNumber;
        tasks[ taskNumber - 1 ] = task;
        var pills = component.find('task-pill');
        if( pills.length === undefined )
          pills.getElement().classList.remove('selected');
        else
        {
          for( let p of pills )
          {
            var e = p.getElement();
            e.classList.remove('selected');
          }
        }
      }
      component.set('v.tasks', tasks);
    }
    component.set('v.currentTaskName', null );
    component.set('v.currentTaskComplaint', null );
    component.set('v.currentTaskTimeEstimate', null);
    component.set('v.currentTaskNumber', null);
  },

  saveService: function( component )
  {
    var action = component.get('c.createServiceERP'),
        riggerId = component.get('v.riggerId'),
        prepaids = component.get('v.prepaids'),
        la, erp, tasks = [];
    erp = {
      'sobjectType': 'AcctSeed__Project__c',
      'AcctSeed__Account__c': component.get('v.accountId'),
      'Serial_Number__c': component.get('v.serialId'),
      'GMBLASERP__Warehouse__c': component.get('v.warehouseId'),
      'Service_Date__c': new Date( component.get('v.startAt') ),
      'Customer_Notes__c': component.get('v.notes'),
      'Parking_Spot__c': component.get('v.parkingSpot')
    };

    for( let task of component.get('v.tasks') )
    {
      tasks.push({
        'sobjectType': 'AcctSeed__Project_Task__c',
        'Name': task.name,
        'Complaint_dh__c': task.complaint,
        'Estimated_Duration__c': task.estimate
      });
    }

    if (riggerId == '') riggerId = null;

    action.setParams({
      erp: erp,
      tasks: tasks,
      prepaids: JSON.stringify(prepaids),
      riggerId: riggerId
    });

    la = new LightningApex( this, action );
    return la.fire();
  },

  getRiggers: function( component )
  {
    var riggers = component.get('v.riggers'),
        warehouseId = component.get('v.warehouseId'),
        action = component.get('c.getRiggers'), la;
    component.set('v.riggers', null);
    component.set('v.riggerId', null);
    action.setParams({
      "warehouseId": warehouseId
    });
    la = new LightningApex( this, action );
    return la.fire();
  },

  getPrepaidsOnAccount: function( component )
  {
    var accountId = component.get('v.accountId'),
        action = component.get('c.getPrepaidsOnAccount'), la;
    action.setParams({
      accountId : accountId
    });
    la = new LightningApex( this, action );
    return la.fire();
  },

  createPrepaidTasks : function( component )
  {
    var prepaids = component.get('v.prepaids'),
        tasks    = component.get('v.tasks'),
        taskNumber = component.get('v.currentTaskNumber');

    for (var i = 0; i < prepaids.length; i++)
    {
      if (prepaids[i].toredeem > 0)
      {
        for (var j = 0; j < prepaids[i].toredeem; j++)
        {
          var foundTasks = 0;
          for (var k = 0; k < tasks.length; k++)
          {
            if (tasks[k].name == prepaids[i].product)
            {
              foundTasks++;
            }
          }
          if (foundTasks < prepaids[i].toredeem) {
            var task = {
              name: prepaids[i].product,
              estimate: prepaids[i].riggingTime,
              complaint: null,
              number: tasks.length + 1
            }
            tasks.push(task);
          }
        }
      }
    }
    component.set('v.tasks', tasks);
  },

  toggle : function(element, action) {
    if (action == 'open') {
      $A.util.removeClass(element, 'slds-is-closed');
      $A.util.addClass(element, 'slds-is-open');
    } else if (action == 'close') {
      $A.util.removeClass(element, 'slds-is-open');
      $A.util.addClass(element, 'slds-is-closed');
    }
  }
})