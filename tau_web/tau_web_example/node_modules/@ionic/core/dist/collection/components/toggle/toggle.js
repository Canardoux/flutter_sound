import { Component, Element, Event, Host, Prop, State, Watch, h } from '@stencil/core';
import { getIonMode } from '../../global/ionic-global';
import { getAriaLabel, renderHiddenInput } from '../../utils/helpers';
import { hapticSelection } from '../../utils/native/haptic';
import { createColorClasses, hostContext } from '../../utils/theme';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 *
 * @part track - The background track of the toggle.
 * @part handle - The toggle handle, or knob, used to change the checked state.
 */
export class Toggle {
  constructor() {
    this.inputId = `ion-tg-${toggleIds++}`;
    this.lastDrag = 0;
    this.activated = false;
    /**
     * The name of the control, which is submitted with the form data.
     */
    this.name = this.inputId;
    /**
     * If `true`, the toggle is selected.
     */
    this.checked = false;
    /**
     * If `true`, the user cannot interact with the toggle.
     */
    this.disabled = false;
    /**
     * The value of the toggle does not mean if it's checked or not, use the `checked`
     * property for that.
     *
     * The value of a toggle is analogous to the value of a `<input type="checkbox">`,
     * it's only used when the toggle participates in a native `<form>`.
     */
    this.value = 'on';
    this.onClick = (ev) => {
      ev.preventDefault();
      if (this.lastDrag + 300 < Date.now()) {
        this.checked = !this.checked;
      }
    };
    this.onFocus = () => {
      this.ionFocus.emit();
    };
    this.onBlur = () => {
      this.ionBlur.emit();
    };
  }
  checkedChanged(isChecked) {
    this.ionChange.emit({
      checked: isChecked,
      value: this.value
    });
  }
  disabledChanged() {
    this.emitStyle();
    if (this.gesture) {
      this.gesture.enable(!this.disabled);
    }
  }
  async connectedCallback() {
    this.gesture = (await import('../../utils/gesture')).createGesture({
      el: this.el,
      gestureName: 'toggle',
      gesturePriority: 100,
      threshold: 5,
      passive: false,
      onStart: () => this.onStart(),
      onMove: ev => this.onMove(ev),
      onEnd: ev => this.onEnd(ev),
    });
    this.disabledChanged();
  }
  disconnectedCallback() {
    if (this.gesture) {
      this.gesture.destroy();
      this.gesture = undefined;
    }
  }
  componentWillLoad() {
    this.emitStyle();
  }
  emitStyle() {
    this.ionStyle.emit({
      'interactive-disabled': this.disabled,
    });
  }
  onStart() {
    this.activated = true;
    // touch-action does not work in iOS
    this.setFocus();
  }
  onMove(detail) {
    if (shouldToggle(document, this.checked, detail.deltaX, -10)) {
      this.checked = !this.checked;
      hapticSelection();
    }
  }
  onEnd(ev) {
    this.activated = false;
    this.lastDrag = Date.now();
    ev.event.preventDefault();
    ev.event.stopImmediatePropagation();
  }
  getValue() {
    return this.value || '';
  }
  setFocus() {
    if (this.focusEl) {
      this.focusEl.focus();
    }
  }
  render() {
    const { activated, color, checked, disabled, el, inputId, name } = this;
    const mode = getIonMode(this);
    const { label, labelId, labelText } = getAriaLabel(el, inputId);
    const value = this.getValue();
    renderHiddenInput(true, el, name, (checked ? value : ''), disabled);
    return (h(Host, { onClick: this.onClick, "aria-labelledby": label ? labelId : null, "aria-checked": `${checked}`, "aria-hidden": disabled ? 'true' : null, role: "switch", class: createColorClasses(color, {
        [mode]: true,
        'in-item': hostContext('ion-item', el),
        'toggle-activated': activated,
        'toggle-checked': checked,
        'toggle-disabled': disabled,
        'interactive': true
      }) },
      h("div", { class: "toggle-icon", part: "track" },
        h("div", { class: "toggle-icon-wrapper" },
          h("div", { class: "toggle-inner", part: "handle" }))),
      h("label", { htmlFor: inputId }, labelText),
      h("input", { type: "checkbox", role: "switch", "aria-checked": `${checked}`, disabled: disabled, id: inputId, onFocus: () => this.onFocus(), onBlur: () => this.onBlur(), ref: focusEl => this.focusEl = focusEl })));
  }
  static get is() { return "ion-toggle"; }
  static get encapsulation() { return "shadow"; }
  static get originalStyleUrls() { return {
    "ios": ["toggle.ios.scss"],
    "md": ["toggle.md.scss"]
  }; }
  static get styleUrls() { return {
    "ios": ["toggle.ios.css"],
    "md": ["toggle.md.css"]
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
    "name": {
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
        "text": "The name of the control, which is submitted with the form data."
      },
      "attribute": "name",
      "reflect": false,
      "defaultValue": "this.inputId"
    },
    "checked": {
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
        "text": "If `true`, the toggle is selected."
      },
      "attribute": "checked",
      "reflect": false,
      "defaultValue": "false"
    },
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
        "text": "If `true`, the user cannot interact with the toggle."
      },
      "attribute": "disabled",
      "reflect": false,
      "defaultValue": "false"
    },
    "value": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string | null",
        "resolved": "null | string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The value of the toggle does not mean if it's checked or not, use the `checked`\nproperty for that.\n\nThe value of a toggle is analogous to the value of a `<input type=\"checkbox\">`,\nit's only used when the toggle participates in a native `<form>`."
      },
      "attribute": "value",
      "reflect": false,
      "defaultValue": "'on'"
    }
  }; }
  static get states() { return {
    "activated": {}
  }; }
  static get events() { return [{
      "method": "ionChange",
      "name": "ionChange",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the value property has changed."
      },
      "complexType": {
        "original": "ToggleChangeEventDetail",
        "resolved": "ToggleChangeEventDetail",
        "references": {
          "ToggleChangeEventDetail": {
            "location": "import",
            "path": "../../interface"
          }
        }
      }
    }, {
      "method": "ionFocus",
      "name": "ionFocus",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the toggle has focus."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionBlur",
      "name": "ionBlur",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the toggle loses focus."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
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
      "propName": "checked",
      "methodName": "checkedChanged"
    }, {
      "propName": "disabled",
      "methodName": "disabledChanged"
    }]; }
}
const shouldToggle = (doc, checked, deltaX, margin) => {
  const isRTL = doc.dir === 'rtl';
  if (checked) {
    return (!isRTL && (margin > deltaX)) ||
      (isRTL && (-margin < deltaX));
  }
  else {
    return (!isRTL && (-margin < deltaX)) ||
      (isRTL && (margin > deltaX));
  }
};
let toggleIds = 0;
