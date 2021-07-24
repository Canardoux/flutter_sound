import { attachShadow, h, Host, proxyCustomElement } from '@stencil/core/internal/client';
import { b as getIonMode } from './ionic-global.js';

const fabCss = ":host{position:absolute;z-index:999}:host(.fab-horizontal-center){left:50%;margin-left:-28px}:host-context([dir=rtl]):host(.fab-horizontal-center),:host-context([dir=rtl]).fab-horizontal-center{left:unset;right:unset;right:50%}@supports ((-webkit-margin-start: 0) or (margin-inline-start: 0)) or (-webkit-margin-start: 0){:host(.fab-horizontal-center){margin-left:unset;-webkit-margin-start:-28px;margin-inline-start:-28px}}:host(.fab-horizontal-start){left:calc(10px + var(--ion-safe-area-left, 0px))}:host-context([dir=rtl]):host(.fab-horizontal-start),:host-context([dir=rtl]).fab-horizontal-start{left:unset;right:unset;right:calc(10px + var(--ion-safe-area-left, 0px))}:host(.fab-horizontal-end){right:calc(10px + var(--ion-safe-area-right, 0px))}:host-context([dir=rtl]):host(.fab-horizontal-end),:host-context([dir=rtl]).fab-horizontal-end{left:unset;right:unset;left:calc(10px + var(--ion-safe-area-right, 0px))}:host(.fab-vertical-top){top:10px}:host(.fab-vertical-top.fab-edge){top:-28px}:host(.fab-vertical-bottom){bottom:10px}:host(.fab-vertical-bottom.fab-edge){bottom:-28px}:host(.fab-vertical-center){margin-top:-28px;top:50%}";

const Fab = class extends HTMLElement {
  constructor() {
    super();
    this.__registerHost();
    attachShadow(this);
    /**
     * If `true`, the fab will display on the edge of the header if
     * `vertical` is `"top"`, and on the edge of the footer if
     * it is `"bottom"`. Should be used with a `fixed` slot.
     */
    this.edge = false;
    /**
     * If `true`, both the `ion-fab-button` and all `ion-fab-list` inside `ion-fab` will become active.
     * That means `ion-fab-button` will become a `close` icon and `ion-fab-list` will become visible.
     */
    this.activated = false;
    this.onClick = () => {
      const hasList = !!this.el.querySelector('ion-fab-list');
      const getButton = this.getFab();
      const isButtonDisabled = getButton && getButton.disabled;
      if (hasList && !isButtonDisabled) {
        this.activated = !this.activated;
      }
    };
  }
  activatedChanged() {
    const activated = this.activated;
    const fab = this.getFab();
    if (fab) {
      fab.activated = activated;
    }
    Array.from(this.el.querySelectorAll('ion-fab-list')).forEach(list => {
      list.activated = activated;
    });
  }
  componentDidLoad() {
    if (this.activated) {
      this.activatedChanged();
    }
  }
  /**
   * Close an active FAB list container.
   */
  async close() {
    this.activated = false;
  }
  getFab() {
    return this.el.querySelector('ion-fab-button');
  }
  render() {
    const { horizontal, vertical, edge } = this;
    const mode = getIonMode(this);
    return (h(Host, { onClick: this.onClick, class: {
        [mode]: true,
        [`fab-horizontal-${horizontal}`]: horizontal !== undefined,
        [`fab-vertical-${vertical}`]: vertical !== undefined,
        'fab-edge': edge
      } }, h("slot", null)));
  }
  get el() { return this; }
  static get watchers() { return {
    "activated": ["activatedChanged"]
  }; }
  static get style() { return fabCss; }
};

const IonFab = /*@__PURE__*/proxyCustomElement(Fab, [1,"ion-fab",{"horizontal":[1],"vertical":[1],"edge":[4],"activated":[1028]}]);

export { IonFab };
