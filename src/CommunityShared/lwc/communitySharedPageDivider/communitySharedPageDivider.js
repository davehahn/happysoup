/**
 * Created by Tim on 2021-05-20.
 */

import { LightningElement, api } from "lwc";

export default class CommunitySharedPageDivider extends LightningElement {
  @api spaceAbove;
  @api spaceBelow;
  @api colour;
  @api thickness;
  @api sectionWidth;
  backgroundColour;

  renderedCallback() {
    this.backgroundColour = "border-top: " + this.thickness + "px solid " + this.colour;
  }
}
