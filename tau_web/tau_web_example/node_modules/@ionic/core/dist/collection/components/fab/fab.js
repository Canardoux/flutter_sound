import { Component, Element, Host, Method, Prop, Watch, h } from '@stencil/core';
import { getIonMode } from '../../global/ionic-global';
export class Fab {
  constructor() {
    /**
     * If `true`, the fab will display on the edge of the header if
     * `vertical` is `"top"`, and on the edge of the footer if
     * it is `"bottom"`. Should be used with a `fixed` slot.
     */
    this.edge = false;
    /**
     * If `true`, both the `ion-fab-button` and all `ion-fab-list` inside `ion-fab` will become active.
     * That means `ion-fab-button` will become a `close` icon and `ion-fab-list` will become visible.
     */
    this.activated = false;
    this.onClick = () => {
      const hasList = !!this.el.querySelector('ion-fab-list');
      const getButton = this.getFab();
      const isButtonDisabled = getButton && getButton.disabled;
      if (hasList && !isButtonDisabled) {
        this.activated = !this.activated;
      }
    };
  }
  activatedChanged() {
    const activated = this.activated;
    const fab = this.getFab();
    if (fab) {
      fab.activated = activated;
    }
    Array.from(this.el.querySelectorAll('ion-fab-list')).forEach(list => {
      list.activated = activated;
    });
  }
  componentDidLoad() {
    if (this.activated) {
      this.activatedChanged();
    }
  }
  /**
   * Close an active FAB list container.
   */
  async close() {
    this.activated = false;
  }
  getFab() {
    return this.el.querySelector('ion-fab-button');
  }
  render() {
    const { horizontal, vertical, edge } = this;
    const mode = getIonMode(this);
    return (h(Host, { onClick: this.onClick, class: {
        [mode]: true,
        [`fab-horizontal-${horizontal}`]: horizontal !== undefined,
        [`fab-vertical-${vertical}`]: vertical !== undefined,
        'fab-edge': edge
      } },
      h("slot", null)));
  }
  static get is() { return "ion-fab"; }
  static get encapsulation() { return "shadow"; }
  static get originalStyleUrls() { return {
    "$": ["fab.scss"]
  }; }
  static get styleUrls() { return {
    "$": ["fab.css"]
  }; }
  static get properties() { return {
    "horizontal": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "'start' | 'end' | 'center'",
        "resolved": "\"center\" | \"end\" | \"start\" | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Where to align the fab horizontally in the viewport."
      },
      "attribute": "horizontal",
      "reflect": false
    },
    "vertical": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "'top' | 'bottom' | 'center'",
        "resolved": "\"bottom\" | \"center\" | \"top\" | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Where to align the fab vertically in the viewport."
      },
      "attribute": "vertical",
      "reflect": false
    },
    "edge": {
      "type": "boolean",
      "mutable": false,
      "complexType": {
        "original": "boolean",
        "resolved": "boolean",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "If `true`, the fab will display on the edge of the header if\n`vertical` is `\"top\"`, and on the edge of the footer if\nit is `\"bottom\"`. Should be used with a `fixed` slot."
      },
      "attribute": "edge",
      "reflect": false,
      "defaultValue": "false"
    },
    "activated": {
      "type": "boolean",
      "mutable": true,
      "complexType": {
        "original": "boolean",
        "resolved": "boolean",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "If `true`, both the `ion-fab-button` and all `ion-fab-list` inside `ion-fab` will become active.\nThat means `ion-fab-button` will become a `close` icon and `ion-fab-list` will become visible."
      },
      "attribute": "activated",
      "reflect": false,
      "defaultValue": "false"
    }
  }; }
  static get methods() { return {
    "close": {
      "complexType": {
        "signature": "() => Promise<void>",
        "parameters": [],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<void>"
      },
      "docs": {
        "text": "Close an active FAB list container.",
        "tags": []
      }
    }
  }; }
  static get elementRef() { return "el"; }
  static get watchers() { return [{
      "propName": "activated",
      "methodName": "activatedChanged"
    }]; }
}
