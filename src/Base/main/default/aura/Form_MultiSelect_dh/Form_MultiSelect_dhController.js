({
	doInit : function(component, event, helper)
  {
    console.log('multi select do init');
    var value = component.get('v.value'),
        options = component.get('v.options');
        console.log( JSON.parse( JSON.stringify(options )));
    if( options === undefined || options === null)
    {
      options = [];
      component.set('v.options', options );
    }
    component.set('v.selectOptions', options );
    helper.setSelected( component );
	},

  afterScripts: function( component )
  {
    var select = component.find('lgnd-multi-select').getElement();
    $(select).chosen({
      placeholder_text_multiple: '-- Select --',
      width: "100%"});

    $(select).chosen().change( $A.getCallback( function() {
      component.set('v.value', $(this).val() );
    }));

    component.set('v.scriptsLoaded', true );
  },

  handleValueChange: function( component, event, helper )
  {
    console.log( 'multi select value changed' );
    var value = component.get('v.value');
    console.log( value );
    helper.setSelected( component );
  },

  onRender: function( component )
  {
    if( component.get('v.scriptsLoaded') == true )
    {
      var select = component.find('lgnd-multi-select').getElement();
      $(select).trigger("chosen:updated");
    }
  }
})