import { Component, Element, Event, Method, Prop, Watch, h } from '@stencil/core';
import { config } from '../../global/config';
import { getIonMode } from '../../global/ionic-global';
import { getTimeGivenProgression } from '../../utils/animation/cubic-bezier';
import { attachComponent, detachComponent } from '../../utils/framework-delegate';
import { transition } from '../../utils/transition';
export class RouterOutlet {
  constructor() {
    this.animationEnabled = true;
    /**
     * The mode determines which platform styles to use.
     */
    this.mode = getIonMode(this);
    /**
     * If `true`, the router-outlet should animate the transition of components.
     */
    this.animated = true;
  }
  swipeHandlerChanged() {
    if (this.gesture) {
      this.gesture.enable(this.swipeHandler !== undefined);
    }
  }
  async connectedCallback() {
    this.gesture = (await import('../../utils/gesture/swipe-back')).createSwipeBackGesture(this.el, () => !!this.swipeHandler && this.swipeHandler.canStart() && this.animationEnabled, () => this.swipeHandler && this.swipeHandler.onStart(), step => this.ani && this.ani.progressStep(step), (shouldComplete, step, dur) => {
      if (this.ani) {
        this.animationEnabled = false;
        this.ani.onFinish(() => {
          this.animationEnabled = true;
          if (this.swipeHandler) {
            this.swipeHandler.onEnd(shouldComplete);
          }
        }, { oneTimeCallback: true });
        // Account for rounding errors in JS
        let newStepValue = (shouldComplete) ? -0.001 : 0.001;
        /**
         * Animation will be reversed here, so need to
         * reverse the easing curve as well
         *
         * Additionally, we need to account for the time relative
         * to the new easing curve, as `stepValue` is going to be given
         * in terms of a linear curve.
         */
        if (!shouldComplete) {
          this.ani.easing('cubic-bezier(1, 0, 0.68, 0.28)');
          newStepValue += getTimeGivenProgression([0, 0], [1, 0], [0.68, 0.28], [1, 1], step)[0];
        }
        else {
          newStepValue += getTimeGivenProgression([0, 0], [0.32, 0.72], [0, 1], [1, 1], step)[0];
        }
        this.ani.progressEnd(shouldComplete ? 1 : 0, newStepValue, dur);
      }
    });
    this.swipeHandlerChanged();
  }
  componentWillLoad() {
    this.ionNavWillLoad.emit();
  }
  disconnectedCallback() {
    if (this.gesture) {
      this.gesture.destroy();
      this.gesture = undefined;
    }
  }
  /** @internal */
  async commit(enteringEl, leavingEl, opts) {
    const unlock = await this.lock();
    let changed = false;
    try {
      changed = await this.transition(enteringEl, leavingEl, opts);
    }
    catch (e) {
      console.error(e);
    }
    unlock();
    return changed;
  }
  /** @internal */
  async setRouteId(id, params, direction, animation) {
    const changed = await this.setRoot(id, params, {
      duration: direction === 'root' ? 0 : undefined,
      direction: direction === 'back' ? 'back' : 'forward',
      animationBuilder: animation
    });
    return {
      changed,
      element: this.activeEl
    };
  }
  /** @internal */
  async getRouteId() {
    const active = this.activeEl;
    return active ? {
      id: active.tagName,
      element: active,
    } : undefined;
  }
  async setRoot(component, params, opts) {
    if (this.activeComponent === component) {
      return false;
    }
    // attach entering view to DOM
    const leavingEl = this.activeEl;
    const enteringEl = await attachComponent(this.delegate, this.el, component, ['ion-page', 'ion-page-invisible'], params);
    this.activeComponent = component;
    this.activeEl = enteringEl;
    // commit animation
    await this.commit(enteringEl, leavingEl, opts);
    await detachComponent(this.delegate, leavingEl);
    return true;
  }
  async transition(enteringEl, leavingEl, opts = {}) {
    if (leavingEl === enteringEl) {
      return false;
    }
    // emit nav will change event
    this.ionNavWillChange.emit();
    const { el, mode } = this;
    const animated = this.animated && config.getBoolean('animated', true);
    const animationBuilder = this.animation || opts.animationBuilder || config.get('navAnimation');
    await transition(Object.assign(Object.assign({ mode,
      animated,
      enteringEl,
      leavingEl, baseEl: el, progressCallback: (opts.progressAnimation
        ? ani => this.ani = ani
        : undefined) }, opts), { animationBuilder }));
    // emit nav changed event
    this.ionNavDidChange.emit();
    return true;
  }
  async lock() {
    const p = this.waitPromise;
    let resolve;
    this.waitPromise = new Promise(r => resolve = r);
    if (p !== undefined) {
      await p;
    }
    return resolve;
  }
  render() {
    return (h("slot", null));
  }
  static get is() { return "ion-router-outlet"; }
  static get encapsulation() { return "shadow"; }
  static get originalStyleUrls() { return {
    "$": ["route-outlet.scss"]
  }; }
  static get styleUrls() { return {
    "$": ["route-outlet.css"]
  }; }
  static get properties() { return {
    "mode": {
      "type": "string",
      "mutable": true,
      "complexType": {
        "original": "\"ios\" | \"md\"",
        "resolved": "\"ios\" | \"md\"",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "The mode determines which platform styles to use."
      },
      "attribute": "mode",
      "reflect": false,
      "defaultValue": "getIonMode(this)"
    },
    "delegate": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "FrameworkDelegate",
        "resolved": "FrameworkDelegate | undefined",
        "references": {
          "FrameworkDelegate": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [{
            "text": undefined,
            "name": "internal"
          }],
        "text": ""
      }
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
        "text": "If `true`, the router-outlet should animate the transition of components."
      },
      "attribute": "animated",
      "reflect": false,
      "defaultValue": "true"
    },
    "animation": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "AnimationBuilder",
        "resolved": "((baseEl: any, opts?: any) => Animation) | undefined",
        "references": {
          "AnimationBuilder": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "By default `ion-nav` animates transition between pages based in the mode (ios or material design).\nHowever, this property allows to create custom transition using `AnimateBuilder` functions."
      }
    },
    "swipeHandler": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "SwipeGestureHandler",
        "resolved": "SwipeGestureHandler | undefined",
        "references": {
          "SwipeGestureHandler": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [{
            "text": undefined,
            "name": "internal"
          }],
        "text": ""
      }
    }
  }; }
  static get events() { return [{
      "method": "ionNavWillLoad",
      "name": "ionNavWillLoad",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [{
            "text": undefined,
            "name": "internal"
          }],
        "text": ""
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionNavWillChange",
      "name": "ionNavWillChange",
      "bubbles": false,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [{
            "text": undefined,
            "name": "internal"
          }],
        "text": ""
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionNavDidChange",
      "name": "ionNavDidChange",
      "bubbles": false,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [{
            "text": undefined,
            "name": "internal"
          }],
        "text": ""
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }]; }
  static get methods() { return {
    "commit": {
      "complexType": {
        "signature": "(enteringEl: HTMLElement, leavingEl: HTMLElement | undefined, opts?: RouterOutletOptions | undefined) => Promise<boolean>",
        "parameters": [{
            "tags": [],
            "text": ""
          }, {
            "tags": [],
            "text": ""
          }, {
            "tags": [],
            "text": ""
          }],
        "references": {
          "Promise": {
            "location": "global"
          },
          "HTMLElement": {
            "location": "global"
          },
          "RouterOutletOptions": {
            "location": "import",
            "path": "../../interface"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "",
        "tags": [{
            "name": "internal",
            "text": undefined
          }]
      }
    },
    "setRouteId": {
      "complexType": {
        "signature": "(id: string, params: ComponentProps | undefined, direction: RouterDirection, animation?: AnimationBuilder | undefined) => Promise<RouteWrite>",
        "parameters": [{
            "tags": [],
            "text": ""
          }, {
            "tags": [],
            "text": ""
          }, {
            "tags": [],
            "text": ""
          }, {
            "tags": [],
            "text": ""
          }],
        "references": {
          "Promise": {
            "location": "global"
          },
          "RouteWrite": {
            "location": "import",
            "path": "../../interface"
          },
          "ComponentProps": {
            "location": "import",
            "path": "../../interface"
          },
          "RouterDirection": {
            "location": "import",
            "path": "../../interface"
          },
          "AnimationBuilder": {
            "location": "import",
            "path": "../../interface"
          }
        },
        "return": "Promise<RouteWrite>"
      },
      "docs": {
        "text": "",
        "tags": [{
            "name": "internal",
            "text": undefined
          }]
      }
    },
    "getRouteId": {
      "complexType": {
        "signature": "() => Promise<RouteID | undefined>",
        "parameters": [],
        "references": {
          "Promise": {
            "location": "global"
          },
          "RouteID": {
            "location": "import",
            "path": "../../interface"
          }
        },
        "return": "Promise<RouteID | undefined>"
      },
      "docs": {
        "text": "",
        "tags": [{
            "name": "internal",
            "text": undefined
          }]
      }
    }
  }; }
  static get elementRef() { return "el"; }
  static get watchers() { return [{
      "propName": "swipeHandler",
      "methodName": "swipeHandlerChanged"
    }]; }
}
