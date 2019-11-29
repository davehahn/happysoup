({
    findRecordsWithName: function(component, nameSearchString){
        if(!component.isValid()) return;

        var searchString = (nameSearchString || '').replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");

        // search salesforce for records with searchString as its name
        // and create a dropdown list of those found records
        var compEvent = component.getEvent("lightningLookupSearchStringEvent");
        compEvent.setParams({ "searchString" : searchString });
        compEvent.fire();
    },

    /*
     * Searches objects (server call)
     */
    searchAction : function(component, searchString, type, filters, pricebookId, secondaryField){
        console.log( 'LightningLookup searchAction ---- ' + searchString );
        console.log('type = ' + type);
        console.log('filters = ' + filters );
        console.log('pricebookId = ' + pricebookId );
        console.log('secondaryField = ' + secondaryField );
        if(!component.isValid()) return;
        console.log( 'component must be valid');
        var action = component.get("c.searchSObject");
        action.setParams({
            'type' : type,
            'searchString' : searchString,
            'serializedFilters': JSON.stringify(filters),
            'pricebookId' : pricebookId,
            'secondaryField' : secondaryField
        });

        action.setCallback(this, function(a) {
            if(a.error && a.error.length){
                return $A.error('Unexpected error: '+a.error[0].message);
            }
            var result = a.getReturnValue();
            var searchResults = {};
            if (result) {
                searchResults = JSON.parse(result);
            }
            console.log( searchResults );
            var compEvent = component.getEvent("lightningLookupResultsEvent");
            compEvent.setParams({ "searchResults" : searchResults });
            compEvent.fire();

        });
        $A.enqueueAction(action);
    },

    getLabel: function(component, type) {
        if(!component.isValid()) return;

        var action = component.get("c.getSObjectLabel");
        var self = this;
        action.setParams({
            'type' : type
        });
        return new Promise(function(resolve, reject) {
            action.setCallback(this, function(a) {
                if(a.error && a.error.length){
                    reject('Unexpected error: '+a.error[0].message);
                } else {
                    var label = a.getReturnValue();
                    resolve(label);
                }
            });
            $A.enqueueAction(action);
        });
    }
})