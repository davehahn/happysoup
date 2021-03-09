({
    /*
     * Executes the search server-side action
     */
    handleSearchStringEvent: function(component, event, helper){
        var type = component.get("v.type");
        var searchString = event.getParam("searchString");
        var filters = component.get("v.filters");
        var pricebookId = component.get("v.pricebookId");
        var secondaryField = component.get("v.secondaryField");
        console.log( 'search event searchString ', + searchString );
        if( searchString !== undefined && searchString.length > 2 )
		  helper.searchAction(component, searchString, type, filters, pricebookId, secondaryField);
    },

    handleResultsEvent: function(component, event, helper) {
        if(!component.isValid()) return;

        var searchResults = event.getParam("searchResults");
        var resultsComponent = component.find("results");

        // clear the currently displayed record list
        var resultListComponent = component.find("resultList");
        resultListComponent.set("v.body", []);

        // create a component for each found record and display those records
        // The reason we create components instead of using an <aura:iteration> tag and saving the searchResults to the component itself,
        // is that doing so causes performance issues.
        for (var i=0; i<searchResults.length; i++) {
            var result = searchResults[i];
            var resultValue;
            if (result.secondary == null) {
                resultValue = result.value;
            } else {
                resultValue = result.value + '\n' + result.secondary;
            }

            $A.createComponents(
                [
                    [ "aura:html", {
                        tag: "li",
                        HTMLAttributes: {
                            role: "presentation",
                            onclick: component.getReference("c.handleOptionSelection"),
                            "data-name": result.value,
                            "data-id": result.id
                        }
                    }],
                    [ "aura:html", {
                        tag: "span",
                        HTMLAttributes: {
                            class: "slds-lookup__item-action slds-media slds-media--center",
                            role: "option"
                        }
                    }],
                    [ "aura:html", {
                        tag: "div",
                        HTMLAttributes: {
                            class: "slds-media__body"
                        }
                    }],
                    [ "aura:html", {
                        tag: "div",
                        HTMLAttributes: {
                            class: "slds-lookup__result-text"
                        },
                        body: resultValue
                    }]
                ],
                function(components) {
                    var listItemComponent = components[0];
                    var lookupItemComponent = components[1];
                    var mediaBodyComponent = components[2];
                    var lookupResultComponent = components[3];

                    mediaBodyComponent.set("v.body", lookupResultComponent);
                    lookupItemComponent.set("v.body", mediaBodyComponent);
                    listItemComponent.set("v.body", lookupItemComponent);

                    var currentResultsComponent = resultListComponent.get("v.body");
                    currentResultsComponent.push(listItemComponent);
                    resultListComponent.set("v.body", currentResultsComponent);
                }
            );
        }

        // display the list of records iff at least one record was found
        if (searchResults.length > 0) {
            $A.util.addClass(resultsComponent, "slds-show");
        } else {
            $A.util.removeClass(resultsComponent, "slds-show");
        }
    },

    doInit: function(component, event, helper) {


      var globalId = component.getGlobalId(),
          isRequired = component.get("v.required"),
          jsonFilters = component.get("v.jsonFilters");

      component.set("v.globalId", globalId);

      if( isRequired )
      {
        var requiredComponent = component.find("required");
        $A.util.removeClass(requiredComponent, "slds-hide");
      }

      if( jsonFilters )
      {
        component.set('v.filters', JSON.parse(jsonFilters) );
      }

      if(!component.get("v.findLabel")) {
        return;
      }

      var type = component.get("v.type");
      helper.getLabel(component, type).then(
          function(label) {
              component.set('v.label', label);
          }
      );


    },

    initAfterJquery : function(component, event, helper){

        var globalId = component.get("v.globalId");

        // hide dropdown when clicking outside
        // and show dropdown when clicking back inside
        $(document).click(
            $A.getCallback(function() {
                component.hideDropdown();
            })
        );
        $("[id='lookup_" + globalId + "']").click(
            $A.getCallback(function(e) {
                e.stopPropagation();
            })
        );
        $("[id='lookupInput_" + globalId + "']").click(
            $A.getCallback(function(e) {
                e.stopPropagation();
                var nameSearchString = component.get("v.value");
                helper.findRecordsWithName(component, nameSearchString);
            })
        );

        // on entering a search string, find records

        $("[id='searchString" + globalId + "']").keyup(

            $A.getCallback(function(e) {
                               // do not search if escape is pressed
                if (e.keyCode == 27) {
                    return;
                }



                // if an sobject id is already saved, clear it
                component.set("v.sobjectId", "");

                var nameSearchString = $(this).val();
                component.set("v.toSearch", true);
                component.set("v.value", nameSearchString);
            })


        );
    },

    handleSearchStringChange: function(component, event, helper) {
        if (!component.get("v.toSearch")) {
            return;
        }
        var nameSearchString = component.get("v.value");

        // if an sobject id is already saved, clear it
        component.set("v.sobjectId", "");

        helper.findRecordsWithName(component, nameSearchString);
    },

    hideDropdown: function(component) {
        var resultsComponent = component.find("results");
        $A.util.removeClass(resultsComponent, "slds-show");
    },

    closeDropdownOnEscape: function(component, event, helper) {
        if (event.key == "Escape") {
            component.hideDropdown();
        }
    },

    handleOptionSelection: function(component, event, helper) {
        // hide dropdown list
        var resultListComponent = component.find("resultList");
        resultListComponent.set("v.body", []);
        component.hideDropdown();

        $option = $(event.currentTarget);
        var name = $option.attr("data-name")
        var id = $option.attr("data-id");

        // update value but do not search for new records since we are selecting a record
        component.set("v.toSearch", false);
        component.set("v.value", name);
        component.set("v.toSearch", true);

        component.set('v.sobjectId', id);

    },

    handleErrorChange: function(component) {
        var error = component.get("v.error");
        var errorComponent = component.find("error");
        var lookupComponent = component.find("lookup");

        if (error) {
            $A.util.addClass(lookupComponent, "slds-has-error");
            $A.util.removeClass(errorComponent, "slds-hide");
        } else {
            $A.util.removeClass(lookupComponent, "slds-has-error");
            $A.util.addClass(errorComponent, "slds-hide");
        }
    }

})