import { Component, Element, Event, Host, Method, Prop, Watch, h, writeTask } from '@stencil/core';
import { config } from '../../global/config';
import { getIonMode } from '../../global/ionic-global';
import { attachComponent, detachComponent } from '../../utils/framework-delegate';
import { BACKDROP, activeAnimations, dismiss, eventMethod, prepareOverlay, present } from '../../utils/overlays';
import { getClassMap } from '../../utils/theme';
import { deepReady } from '../../utils/transition';
import { iosEnterAnimation } from './animations/ios.enter';
import { iosLeaveAnimation } from './animations/ios.leave';
import { mdEnterAnimation } from './animations/md.enter';
import { mdLeaveAnimation } from './animations/md.leave';
import { createSwipeToCloseGesture } from './gestures/swipe-to-close';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export class Modal {
  constructor() {
    // Whether or not modal is being dismissed via gesture
    this.gestureAnimationDismissing = false;
    this.presented = false;
    /**
     * If `true`, the keyboard will be automatically dismissed when the overlay is presented.
     */
    this.keyboardClose = true;
    /**
     * If `true`, the modal will be dismissed when the backdrop is clicked.
     */
    this.backdropDismiss = true;
    /**
     * If `true`, a backdrop will be displayed behind the modal.
     */
    this.showBackdrop = true;
    /**
     * If `true`, the modal will animate.
     */
    this.animated = true;
    /**
     * If `true`, the modal can be swiped to dismiss. Only applies in iOS mode.
     */
    this.swipeToClose = false;
    this.onBackdropTap = () => {
      this.dismiss(undefined, BACKDROP);
    };
    this.onDismiss = (ev) => {
      ev.stopPropagation();
      ev.preventDefault();
      this.dismiss();
    };
    this.onLifecycle = (modalEvent) => {
      const el = this.usersElement;
      const name = LIFECYCLE_MAP[modalEvent.type];
      if (el && name) {
        const ev = new CustomEvent(name, {
          bubbles: false,
          cancelable: false,
          detail: modalEvent.detail
        });
        el.dispatchEvent(ev);
      }
    };
  }
  swipeToCloseChanged(enable) {
    if (this.gesture) {
      this.gesture.enable(enable);
    }
    else if (enable) {
      this.initSwipeToClose();
    }
  }
  connectedCallback() {
    prepareOverlay(this.el);
  }
  /**
   * Present the modal overlay after it has been created.
   */
  async present() {
    if (this.presented) {
      return;
    }
    const container = this.el.querySelector(`.modal-wrapper`);
    if (!container) {
      throw new Error('container is undefined');
    }
    const componentProps = Object.assign(Object.assign({}, this.componentProps), { modal: this.el });
    this.usersElement = await attachComponent(this.delegate, container, this.component, ['ion-page'], componentProps);
    await deepReady(this.usersElement);
    writeTask(() => this.el.classList.add('show-modal'));
    await present(this, 'modalEnter', iosEnterAnimation, mdEnterAnimation, this.presentingElement);
    if (this.swipeToClose) {
      this.initSwipeToClose();
    }
  }
  initSwipeToClose() {
    if (getIonMode(this) !== 'ios') {
      return;
    }
    // All of the elements needed for the swipe gesture
    // should be in the DOM and referenced by now, except
    // for the presenting el
    const animationBuilder = this.leaveAnimation || config.get('modalLeave', iosLeaveAnimation);
    const ani = this.animation = animationBuilder(this.el, this.presentingElement);
    this.gesture = createSwipeToCloseGesture(this.el, ani, () => {
      /**
       * While the gesture animation is finishing
       * it is possible for a user to tap the backdrop.
       * This would result in the dismiss animation
       * being played again. Typically this is avoided
       * by setting `presented = false` on the overlay
       * component; however, we cannot do that here as
       * that would prevent the element from being
       * removed from the DOM.
       */
      this.gestureAnimationDismissing = true;
      this.animation.onFinish(async () => {
        await this.dismiss(undefined, 'gesture');
        this.gestureAnimationDismissing = false;
      });
    });
    this.gesture.enable(true);
  }
  /**
   * Dismiss the modal overlay after it has been presented.
   *
   * @param data Any data to emit in the dismiss events.
   * @param role The role of the element that is dismissing the modal. For example, 'cancel' or 'backdrop'.
   */
  async dismiss(data, role) {
    if (this.gestureAnimationDismissing && role !== 'gesture') {
      return false;
    }
    const enteringAnimation = activeAnimations.get(this) || [];
    const dismissed = await dismiss(this, data, role, 'modalLeave', iosLeaveAnimation, mdLeaveAnimation, this.presentingElement);
    if (dismissed) {
      await detachComponent(this.delegate, this.usersElement);
      if (this.animation) {
        this.animation.destroy();
      }
      enteringAnimation.forEach(ani => ani.destroy());
    }
    this.animation = undefined;
    return dismissed;
  }
  /**
   * Returns a promise that resolves when the modal did dismiss.
   */
  onDidDismiss() {
    return eventMethod(this.el, 'ionModalDidDismiss');
  }
  /**
   * Returns a promise that resolves when the modal will dismiss.
   */
  onWillDismiss() {
    return eventMethod(this.el, 'ionModalWillDismiss');
  }
  render() {
    const mode = getIonMode(this);
    return (h(Host, { "no-router": true, "aria-modal": "true", tabindex: "-1", class: Object.assign({ [mode]: true, [`modal-card`]: this.presentingElement !== undefined && mode === 'ios' }, getClassMap(this.cssClass)), style: {
        zIndex: `${20000 + this.overlayIndex}`,
      }, onIonBackdropTap: this.onBackdropTap, onIonDismiss: this.onDismiss, onIonModalDidPresent: this.onLifecycle, onIonModalWillPresent: this.onLifecycle, onIonModalWillDismiss: this.onLifecycle, onIonModalDidDismiss: this.onLifecycle },
      h("ion-backdrop", { visible: this.showBackdrop, tappable: this.backdropDismiss }),
      mode === 'ios' && h("div", { class: "modal-shadow" }),
      h("div", { tabindex: "0" }),
      h("div", { role: "dialog", class: "modal-wrapper ion-overlay-wrapper" }),
      h("div", { tabindex: "0" })));
  }
  static get is() { return "ion-modal"; }
  static get encapsulation() { return "scoped"; }
  static get originalStyleUrls() { return {
    "ios": ["modal.ios.scss"],
    "md": ["modal.md.scss"]
  }; }
  static get styleUrls() { return {
    "ios": ["modal.ios.css"],
    "md": ["modal.md.css"]
  }; }
  static get properties() { return {
    "overlayIndex": {
      "type": "number",
      "mutable": false,
      "complexType": {
        "original": "number",
        "resolved": "number",
        "references": {}
      },
      "required": true,
      "optional": false,
      "docs": {
        "tags": [{
            "text": undefined,
            "name": "internal"
          }],
        "text": ""
      },
      "attribute": "overlay-index",
      "reflect": false
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
    "keyboardClose": {
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
        "text": "If `true`, the keyboard will be automatically dismissed when the overlay is presented."
      },
      "attribute": "keyboard-close",
      "reflect": false,
      "defaultValue": "true"
    },
    "enterAnimation": {
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
        "text": "Animation to use when the modal is presented."
      }
    },
    "leaveAnimation": {
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
        "text": "Animation to use when the modal is dismissed."
      }
    },
    "component": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "ComponentRef",
        "resolved": "Function | HTMLElement | null | string",
        "references": {
          "ComponentRef": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": true,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "The component to display inside of the modal."
      },
      "attribute": "component",
      "reflect": false
    },
    "componentProps": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "ComponentProps",
        "resolved": "undefined | { [key: string]: any; }",
        "references": {
          "ComponentProps": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The data to pass to the modal component."
      }
    },
    "cssClass": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string | string[]",
        "resolved": "string | string[] | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Additional classes to apply for custom CSS. If multiple classes are\nprovided they should be separated by spaces."
      },
      "attribute": "css-class",
      "reflect": false
    },
    "backdropDismiss": {
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
        "text": "If `true`, the modal will be dismissed when the backdrop is clicked."
      },
      "attribute": "backdrop-dismiss",
      "reflect": false,
      "defaultValue": "true"
    },
    "showBackdrop": {
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
        "text": "If `true`, a backdrop will be displayed behind the modal."
      },
      "attribute": "show-backdrop",
      "reflect": false,
      "defaultValue": "true"
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
        "text": "If `true`, the modal will animate."
      },
      "attribute": "animated",
      "reflect": false,
      "defaultValue": "true"
    },
    "swipeToClose": {
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
        "text": "If `true`, the modal can be swiped to dismiss. Only applies in iOS mode."
      },
      "attribute": "swipe-to-close",
      "reflect": false,
      "defaultValue": "false"
    },
    "presentingElement": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "HTMLElement",
        "resolved": "HTMLElement | undefined",
        "references": {
          "HTMLElement": {
            "location": "global"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The element that presented the modal. This is used for card presentation effects\nand for stacking multiple modals on top of each other. Only applies in iOS mode."
      }
    }
  }; }
  static get events() { return [{
      "method": "didPresent",
      "name": "ionModalDidPresent",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted after the modal has presented."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "willPresent",
      "name": "ionModalWillPresent",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted before the modal has presented."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "willDismiss",
      "name": "ionModalWillDismiss",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted before the modal has dismissed."
      },
      "complexType": {
        "original": "OverlayEventDetail",
        "resolved": "OverlayEventDetail<any>",
        "references": {
          "OverlayEventDetail": {
            "location": "import",
            "path": "../../interface"
          }
        }
      }
    }, {
      "method": "didDismiss",
      "name": "ionModalDidDismiss",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted after the modal has dismissed."
      },
      "complexType": {
        "original": "OverlayEventDetail",
        "resolved": "OverlayEventDetail<any>",
        "references": {
          "OverlayEventDetail": {
            "location": "import",
            "path": "../../interface"
          }
        }
      }
    }]; }
  static get methods() { return {
    "present": {
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
        "text": "Present the modal overlay after it has been created.",
        "tags": []
      }
    },
    "dismiss": {
      "complexType": {
        "signature": "(data?: any, role?: string | undefined) => Promise<boolean>",
        "parameters": [{
            "tags": [{
                "text": "data Any data to emit in the dismiss events.",
                "name": "param"
              }],
            "text": "Any data to emit in the dismiss events."
          }, {
            "tags": [{
                "text": "role The role of the element that is dismissing the modal. For example, 'cancel' or 'backdrop'.",
                "name": "param"
              }],
            "text": "The role of the element that is dismissing the modal. For example, 'cancel' or 'backdrop'."
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "Dismiss the modal overlay after it has been presented.",
        "tags": [{
            "name": "param",
            "text": "data Any data to emit in the dismiss events."
          }, {
            "name": "param",
            "text": "role The role of the element that is dismissing the modal. For example, 'cancel' or 'backdrop'."
          }]
      }
    },
    "onDidDismiss": {
      "complexType": {
        "signature": "<T = any>() => Promise<OverlayEventDetail<T>>",
        "parameters": [],
        "references": {
          "Promise": {
            "location": "global"
          },
          "OverlayEventDetail": {
            "location": "import",
            "path": "../../interface"
          },
          "T": {
            "location": "global"
          }
        },
        "return": "Promise<OverlayEventDetail<T>>"
      },
      "docs": {
        "text": "Returns a promise that resolves when the modal did dismiss.",
        "tags": []
      }
    },
    "onWillDismiss": {
      "complexType": {
        "signature": "<T = any>() => Promise<OverlayEventDetail<T>>",
        "parameters": [],
        "references": {
          "Promise": {
            "location": "global"
          },
          "OverlayEventDetail": {
            "location": "import",
            "path": "../../interface"
          },
          "T": {
            "location": "global"
          }
        },
        "return": "Promise<OverlayEventDetail<T>>"
      },
      "docs": {
        "text": "Returns a promise that resolves when the modal will dismiss.",
        "tags": []
      }
    }
  }; }
  static get elementRef() { return "el"; }
  static get watchers() { return [{
      "propName": "swipeToClose",
      "methodName": "swipeToCloseChanged"
    }]; }
}
const LIFECYCLE_MAP = {
  'ionModalDidPresent': 'ionViewDidEnter',
  'ionModalWillPresent': 'ionViewWillEnter',
  'ionModalWillDismiss': 'ionViewWillLeave',
  'ionModalDidDismiss': 'ionViewDidLeave',
};
