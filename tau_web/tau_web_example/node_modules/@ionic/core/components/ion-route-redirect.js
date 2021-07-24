import { createEvent, proxyCustomElement } from '@stencil/core/internal/client';

const RouteRedirect = class extends HTMLElement {
  constructor() {
    super();
    this.__registerHost();
    this.ionRouteRedirectChanged = createEvent(this, "ionRouteRedirectChanged", 7);
  }
  propDidChange() {
    this.ionRouteRedirectChanged.emit();
  }
  connectedCallback() {
    this.ionRouteRedirectChanged.emit();
  }
  static get watchers() { return {
    "from": ["propDidChange"],
    "to": ["propDidChange"]
  }; }
};

const IonRouteRedirect = /*@__PURE__*/proxyCustomElement(RouteRedirect, [0,"ion-route-redirect",{"from":[1],"to":[1]}]);

export { IonRouteRedirect };
