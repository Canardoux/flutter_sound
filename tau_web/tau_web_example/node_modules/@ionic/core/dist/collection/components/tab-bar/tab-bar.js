import { Component, Element, Event, Host, Prop, State, Watch, h } from '@stencil/core';
import { getIonMode } from '../../global/ionic-global';
import { createColorClasses } from '../../utils/theme';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export class TabBar {
  constructor() {
    this.keyboardVisible = false;
    /**
     * If `true`, the tab bar will be translucent.
     * Only applies when the mode is `"ios"` and the device supports
     * [`backdrop-filter`](https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter#Browser_compatibility).
     */
    this.translucent = false;
  }
  selectedTabChanged() {
    if (this.selectedTab !== undefined) {
      this.ionTabBarChanged.emit({
        tab: this.selectedTab
      });
    }
  }
  componentWillLoad() {
    this.selectedTabChanged();
  }
  connectedCallback() {
    if (typeof window !== 'undefined') {
      this.keyboardWillShowHandler = () => {
        if (this.el.getAttribute('slot') !== 'top') {
          this.keyboardVisible = true;
        }
      };
      this.keyboardWillHideHandler = () => {
        setTimeout(() => this.keyboardVisible = false, 50);
      };
      window.addEventListener('keyboardWillShow', this.keyboardWillShowHandler);
      window.addEventListener('keyboardWillHide', this.keyboardWillHideHandler);
    }
  }
  disconnectedCallback() {
    if (typeof window !== 'undefined') {
      window.removeEventListener('keyboardWillShow', this.keyboardWillShowHandler);
      window.removeEventListener('keyboardWillHide', this.keyboardWillHideHandler);
      this.keyboardWillShowHandler = this.keyboardWillHideHandler = undefined;
    }
  }
  render() {
    const { color, translucent, keyboardVisible } = this;
    const mode = getIonMode(this);
    return (h(Host, { role: "tablist", "aria-hidden": keyboardVisible ? 'true' : null, class: createColorClasses(color, {
        [mode]: true,
        'tab-bar-translucent': translucent,
        'tab-bar-hidden': keyboardVisible,
      }) },
      h("slot", null)));
  }
  static get is() { return "ion-tab-bar"; }
  static get encapsulation() { return "shadow"; }
  static get originalStyleUrls() { return {
    "ios": ["tab-bar.ios.scss"],
    "md": ["tab-bar.md.scss"]
  }; }
  static get styleUrls() { return {
    "ios": ["tab-bar.ios.css"],
    "md": ["tab-bar.md.css"]
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
    "selectedTab": {
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
        "text": "The selected tab component"
      },
      "attribute": "selected-tab",
      "reflect": false
    },
    "translucent": {
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
        "text": "If `true`, the tab bar will be translucent.\nOnly applies when the mode is `\"ios\"` and the device supports\n[`backdrop-filter`](https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter#Browser_compatibility)."
      },
      "attribute": "translucent",
      "reflect": false,
      "defaultValue": "false"
    }
  }; }
  static get states() { return {
    "keyboardVisible": {}
  }; }
  static get events() { return [{
      "method": "ionTabBarChanged",
      "name": "ionTabBarChanged",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [{
            "text": undefined,
            "name": "internal"
          }],
        "text": ""
      },
      "complexType": {
        "original": "TabBarChangedEventDetail",
        "resolved": "TabBarChangedEventDetail",
        "references": {
          "TabBarChangedEventDetail": {
            "location": "import",
            "path": "../../interface"
          }
        }
      }
    }]; }
  static get elementRef() { return "el"; }
  static get watchers() { return [{
      "propName": "selectedTab",
      "methodName": "selectedTabChanged"
    }]; }
}
