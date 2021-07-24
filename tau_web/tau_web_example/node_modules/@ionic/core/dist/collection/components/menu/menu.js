import { Build, Component, Element, Event, Host, Listen, Method, Prop, State, Watch, h } from '@stencil/core';
import { config } from '../../global/config';
import { getIonMode } from '../../global/ionic-global';
import { getTimeGivenProgression } from '../../utils/animation/cubic-bezier';
import { GESTURE_CONTROLLER } from '../../utils/gesture';
import { assert, clamp, isEndSide as isEnd } from '../../utils/helpers';
import { menuController } from '../../utils/menu-controller';
const iosEasing = 'cubic-bezier(0.32,0.72,0,1)';
const mdEasing = 'cubic-bezier(0.0,0.0,0.2,1)';
const iosEasingReverse = 'cubic-bezier(1, 0, 0.68, 0.28)';
const mdEasingReverse = 'cubic-bezier(0.4, 0, 0.6, 1)';
/**
 * @part container - The container for the menu content.
 * @part backdrop - The backdrop that appears over the main content when the menu is open.
 */
export class Menu {
  constructor() {
    this.lastOnEnd = 0;
    this.blocker = GESTURE_CONTROLLER.createBlocker({ disableScroll: true });
    this.isAnimating = false;
    this._isOpen = false;
    this.isPaneVisible = false;
    this.isEndSide = false;
    /**
     * If `true`, the menu is disabled.
     */
    this.disabled = false;
    /**
     * Which side of the view the menu should be placed.
     */
    this.side = 'start';
    /**
     * If `true`, swiping the menu is enabled.
     */
    this.swipeGesture = true;
    /**
     * The edge threshold for dragging the menu open.
     * If a drag/swipe happens over this value, the menu is not triggered.
     */
    this.maxEdgeStart = 50;
  }
  typeChanged(type, oldType) {
    const contentEl = this.contentEl;
    if (contentEl) {
      if (oldType !== undefined) {
        contentEl.classList.remove(`menu-content-${oldType}`);
      }
      contentEl.classList.add(`menu-content-${type}`);
      contentEl.removeAttribute('style');
    }
    if (this.menuInnerEl) {
      // Remove effects of previous animations
      this.menuInnerEl.removeAttribute('style');
    }
    this.animation = undefined;
  }
  disabledChanged() {
    this.updateState();
    this.ionMenuChange.emit({
      disabled: this.disabled,
      open: this._isOpen
    });
  }
  sideChanged() {
    this.isEndSide = isEnd(this.side);
  }
  swipeGestureChanged() {
    this.updateState();
  }
  async connectedCallback() {
    if (this.type === undefined) {
      this.type = config.get('menuType', 'overlay');
    }
    if (!Build.isBrowser) {
      this.disabled = true;
      return;
    }
    const el = this.el;
    const parent = el.parentNode;
    if (this.contentId === undefined) {
      console.warn(`[DEPRECATED][ion-menu] Using the [main] attribute is deprecated, please use the "contentId" property instead:
BEFORE:
  <ion-menu>...</ion-menu>
  <div main>...</div>

AFTER:
  <ion-menu contentId="main-content"></ion-menu>
  <div id="main-content">...</div>
`);
    }
    const content = this.contentId !== undefined
      ? document.getElementById(this.contentId)
      : parent && parent.querySelector && parent.querySelector('[main]');
    if (!content || !content.tagName) {
      // requires content element
      console.error('Menu: must have a "content" element to listen for drag events on.');
      return;
    }
    this.contentEl = content;
    // add menu's content classes
    content.classList.add('menu-content');
    this.typeChanged(this.type, undefined);
    this.sideChanged();
    // register this menu with the app's menu controller
    menuController._register(this);
    this.gesture = (await import('../../utils/gesture')).createGesture({
      el: document,
      gestureName: 'menu-swipe',
      gesturePriority: 30,
      threshold: 10,
      blurOnStart: true,
      canStart: ev => this.canStart(ev),
      onWillStart: () => this.onWillStart(),
      onStart: () => this.onStart(),
      onMove: ev => this.onMove(ev),
      onEnd: ev => this.onEnd(ev),
    });
    this.updateState();
  }
  async componentDidLoad() {
    this.ionMenuChange.emit({ disabled: this.disabled, open: this._isOpen });
    this.updateState();
  }
  disconnectedCallback() {
    this.blocker.destroy();
    menuController._unregister(this);
    if (this.animation) {
      this.animation.destroy();
    }
    if (this.gesture) {
      this.gesture.destroy();
      this.gesture = undefined;
    }
    this.animation = undefined;
    this.contentEl = this.backdropEl = this.menuInnerEl = undefined;
  }
  onSplitPaneChanged(ev) {
    this.isPaneVisible = ev.detail.isPane(this.el);
    this.updateState();
  }
  onBackdropClick(ev) {
    if (this._isOpen && this.lastOnEnd < ev.timeStamp - 100) {
      const shouldClose = (ev.composedPath)
        ? !ev.composedPath().includes(this.menuInnerEl)
        : false;
      if (shouldClose) {
        ev.preventDefault();
        ev.stopPropagation();
        this.close();
      }
    }
  }
  /**
   * Returns `true` is the menu is open.
   */
  isOpen() {
    return Promise.resolve(this._isOpen);
  }
  /**
   * Returns `true` is the menu is active.
   *
   * A menu is active when it can be opened or closed, meaning it's enabled
   * and it's not part of a `ion-split-pane`.
   */
  isActive() {
    return Promise.resolve(this._isActive());
  }
  /**
   * Opens the menu. If the menu is already open or it can't be opened,
   * it returns `false`.
   */
  open(animated = true) {
    return this.setOpen(true, animated);
  }
  /**
   * Closes the menu. If the menu is already closed or it can't be closed,
   * it returns `false`.
   */
  close(animated = true) {
    return this.setOpen(false, animated);
  }
  /**
   * Toggles the menu. If the menu is already open, it will try to close, otherwise it will try to open it.
   * If the operation can't be completed successfully, it returns `false`.
   */
  toggle(animated = true) {
    return this.setOpen(!this._isOpen, animated);
  }
  /**
   * Opens or closes the button.
   * If the operation can't be completed successfully, it returns `false`.
   */
  setOpen(shouldOpen, animated = true) {
    return menuController._setOpen(this, shouldOpen, animated);
  }
  async _setOpen(shouldOpen, animated = true) {
    // If the menu is disabled or it is currently being animated, let's do nothing
    if (!this._isActive() || this.isAnimating || shouldOpen === this._isOpen) {
      return false;
    }
    this.beforeAnimation(shouldOpen);
    await this.loadAnimation();
    await this.startAnimation(shouldOpen, animated);
    this.afterAnimation(shouldOpen);
    return true;
  }
  async loadAnimation() {
    // Menu swipe animation takes the menu's inner width as parameter,
    // If `offsetWidth` changes, we need to create a new animation.
    const width = this.menuInnerEl.offsetWidth;
    if (width === this.width && this.animation !== undefined) {
      return;
    }
    this.width = width;
    // Destroy existing animation
    if (this.animation) {
      this.animation.destroy();
      this.animation = undefined;
    }
    // Create new animation
    this.animation = await menuController._createAnimation(this.type, this);
    if (!config.getBoolean('animated', true)) {
      this.animation.duration(0);
    }
    this.animation.fill('both');
  }
  async startAnimation(shouldOpen, animated) {
    const isReversed = !shouldOpen;
    const mode = getIonMode(this);
    const easing = mode === 'ios' ? iosEasing : mdEasing;
    const easingReverse = mode === 'ios' ? iosEasingReverse : mdEasingReverse;
    const ani = this.animation
      .direction((isReversed) ? 'reverse' : 'normal')
      .easing((isReversed) ? easingReverse : easing)
      .onFinish(() => {
      if (ani.getDirection() === 'reverse') {
        ani.direction('normal');
      }
    });
    if (animated) {
      await ani.play();
    }
    else {
      ani.play({ sync: true });
    }
  }
  _isActive() {
    return !this.disabled && !this.isPaneVisible;
  }
  canSwipe() {
    return this.swipeGesture && !this.isAnimating && this._isActive();
  }
  canStart(detail) {
    // Do not allow swipe gesture if a modal is open
    const isModalPresented = !!document.querySelector('ion-modal.show-modal');
    if (isModalPresented || !this.canSwipe()) {
      return false;
    }
    if (this._isOpen) {
      return true;
      // TODO error
    }
    else if (menuController._getOpenSync()) {
      return false;
    }
    return checkEdgeSide(window, detail.currentX, this.isEndSide, this.maxEdgeStart);
  }
  onWillStart() {
    this.beforeAnimation(!this._isOpen);
    return this.loadAnimation();
  }
  onStart() {
    if (!this.isAnimating || !this.animation) {
      assert(false, 'isAnimating has to be true');
      return;
    }
    // the cloned animation should not use an easing curve during seek
    this.animation.progressStart(true, (this._isOpen) ? 1 : 0);
  }
  onMove(detail) {
    if (!this.isAnimating || !this.animation) {
      assert(false, 'isAnimating has to be true');
      return;
    }
    const delta = computeDelta(detail.deltaX, this._isOpen, this.isEndSide);
    const stepValue = delta / this.width;
    this.animation.progressStep((this._isOpen) ? 1 - stepValue : stepValue);
  }
  onEnd(detail) {
    if (!this.isAnimating || !this.animation) {
      assert(false, 'isAnimating has to be true');
      return;
    }
    const isOpen = this._isOpen;
    const isEndSide = this.isEndSide;
    const delta = computeDelta(detail.deltaX, isOpen, isEndSide);
    const width = this.width;
    const stepValue = delta / width;
    const velocity = detail.velocityX;
    const z = width / 2.0;
    const shouldCompleteRight = velocity >= 0 && (velocity > 0.2 || detail.deltaX > z);
    const shouldCompleteLeft = velocity <= 0 && (velocity < -0.2 || detail.deltaX < -z);
    const shouldComplete = isOpen
      ? isEndSide ? shouldCompleteRight : shouldCompleteLeft
      : isEndSide ? shouldCompleteLeft : shouldCompleteRight;
    let shouldOpen = !isOpen && shouldComplete;
    if (isOpen && !shouldComplete) {
      shouldOpen = true;
    }
    this.lastOnEnd = detail.currentTime;
    // Account for rounding errors in JS
    let newStepValue = (shouldComplete) ? 0.001 : -0.001;
    /**
     * TODO: stepValue can sometimes return a negative
     * value, but you can't have a negative time value
     * for the cubic bezier curve (at least with web animations)
     * Not sure if the negative step value is an error or not
     */
    const adjustedStepValue = (stepValue < 0) ? 0.01 : stepValue;
    /**
     * Animation will be reversed here, so need to
     * reverse the easing curve as well
     *
     * Additionally, we need to account for the time relative
     * to the new easing curve, as `stepValue` is going to be given
     * in terms of a linear curve.
     */
    newStepValue += getTimeGivenProgression([0, 0], [0.4, 0], [0.6, 1], [1, 1], clamp(0, adjustedStepValue, 0.9999))[0] || 0;
    const playTo = (this._isOpen) ? !shouldComplete : shouldComplete;
    this.animation
      .easing('cubic-bezier(0.4, 0.0, 0.6, 1)')
      .onFinish(() => this.afterAnimation(shouldOpen), { oneTimeCallback: true })
      .progressEnd((playTo) ? 1 : 0, (this._isOpen) ? 1 - newStepValue : newStepValue, 300);
  }
  beforeAnimation(shouldOpen) {
    assert(!this.isAnimating, '_before() should not be called while animating');
    // this places the menu into the correct location before it animates in
    // this css class doesn't actually kick off any animations
    this.el.classList.add(SHOW_MENU);
    if (this.backdropEl) {
      this.backdropEl.classList.add(SHOW_BACKDROP);
    }
    this.blocker.block();
    this.isAnimating = true;
    if (shouldOpen) {
      this.ionWillOpen.emit();
    }
    else {
      this.ionWillClose.emit();
    }
  }
  afterAnimation(isOpen) {
    assert(this.isAnimating, '_before() should be called while animating');
    // keep opening/closing the menu disabled for a touch more yet
    // only add listeners/css if it's enabled and isOpen
    // and only remove listeners/css if it's not open
    // emit opened/closed events
    this._isOpen = isOpen;
    this.isAnimating = false;
    if (!this._isOpen) {
      this.blocker.unblock();
    }
    if (isOpen) {
      // add css class
      if (this.contentEl) {
        this.contentEl.classList.add(MENU_CONTENT_OPEN);
      }
      // emit open event
      this.ionDidOpen.emit();
    }
    else {
      // remove css classes
      this.el.classList.remove(SHOW_MENU);
      if (this.contentEl) {
        this.contentEl.classList.remove(MENU_CONTENT_OPEN);
      }
      if (this.backdropEl) {
        this.backdropEl.classList.remove(SHOW_BACKDROP);
      }
      if (this.animation) {
        this.animation.stop();
      }
      // emit close event
      this.ionDidClose.emit();
    }
  }
  updateState() {
    const isActive = this._isActive();
    if (this.gesture) {
      this.gesture.enable(isActive && this.swipeGesture);
    }
    // Close menu immediately
    if (!isActive && this._isOpen) {
      // close if this menu is open, and should not be enabled
      this.forceClosing();
    }
    if (!this.disabled) {
      menuController._setActiveMenu(this);
    }
    assert(!this.isAnimating, 'can not be animating');
  }
  forceClosing() {
    assert(this._isOpen, 'menu cannot be closed');
    this.isAnimating = true;
    const ani = this.animation.direction('reverse');
    ani.play({ sync: true });
    this.afterAnimation(false);
  }
  render() {
    const { isEndSide, type, disabled, isPaneVisible } = this;
    const mode = getIonMode(this);
    return (h(Host, { role: "navigation", class: {
        [mode]: true,
        [`menu-type-${type}`]: true,
        'menu-enabled': !disabled,
        'menu-side-end': isEndSide,
        'menu-side-start': !isEndSide,
        'menu-pane-visible': isPaneVisible
      } },
      h("div", { class: "menu-inner", part: "container", ref: el => this.menuInnerEl = el },
        h("slot", null)),
      h("ion-backdrop", { ref: el => this.backdropEl = el, class: "menu-backdrop", tappable: false, stopPropagation: false, part: "backdrop" })));
  }
  static get is() { return "ion-menu"; }
  static get encapsulation() { return "shadow"; }
  static get originalStyleUrls() { return {
    "ios": ["menu.ios.scss"],
    "md": ["menu.md.scss"]
  }; }
  static get styleUrls() { return {
    "ios": ["menu.ios.css"],
    "md": ["menu.md.css"]
  }; }
  static get properties() { return {
    "contentId": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string",
        "resolved": "string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The `id` of the main content. When using\na router this is typically `ion-router-outlet`.\nWhen not using a router, this is typically\nyour main view's `ion-content`. This is not the\nid of the `ion-content` inside of your `ion-menu`."
      },
      "attribute": "content-id",
      "reflect": true
    },
    "menuId": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string",
        "resolved": "string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "An id for the menu."
      },
      "attribute": "menu-id",
      "reflect": true
    },
    "type": {
      "type": "string",
      "mutable": true,
      "complexType": {
        "original": "string",
        "resolved": "string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The display type of the menu.\nAvailable options: `\"overlay\"`, `\"reveal\"`, `\"push\"`."
      },
      "attribute": "type",
      "reflect": false
    },
    "disabled": {
      "type": "boolean",
      "mutable": true,
      "complexType": {
        "original": "boolean",
        "resolved": "boolean",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "If `true`, the menu is disabled."
      },
      "attribute": "disabled",
      "reflect": false,
      "defaultValue": "false"
    },
    "side": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "Side",
        "resolved": "\"end\" | \"start\"",
        "references": {
          "Side": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "Which side of the view the menu should be placed."
      },
      "attribute": "side",
      "reflect": true,
      "defaultValue": "'start'"
    },
    "swipeGesture": {
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
        "text": "If `true`, swiping the menu is enabled."
      },
      "attribute": "swipe-gesture",
      "reflect": false,
      "defaultValue": "true"
    },
    "maxEdgeStart": {
      "type": "number",
      "mutable": false,
      "complexType": {
        "original": "number",
        "resolved": "number",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "The edge threshold for dragging the menu open.\nIf a drag/swipe happens over this value, the menu is not triggered."
      },
      "attribute": "max-edge-start",
      "reflect": false,
      "defaultValue": "50"
    }
  }; }
  static get states() { return {
    "isPaneVisible": {},
    "isEndSide": {}
  }; }
  static get events() { return [{
      "method": "ionWillOpen",
      "name": "ionWillOpen",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the menu is about to be opened."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionWillClose",
      "name": "ionWillClose",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the menu is about to be closed."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionDidOpen",
      "name": "ionDidOpen",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the menu is open."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionDidClose",
      "name": "ionDidClose",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the menu is closed."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionMenuChange",
      "name": "ionMenuChange",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [{
            "text": undefined,
            "name": "internal"
          }],
        "text": "Emitted when the menu state is changed."
      },
      "complexType": {
        "original": "MenuChangeEventDetail",
        "resolved": "MenuChangeEventDetail",
        "references": {
          "MenuChangeEventDetail": {
            "location": "import",
            "path": "../../interface"
          }
        }
      }
    }]; }
  static get methods() { return {
    "isOpen": {
      "complexType": {
        "signature": "() => Promise<boolean>",
        "parameters": [],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "Returns `true` is the menu is open.",
        "tags": []
      }
    },
    "isActive": {
      "complexType": {
        "signature": "() => Promise<boolean>",
        "parameters": [],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "Returns `true` is the menu is active.\n\nA menu is active when it can be opened or closed, meaning it's enabled\nand it's not part of a `ion-split-pane`.",
        "tags": []
      }
    },
    "open": {
      "complexType": {
        "signature": "(animated?: boolean) => Promise<boolean>",
        "parameters": [{
            "tags": [],
            "text": ""
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "Opens the menu. If the menu is already open or it can't be opened,\nit returns `false`.",
        "tags": []
      }
    },
    "close": {
      "complexType": {
        "signature": "(animated?: boolean) => Promise<boolean>",
        "parameters": [{
            "tags": [],
            "text": ""
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "Closes the menu. If the menu is already closed or it can't be closed,\nit returns `false`.",
        "tags": []
      }
    },
    "toggle": {
      "complexType": {
        "signature": "(animated?: boolean) => Promise<boolean>",
        "parameters": [{
            "tags": [],
            "text": ""
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "Toggles the menu. If the menu is already open, it will try to close, otherwise it will try to open it.\nIf the operation can't be completed successfully, it returns `false`.",
        "tags": []
      }
    },
    "setOpen": {
      "complexType": {
        "signature": "(shouldOpen: boolean, animated?: boolean) => Promise<boolean>",
        "parameters": [{
            "tags": [],
            "text": ""
          }, {
            "tags": [],
            "text": ""
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "Opens or closes the button.\nIf the operation can't be completed successfully, it returns `false`.",
        "tags": []
      }
    }
  }; }
  static get elementRef() { return "el"; }
  static get watchers() { return [{
      "propName": "type",
      "methodName": "typeChanged"
    }, {
      "propName": "disabled",
      "methodName": "disabledChanged"
    }, {
      "propName": "side",
      "methodName": "sideChanged"
    }, {
      "propName": "swipeGesture",
      "methodName": "swipeGestureChanged"
    }]; }
  static get listeners() { return [{
      "name": "ionSplitPaneVisible",
      "method": "onSplitPaneChanged",
      "target": "body",
      "capture": false,
      "passive": false
    }, {
      "name": "click",
      "method": "onBackdropClick",
      "target": undefined,
      "capture": true,
      "passive": false
    }]; }
}
const computeDelta = (deltaX, isOpen, isEndSide) => {
  return Math.max(0, isOpen !== isEndSide ? -deltaX : deltaX);
};
const checkEdgeSide = (win, posX, isEndSide, maxEdgeStart) => {
  if (isEndSide) {
    return posX >= win.innerWidth - maxEdgeStart;
  }
  else {
    return posX <= maxEdgeStart;
  }
};
const SHOW_MENU = 'show-menu';
const SHOW_BACKDROP = 'show-backdrop';
const MENU_CONTENT_OPEN = 'menu-content-open';
