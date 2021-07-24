import { Component, Element, Event, Host, Listen, Method, Prop, Watch, forceUpdate, h } from '@stencil/core';
import { getIonMode } from '../../global/ionic-global';
import { createButtonActiveGesture } from '../../utils/gesture/button-active';
import { BACKDROP, dismiss, eventMethod, isCancel, prepareOverlay, present, safeCall } from '../../utils/overlays';
import { sanitizeDOMString } from '../../utils/sanitization';
import { getClassMap } from '../../utils/theme';
import { iosEnterAnimation } from './animations/ios.enter';
import { iosLeaveAnimation } from './animations/ios.leave';
import { mdEnterAnimation } from './animations/md.enter';
import { mdLeaveAnimation } from './animations/md.leave';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export class Alert {
  constructor() {
    this.processedInputs = [];
    this.processedButtons = [];
    this.presented = false;
    /**
     * If `true`, the keyboard will be automatically dismissed when the overlay is presented.
     */
    this.keyboardClose = true;
    /**
     * Array of buttons to be added to the alert.
     */
    this.buttons = [];
    /**
     * Array of input to show in the alert.
     */
    this.inputs = [];
    /**
     * If `true`, the alert will be dismissed when the backdrop is clicked.
     */
    this.backdropDismiss = true;
    /**
     * If `true`, the alert will be translucent.
     * Only applies when the mode is `"ios"` and the device supports
     * [`backdrop-filter`](https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter#Browser_compatibility).
     */
    this.translucent = false;
    /**
     * If `true`, the alert will animate.
     */
    this.animated = true;
    this.onBackdropTap = () => {
      this.dismiss(undefined, BACKDROP);
    };
    this.dispatchCancelHandler = (ev) => {
      const role = ev.detail.role;
      if (isCancel(role)) {
        const cancelButton = this.processedButtons.find(b => b.role === 'cancel');
        this.callButtonHandler(cancelButton);
      }
    };
  }
  onKeydown(ev) {
    const inputTypes = new Set(this.processedInputs.map(i => i.type));
    // The only inputs we want to navigate between using arrow keys are the radios
    // ignore the keydown event if it is not on a radio button
    if (!inputTypes.has('radio')
      || (ev.target && !this.el.contains(ev.target))
      || ev.target.classList.contains('alert-button')) {
      return;
    }
    // Get all radios inside of the radio group and then
    // filter out disabled radios since we need to skip those
    const query = this.el.querySelectorAll('.alert-radio');
    const radios = Array.from(query).filter(radio => !radio.disabled);
    // The focused radio is the one that shares the same id as
    // the event target
    const index = radios.findIndex(radio => radio.id === ev.target.id);
    // We need to know what the next radio element should
    // be in order to change the focus
    let nextEl;
    // If hitting arrow down or arrow right, move to the next radio
    // If we're on the last radio, move to the first radio
    if (['ArrowDown', 'ArrowRight'].includes(ev.code)) {
      nextEl = (index === radios.length - 1)
        ? radios[0]
        : radios[index + 1];
    }
    // If hitting arrow up or arrow left, move to the previous radio
    // If we're on the first radio, move to the last radio
    if (['ArrowUp', 'ArrowLeft'].includes(ev.code)) {
      nextEl = (index === 0)
        ? radios[radios.length - 1]
        : radios[index - 1];
    }
    if (nextEl && radios.includes(nextEl)) {
      const nextProcessed = this.processedInputs.find(input => input.id === (nextEl === null || nextEl === void 0 ? void 0 : nextEl.id));
      if (nextProcessed) {
        this.rbClick(nextProcessed);
        nextEl.focus();
      }
    }
  }
  buttonsChanged() {
    const buttons = this.buttons;
    this.processedButtons = buttons.map(btn => {
      return (typeof btn === 'string')
        ? { text: btn, role: btn.toLowerCase() === 'cancel' ? 'cancel' : undefined }
        : btn;
    });
  }
  inputsChanged() {
    const inputs = this.inputs;
    // Get the first input that is not disabled and the checked one
    // If an enabled checked input exists, set it to be the focusable input
    // otherwise we default to focus the first input
    // This will only be used when the input is type radio
    const first = inputs.find(input => !input.disabled);
    const checked = inputs.find(input => input.checked && !input.disabled);
    const focusable = checked || first;
    // An alert can be created with several different inputs. Radios,
    // checkboxes and inputs are all accepted, but they cannot be mixed.
    const inputTypes = new Set(inputs.map(i => i.type));
    if (inputTypes.has('checkbox') && inputTypes.has('radio')) {
      console.warn(`Alert cannot mix input types: ${(Array.from(inputTypes.values()).join('/'))}. Please see alert docs for more info.`);
    }
    this.inputType = inputTypes.values().next().value;
    this.processedInputs = inputs.map((i, index) => ({
      type: i.type || 'text',
      name: i.name || `${index}`,
      placeholder: i.placeholder || '',
      value: i.value,
      label: i.label,
      checked: !!i.checked,
      disabled: !!i.disabled,
      id: i.id || `alert-input-${this.overlayIndex}-${index}`,
      handler: i.handler,
      min: i.min,
      max: i.max,
      cssClass: i.cssClass || '',
      attributes: i.attributes || {},
      tabindex: (i.type === 'radio' && i !== focusable) ? -1 : 0
    }));
  }
  connectedCallback() {
    prepareOverlay(this.el);
  }
  componentWillLoad() {
    this.inputsChanged();
    this.buttonsChanged();
  }
  disconnectedCallback() {
    if (this.gesture) {
      this.gesture.destroy();
      this.gesture = undefined;
    }
  }
  componentDidLoad() {
    /**
     * Do not create gesture if:
     * 1. A gesture already exists
     * 2. App is running in MD mode
     * 3. A wrapper ref does not exist
     */
    if (this.gesture || getIonMode(this) === 'md' || !this.wrapperEl) {
      return;
    }
    this.gesture = createButtonActiveGesture(this.wrapperEl, (refEl) => refEl.classList.contains('alert-button'));
    this.gesture.enable(true);
  }
  /**
   * Present the alert overlay after it has been created.
   */
  present() {
    return present(this, 'alertEnter', iosEnterAnimation, mdEnterAnimation);
  }
  /**
   * Dismiss the alert overlay after it has been presented.
   *
   * @param data Any data to emit in the dismiss events.
   * @param role The role of the element that is dismissing the alert.
   * This can be useful in a button handler for determining which button was
   * clicked to dismiss the alert.
   * Some examples include: ``"cancel"`, `"destructive"`, "selected"`, and `"backdrop"`.
   */
  dismiss(data, role) {
    return dismiss(this, data, role, 'alertLeave', iosLeaveAnimation, mdLeaveAnimation);
  }
  /**
   * Returns a promise that resolves when the alert did dismiss.
   */
  onDidDismiss() {
    return eventMethod(this.el, 'ionAlertDidDismiss');
  }
  /**
   * Returns a promise that resolves when the alert will dismiss.
   */
  onWillDismiss() {
    return eventMethod(this.el, 'ionAlertWillDismiss');
  }
  rbClick(selectedInput) {
    for (const input of this.processedInputs) {
      input.checked = input === selectedInput;
      input.tabindex = input === selectedInput ? 0 : -1;
    }
    this.activeId = selectedInput.id;
    safeCall(selectedInput.handler, selectedInput);
    forceUpdate(this);
  }
  cbClick(selectedInput) {
    selectedInput.checked = !selectedInput.checked;
    safeCall(selectedInput.handler, selectedInput);
    forceUpdate(this);
  }
  buttonClick(button) {
    const role = button.role;
    const values = this.getValues();
    if (isCancel(role)) {
      return this.dismiss({ values }, role);
    }
    const returnData = this.callButtonHandler(button, values);
    if (returnData !== false) {
      return this.dismiss(Object.assign({ values }, returnData), button.role);
    }
    return Promise.resolve(false);
  }
  callButtonHandler(button, data) {
    if (button && button.handler) {
      // a handler has been provided, execute it
      // pass the handler the values from the inputs
      const returnData = safeCall(button.handler, data);
      if (returnData === false) {
        // if the return value of the handler is false then do not dismiss
        return false;
      }
      if (typeof returnData === 'object') {
        return returnData;
      }
    }
    return {};
  }
  getValues() {
    if (this.processedInputs.length === 0) {
      // this is an alert without any options/inputs at all
      return undefined;
    }
    if (this.inputType === 'radio') {
      // this is an alert with radio buttons (single value select)
      // return the one value which is checked, otherwise undefined
      const checkedInput = this.processedInputs.find(i => !!i.checked);
      return checkedInput ? checkedInput.value : undefined;
    }
    if (this.inputType === 'checkbox') {
      // this is an alert with checkboxes (multiple value select)
      // return an array of all the checked values
      return this.processedInputs.filter(i => i.checked).map(i => i.value);
    }
    // this is an alert with text inputs
    // return an object of all the values with the input name as the key
    const values = {};
    this.processedInputs.forEach(i => {
      values[i.name] = i.value || '';
    });
    return values;
  }
  renderAlertInputs() {
    switch (this.inputType) {
      case 'checkbox': return this.renderCheckbox();
      case 'radio': return this.renderRadio();
      default: return this.renderInput();
    }
  }
  renderCheckbox() {
    const inputs = this.processedInputs;
    const mode = getIonMode(this);
    if (inputs.length === 0) {
      return null;
    }
    return (h("div", { class: "alert-checkbox-group" }, inputs.map(i => (h("button", { type: "button", onClick: () => this.cbClick(i), "aria-checked": `${i.checked}`, id: i.id, disabled: i.disabled, tabIndex: i.tabindex, role: "checkbox", class: Object.assign(Object.assign({}, getClassMap(i.cssClass)), { 'alert-tappable': true, 'alert-checkbox': true, 'alert-checkbox-button': true, 'ion-focusable': true, 'alert-checkbox-button-disabled': i.disabled || false }) },
      h("div", { class: "alert-button-inner" },
        h("div", { class: "alert-checkbox-icon" },
          h("div", { class: "alert-checkbox-inner" })),
        h("div", { class: "alert-checkbox-label" }, i.label)),
      mode === 'md' && h("ion-ripple-effect", null))))));
  }
  renderRadio() {
    const inputs = this.processedInputs;
    if (inputs.length === 0) {
      return null;
    }
    return (h("div", { class: "alert-radio-group", role: "radiogroup", "aria-activedescendant": this.activeId }, inputs.map(i => (h("button", { type: "button", onClick: () => this.rbClick(i), "aria-checked": `${i.checked}`, disabled: i.disabled, id: i.id, tabIndex: i.tabindex, class: Object.assign(Object.assign({}, getClassMap(i.cssClass)), { 'alert-radio-button': true, 'alert-tappable': true, 'alert-radio': true, 'ion-focusable': true, 'alert-radio-button-disabled': i.disabled || false }), role: "radio" },
      h("div", { class: "alert-button-inner" },
        h("div", { class: "alert-radio-icon" },
          h("div", { class: "alert-radio-inner" })),
        h("div", { class: "alert-radio-label" }, i.label)))))));
  }
  renderInput() {
    const inputs = this.processedInputs;
    if (inputs.length === 0) {
      return null;
    }
    return (h("div", { class: "alert-input-group" }, inputs.map(i => {
      var _a, _b, _c, _d;
      if (i.type === 'textarea') {
        return (h("div", { class: "alert-input-wrapper" },
          h("textarea", Object.assign({ placeholder: i.placeholder, value: i.value, id: i.id, tabIndex: i.tabindex }, i.attributes, { disabled: (_b = (_a = i.attributes) === null || _a === void 0 ? void 0 : _a.disabled) !== null && _b !== void 0 ? _b : i.disabled, class: inputClass(i), onInput: e => {
              var _a;
              i.value = e.target.value;
              if ((_a = i.attributes) === null || _a === void 0 ? void 0 : _a.onInput) {
                i.attributes.onInput(e);
              }
            } }))));
      }
      else {
        return (h("div", { class: "alert-input-wrapper" },
          h("input", Object.assign({ placeholder: i.placeholder, type: i.type, min: i.min, max: i.max, value: i.value, id: i.id, tabIndex: i.tabindex }, i.attributes, { disabled: (_d = (_c = i.attributes) === null || _c === void 0 ? void 0 : _c.disabled) !== null && _d !== void 0 ? _d : i.disabled, class: inputClass(i), onInput: e => {
              var _a;
              i.value = e.target.value;
              if ((_a = i.attributes) === null || _a === void 0 ? void 0 : _a.onInput) {
                i.attributes.onInput(e);
              }
            } }))));
      }
    })));
  }
  renderAlertButtons() {
    const buttons = this.processedButtons;
    const mode = getIonMode(this);
    const alertButtonGroupClass = {
      'alert-button-group': true,
      'alert-button-group-vertical': buttons.length > 2
    };
    return (h("div", { class: alertButtonGroupClass }, buttons.map(button => h("button", { type: "button", class: buttonClass(button), tabIndex: 0, onClick: () => this.buttonClick(button) },
      h("span", { class: "alert-button-inner" }, button.text),
      mode === 'md' && h("ion-ripple-effect", null)))));
  }
  render() {
    const { overlayIndex, header, subHeader } = this;
    const mode = getIonMode(this);
    const hdrId = `alert-${overlayIndex}-hdr`;
    const subHdrId = `alert-${overlayIndex}-sub-hdr`;
    const msgId = `alert-${overlayIndex}-msg`;
    return (h(Host, { role: "dialog", "aria-modal": "true", tabindex: "-1", style: {
        zIndex: `${20000 + overlayIndex}`,
      }, class: Object.assign(Object.assign({}, getClassMap(this.cssClass)), { [mode]: true, 'alert-translucent': this.translucent }), onIonAlertWillDismiss: this.dispatchCancelHandler, onIonBackdropTap: this.onBackdropTap },
      h("ion-backdrop", { tappable: this.backdropDismiss }),
      h("div", { tabindex: "0" }),
      h("div", { class: "alert-wrapper ion-overlay-wrapper", ref: el => this.wrapperEl = el },
        h("div", { class: "alert-head" },
          header && h("h2", { id: hdrId, class: "alert-title" }, header),
          subHeader && h("h2", { id: subHdrId, class: "alert-sub-title" }, subHeader)),
        h("div", { id: msgId, class: "alert-message", innerHTML: sanitizeDOMString(this.message) }),
        this.renderAlertInputs(),
        this.renderAlertButtons()),
      h("div", { tabindex: "0" })));
  }
  static get is() { return "ion-alert"; }
  static get encapsulation() { return "scoped"; }
  static get originalStyleUrls() { return {
    "ios": ["alert.ios.scss"],
    "md": ["alert.md.scss"]
  }; }
  static get styleUrls() { return {
    "ios": ["alert.ios.css"],
    "md": ["alert.md.css"]
  }; }
  static get properties() { return {
    "overlayIndex": {
      "type": "number",
      "mutable": false,
      "complexType": {
        "original": "number",
        "resolved": "number",
        "references": {}
      },
      "required": true,
      "optional": false,
      "docs": {
        "tags": [{
            "text": undefined,
            "name": "internal"
          }],
        "text": ""
      },
      "attribute": "overlay-index",
      "reflect": false
    },
    "keyboardClose": {
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
        "text": "If `true`, the keyboard will be automatically dismissed when the overlay is presented."
      },
      "attribute": "keyboard-close",
      "reflect": false,
      "defaultValue": "true"
    },
    "enterAnimation": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "AnimationBuilder",
        "resolved": "((baseEl: any, opts?: any) => Animation) | undefined",
        "references": {
          "AnimationBuilder": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Animation to use when the alert is presented."
      }
    },
    "leaveAnimation": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "AnimationBuilder",
        "resolved": "((baseEl: any, opts?: any) => Animation) | undefined",
        "references": {
          "AnimationBuilder": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Animation to use when the alert is dismissed."
      }
    },
    "cssClass": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string | string[]",
        "resolved": "string | string[] | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Additional classes to apply for custom CSS. If multiple classes are\nprovided they should be separated by spaces."
      },
      "attribute": "css-class",
      "reflect": false
    },
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
        "text": "The main title in the heading of the alert."
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
        "text": "The subtitle in the heading of the alert. Displayed under the title."
      },
      "attribute": "sub-header",
      "reflect": false
    },
    "message": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string | IonicSafeString",
        "resolved": "IonicSafeString | string | undefined",
        "references": {
          "IonicSafeString": {
            "location": "import",
            "path": "../../utils/sanitization"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The main message to be displayed in the alert.\n`message` can accept either plaintext or HTML as a string.\nTo display characters normally reserved for HTML, they\nmust be escaped. For example `<Ionic>` would become\n`&lt;Ionic&gt;`\n\nFor more information: [Security Documentation](https://ionicframework.com/docs/faq/security)"
      },
      "attribute": "message",
      "reflect": false
    },
    "buttons": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "(AlertButton | string)[]",
        "resolved": "(string | AlertButton)[]",
        "references": {
          "AlertButton": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "Array of buttons to be added to the alert."
      },
      "defaultValue": "[]"
    },
    "inputs": {
      "type": "unknown",
      "mutable": true,
      "complexType": {
        "original": "AlertInput[]",
        "resolved": "AlertInput[]",
        "references": {
          "AlertInput": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "Array of input to show in the alert."
      },
      "defaultValue": "[]"
    },
    "backdropDismiss": {
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
        "text": "If `true`, the alert will be dismissed when the backdrop is clicked."
      },
      "attribute": "backdrop-dismiss",
      "reflect": false,
      "defaultValue": "true"
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
        "text": "If `true`, the alert will be translucent.\nOnly applies when the mode is `\"ios\"` and the device supports\n[`backdrop-filter`](https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter#Browser_compatibility)."
      },
      "attribute": "translucent",
      "reflect": false,
      "defaultValue": "false"
    },
    "animated": {
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
        "text": "If `true`, the alert will animate."
      },
      "attribute": "animated",
      "reflect": false,
      "defaultValue": "true"
    }
  }; }
  static get events() { return [{
      "method": "didPresent",
      "name": "ionAlertDidPresent",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted after the alert has presented."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "willPresent",
      "name": "ionAlertWillPresent",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted before the alert has presented."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "willDismiss",
      "name": "ionAlertWillDismiss",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted before the alert has dismissed."
      },
      "complexType": {
        "original": "OverlayEventDetail",
        "resolved": "OverlayEventDetail<any>",
        "references": {
          "OverlayEventDetail": {
            "location": "import",
            "path": "../../interface"
          }
        }
      }
    }, {
      "method": "didDismiss",
      "name": "ionAlertDidDismiss",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted after the alert has dismissed."
      },
      "complexType": {
        "original": "OverlayEventDetail",
        "resolved": "OverlayEventDetail<any>",
        "references": {
          "OverlayEventDetail": {
            "location": "import",
            "path": "../../interface"
          }
        }
      }
    }]; }
  static get methods() { return {
    "present": {
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
        "text": "Present the alert overlay after it has been created.",
        "tags": []
      }
    },
    "dismiss": {
      "complexType": {
        "signature": "(data?: any, role?: string | undefined) => Promise<boolean>",
        "parameters": [{
            "tags": [{
                "text": "data Any data to emit in the dismiss events.",
                "name": "param"
              }],
            "text": "Any data to emit in the dismiss events."
          }, {
            "tags": [{
                "text": "role The role of the element that is dismissing the alert.\nThis can be useful in a button handler for determining which button was\nclicked to dismiss the alert.\nSome examples include: ``\"cancel\"`, `\"destructive\"`, \"selected\"`, and `\"backdrop\"`.",
                "name": "param"
              }],
            "text": "The role of the element that is dismissing the alert.\nThis can be useful in a button handler for determining which button was\nclicked to dismiss the alert.\nSome examples include: ``\"cancel\"`, `\"destructive\"`, \"selected\"`, and `\"backdrop\"`."
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "Dismiss the alert overlay after it has been presented.",
        "tags": [{
            "name": "param",
            "text": "data Any data to emit in the dismiss events."
          }, {
            "name": "param",
            "text": "role The role of the element that is dismissing the alert.\nThis can be useful in a button handler for determining which button was\nclicked to dismiss the alert.\nSome examples include: ``\"cancel\"`, `\"destructive\"`, \"selected\"`, and `\"backdrop\"`."
          }]
      }
    },
    "onDidDismiss": {
      "complexType": {
        "signature": "<T = any>() => Promise<OverlayEventDetail<T>>",
        "parameters": [],
        "references": {
          "Promise": {
            "location": "global"
          },
          "OverlayEventDetail": {
            "location": "import",
            "path": "../../interface"
          },
          "T": {
            "location": "global"
          }
        },
        "return": "Promise<OverlayEventDetail<T>>"
      },
      "docs": {
        "text": "Returns a promise that resolves when the alert did dismiss.",
        "tags": []
      }
    },
    "onWillDismiss": {
      "complexType": {
        "signature": "<T = any>() => Promise<OverlayEventDetail<T>>",
        "parameters": [],
        "references": {
          "Promise": {
            "location": "global"
          },
          "OverlayEventDetail": {
            "location": "import",
            "path": "../../interface"
          },
          "T": {
            "location": "global"
          }
        },
        "return": "Promise<OverlayEventDetail<T>>"
      },
      "docs": {
        "text": "Returns a promise that resolves when the alert will dismiss.",
        "tags": []
      }
    }
  }; }
  static get elementRef() { return "el"; }
  static get watchers() { return [{
      "propName": "buttons",
      "methodName": "buttonsChanged"
    }, {
      "propName": "inputs",
      "methodName": "inputsChanged"
    }]; }
  static get listeners() { return [{
      "name": "keydown",
      "method": "onKeydown",
      "target": "document",
      "capture": false,
      "passive": false
    }]; }
}
const inputClass = (input) => {
  var _a, _b, _c;
  return Object.assign(Object.assign({ 'alert-input': true, 'alert-input-disabled': ((_b = (_a = input.attributes) === null || _a === void 0 ? void 0 : _a.disabled) !== null && _b !== void 0 ? _b : input.disabled) || false }, getClassMap(input.cssClass)), getClassMap(input.attributes ? (_c = input.attributes.class) === null || _c === void 0 ? void 0 : _c.toString() : ''));
};
const buttonClass = (button) => {
  return Object.assign({ 'alert-button': true, 'ion-focusable': true, 'ion-activatable': true, [`alert-button-role-${button.role}`]: button.role !== undefined }, getClassMap(button.cssClass));
};
