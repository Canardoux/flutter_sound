import { attachComponent } from '../../utils/framework-delegate';
import { assert } from '../../utils/helpers';
export const VIEW_STATE_NEW = 1;
export const VIEW_STATE_ATTACHED = 2;
export const VIEW_STATE_DESTROYED = 3;
export class ViewController {
  constructor(component, params) {
    this.component = component;
    this.params = params;
    this.state = VIEW_STATE_NEW;
  }
  async init(container) {
    this.state = VIEW_STATE_ATTACHED;
    if (!this.element) {
      const component = this.component;
      this.element = await attachComponent(this.delegate, container, component, ['ion-page', 'ion-page-invisible'], this.params);
    }
  }
  /**
   * DOM WRITE
   */
  _destroy() {
    assert(this.state !== VIEW_STATE_DESTROYED, 'view state must be ATTACHED');
    const element = this.element;
    if (element) {
      if (this.delegate) {
        this.delegate.removeViewFromDom(element.parentElement, element);
      }
      else {
        element.remove();
      }
    }
    this.nav = undefined;
    this.state = VIEW_STATE_DESTROYED;
  }
}
export const matches = (view, id, params) => {
  if (!view) {
    return false;
  }
  if (view.component !== id) {
    return false;
  }
  const currentParams = view.params;
  if (currentParams === params) {
    return true;
  }
  if (!currentParams && !params) {
    return true;
  }
  if (!currentParams || !params) {
    return false;
  }
  const keysA = Object.keys(currentParams);
  const keysB = Object.keys(params);
  if (keysA.length !== keysB.length) {
    return false;
  }
  // Test for A's keys different from B.
  for (const key of keysA) {
    if (currentParams[key] !== params[key]) {
      return false;
    }
  }
  return true;
};
export const convertToView = (page, params) => {
  if (!page) {
    return null;
  }
  if (page instanceof ViewController) {
    return page;
  }
  return new ViewController(page, params);
};
export const convertToViews = (pages) => {
  return pages.map(page => {
    if (page instanceof ViewController) {
      return page;
    }
    if ('component' in page) {
      /**
       * TODO Ionic 6:
       * Consider switching to just using `undefined` here
       * as well as on the public interfaces and on
       * `NavComponentWithProps`. Previously `pages` was
       * of type `any[]` so TypeScript did not catch this.
       */
      return convertToView(page.component, (page.componentProps === null) ? undefined : page.componentProps);
    }
    return convertToView(page, undefined);
  }).filter(v => v !== null);
};
