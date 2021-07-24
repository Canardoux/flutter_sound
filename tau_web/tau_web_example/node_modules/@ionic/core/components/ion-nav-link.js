import { h, Host, proxyCustomElement } from '@stencil/core/internal/client';

const navLink = (el, routerDirection, component, componentProps, routerAnimation) => {
  const nav = el.closest('ion-nav');
  if (nav) {
    if (routerDirection === 'forward') {
      if (component !== undefined) {
        return nav.push(component, componentProps, { skipIfBusy: true, animationBuilder: routerAnimation });
      }
    }
    else if (routerDirection === 'root') {
      if (component !== undefined) {
        return nav.setRoot(component, componentProps, { skipIfBusy: true, animationBuilder: routerAnimation });
      }
    }
    else if (routerDirection === 'back') {
      return nav.pop({ skipIfBusy: true, animationBuilder: routerAnimation });
    }
  }
  return Promise.resolve(false);
};

const NavLink = class extends HTMLElement {
  constructor() {
    super();
    this.__registerHost();
    /**
     * The transition direction when navigating to another page.
     */
    this.routerDirection = 'forward';
    this.onClick = () => {
      return navLink(this.el, this.routerDirection, this.component, this.componentProps, this.routerAnimation);
    };
  }
  render() {
    return (h(Host, { onClick: this.onClick }));
  }
  get el() { return this; }
};

const IonNavLink = /*@__PURE__*/proxyCustomElement(NavLink, [0,"ion-nav-link",{"component":[1],"componentProps":[16],"routerDirection":[1,"router-direction"],"routerAnimation":[16]}]);

export { IonNavLink };
