import { Component, Element, Event, Host, Method, Prop, State, Watch, forceUpdate, h } from '@stencil/core';
import { config } from '../../global/config';
import { getIonMode } from '../../global/ionic-global';
import { debounceEvent, raf } from '../../utils/helpers';
import { createColorClasses } from '../../utils/theme';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export class Searchbar {
  constructor() {
    this.isCancelVisible = false;
    this.shouldAlignLeft = true;
    this.focused = false;
    this.noAnimate = true;
    /**
     * If `true`, enable searchbar animation.
     */
    this.animated = false;
    /**
     * Set the input's autocomplete property.
     */
    this.autocomplete = 'off';
    /**
     * Set the input's autocorrect property.
     */
    this.autocorrect = 'off';
    /**
     * Set the cancel button icon. Only applies to `md` mode.
     * Defaults to `"arrow-back-sharp"`.
     */
    this.cancelButtonIcon = config.get('backButtonIcon', 'arrow-back-sharp');
    /**
     * Set the the cancel button text. Only applies to `ios` mode.
     */
    this.cancelButtonText = 'Cancel';
    /**
     * Set the amount of time, in milliseconds, to wait to trigger the `ionChange` event after each keystroke. This also impacts form bindings such as `ngModel` or `v-model`.
     */
    this.debounce = 250;
    /**
     * If `true`, the user cannot interact with the input.
     */
    this.disabled = false;
    /**
     * Set the input's placeholder.
     * `placeholder` can accept either plaintext or HTML as a string.
     * To display characters normally reserved for HTML, they
     * must be escaped. For example `<Ionic>` would become
     * `&lt;Ionic&gt;`
     *
     * For more information: [Security Documentation](https://ionicframework.com/docs/faq/security)
     */
    this.placeholder = 'Search';
    /**
     * Sets the behavior for the cancel button. Defaults to `"never"`.
     * Setting to `"focus"` shows the cancel button on focus.
     * Setting to `"never"` hides the cancel button.
     * Setting to `"always"` shows the cancel button regardless
     * of focus state.
     */
    this.showCancelButton = 'never';
    /**
     * Sets the behavior for the clear button. Defaults to `"focus"`.
     * Setting to `"focus"` shows the clear button on focus if the
     * input is not empty.
     * Setting to `"never"` hides the clear button.
     * Setting to `"always"` shows the clear button regardless
     * of focus state, but only if the input is not empty.
     */
    this.showClearButton = 'focus';
    /**
     * If `true`, enable spellcheck on the input.
     */
    this.spellcheck = false;
    /**
     * Set the type of the input.
     */
    this.type = 'search';
    /**
     * the value of the searchbar.
     */
    this.value = '';
    /**
     * Clears the input field and triggers the control change.
     */
    this.onClearInput = (ev, shouldFocus) => {
      this.ionClear.emit();
      if (ev) {
        ev.preventDefault();
        ev.stopPropagation();
      }
      // setTimeout() fixes https://github.com/ionic-team/ionic/issues/7527
      // wait for 4 frames
      setTimeout(() => {
        const value = this.getValue();
        if (value !== '') {
          this.value = '';
          this.ionInput.emit();
          /**
           * When tapping clear button
           * ensure input is focused after
           * clearing input so users
           * can quickly start typing.
           */
          if (shouldFocus && !this.focused) {
            this.setFocus();
          }
        }
      }, 16 * 4);
    };
    /**
     * Clears the input field and tells the input to blur since
     * the clearInput function doesn't want the input to blur
     * then calls the custom cancel function if the user passed one in.
     */
    this.onCancelSearchbar = (ev) => {
      if (ev) {
        ev.preventDefault();
        ev.stopPropagation();
      }
      this.ionCancel.emit();
      this.onClearInput();
      if (this.nativeInput) {
        this.nativeInput.blur();
      }
    };
    /**
     * Update the Searchbar input value when the input changes
     */
    this.onInput = (ev) => {
      const input = ev.target;
      if (input) {
        this.value = input.value;
      }
      this.ionInput.emit(ev);
    };
    /**
     * Sets the Searchbar to not focused and checks if it should align left
     * based on whether there is a value in the searchbar or not.
     */
    this.onBlur = () => {
      this.focused = false;
      this.ionBlur.emit();
      this.positionElements();
    };
    /**
     * Sets the Searchbar to focused and active on input focus.
     */
    this.onFocus = () => {
      this.focused = true;
      this.ionFocus.emit();
      this.positionElements();
    };
  }
  debounceChanged() {
    this.ionChange = debounceEvent(this.ionChange, this.debounce);
  }
  valueChanged() {
    const inputEl = this.nativeInput;
    const value = this.getValue();
    if (inputEl && inputEl.value !== value) {
      inputEl.value = value;
    }
    this.ionChange.emit({ value });
  }
  showCancelButtonChanged() {
    requestAnimationFrame(() => {
      this.positionElements();
      forceUpdate(this);
    });
  }
  connectedCallback() {
    this.emitStyle();
  }
  componentDidLoad() {
    this.positionElements();
    this.debounceChanged();
    setTimeout(() => {
      this.noAnimate = false;
    }, 300);
  }
  emitStyle() {
    this.ionStyle.emit({
      'searchbar': true
    });
  }
  /**
   * Sets focus on the specified `ion-searchbar`. Use this method instead of the global
   * `input.focus()`.
   */
  async setFocus() {
    if (this.nativeInput) {
      this.nativeInput.focus();
    }
  }
  /**
   * Returns the native `<input>` element used under the hood.
   */
  getInputElement() {
    return Promise.resolve(this.nativeInput);
  }
  /**
   * Positions the input search icon, placeholder, and the cancel button
   * based on the input value and if it is focused. (ios only)
   */
  positionElements() {
    const value = this.getValue();
    const prevAlignLeft = this.shouldAlignLeft;
    const mode = getIonMode(this);
    const shouldAlignLeft = (!this.animated || value.trim() !== '' || !!this.focused);
    this.shouldAlignLeft = shouldAlignLeft;
    if (mode !== 'ios') {
      return;
    }
    if (prevAlignLeft !== shouldAlignLeft) {
      this.positionPlaceholder();
    }
    if (this.animated) {
      this.positionCancelButton();
    }
  }
  /**
   * Positions the input placeholder
   */
  positionPlaceholder() {
    const inputEl = this.nativeInput;
    if (!inputEl) {
      return;
    }
    const isRTL = document.dir === 'rtl';
    const iconEl = (this.el.shadowRoot || this.el).querySelector('.searchbar-search-icon');
    if (this.shouldAlignLeft) {
      inputEl.removeAttribute('style');
      iconEl.removeAttribute('style');
    }
    else {
      // Create a dummy span to get the placeholder width
      const doc = document;
      const tempSpan = doc.createElement('span');
      tempSpan.innerText = this.placeholder || '';
      doc.body.appendChild(tempSpan);
      // Get the width of the span then remove it
      raf(() => {
        const textWidth = tempSpan.offsetWidth;
        tempSpan.remove();
        // Calculate the input padding
        const inputLeft = 'calc(50% - ' + (textWidth / 2) + 'px)';
        // Calculate the icon margin
        const iconLeft = 'calc(50% - ' + ((textWidth / 2) + 30) + 'px)';
        // Set the input padding start and icon margin start
        if (isRTL) {
          inputEl.style.paddingRight = inputLeft;
          iconEl.style.marginRight = iconLeft;
        }
        else {
          inputEl.style.paddingLeft = inputLeft;
          iconEl.style.marginLeft = iconLeft;
        }
      });
    }
  }
  /**
   * Show the iOS Cancel button on focus, hide it offscreen otherwise
   */
  positionCancelButton() {
    const isRTL = document.dir === 'rtl';
    const cancelButton = (this.el.shadowRoot || this.el).querySelector('.searchbar-cancel-button');
    const shouldShowCancel = this.shouldShowCancelButton();
    if (cancelButton && shouldShowCancel !== this.isCancelVisible) {
      const cancelStyle = cancelButton.style;
      this.isCancelVisible = shouldShowCancel;
      if (shouldShowCancel) {
        if (isRTL) {
          cancelStyle.marginLeft = '0';
        }
        else {
          cancelStyle.marginRight = '0';
        }
      }
      else {
        const offset = cancelButton.offsetWidth;
        if (offset > 0) {
          if (isRTL) {
            cancelStyle.marginLeft = -offset + 'px';
          }
          else {
            cancelStyle.marginRight = -offset + 'px';
          }
        }
      }
    }
  }
  getValue() {
    return this.value || '';
  }
  hasValue() {
    return this.getValue() !== '';
  }
  /**
   * Determines whether or not the cancel button should be visible onscreen.
   * Cancel button should be shown if one of two conditions applies:
   * 1. `showCancelButton` is set to `always`.
   * 2. `showCancelButton` is set to `focus`, and the searchbar has been focused.
   */
  shouldShowCancelButton() {
    if ((this.showCancelButton === 'never') || (this.showCancelButton === 'focus' && !this.focused)) {
      return false;
    }
    return true;
  }
  /**
   * Determines whether or not the clear button should be visible onscreen.
   * Clear button should be shown if one of two conditions applies:
   * 1. `showClearButton` is set to `always`.
   * 2. `showClearButton` is set to `focus`, and the searchbar has been focused.
   */
  shouldShowClearButton() {
    if ((this.showClearButton === 'never') || (this.showClearButton === 'focus' && !this.focused)) {
      return false;
    }
    return true;
  }
  render() {
    const { cancelButtonText } = this;
    const animated = this.animated && config.getBoolean('animated', true);
    const mode = getIonMode(this);
    const clearIcon = this.clearIcon || (mode === 'ios' ? 'close-circle' : 'close-sharp');
    const searchIcon = this.searchIcon || (mode === 'ios' ? 'search-outline' : 'search-sharp');
    const shouldShowCancelButton = this.shouldShowCancelButton();
    const cancelButton = (this.showCancelButton !== 'never') && (h("button", { "aria-label": cancelButtonText, "aria-hidden": shouldShowCancelButton ? undefined : 'true', type: "button", tabIndex: mode === 'ios' && !shouldShowCancelButton ? -1 : undefined, onMouseDown: this.onCancelSearchbar, onTouchStart: this.onCancelSearchbar, class: "searchbar-cancel-button" },
      h("div", { "aria-hidden": "true" }, mode === 'md'
        ? h("ion-icon", { "aria-hidden": "true", mode: mode, icon: this.cancelButtonIcon, lazy: false })
        : cancelButtonText)));
    return (h(Host, { role: "search", "aria-disabled": this.disabled ? 'true' : null, class: createColorClasses(this.color, {
        [mode]: true,
        'searchbar-animated': animated,
        'searchbar-disabled': this.disabled,
        'searchbar-no-animate': animated && this.noAnimate,
        'searchbar-has-value': this.hasValue(),
        'searchbar-left-aligned': this.shouldAlignLeft,
        'searchbar-has-focus': this.focused,
        'searchbar-should-show-clear': this.shouldShowClearButton(),
        'searchbar-should-show-cancel': this.shouldShowCancelButton()
      }) },
      h("div", { class: "searchbar-input-container" },
        h("input", { "aria-label": "search text", disabled: this.disabled, ref: el => this.nativeInput = el, class: "searchbar-input", inputMode: this.inputmode, enterKeyHint: this.enterkeyhint, onInput: this.onInput, onBlur: this.onBlur, onFocus: this.onFocus, placeholder: this.placeholder, type: this.type, value: this.getValue(), autoComplete: this.autocomplete, autoCorrect: this.autocorrect, spellcheck: this.spellcheck }),
        mode === 'md' && cancelButton,
        h("ion-icon", { "aria-hidden": "true", mode: mode, icon: searchIcon, lazy: false, class: "searchbar-search-icon" }),
        h("button", { "aria-label": "reset", type: "button", "no-blur": true, class: "searchbar-clear-button", onMouseDown: ev => this.onClearInput(ev, true), onTouchStart: ev => this.onClearInput(ev, true) },
          h("ion-icon", { "aria-hidden": "true", mode: mode, icon: clearIcon, lazy: false, class: "searchbar-clear-icon" }))),
      mode === 'ios' && cancelButton));
  }
  static get is() { return "ion-searchbar"; }
  static get encapsulation() { return "scoped"; }
  static get originalStyleUrls() { return {
    "ios": ["searchbar.ios.scss"],
    "md": ["searchbar.md.scss"]
  }; }
  static get styleUrls() { return {
    "ios": ["searchbar.ios.css"],
    "md": ["searchbar.md.css"]
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
        "text": "If `true`, enable searchbar animation."
      },
      "attribute": "animated",
      "reflect": false,
      "defaultValue": "false"
    },
    "autocomplete": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "AutocompleteTypes",
        "resolved": "\"on\" | \"off\" | \"name\" | \"honorific-prefix\" | \"given-name\" | \"additional-name\" | \"family-name\" | \"honorific-suffix\" | \"nickname\" | \"email\" | \"username\" | \"new-password\" | \"current-password\" | \"one-time-code\" | \"organization-title\" | \"organization\" | \"street-address\" | \"address-line1\" | \"address-line2\" | \"address-line3\" | \"address-level4\" | \"address-level3\" | \"address-level2\" | \"address-level1\" | \"country\" | \"country-name\" | \"postal-code\" | \"cc-name\" | \"cc-given-name\" | \"cc-additional-name\" | \"cc-family-name\" | \"cc-number\" | \"cc-exp\" | \"cc-exp-month\" | \"cc-exp-year\" | \"cc-csc\" | \"cc-type\" | \"transaction-currency\" | \"transaction-amount\" | \"language\" | \"bday\" | \"bday-day\" | \"bday-month\" | \"bday-year\" | \"sex\" | \"tel\" | \"tel-country-code\" | \"tel-national\" | \"tel-area-code\" | \"tel-local\" | \"tel-extension\" | \"impp\" | \"url\" | \"photo\"",
        "references": {
          "AutocompleteTypes": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "Set the input's autocomplete property."
      },
      "attribute": "autocomplete",
      "reflect": false,
      "defaultValue": "'off'"
    },
    "autocorrect": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "'on' | 'off'",
        "resolved": "\"off\" | \"on\"",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "Set the input's autocorrect property."
      },
      "attribute": "autocorrect",
      "reflect": false,
      "defaultValue": "'off'"
    },
    "cancelButtonIcon": {
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
        "text": "Set the cancel button icon. Only applies to `md` mode.\nDefaults to `\"arrow-back-sharp\"`."
      },
      "attribute": "cancel-button-icon",
      "reflect": false,
      "defaultValue": "config.get('backButtonIcon', 'arrow-back-sharp') as string"
    },
    "cancelButtonText": {
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
        "text": "Set the the cancel button text. Only applies to `ios` mode."
      },
      "attribute": "cancel-button-text",
      "reflect": false,
      "defaultValue": "'Cancel'"
    },
    "clearIcon": {
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
        "text": "Set the clear icon. Defaults to `\"close-circle\"` for `ios` and `\"close-sharp\"` for `md`."
      },
      "attribute": "clear-icon",
      "reflect": false
    },
    "debounce": {
      "type": "number",
      "mutable": false,
      "complexType": {
        "original": "number",
        "resolved": "number",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "Set the amount of time, in milliseconds, to wait to trigger the `ionChange` event after each keystroke. This also impacts form bindings such as `ngModel` or `v-model`."
      },
      "attribute": "debounce",
      "reflect": false,
      "defaultValue": "250"
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
        "text": "If `true`, the user cannot interact with the input."
      },
      "attribute": "disabled",
      "reflect": false,
      "defaultValue": "false"
    },
    "inputmode": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "'none' | 'text' | 'tel' | 'url' | 'email' | 'numeric' | 'decimal' | 'search'",
        "resolved": "\"decimal\" | \"email\" | \"none\" | \"numeric\" | \"search\" | \"tel\" | \"text\" | \"url\" | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "A hint to the browser for which keyboard to display.\nPossible values: `\"none\"`, `\"text\"`, `\"tel\"`, `\"url\"`,\n`\"email\"`, `\"numeric\"`, `\"decimal\"`, and `\"search\"`."
      },
      "attribute": "inputmode",
      "reflect": false
    },
    "enterkeyhint": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "'enter' | 'done' | 'go' | 'next' | 'previous' | 'search' | 'send'",
        "resolved": "\"done\" | \"enter\" | \"go\" | \"next\" | \"previous\" | \"search\" | \"send\" | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "A hint to the browser for which enter key to display.\nPossible values: `\"enter\"`, `\"done\"`, `\"go\"`, `\"next\"`,\n`\"previous\"`, `\"search\"`, and `\"send\"`."
      },
      "attribute": "enterkeyhint",
      "reflect": false
    },
    "placeholder": {
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
        "text": "Set the input's placeholder.\n`placeholder` can accept either plaintext or HTML as a string.\nTo display characters normally reserved for HTML, they\nmust be escaped. For example `<Ionic>` would become\n`&lt;Ionic&gt;`\n\nFor more information: [Security Documentation](https://ionicframework.com/docs/faq/security)"
      },
      "attribute": "placeholder",
      "reflect": false,
      "defaultValue": "'Search'"
    },
    "searchIcon": {
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
        "text": "The icon to use as the search icon. Defaults to `\"search-outline\"` in\n`ios` mode and `\"search-sharp\"` in `md` mode."
      },
      "attribute": "search-icon",
      "reflect": false
    },
    "showCancelButton": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "'never' | 'focus' | 'always'",
        "resolved": "\"always\" | \"focus\" | \"never\"",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "Sets the behavior for the cancel button. Defaults to `\"never\"`.\nSetting to `\"focus\"` shows the cancel button on focus.\nSetting to `\"never\"` hides the cancel button.\nSetting to `\"always\"` shows the cancel button regardless\nof focus state."
      },
      "attribute": "show-cancel-button",
      "reflect": false,
      "defaultValue": "'never'"
    },
    "showClearButton": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "'never' | 'focus' | 'always'",
        "resolved": "\"always\" | \"focus\" | \"never\"",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "Sets the behavior for the clear button. Defaults to `\"focus\"`.\nSetting to `\"focus\"` shows the clear button on focus if the\ninput is not empty.\nSetting to `\"never\"` hides the clear button.\nSetting to `\"always\"` shows the clear button regardless\nof focus state, but only if the input is not empty."
      },
      "attribute": "show-clear-button",
      "reflect": false,
      "defaultValue": "'focus'"
    },
    "spellcheck": {
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
        "text": "If `true`, enable spellcheck on the input."
      },
      "attribute": "spellcheck",
      "reflect": false,
      "defaultValue": "false"
    },
    "type": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "'text' | 'password' | 'email' | 'number' | 'search' | 'tel' | 'url'",
        "resolved": "\"email\" | \"number\" | \"password\" | \"search\" | \"tel\" | \"text\" | \"url\"",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "Set the type of the input."
      },
      "attribute": "type",
      "reflect": false,
      "defaultValue": "'search'"
    },
    "value": {
      "type": "string",
      "mutable": true,
      "complexType": {
        "original": "string | null",
        "resolved": "null | string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "the value of the searchbar."
      },
      "attribute": "value",
      "reflect": false,
      "defaultValue": "''"
    }
  }; }
  static get states() { return {
    "focused": {},
    "noAnimate": {}
  }; }
  static get events() { return [{
      "method": "ionInput",
      "name": "ionInput",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when a keyboard input occurred."
      },
      "complexType": {
        "original": "KeyboardEvent",
        "resolved": "KeyboardEvent",
        "references": {
          "KeyboardEvent": {
            "location": "global"
          }
        }
      }
    }, {
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
        "original": "SearchbarChangeEventDetail",
        "resolved": "SearchbarChangeEventDetail",
        "references": {
          "SearchbarChangeEventDetail": {
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
        "text": "Emitted when the cancel button is clicked."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionClear",
      "name": "ionClear",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the clear input button is clicked."
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
        "text": "Emitted when the input loses focus."
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
        "text": "Emitted when the input has focus."
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
    "setFocus": {
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
        "text": "Sets focus on the specified `ion-searchbar`. Use this method instead of the global\n`input.focus()`.",
        "tags": []
      }
    },
    "getInputElement": {
      "complexType": {
        "signature": "() => Promise<HTMLInputElement>",
        "parameters": [],
        "references": {
          "Promise": {
            "location": "global"
          },
          "HTMLInputElement": {
            "location": "global"
          }
        },
        "return": "Promise<HTMLInputElement>"
      },
      "docs": {
        "text": "Returns the native `<input>` element used under the hood.",
        "tags": []
      }
    }
  }; }
  static get elementRef() { return "el"; }
  static get watchers() { return [{
      "propName": "debounce",
      "methodName": "debounceChanged"
    }, {
      "propName": "value",
      "methodName": "valueChanged"
    }, {
      "propName": "showCancelButton",
      "methodName": "showCancelButtonChanged"
    }]; }
}
