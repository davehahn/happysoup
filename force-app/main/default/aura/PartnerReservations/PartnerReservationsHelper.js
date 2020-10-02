/**
 * Created by dave on 2020-10-01.
 */

({
  listNames: [
    'Available to Reserve',
    'Currently Reserved',
    'All Boats on Order'
  ],

  init: function( component )
  {
    let action = component.get('c.isFactoryStore');
    return new LightningApex( this, action ).fire();
  },

  fetchRecords: function( component )
  {
    let action = component.get('c.fetchOrderTypeDetails');

    action.setParams({
      orderType: 'boat'
    });

    return new Promise( (resolve, reject) => {
      new LightningApex( this, action ).fire()
      .then(
        $A.getCallback( (result) => {
          resolve( this.groupRecords( result) );
        }),
        $A.getCallback( (err) => {
          reject( err );
        })
      );
    });

  },

  groupRecords: function( records )
  {
    let grouped = {};
    records.forEach( record => {
      if( Object.keys(grouped).indexOf( record.majorItemName) < 0 )
      {
         grouped[ record.majorItemName ] = [];
      }
      grouped[ record.majorItemName ].push( record );
    });

    return Object.keys( grouped )
    .reduce( ( result, key ) => {
      result.push({
        name: key,
        records: grouped[key],
        count: grouped[key].length
      });
      return result;
    }, [] );
  },

  filterResults: function( component )
  {
    let self = this;
    const listName = component.get('v.selectedList');
    switch( this.listNames.indexOf( listName) )
    {
      case 0:
        self.filterForAvailable( component );
        break;
      case 1:
        self.filterForReserved( component );
        break;
      case 2:
        component.set('v.filteredRecords', component.get('v.allRecords') );
        break;
      default:
        return false;
    }
  },

  filterForAvailable: function( component )
  {
   console.log( 'filter for available' );
   const allRecords = component.get('v.allRecords'),
             checkAttrName = component.get('v.isFactoryStore') ?
               'retailErpId' : 'reservedForCustomerId';
        [];
       let filtered = allRecords.reduce( (result, boatModel) => {
         console.log( boatModel );
         const check = boatModel.records.filter( rec => rec[checkAttrName] === null );
         console.log( check );
         if( check.length > 0 )
         {
           result.push({
             name: boatModel.name,
             records: check,
             count: check.length
           });
         }
         return result;
       }, [] );
       component.set('v.filteredRecords', filtered );
  },

  filterForReserved: function( component )
  {
    console.log( 'filter for reserved' );
    const allRecords = component.get('v.allRecords'),
          checkAttrName = component.get('v.isFactoryStore') ?
            'retailErpId' : 'reservedForCustomerId';
     [];
    let filtered = allRecords.reduce( (result, boatModel) => {
      console.log( boatModel );
      const check = boatModel.records.filter( rec => rec[checkAttrName] !== null );
      console.log( check );
      if( check.length > 0 )
      {
        result.push({
          name: boatModel.name,
          records: check,
          count: check.length
        });
      }
      return result;
    }, [] );
    component.set('v.filteredRecords', filtered );
  }
});