import { Component, Host, Listen, Prop, h } from '@stencil/core';
import { getIonMode } from '../../global/ionic-global';
import { safeCall } from '../../utils/overlays';
import { getClassMap } from '../../utils/theme';
/**
 * @internal
 */
export class SelectPopover {
  constructor() {
    /** Array of options for the popover */
    this.options = [];
  }
  onSelect(ev) {
    const option = this.options.find(o => o.value === ev.target.value);
    if (option) {
      safeCall(option.handler);
    }
  }
  render() {
    const checkedOption = this.options.find(o => o.checked);
    const checkedValue = checkedOption ? checkedOption.value : undefined;
    return (h(Host, { class: getIonMode(this) },
      h("ion-list", null,
        this.header !== undefined && h("ion-list-header", null, this.header),
        (this.subHeader !== undefined || this.message !== undefined) &&
          h("ion-item", null,
            h("ion-label", { class: "ion-text-wrap" },
              this.subHeader !== undefined && h("h3", null, this.subHeader),
              this.message !== undefined && h("p", null, this.message))),
        h("ion-radio-group", { value: checkedValue }, this.options.map(option => h("ion-item", { class: getClassMap(option.cssClass) },
          h("ion-label", null, option.text),
          h("ion-radio", { value: option.value, disabled: option.disabled })))))));
  }
  static get is() { return "ion-select-popover"; }
  static get encapsulation() { return "scoped"; }
  static get originalStyleUrls() { return {
    "$": ["select-popover.scss"]
  }; }
  static get styleUrls() { return {
    "$": ["select-popover.css"]
  }; }
  static get properties() { return {
    "header": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string",
        "resolved": "string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Header text for the popover"
      },
      "attribute": "header",
      "reflect": false
    },
    "subHeader": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string",
        "resolved": "string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Subheader text for the popover"
      },
      "attribute": "sub-header",
      "reflect": false
    },
    "message": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string",
        "resolved": "string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Text for popover body"
      },
      "attribute": "message",
      "reflect": false
    },
    "options": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "SelectPopoverOption[]",
        "resolved": "SelectPopoverOption[]",
        "references": {
          "SelectPopoverOption": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "Array of options for the popover"
      },
      "defaultValue": "[]"
    }
  }; }
  static get listeners() { return [{
      "name": "ionChange",
      "method": "onSelect",
      "target": undefined,
      "capture": false,
      "passive": false
    }]; }
}
