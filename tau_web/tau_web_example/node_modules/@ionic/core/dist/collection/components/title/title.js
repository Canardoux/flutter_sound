import { Component, Element, Event, Host, Prop, Watch, h } from '@stencil/core';
import { getIonMode } from '../../global/ionic-global';
import { createColorClasses } from '../../utils/theme';
export class ToolbarTitle {
  sizeChanged() {
    this.emitStyle();
  }
  connectedCallback() {
    this.emitStyle();
  }
  emitStyle() {
    const size = this.getSize();
    this.ionStyle.emit({
      [`title-${size}`]: true
    });
  }
  getSize() {
    return (this.size !== undefined) ? this.size : 'default';
  }
  render() {
    const mode = getIonMode(this);
    const size = this.getSize();
    return (h(Host, { class: createColorClasses(this.color, {
        [mode]: true,
        [`title-${size}`]: true,
        'title-rtl': document.dir === 'rtl'
      }) },
      h("div", { class: "toolbar-title" },
        h("slot", null))));
  }
  static get is() { return "ion-title"; }
  static get encapsulation() { return "shadow"; }
  static get originalStyleUrls() { return {
    "ios": ["title.ios.scss"],
    "md": ["title.md.scss"]
  }; }
  static get styleUrls() { return {
    "ios": ["title.ios.css"],
    "md": ["title.md.css"]
  }; }
  static get properties() { return {
    "color": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "Color",
        "resolved": "string | undefined",
        "references": {
          "Color": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The color to use from your application's color palette.\nDefault options are: `\"primary\"`, `\"secondary\"`, `\"tertiary\"`, `\"success\"`, `\"warning\"`, `\"danger\"`, `\"light\"`, `\"medium\"`, and `\"dark\"`.\nFor more information on colors, see [theming](/docs/theming/basics)."
      },
      "attribute": "color",
      "reflect": true
    },
    "size": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "'large' | 'small'",
        "resolved": "\"large\" | \"small\" | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The size of the toolbar title."
      },
      "attribute": "size",
      "reflect": false
    }
  }; }
  static get events() { return [{
      "method": "ionStyle",
      "name": "ionStyle",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [{
            "text": undefined,
            "name": "internal"
          }],
        "text": "Emitted when the styles change."
      },
      "complexType": {
        "original": "StyleEventDetail",
        "resolved": "StyleEventDetail",
        "references": {
          "StyleEventDetail": {
            "location": "import",
            "path": "../../interface"
          }
        }
      }
    }]; }
  static get elementRef() { return "el"; }
  static get watchers() { return [{
      "propName": "size",
      "methodName": "sizeChanged"
    }]; }
}
