import { attachShadow, h, Host, proxyCustomElement } from '@stencil/core/internal/client';
import { b as getIonMode } from './ionic-global.js';

const selectOptionCss = ":host{display:none}";

const SelectOption = class extends HTMLElement {
  constructor() {
    super();
    this.__registerHost();
    attachShadow(this);
    this.inputId = `ion-selopt-${selectOptionIds++}`;
    /**
     * If `true`, the user cannot interact with the select option. This property does not apply when `interface="action-sheet"` as `ion-action-sheet` does not allow for disabled buttons.
     */
    this.disabled = false;
  }
  render() {
    return (h(Host, { role: "option", id: this.inputId, class: getIonMode(this) }));
  }
  get el() { return this; }
  static get style() { return selectOptionCss; }
};
let selectOptionIds = 0;

const IonSelectOption = /*@__PURE__*/proxyCustomElement(SelectOption, [1,"ion-select-option",{"disabled":[4],"value":[8]}]);

export { IonSelectOption };
