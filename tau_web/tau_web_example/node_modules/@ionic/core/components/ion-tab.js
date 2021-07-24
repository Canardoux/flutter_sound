import { attachShadow, Build, h, Host, proxyCustomElement } from '@stencil/core/internal/client';
import { a as attachComponent } from './framework-delegate.js';

const tabCss = ":host(.tab-hidden){display:none !important}";

const Tab = class extends HTMLElement {
  constructor() {
    super();
    this.__registerHost();
    attachShadow(this);
    this.loaded = false;
    /** @internal */
    this.active = false;
  }
  async componentWillLoad() {
    if (Build.isDev) {
      if (this.component !== undefined && this.el.childElementCount > 0) {
        console.error('You can not use a lazy-loaded component in a tab and inlined content at the same time.' +
          `- Remove the component attribute in: <ion-tab component="${this.component}">` +
          ` or` +
          `- Remove the embedded content inside the ion-tab: <ion-tab></ion-tab>`);
      }
    }
    if (this.active) {
      await this.setActive();
    }
  }
  /** Set the active component for the tab */
  async setActive() {
    await this.prepareLazyLoaded();
    this.active = true;
  }
  changeActive(isActive) {
    if (isActive) {
      this.prepareLazyLoaded();
    }
  }
  prepareLazyLoaded() {
    if (!this.loaded && this.component != null) {
      this.loaded = true;
      try {
        return attachComponent(this.delegate, this.el, this.component, ['ion-page']);
      }
      catch (e) {
        console.error(e);
      }
    }
    return Promise.resolve(undefined);
  }
  render() {
    const { tab, active, component } = this;
    return (h(Host, { role: "tabpanel", "aria-hidden": !active ? 'true' : null, "aria-labelledby": `tab-button-${tab}`, class: {
        'ion-page': component === undefined,
        'tab-hidden': !active
      } }, h("slot", null)));
  }
  get el() { return this; }
  static get watchers() { return {
    "active": ["changeActive"]
  }; }
  static get style() { return tabCss; }
};

const IonTab = /*@__PURE__*/proxyCustomElement(Tab, [1,"ion-tab",{"active":[1028],"delegate":[16],"tab":[1],"component":[1]}]);

export { IonTab };
