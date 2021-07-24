import { Component, Element, Event, Host, Listen, Method, Prop, forceUpdate, h, readTask } from '@stencil/core';
import { config } from '../../global/config';
import { getIonMode } from '../../global/ionic-global';
import { isPlatform } from '../../utils/platform';
import { createColorClasses, hostContext } from '../../utils/theme';
/**
 * @slot - Content is placed in the scrollable area if provided without a slot.
 * @slot fixed - Should be used for fixed content that should not scroll.
 *
 * @part background - The background of the content.
 * @part scroll - The scrollable container of the content.
 */
export class Content {
  constructor() {
    this.isScrolling = false;
    this.lastScroll = 0;
    this.queued = false;
    this.cTop = -1;
    this.cBottom = -1;
    this.isMainContent = true;
    // Detail is used in a hot loop in the scroll event, by allocating it here
    // V8 will be able to inline any read/write to it since it's a monomorphic class.
    // https://mrale.ph/blog/2015/01/11/whats-up-with-monomorphism.html
    this.detail = {
      scrollTop: 0,
      scrollLeft: 0,
      type: 'scroll',
      event: undefined,
      startX: 0,
      startY: 0,
      startTime: 0,
      currentX: 0,
      currentY: 0,
      velocityX: 0,
      velocityY: 0,
      deltaX: 0,
      deltaY: 0,
      currentTime: 0,
      data: undefined,
      isScrolling: true,
    };
    /**
     * If `true`, the content will scroll behind the headers
     * and footers. This effect can easily be seen by setting the toolbar
     * to transparent.
     */
    this.fullscreen = false;
    /**
     * If you want to enable the content scrolling in the X axis, set this property to `true`.
     */
    this.scrollX = false;
    /**
     * If you want to disable the content scrolling in the Y axis, set this property to `false`.
     */
    this.scrollY = true;
    /**
     * Because of performance reasons, ionScroll events are disabled by default, in order to enable them
     * and start listening from (ionScroll), set this property to `true`.
     */
    this.scrollEvents = false;
  }
  connectedCallback() {
    this.isMainContent = this.el.closest('ion-menu, ion-popover, ion-modal') === null;
  }
  disconnectedCallback() {
    this.onScrollEnd();
  }
  onAppLoad() {
    this.resize();
  }
  onClick(ev) {
    if (this.isScrolling) {
      ev.preventDefault();
      ev.stopPropagation();
    }
  }
  shouldForceOverscroll() {
    const { forceOverscroll } = this;
    const mode = getIonMode(this);
    return forceOverscroll === undefined
      ? mode === 'ios' && isPlatform('ios')
      : forceOverscroll;
  }
  resize() {
    if (this.fullscreen) {
      readTask(() => this.readDimensions());
    }
    else if (this.cTop !== 0 || this.cBottom !== 0) {
      this.cTop = this.cBottom = 0;
      forceUpdate(this);
    }
  }
  readDimensions() {
    const page = getPageElement(this.el);
    const top = Math.max(this.el.offsetTop, 0);
    const bottom = Math.max(page.offsetHeight - top - this.el.offsetHeight, 0);
    const dirty = top !== this.cTop || bottom !== this.cBottom;
    if (dirty) {
      this.cTop = top;
      this.cBottom = bottom;
      forceUpdate(this);
    }
  }
  onScroll(ev) {
    const timeStamp = Date.now();
    const shouldStart = !this.isScrolling;
    this.lastScroll = timeStamp;
    if (shouldStart) {
      this.onScrollStart();
    }
    if (!this.queued && this.scrollEvents) {
      this.queued = true;
      readTask(ts => {
        this.queued = false;
        this.detail.event = ev;
        updateScrollDetail(this.detail, this.scrollEl, ts, shouldStart);
        this.ionScroll.emit(this.detail);
      });
    }
  }
  /**
   * Get the element where the actual scrolling takes place.
   * This element can be used to subscribe to `scroll` events or manually modify
   * `scrollTop`. However, it's recommended to use the API provided by `ion-content`:
   *
   * i.e. Using `ionScroll`, `ionScrollStart`, `ionScrollEnd` for scrolling events
   * and `scrollToPoint()` to scroll the content into a certain point.
   */
  getScrollElement() {
    return Promise.resolve(this.scrollEl);
  }
  /**
   * Scroll to the top of the component.
   *
   * @param duration The amount of time to take scrolling to the top. Defaults to `0`.
   */
  scrollToTop(duration = 0) {
    return this.scrollToPoint(undefined, 0, duration);
  }
  /**
   * Scroll to the bottom of the component.
   *
   * @param duration The amount of time to take scrolling to the bottom. Defaults to `0`.
   */
  scrollToBottom(duration = 0) {
    const y = this.scrollEl.scrollHeight - this.scrollEl.clientHeight;
    return this.scrollToPoint(undefined, y, duration);
  }
  /**
   * Scroll by a specified X/Y distance in the component.
   *
   * @param x The amount to scroll by on the horizontal axis.
   * @param y The amount to scroll by on the vertical axis.
   * @param duration The amount of time to take scrolling by that amount.
   */
  scrollByPoint(x, y, duration) {
    return this.scrollToPoint(x + this.scrollEl.scrollLeft, y + this.scrollEl.scrollTop, duration);
  }
  /**
   * Scroll to a specified X/Y location in the component.
   *
   * @param x The point to scroll to on the horizontal axis.
   * @param y The point to scroll to on the vertical axis.
   * @param duration The amount of time to take scrolling to that point. Defaults to `0`.
   */
  async scrollToPoint(x, y, duration = 0) {
    const el = this.scrollEl;
    if (duration < 32) {
      if (y != null) {
        el.scrollTop = y;
      }
      if (x != null) {
        el.scrollLeft = x;
      }
      return;
    }
    let resolve;
    let startTime = 0;
    const promise = new Promise(r => resolve = r);
    const fromY = el.scrollTop;
    const fromX = el.scrollLeft;
    const deltaY = y != null ? y - fromY : 0;
    const deltaX = x != null ? x - fromX : 0;
    // scroll loop
    const step = (timeStamp) => {
      const linearTime = Math.min(1, ((timeStamp - startTime) / duration)) - 1;
      const easedT = Math.pow(linearTime, 3) + 1;
      if (deltaY !== 0) {
        el.scrollTop = Math.floor((easedT * deltaY) + fromY);
      }
      if (deltaX !== 0) {
        el.scrollLeft = Math.floor((easedT * deltaX) + fromX);
      }
      if (easedT < 1) {
        // do not use DomController here
        // must use nativeRaf in order to fire in the next frame
        // TODO: remove as any
        requestAnimationFrame(step);
      }
      else {
        resolve();
      }
    };
    // chill out for a frame first
    requestAnimationFrame(ts => {
      startTime = ts;
      step(ts);
    });
    return promise;
  }
  onScrollStart() {
    this.isScrolling = true;
    this.ionScrollStart.emit({
      isScrolling: true
    });
    if (this.watchDog) {
      clearInterval(this.watchDog);
    }
    // watchdog
    this.watchDog = setInterval(() => {
      if (this.lastScroll < Date.now() - 120) {
        this.onScrollEnd();
      }
    }, 100);
  }
  onScrollEnd() {
    clearInterval(this.watchDog);
    this.watchDog = null;
    if (this.isScrolling) {
      this.isScrolling = false;
      this.ionScrollEnd.emit({
        isScrolling: false
      });
    }
  }
  render() {
    const { isMainContent, scrollX, scrollY } = this;
    const mode = getIonMode(this);
    const forceOverscroll = this.shouldForceOverscroll();
    const TagType = isMainContent ? 'main' : 'div';
    const transitionShadow = (mode === 'ios' && config.getBoolean('experimentalTransitionShadow', true));
    this.resize();
    return (h(Host, { class: createColorClasses(this.color, {
        [mode]: true,
        'content-sizing': hostContext('ion-popover', this.el),
        'overscroll': forceOverscroll,
      }), style: {
        '--offset-top': `${this.cTop}px`,
        '--offset-bottom': `${this.cBottom}px`,
      } },
      h("div", { id: "background-content", part: "background" }),
      h(TagType, { class: {
          'inner-scroll': true,
          'scroll-x': scrollX,
          'scroll-y': scrollY,
          'overscroll': (scrollX || scrollY) && forceOverscroll
        }, ref: (el) => this.scrollEl = el, onScroll: (this.scrollEvents) ? (ev) => this.onScroll(ev) : undefined, part: "scroll" },
        h("slot", null)),
      transitionShadow ? (h("div", { class: "transition-effect" },
        h("div", { class: "transition-cover" }),
        h("div", { class: "transition-shadow" }))) : null,
      h("slot", { name: "fixed" })));
  }
  static get is() { return "ion-content"; }
  static get encapsulation() { return "shadow"; }
  static get originalStyleUrls() { return {
    "$": ["content.scss"]
  }; }
  static get styleUrls() { return {
    "$": ["content.css"]
  }; }
  static get properties() { return {
    "color": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "Color",
        "resolved": "string | undefined",
        "references": {
          "Color": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The color to use from your application's color palette.\nDefault options are: `\"primary\"`, `\"secondary\"`, `\"tertiary\"`, `\"success\"`, `\"warning\"`, `\"danger\"`, `\"light\"`, `\"medium\"`, and `\"dark\"`.\nFor more information on colors, see [theming](/docs/theming/basics)."
      },
      "attribute": "color",
      "reflect": true
    },
    "fullscreen": {
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
        "text": "If `true`, the content will scroll behind the headers\nand footers. This effect can easily be seen by setting the toolbar\nto transparent."
      },
      "attribute": "fullscreen",
      "reflect": false,
      "defaultValue": "false"
    },
    "forceOverscroll": {
      "type": "boolean",
      "mutable": true,
      "complexType": {
        "original": "boolean",
        "resolved": "boolean | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "If `true` and the content does not cause an overflow scroll, the scroll interaction will cause a bounce.\nIf the content exceeds the bounds of ionContent, nothing will change.\nNote, the does not disable the system bounce on iOS. That is an OS level setting."
      },
      "attribute": "force-overscroll",
      "reflect": false
    },
    "scrollX": {
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
        "text": "If you want to enable the content scrolling in the X axis, set this property to `true`."
      },
      "attribute": "scroll-x",
      "reflect": false,
      "defaultValue": "false"
    },
    "scrollY": {
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
        "text": "If you want to disable the content scrolling in the Y axis, set this property to `false`."
      },
      "attribute": "scroll-y",
      "reflect": false,
      "defaultValue": "true"
    },
    "scrollEvents": {
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
        "text": "Because of performance reasons, ionScroll events are disabled by default, in order to enable them\nand start listening from (ionScroll), set this property to `true`."
      },
      "attribute": "scroll-events",
      "reflect": false,
      "defaultValue": "false"
    }
  }; }
  static get events() { return [{
      "method": "ionScrollStart",
      "name": "ionScrollStart",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the scroll has started."
      },
      "complexType": {
        "original": "ScrollBaseDetail",
        "resolved": "ScrollBaseDetail",
        "references": {
          "ScrollBaseDetail": {
            "location": "import",
            "path": "../../interface"
          }
        }
      }
    }, {
      "method": "ionScroll",
      "name": "ionScroll",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted while scrolling. This event is disabled by default.\nLook at the property: `scrollEvents`"
      },
      "complexType": {
        "original": "ScrollDetail",
        "resolved": "ScrollDetail",
        "references": {
          "ScrollDetail": {
            "location": "import",
            "path": "../../interface"
          }
        }
      }
    }, {
      "method": "ionScrollEnd",
      "name": "ionScrollEnd",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the scroll has ended."
      },
      "complexType": {
        "original": "ScrollBaseDetail",
        "resolved": "ScrollBaseDetail",
        "references": {
          "ScrollBaseDetail": {
            "location": "import",
            "path": "../../interface"
          }
        }
      }
    }]; }
  static get methods() { return {
    "getScrollElement": {
      "complexType": {
        "signature": "() => Promise<HTMLElement>",
        "parameters": [],
        "references": {
          "Promise": {
            "location": "global"
          },
          "HTMLElement": {
            "location": "global"
          }
        },
        "return": "Promise<HTMLElement>"
      },
      "docs": {
        "text": "Get the element where the actual scrolling takes place.\nThis element can be used to subscribe to `scroll` events or manually modify\n`scrollTop`. However, it's recommended to use the API provided by `ion-content`:\n\ni.e. Using `ionScroll`, `ionScrollStart`, `ionScrollEnd` for scrolling events\nand `scrollToPoint()` to scroll the content into a certain point.",
        "tags": []
      }
    },
    "scrollToTop": {
      "complexType": {
        "signature": "(duration?: number) => Promise<void>",
        "parameters": [{
            "tags": [{
                "text": "duration The amount of time to take scrolling to the top. Defaults to `0`.",
                "name": "param"
              }],
            "text": "The amount of time to take scrolling to the top. Defaults to `0`."
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<void>"
      },
      "docs": {
        "text": "Scroll to the top of the component.",
        "tags": [{
            "name": "param",
            "text": "duration The amount of time to take scrolling to the top. Defaults to `0`."
          }]
      }
    },
    "scrollToBottom": {
      "complexType": {
        "signature": "(duration?: number) => Promise<void>",
        "parameters": [{
            "tags": [{
                "text": "duration The amount of time to take scrolling to the bottom. Defaults to `0`.",
                "name": "param"
              }],
            "text": "The amount of time to take scrolling to the bottom. Defaults to `0`."
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<void>"
      },
      "docs": {
        "text": "Scroll to the bottom of the component.",
        "tags": [{
            "name": "param",
            "text": "duration The amount of time to take scrolling to the bottom. Defaults to `0`."
          }]
      }
    },
    "scrollByPoint": {
      "complexType": {
        "signature": "(x: number, y: number, duration: number) => Promise<void>",
        "parameters": [{
            "tags": [{
                "text": "x The amount to scroll by on the horizontal axis.",
                "name": "param"
              }],
            "text": "The amount to scroll by on the horizontal axis."
          }, {
            "tags": [{
                "text": "y The amount to scroll by on the vertical axis.",
                "name": "param"
              }],
            "text": "The amount to scroll by on the vertical axis."
          }, {
            "tags": [{
                "text": "duration The amount of time to take scrolling by that amount.",
                "name": "param"
              }],
            "text": "The amount of time to take scrolling by that amount."
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<void>"
      },
      "docs": {
        "text": "Scroll by a specified X/Y distance in the component.",
        "tags": [{
            "name": "param",
            "text": "x The amount to scroll by on the horizontal axis."
          }, {
            "name": "param",
            "text": "y The amount to scroll by on the vertical axis."
          }, {
            "name": "param",
            "text": "duration The amount of time to take scrolling by that amount."
          }]
      }
    },
    "scrollToPoint": {
      "complexType": {
        "signature": "(x: number | undefined | null, y: number | undefined | null, duration?: number) => Promise<void>",
        "parameters": [{
            "tags": [{
                "text": "x The point to scroll to on the horizontal axis.",
                "name": "param"
              }],
            "text": "The point to scroll to on the horizontal axis."
          }, {
            "tags": [{
                "text": "y The point to scroll to on the vertical axis.",
                "name": "param"
              }],
            "text": "The point to scroll to on the vertical axis."
          }, {
            "tags": [{
                "text": "duration The amount of time to take scrolling to that point. Defaults to `0`.",
                "name": "param"
              }],
            "text": "The amount of time to take scrolling to that point. Defaults to `0`."
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<void>"
      },
      "docs": {
        "text": "Scroll to a specified X/Y location in the component.",
        "tags": [{
            "name": "param",
            "text": "x The point to scroll to on the horizontal axis."
          }, {
            "name": "param",
            "text": "y The point to scroll to on the vertical axis."
          }, {
            "name": "param",
            "text": "duration The amount of time to take scrolling to that point. Defaults to `0`."
          }]
      }
    }
  }; }
  static get elementRef() { return "el"; }
  static get listeners() { return [{
      "name": "appload",
      "method": "onAppLoad",
      "target": "window",
      "capture": false,
      "passive": false
    }, {
      "name": "click",
      "method": "onClick",
      "target": undefined,
      "capture": true,
      "passive": false
    }]; }
}
const getParentElement = (el) => {
  if (el.parentElement) {
    // normal element with a parent element
    return el.parentElement;
  }
  if (el.parentNode && el.parentNode.host) {
    // shadow dom's document fragment
    return el.parentNode.host;
  }
  return null;
};
const getPageElement = (el) => {
  const tabs = el.closest('ion-tabs');
  if (tabs) {
    return tabs;
  }
  const page = el.closest('ion-app,ion-page,.ion-page,page-inner');
  if (page) {
    return page;
  }
  return getParentElement(el);
};
// ******** DOM READ ****************
const updateScrollDetail = (detail, el, timestamp, shouldStart) => {
  const prevX = detail.currentX;
  const prevY = detail.currentY;
  const prevT = detail.currentTime;
  const currentX = el.scrollLeft;
  const currentY = el.scrollTop;
  const timeDelta = timestamp - prevT;
  if (shouldStart) {
    // remember the start positions
    detail.startTime = timestamp;
    detail.startX = currentX;
    detail.startY = currentY;
    detail.velocityX = detail.velocityY = 0;
  }
  detail.currentTime = timestamp;
  detail.currentX = detail.scrollLeft = currentX;
  detail.currentY = detail.scrollTop = currentY;
  detail.deltaX = currentX - detail.startX;
  detail.deltaY = currentY - detail.startY;
  if (timeDelta > 0 && timeDelta < 100) {
    const velocityX = (currentX - prevX) / timeDelta;
    const velocityY = (currentY - prevY) / timeDelta;
    detail.velocityX = velocityX * 0.7 + detail.velocityX * 0.3;
    detail.velocityY = velocityY * 0.7 + detail.velocityY * 0.3;
  }
};
