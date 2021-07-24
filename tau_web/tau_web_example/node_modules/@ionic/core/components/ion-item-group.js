import { h, Host, proxyCustomElement } from '@stencil/core/internal/client';
import { b as getIonMode } from './ionic-global.js';

const itemGroupIosCss = "ion-item-group{display:block}";

const itemGroupMdCss = "ion-item-group{display:block}";

const ItemGroup = class extends HTMLElement {
  constructor() {
    super();
    this.__registerHost();
  }
  render() {
    const mode = getIonMode(this);
    return (h(Host, { role: "group", class: {
        [mode]: true,
        // Used internally for styling
        [`item-group-${mode}`]: true,
        'item': true
      } }));
  }
  static get style() { return {
    ios: itemGroupIosCss,
    md: itemGroupMdCss
  }; }
};

const IonItemGroup = /*@__PURE__*/proxyCustomElement(ItemGroup, [32,"ion-item-group"]);

export { IonItemGroup };
