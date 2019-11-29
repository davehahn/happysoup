<aura:application extends="force:slds">
	<aura:attribute type="String" name="city" default="Whitefish" />
	<aura:attribute type="String" name="team" default="Production" />

	<aura:handler value="{!this}" name="init" action="{!c.init}" />

  <div class="slds-scope">
  	<div class="fullpage">
	  	<c:Rigger_Schedule_TV_mp city="{!v.city}" team="{!v.team}" />
	  </div>
	</div>

</aura:application>