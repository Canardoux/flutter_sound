import { attachShadow, h, Host, proxyCustomElement } from '@stencil/core/internal/client';
import { b as getIonMode } from './ionic-global.js';
import { c as createColorClasses } from './theme.js';

const textCss = ":host(.ion-color){color:var(--ion-color-base)}";

const Text = class extends HTMLElement {
  constructor() {
    super();
    this.__registerHost();
    attachShadow(this);
  }
  render() {
    const mode = getIonMode(this);
    return (h(Host, { class: createColorClasses(this.color, {
        [mode]: true,
      }) }, h("slot", null)));
  }
  static get style() { return textCss; }
};

const IonText = /*@__PURE__*/proxyCustomElement(Text, [1,"ion-text",{"color":[513]}]);

export { IonText };
