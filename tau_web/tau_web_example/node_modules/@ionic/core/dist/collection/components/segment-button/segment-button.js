import { Component, Element, Host, Prop, State, forceUpdate, h } from '@stencil/core';
import { getIonMode } from '../../global/ionic-global';
import { addEventListener, removeEventListener } from '../../utils/helpers';
import { hostContext } from '../../utils/theme';
let ids = 0;
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 *
 * @part native - The native HTML button element that wraps all child elements.
 * @part indicator - The indicator displayed on the checked segment button.
 * @part indicator-background - The background element for the indicator displayed on the checked segment button.
 */
export class SegmentButton {
  constructor() {
    this.segmentEl = null;
    this.checked = false;
    /**
     * If `true`, the user cannot interact with the segment button.
     */
    this.disabled = false;
    /**
     * Set the layout of the text and icon in the segment.
     */
    this.layout = 'icon-top';
    /**
     * The type of the button.
     */
    this.type = 'button';
    /**
     * The value of the segment button.
     */
    this.value = 'ion-sb-' + (ids++);
    this.updateStyle = () => {
      forceUpdate(this);
    };
    this.updateState = () => {
      if (this.segmentEl) {
        this.checked = this.segmentEl.value === this.value;
      }
    };
  }
  connectedCallback() {
    const segmentEl = this.segmentEl = this.el.closest('ion-segment');
    if (segmentEl) {
      this.updateState();
      addEventListener(segmentEl, 'ionSelect', this.updateState);
      addEventListener(segmentEl, 'ionStyle', this.updateStyle);
    }
  }
  disconnectedCallback() {
    const segmentEl = this.segmentEl;
    if (segmentEl) {
      removeEventListener(segmentEl, 'ionSelect', this.updateState);
      removeEventListener(segmentEl, 'ionStyle', this.updateStyle);
      this.segmentEl = null;
    }
  }
  get hasLabel() {
    return !!this.el.querySelector('ion-label');
  }
  get hasIcon() {
    return !!this.el.querySelector('ion-icon');
  }
  get tabIndex() {
    if (this.disabled) {
      return -1;
    }
    const hasTabIndex = this.el.hasAttribute('tabindex');
    if (hasTabIndex) {
      return this.el.getAttribute('tabindex');
    }
    return 0;
  }
  render() {
    const { checked, type, disabled, hasIcon, hasLabel, layout, segmentEl, tabIndex } = this;
    const mode = getIonMode(this);
    const hasSegmentColor = () => segmentEl !== null && segmentEl.color !== undefined;
    return (h(Host, { role: "tab", "aria-selected": checked ? 'true' : 'false', "aria-disabled": disabled ? 'true' : null, tabIndex: tabIndex, class: {
        [mode]: true,
        'in-toolbar': hostContext('ion-toolbar', this.el),
        'in-toolbar-color': hostContext('ion-toolbar[color]', this.el),
        'in-segment': hostContext('ion-segment', this.el),
        'in-segment-color': hasSegmentColor(),
        'segment-button-has-label': hasLabel,
        'segment-button-has-icon': hasIcon,
        'segment-button-has-label-only': hasLabel && !hasIcon,
        'segment-button-has-icon-only': hasIcon && !hasLabel,
        'segment-button-disabled': disabled,
        'segment-button-checked': checked,
        [`segment-button-layout-${layout}`]: true,
        'ion-activatable': true,
        'ion-activatable-instant': true,
        'ion-focusable': true,
      } },
      h("button", { type: type, tabIndex: -1, class: "button-native", part: "native", disabled: disabled },
        h("span", { class: "button-inner" },
          h("slot", null)),
        mode === 'md' && h("ion-ripple-effect", null)),
      h("div", { part: "indicator", class: {
          'segment-button-indicator': true,
          'segment-button-indicator-animated': true
        } },
        h("div", { part: "indicator-background", class: "segment-button-indicator-background" }))));
  }
  static get is() { return "ion-segment-button"; }
  static get encapsulation() { return "shadow"; }
  static get originalStyleUrls() { return {
    "ios": ["segment-button.ios.scss"],
    "md": ["segment-button.md.scss"]
  }; }
  static get styleUrls() { return {
    "ios": ["segment-button.ios.css"],
    "md": ["segment-button.md.css"]
  }; }
  static get properties() { return {
    "disabled": {
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
        "text": "If `true`, the user cannot interact with the segment button."
      },
      "attribute": "disabled",
      "reflect": false,
      "defaultValue": "false"
    },
    "layout": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "SegmentButtonLayout",
        "resolved": "\"icon-bottom\" | \"icon-end\" | \"icon-hide\" | \"icon-start\" | \"icon-top\" | \"label-hide\" | undefined",
        "references": {
          "SegmentButtonLayout": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Set the layout of the text and icon in the segment."
      },
      "attribute": "layout",
      "reflect": false,
      "defaultValue": "'icon-top'"
    },
    "type": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "'submit' | 'reset' | 'button'",
        "resolved": "\"button\" | \"reset\" | \"submit\"",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "The type of the button."
      },
      "attribute": "type",
      "reflect": false,
      "defaultValue": "'button'"
    },
    "value": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string",
        "resolved": "string",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "The value of the segment button."
      },
      "attribute": "value",
      "reflect": false,
      "defaultValue": "'ion-sb-' + (ids++)"
    }
  }; }
  static get states() { return {
    "checked": {}
  }; }
  static get elementRef() { return "el"; }
}
