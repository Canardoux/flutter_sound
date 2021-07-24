import { Component, Element, Host, Listen, h } from '@stencil/core';
import { getIonMode } from '../../global/ionic-global';
/**
 * @part icon - The icon of the reorder handle (uses ion-icon).
 */
export class Reorder {
  onClick(ev) {
    const reorderGroup = this.el.closest('ion-reorder-group');
    ev.preventDefault();
    // Only stop event propagation if the reorder is inside of an enabled
    // reorder group. This allows interaction with clickable children components.
    if (!reorderGroup || !reorderGroup.disabled) {
      ev.stopImmediatePropagation();
    }
  }
  render() {
    const mode = getIonMode(this);
    const reorderIcon = mode === 'ios' ? 'reorder-three-outline' : 'reorder-two-sharp';
    return (h(Host, { class: mode },
      h("slot", null,
        h("ion-icon", { name: reorderIcon, lazy: false, class: "reorder-icon", part: "icon" }))));
  }
  static get is() { return "ion-reorder"; }
  static get encapsulation() { return "shadow"; }
  static get originalStyleUrls() { return {
    "ios": ["reorder.ios.scss"],
    "md": ["reorder.md.scss"]
  }; }
  static get styleUrls() { return {
    "ios": ["reorder.ios.css"],
    "md": ["reorder.md.css"]
  }; }
  static get elementRef() { return "el"; }
  static get listeners() { return [{
      "name": "click",
      "method": "onClick",
      "target": undefined,
      "capture": true,
      "passive": false
    }]; }
}
