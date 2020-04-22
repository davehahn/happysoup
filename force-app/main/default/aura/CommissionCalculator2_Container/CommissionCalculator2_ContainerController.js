/**
 * Created by dave on 2020-02-10.
 */

({
  doInit: function( component )
  {
    console.log( 'container.doInit');
    component.find("calc").doInit();
  }
});