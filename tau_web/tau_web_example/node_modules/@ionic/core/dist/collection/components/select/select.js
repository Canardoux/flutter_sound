import { Component, Element, Event, Host, Method, Prop, State, Watch, h } from '@stencil/core';
import { getIonMode } from '../../global/ionic-global';
import { findItemLabel, getAriaLabel, renderHiddenInput } from '../../utils/helpers';
import { actionSheetController, alertController, popoverController } from '../../utils/overlays';
import { hostContext } from '../../utils/theme';
import { watchForOptions } from '../../utils/watch-options';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 *
 * @part placeholder - The text displayed in the select when there is no value.
 * @part text - The displayed value of the select.
 * @part icon - The select icon container.
 */
export class Select {
  constructor() {
    this.inputId = `ion-sel-${selectIds++}`;
    this.didInit = false;
    this.isExpanded = false;
    /**
     * If `true`, the user cannot interact with the select.
     */
    this.disabled = false;
    /**
     * The text to display on the cancel button.
     */
    this.cancelText = 'Cancel';
    /**
     * The text to display on the ok button.
     */
    this.okText = 'OK';
    /**
     * The name of the control, which is submitted with the form data.
     */
    this.name = this.inputId;
    /**
     * If `true`, the select can accept multiple values.
     */
    this.multiple = false;
    /**
     * The interface the select should use: `action-sheet`, `popover` or `alert`.
     */
    this.interface = 'alert';
    /**
     * Any additional options that the `alert`, `action-sheet` or `popover` interface
     * can take. See the [ion-alert docs](../alert), the
     * [ion-action-sheet docs](../action-sheet) and the
     * [ion-popover docs](../popover) for the
     * create options for each interface.
     *
     * Note: `interfaceOptions` will not override `inputs` or `buttons` with the `alert` interface.
     */
    this.interfaceOptions = {};
    this.onClick = (ev) => {
      this.setFocus();
      this.open(ev);
    };
    this.onFocus = () => {
      this.ionFocus.emit();
    };
    this.onBlur = () => {
      this.ionBlur.emit();
    };
  }
  disabledChanged() {
    this.emitStyle();
  }
  valueChanged() {
    this.emitStyle();
    if (this.didInit) {
      this.ionChange.emit({
        value: this.value,
      });
    }
  }
  async connectedCallback() {
    this.updateOverlayOptions();
    this.emitStyle();
    this.mutationO = watchForOptions(this.el, 'ion-select-option', async () => {
      this.updateOverlayOptions();
    });
  }
  disconnectedCallback() {
    if (this.mutationO) {
      this.mutationO.disconnect();
      this.mutationO = undefined;
    }
  }
  componentDidLoad() {
    this.didInit = true;
  }
  /**
   * Open the select overlay. The overlay is either an alert, action sheet, or popover,
   * depending on the `interface` property on the `ion-select`.
   *
   * @param event The user interface event that called the open.
   */
  async open(event) {
    if (this.disabled || this.isExpanded) {
      return undefined;
    }
    const overlay = this.overlay = await this.createOverlay(event);
    this.isExpanded = true;
    overlay.onDidDismiss().then(() => {
      this.overlay = undefined;
      this.isExpanded = false;
      this.setFocus();
    });
    await overlay.present();
    return overlay;
  }
  createOverlay(ev) {
    let selectInterface = this.interface;
    if ((selectInterface === 'action-sheet' || selectInterface === 'popover') && this.multiple) {
      console.warn(`Select interface cannot be "${selectInterface}" with a multi-value select. Using the "alert" interface instead.`);
      selectInterface = 'alert';
    }
    if (selectInterface === 'popover' && !ev) {
      console.warn('Select interface cannot be a "popover" without passing an event. Using the "alert" interface instead.');
      selectInterface = 'alert';
    }
    if (selectInterface === 'popover') {
      return this.openPopover(ev);
    }
    if (selectInterface === 'action-sheet') {
      return this.openActionSheet();
    }
    return this.openAlert();
  }
  updateOverlayOptions() {
    const overlay = this.overlay;
    if (!overlay) {
      return;
    }
    const childOpts = this.childOpts;
    const value = this.value;
    switch (this.interface) {
      case 'action-sheet':
        overlay.buttons = this.createActionSheetButtons(childOpts, value);
        break;
      case 'popover':
        const popover = overlay.querySelector('ion-select-popover');
        if (popover) {
          popover.options = this.createPopoverOptions(childOpts, value);
        }
        break;
      case 'alert':
        const inputType = (this.multiple ? 'checkbox' : 'radio');
        overlay.inputs = this.createAlertInputs(childOpts, inputType, value);
        break;
    }
  }
  createActionSheetButtons(data, selectValue) {
    const actionSheetButtons = data.map(option => {
      const value = getOptionValue(option);
      // Remove hydrated before copying over classes
      const copyClasses = Array.from(option.classList).filter(cls => cls !== 'hydrated').join(' ');
      const optClass = `${OPTION_CLASS} ${copyClasses}`;
      return {
        role: (isOptionSelected(value, selectValue, this.compareWith) ? 'selected' : ''),
        text: option.textContent,
        cssClass: optClass,
        handler: () => {
          this.value = value;
        }
      };
    });
    // Add "cancel" button
    actionSheetButtons.push({
      text: this.cancelText,
      role: 'cancel',
      handler: () => {
        this.ionCancel.emit();
      }
    });
    return actionSheetButtons;
  }
  createAlertInputs(data, inputType, selectValue) {
    const alertInputs = data.map(option => {
      const value = getOptionValue(option);
      // Remove hydrated before copying over classes
      const copyClasses = Array.from(option.classList).filter(cls => cls !== 'hydrated').join(' ');
      const optClass = `${OPTION_CLASS} ${copyClasses}`;
      return {
        type: inputType,
        cssClass: optClass,
        label: option.textContent || '',
        value,
        checked: isOptionSelected(value, selectValue, this.compareWith),
        disabled: option.disabled
      };
    });
    return alertInputs;
  }
  createPopoverOptions(data, selectValue) {
    const popoverOptions = data.map(option => {
      const value = getOptionValue(option);
      // Remove hydrated before copying over classes
      const copyClasses = Array.from(option.classList).filter(cls => cls !== 'hydrated').join(' ');
      const optClass = `${OPTION_CLASS} ${copyClasses}`;
      return {
        text: option.textContent || '',
        cssClass: optClass,
        value,
        checked: isOptionSelected(value, selectValue, this.compareWith),
        disabled: option.disabled,
        handler: () => {
          this.value = value;
          this.close();
        }
      };
    });
    return popoverOptions;
  }
  async openPopover(ev) {
    const interfaceOptions = this.interfaceOptions;
    const mode = getIonMode(this);
    const value = this.value;
    const popoverOpts = Object.assign(Object.assign({ mode }, interfaceOptions), { component: 'ion-select-popover', cssClass: ['select-popover', interfaceOptions.cssClass], event: ev, componentProps: {
        header: interfaceOptions.header,
        subHeader: interfaceOptions.subHeader,
        message: interfaceOptions.message,
        value,
        options: this.createPopoverOptions(this.childOpts, value)
      } });
    return popoverController.create(popoverOpts);
  }
  async openActionSheet() {
    const mode = getIonMode(this);
    const interfaceOptions = this.interfaceOptions;
    const actionSheetOpts = Object.assign(Object.assign({ mode }, interfaceOptions), { buttons: this.createActionSheetButtons(this.childOpts, this.value), cssClass: ['select-action-sheet', interfaceOptions.cssClass] });
    return actionSheetController.create(actionSheetOpts);
  }
  async openAlert() {
    const label = this.getLabel();
    const labelText = (label) ? label.textContent : null;
    const interfaceOptions = this.interfaceOptions;
    const inputType = (this.multiple ? 'checkbox' : 'radio');
    const mode = getIonMode(this);
    const alertOpts = Object.assign(Object.assign({ mode }, interfaceOptions), { header: interfaceOptions.header ? interfaceOptions.header : labelText, inputs: this.createAlertInputs(this.childOpts, inputType, this.value), buttons: [
        {
          text: this.cancelText,
          role: 'cancel',
          handler: () => {
            this.ionCancel.emit();
          }
        },
        {
          text: this.okText,
          handler: (selectedValues) => {
            this.value = selectedValues;
          }
        }
      ], cssClass: ['select-alert', interfaceOptions.cssClass,
        (this.multiple ? 'multiple-select-alert' : 'single-select-alert')] });
    return alertController.create(alertOpts);
  }
  /**
   * Close the select interface.
   */
  close() {
    // TODO check !this.overlay || !this.isFocus()
    if (!this.overlay) {
      return Promise.resolve(false);
    }
    return this.overlay.dismiss();
  }
  getLabel() {
    return findItemLabel(this.el);
  }
  hasValue() {
    return this.getText() !== '';
  }
  get childOpts() {
    return Array.from(this.el.querySelectorAll('ion-select-option'));
  }
  getText() {
    const selectedText = this.selectedText;
    if (selectedText != null && selectedText !== '') {
      return selectedText;
    }
    return generateText(this.childOpts, this.value, this.compareWith);
  }
  setFocus() {
    if (this.focusEl) {
      this.focusEl.focus();
    }
  }
  emitStyle() {
    this.ionStyle.emit({
      'interactive': true,
      'select': true,
      'has-placeholder': this.placeholder != null,
      'has-value': this.hasValue(),
      'interactive-disabled': this.disabled,
      'select-disabled': this.disabled
    });
  }
  render() {
    const { disabled, el, inputId, isExpanded, name, placeholder, value } = this;
    const mode = getIonMode(this);
    const { labelText, labelId } = getAriaLabel(el, inputId);
    renderHiddenInput(true, el, name, parseValue(value), disabled);
    const displayValue = this.getText();
    let addPlaceholderClass = false;
    let selectText = displayValue;
    if (selectText === '' && placeholder != null) {
      selectText = placeholder;
      addPlaceholderClass = true;
    }
    const selectTextClasses = {
      'select-text': true,
      'select-placeholder': addPlaceholderClass
    };
    const textPart = addPlaceholderClass ? 'placeholder' : 'text';
    // If there is a label then we need to concatenate it with the
    // current value (or placeholder) and a comma so it separates
    // nicely when the screen reader announces it, otherwise just
    // announce the value / placeholder
    const displayLabel = labelText !== undefined
      ? (selectText !== '' ? `${selectText}, ${labelText}` : labelText)
      : selectText;
    return (h(Host, { onClick: this.onClick, role: "button", "aria-haspopup": "listbox", "aria-disabled": disabled ? 'true' : null, "aria-label": displayLabel, class: {
        [mode]: true,
        'in-item': hostContext('ion-item', el),
        'select-disabled': disabled,
        'select-expanded': isExpanded
      } },
      h("div", { "aria-hidden": "true", class: selectTextClasses, part: textPart }, selectText),
      h("div", { class: "select-icon", role: "presentation", part: "icon" },
        h("div", { class: "select-icon-inner" })),
      h("label", { id: labelId }, displayLabel),
      h("button", { type: "button", disabled: disabled, id: inputId, "aria-labelledby": labelId, "aria-haspopup": "listbox", "aria-expanded": `${isExpanded}`, onFocus: this.onFocus, onBlur: this.onBlur, ref: (focusEl => this.focusEl = focusEl) })));
  }
  static get is() { return "ion-select"; }
  static get encapsulation() { return "shadow"; }
  static get originalStyleUrls() { return {
    "ios": ["select.ios.scss"],
    "md": ["select.md.scss"]
  }; }
  static get styleUrls() { return {
    "ios": ["select.ios.css"],
    "md": ["select.md.css"]
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
        "text": "If `true`, the user cannot interact with the select."
      },
      "attribute": "disabled",
      "reflect": false,
      "defaultValue": "false"
    },
    "cancelText": {
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
        "text": "The text to display on the cancel button."
      },
      "attribute": "cancel-text",
      "reflect": false,
      "defaultValue": "'Cancel'"
    },
    "okText": {
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
        "text": "The text to display on the ok button."
      },
      "attribute": "ok-text",
      "reflect": false,
      "defaultValue": "'OK'"
    },
    "placeholder": {
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
        "text": "The text to display when the select is empty."
      },
      "attribute": "placeholder",
      "reflect": false
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
    "selectedText": {
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
        "text": "The text to display instead of the selected option's value."
      },
      "attribute": "selected-text",
      "reflect": false
    },
    "multiple": {
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
        "text": "If `true`, the select can accept multiple values."
      },
      "attribute": "multiple",
      "reflect": false,
      "defaultValue": "false"
    },
    "interface": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "SelectInterface",
        "resolved": "\"action-sheet\" | \"alert\" | \"popover\"",
        "references": {
          "SelectInterface": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "The interface the select should use: `action-sheet`, `popover` or `alert`."
      },
      "attribute": "interface",
      "reflect": false,
      "defaultValue": "'alert'"
    },
    "interfaceOptions": {
      "type": "any",
      "mutable": false,
      "complexType": {
        "original": "any",
        "resolved": "any",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "Any additional options that the `alert`, `action-sheet` or `popover` interface\ncan take. See the [ion-alert docs](../alert), the\n[ion-action-sheet docs](../action-sheet) and the\n[ion-popover docs](../popover) for the\ncreate options for each interface.\n\nNote: `interfaceOptions` will not override `inputs` or `buttons` with the `alert` interface."
      },
      "attribute": "interface-options",
      "reflect": false,
      "defaultValue": "{}"
    },
    "compareWith": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string | SelectCompareFn | null",
        "resolved": "((currentValue: any, compareValue: any) => boolean) | null | string | undefined",
        "references": {
          "SelectCompareFn": {
            "location": "import",
            "path": "./select-interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "A property name or function used to compare object values"
      },
      "attribute": "compare-with",
      "reflect": false
    },
    "value": {
      "type": "any",
      "mutable": true,
      "complexType": {
        "original": "any | null",
        "resolved": "any",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "the value of the select."
      },
      "attribute": "value",
      "reflect": false
    }
  }; }
  static get states() { return {
    "isExpanded": {}
  }; }
  static get events() { return [{
      "method": "ionChange",
      "name": "ionChange",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the value has changed."
      },
      "complexType": {
        "original": "SelectChangeEventDetail",
        "resolved": "SelectChangeEventDetail<any>",
        "references": {
          "SelectChangeEventDetail": {
            "location": "import",
            "path": "../../interface"
          }
        }
      }
    }, {
      "method": "ionCancel",
      "name": "ionCancel",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the selection is cancelled."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionFocus",
      "name": "ionFocus",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the select has focus."
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
        "text": "Emitted when the select loses focus."
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
  static get methods() { return {
    "open": {
      "complexType": {
        "signature": "(event?: UIEvent | undefined) => Promise<any>",
        "parameters": [{
            "tags": [{
                "text": "event The user interface event that called the open.",
                "name": "param"
              }],
            "text": "The user interface event that called the open."
          }],
        "references": {
          "Promise": {
            "location": "global"
          },
          "UIEvent": {
            "location": "global"
          }
        },
        "return": "Promise<any>"
      },
      "docs": {
        "text": "Open the select overlay. The overlay is either an alert, action sheet, or popover,\ndepending on the `interface` property on the `ion-select`.",
        "tags": [{
            "name": "param",
            "text": "event The user interface event that called the open."
          }]
      }
    }
  }; }
  static get elementRef() { return "el"; }
  static get watchers() { return [{
      "propName": "disabled",
      "methodName": "disabledChanged"
    }, {
      "propName": "placeholder",
      "methodName": "disabledChanged"
    }, {
      "propName": "value",
      "methodName": "valueChanged"
    }]; }
}
const isOptionSelected = (currentValue, compareValue, compareWith) => {
  if (currentValue === undefined) {
    return false;
  }
  if (Array.isArray(currentValue)) {
    return currentValue.some(val => compareOptions(val, compareValue, compareWith));
  }
  else {
    return compareOptions(currentValue, compareValue, compareWith);
  }
};
const getOptionValue = (el) => {
  const value = el.value;
  return (value === undefined)
    ? el.textContent || ''
    : value;
};
const parseValue = (value) => {
  if (value == null) {
    return undefined;
  }
  if (Array.isArray(value)) {
    return value.join(',');
  }
  return value.toString();
};
const compareOptions = (currentValue, compareValue, compareWith) => {
  if (typeof compareWith === 'function') {
    return compareWith(currentValue, compareValue);
  }
  else if (typeof compareWith === 'string') {
    return currentValue[compareWith] === compareValue[compareWith];
  }
  else {
    return Array.isArray(compareValue) ? compareValue.includes(currentValue) : currentValue === compareValue;
  }
};
const generateText = (opts, value, compareWith) => {
  if (value === undefined) {
    return '';
  }
  if (Array.isArray(value)) {
    return value
      .map(v => textForValue(opts, v, compareWith))
      .filter(opt => opt !== null)
      .join(', ');
  }
  else {
    return textForValue(opts, value, compareWith) || '';
  }
};
const textForValue = (opts, value, compareWith) => {
  const selectOpt = opts.find(opt => {
    return compareOptions(getOptionValue(opt), value, compareWith);
  });
  return selectOpt
    ? selectOpt.textContent
    : null;
};
let selectIds = 0;
const OPTION_CLASS = 'select-interface-option';
