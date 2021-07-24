import { Component, Element, Event, Host, Method, Prop, Watch, h } from '@stencil/core';
import { getIonMode } from '../../global/ionic-global';
import { componentOnReady } from '../../utils/helpers';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export class Slides {
  constructor() {
    this.swiperReady = false;
    this.swiper = new Promise(resolve => { this.readySwiper = resolve; });
    this.didInit = false;
    /**
     * Options to pass to the swiper instance.
     * See http://idangero.us/swiper/api/ for valid options
     */
    this.options = {}; // SwiperOptions;  // TODO
    /**
     * If `true`, show the pagination.
     */
    this.pager = false;
    /**
     * If `true`, show the scrollbar.
     */
    this.scrollbar = false;
  }
  async optionsChanged() {
    if (this.swiperReady) {
      const swiper = await this.getSwiper();
      if (swiper === null || swiper === void 0 ? void 0 : swiper.params) {
        Object.assign(swiper.params, this.options);
        await this.update();
      }
    }
  }
  connectedCallback() {
    // tslint:disable-next-line: strict-type-predicates
    if (typeof MutationObserver !== 'undefined') {
      const mut = this.mutationO = new MutationObserver(() => {
        if (this.swiperReady) {
          this.update();
        }
      });
      mut.observe(this.el, {
        childList: true,
        subtree: true
      });
      componentOnReady(this.el, () => {
        if (!this.didInit) {
          this.didInit = true;
          this.initSwiper();
        }
      });
    }
  }
  disconnectedCallback() {
    if (this.mutationO) {
      this.mutationO.disconnect();
      this.mutationO = undefined;
    }
    /**
     * We need to synchronously destroy
     * swiper otherwise it is possible
     * that it will be left in a
     * destroyed state if connectedCallback
     * is called multiple times
     */
    const swiper = this.syncSwiper;
    if (swiper !== undefined) {
      swiper.destroy(true, true);
      this.swiper = new Promise(resolve => { this.readySwiper = resolve; });
      this.swiperReady = false;
      this.syncSwiper = undefined;
    }
    this.didInit = false;
  }
  /**
   * Update the underlying slider implementation. Call this if you've added or removed
   * child slides.
   */
  async update() {
    const [swiper] = await Promise.all([
      this.getSwiper(),
      waitForSlides(this.el)
    ]);
    swiper.update();
  }
  /**
   * Force swiper to update its height (when autoHeight is enabled) for the duration
   * equal to 'speed' parameter.
   *
   * @param speed The transition duration (in ms).
   */
  async updateAutoHeight(speed) {
    const swiper = await this.getSwiper();
    swiper.updateAutoHeight(speed);
  }
  /**
   * Transition to the specified slide.
   *
   * @param index The index of the slide to transition to.
   * @param speed The transition duration (in ms).
   * @param runCallbacks If true, the transition will produce [Transition/SlideChange][Start/End] transition events.
   */
  async slideTo(index, speed, runCallbacks) {
    const swiper = await this.getSwiper();
    swiper.slideTo(index, speed, runCallbacks);
  }
  /**
   * Transition to the next slide.
   *
   * @param speed The transition duration (in ms).
   * @param runCallbacks If true, the transition will produce [Transition/SlideChange][Start/End] transition events.
   */
  async slideNext(speed, runCallbacks) {
    const swiper = await this.getSwiper();
    swiper.slideNext(speed, runCallbacks);
  }
  /**
   * Transition to the previous slide.
   *
   * @param speed The transition duration (in ms).
   * @param runCallbacks If true, the transition will produce the [Transition/SlideChange][Start/End] transition events.
   */
  async slidePrev(speed, runCallbacks) {
    const swiper = await this.getSwiper();
    swiper.slidePrev(speed, runCallbacks);
  }
  /**
   * Get the index of the active slide.
   */
  async getActiveIndex() {
    const swiper = await this.getSwiper();
    return swiper.activeIndex;
  }
  /**
   * Get the index of the previous slide.
   */
  async getPreviousIndex() {
    const swiper = await this.getSwiper();
    return swiper.previousIndex;
  }
  /**
   * Get the total number of slides.
   */
  async length() {
    const swiper = await this.getSwiper();
    return swiper.slides.length;
  }
  /**
   * Get whether or not the current slide is the last slide.
   */
  async isEnd() {
    const swiper = await this.getSwiper();
    return swiper.isEnd;
  }
  /**
   * Get whether or not the current slide is the first slide.
   */
  async isBeginning() {
    const swiper = await this.getSwiper();
    return swiper.isBeginning;
  }
  /**
   * Start auto play.
   */
  async startAutoplay() {
    const swiper = await this.getSwiper();
    if (swiper.autoplay) {
      swiper.autoplay.start();
    }
  }
  /**
   * Stop auto play.
   */
  async stopAutoplay() {
    const swiper = await this.getSwiper();
    if (swiper.autoplay) {
      swiper.autoplay.stop();
    }
  }
  /**
   * Lock or unlock the ability to slide to the next slide.
   *
   * @param lock If `true`, disable swiping to the next slide.
   */
  async lockSwipeToNext(lock) {
    const swiper = await this.getSwiper();
    swiper.allowSlideNext = !lock;
  }
  /**
   * Lock or unlock the ability to slide to the previous slide.
   *
   * @param lock If `true`, disable swiping to the previous slide.
   */
  async lockSwipeToPrev(lock) {
    const swiper = await this.getSwiper();
    swiper.allowSlidePrev = !lock;
  }
  /**
   * Lock or unlock the ability to slide to the next or previous slide.
   *
   * @param lock If `true`, disable swiping to the next and previous slide.
   */
  async lockSwipes(lock) {
    const swiper = await this.getSwiper();
    swiper.allowSlideNext = !lock;
    swiper.allowSlidePrev = !lock;
    swiper.allowTouchMove = !lock;
  }
  /**
   * Get the Swiper instance.
   * Use this to access the full Swiper API.
   * See https://idangero.us/swiper/api/ for all API options.
   */
  async getSwiper() {
    return this.swiper;
  }
  async initSwiper() {
    const finalOptions = this.normalizeOptions();
    // init swiper core
    // @ts-ignore
    const { Swiper } = await import('./swiper/swiper.bundle.js');
    await waitForSlides(this.el);
    const swiper = new Swiper(this.el, finalOptions);
    this.swiperReady = true;
    this.syncSwiper = swiper;
    this.readySwiper(swiper);
  }
  normalizeOptions() {
    // Base options, can be changed
    // TODO Add interface SwiperOptions
    const swiperOptions = {
      effect: undefined,
      direction: 'horizontal',
      initialSlide: 0,
      loop: false,
      parallax: false,
      slidesPerView: 1,
      spaceBetween: 0,
      speed: 300,
      slidesPerColumn: 1,
      slidesPerColumnFill: 'column',
      slidesPerGroup: 1,
      centeredSlides: false,
      slidesOffsetBefore: 0,
      slidesOffsetAfter: 0,
      touchEventsTarget: 'container',
      autoplay: false,
      freeMode: false,
      freeModeMomentum: true,
      freeModeMomentumRatio: 1,
      freeModeMomentumBounce: true,
      freeModeMomentumBounceRatio: 1,
      freeModeMomentumVelocityRatio: 1,
      freeModeSticky: false,
      freeModeMinimumVelocity: 0.02,
      autoHeight: false,
      setWrapperSize: false,
      zoom: {
        maxRatio: 3,
        minRatio: 1,
        toggle: false,
      },
      touchRatio: 1,
      touchAngle: 45,
      simulateTouch: true,
      touchStartPreventDefault: false,
      shortSwipes: true,
      longSwipes: true,
      longSwipesRatio: 0.5,
      longSwipesMs: 300,
      followFinger: true,
      threshold: 0,
      touchMoveStopPropagation: true,
      touchReleaseOnEdges: false,
      iOSEdgeSwipeDetection: false,
      iOSEdgeSwipeThreshold: 20,
      resistance: true,
      resistanceRatio: 0.85,
      watchSlidesProgress: false,
      watchSlidesVisibility: false,
      preventClicks: true,
      preventClicksPropagation: true,
      slideToClickedSlide: false,
      loopAdditionalSlides: 0,
      noSwiping: true,
      runCallbacksOnInit: true,
      coverflowEffect: {
        rotate: 50,
        stretch: 0,
        depth: 100,
        modifier: 1,
        slideShadows: true
      },
      flipEffect: {
        slideShadows: true,
        limitRotation: true
      },
      cubeEffect: {
        slideShadows: true,
        shadow: true,
        shadowOffset: 20,
        shadowScale: 0.94
      },
      fadeEffect: {
        crossFade: false
      },
      a11y: {
        prevSlideMessage: 'Previous slide',
        nextSlideMessage: 'Next slide',
        firstSlideMessage: 'This is the first slide',
        lastSlideMessage: 'This is the last slide'
      }
    };
    if (this.pager) {
      swiperOptions.pagination = {
        el: this.paginationEl,
        type: 'bullets',
        clickable: false,
        hideOnClick: false,
      };
    }
    if (this.scrollbar) {
      swiperOptions.scrollbar = {
        el: this.scrollbarEl,
        hide: true,
      };
    }
    // Keep the event options separate, we dont want users
    // overwriting these
    const eventOptions = {
      on: {
        init: () => {
          setTimeout(() => {
            this.ionSlidesDidLoad.emit();
          }, 20);
        },
        slideChangeTransitionStart: this.ionSlideWillChange.emit,
        slideChangeTransitionEnd: this.ionSlideDidChange.emit,
        slideNextTransitionStart: this.ionSlideNextStart.emit,
        slidePrevTransitionStart: this.ionSlidePrevStart.emit,
        slideNextTransitionEnd: this.ionSlideNextEnd.emit,
        slidePrevTransitionEnd: this.ionSlidePrevEnd.emit,
        transitionStart: this.ionSlideTransitionStart.emit,
        transitionEnd: this.ionSlideTransitionEnd.emit,
        sliderMove: this.ionSlideDrag.emit,
        reachBeginning: this.ionSlideReachStart.emit,
        reachEnd: this.ionSlideReachEnd.emit,
        touchStart: this.ionSlideTouchStart.emit,
        touchEnd: this.ionSlideTouchEnd.emit,
        tap: this.ionSlideTap.emit,
        doubleTap: this.ionSlideDoubleTap.emit
      }
    };
    const customEvents = (!!this.options && !!this.options.on) ? this.options.on : {};
    // merge "on" event listeners, while giving our event listeners priority
    const mergedEventOptions = { on: Object.assign(Object.assign({}, customEvents), eventOptions.on) };
    // Merge the base, user options, and events together then pas to swiper
    return Object.assign(Object.assign(Object.assign({}, swiperOptions), this.options), mergedEventOptions);
  }
  render() {
    const mode = getIonMode(this);
    return (h(Host, { class: {
        [`${mode}`]: true,
        // Used internally for styling
        [`slides-${mode}`]: true,
        'swiper-container': true
      } },
      h("div", { class: "swiper-wrapper" },
        h("slot", null)),
      this.pager && h("div", { class: "swiper-pagination", ref: el => this.paginationEl = el }),
      this.scrollbar && h("div", { class: "swiper-scrollbar", ref: el => this.scrollbarEl = el })));
  }
  static get is() { return "ion-slides"; }
  static get originalStyleUrls() { return {
    "ios": ["slides.ios.scss"],
    "md": ["slides.md.scss"]
  }; }
  static get styleUrls() { return {
    "ios": ["slides.ios.css"],
    "md": ["slides.md.css"]
  }; }
  static get assetsDirs() { return ["swiper"]; }
  static get properties() { return {
    "options": {
      "type": "any",
      "mutable": false,
      "complexType": {
        "original": "any",
        "resolved": "any",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "Options to pass to the swiper instance.\nSee http://idangero.us/swiper/api/ for valid options"
      },
      "attribute": "options",
      "reflect": false,
      "defaultValue": "{}"
    },
    "pager": {
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
        "text": "If `true`, show the pagination."
      },
      "attribute": "pager",
      "reflect": false,
      "defaultValue": "false"
    },
    "scrollbar": {
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
        "text": "If `true`, show the scrollbar."
      },
      "attribute": "scrollbar",
      "reflect": false,
      "defaultValue": "false"
    }
  }; }
  static get events() { return [{
      "method": "ionSlidesDidLoad",
      "name": "ionSlidesDidLoad",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted after Swiper initialization"
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionSlideTap",
      "name": "ionSlideTap",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the user taps/clicks on the slide's container."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionSlideDoubleTap",
      "name": "ionSlideDoubleTap",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the user double taps on the slide's container."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionSlideWillChange",
      "name": "ionSlideWillChange",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted before the active slide has changed."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionSlideDidChange",
      "name": "ionSlideDidChange",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted after the active slide has changed."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionSlideNextStart",
      "name": "ionSlideNextStart",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the next slide has started."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionSlidePrevStart",
      "name": "ionSlidePrevStart",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the previous slide has started."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionSlideNextEnd",
      "name": "ionSlideNextEnd",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the next slide has ended."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionSlidePrevEnd",
      "name": "ionSlidePrevEnd",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the previous slide has ended."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionSlideTransitionStart",
      "name": "ionSlideTransitionStart",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the slide transition has started."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionSlideTransitionEnd",
      "name": "ionSlideTransitionEnd",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the slide transition has ended."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionSlideDrag",
      "name": "ionSlideDrag",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the slider is actively being moved."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionSlideReachStart",
      "name": "ionSlideReachStart",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the slider is at its initial position."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionSlideReachEnd",
      "name": "ionSlideReachEnd",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the slider is at the last slide."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionSlideTouchStart",
      "name": "ionSlideTouchStart",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the user first touches the slider."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionSlideTouchEnd",
      "name": "ionSlideTouchEnd",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the user releases the touch."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }]; }
  static get methods() { return {
    "update": {
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
        "text": "Update the underlying slider implementation. Call this if you've added or removed\nchild slides.",
        "tags": []
      }
    },
    "updateAutoHeight": {
      "complexType": {
        "signature": "(speed?: number | undefined) => Promise<void>",
        "parameters": [{
            "tags": [{
                "text": "speed The transition duration (in ms).",
                "name": "param"
              }],
            "text": "The transition duration (in ms)."
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<void>"
      },
      "docs": {
        "text": "Force swiper to update its height (when autoHeight is enabled) for the duration\nequal to 'speed' parameter.",
        "tags": [{
            "name": "param",
            "text": "speed The transition duration (in ms)."
          }]
      }
    },
    "slideTo": {
      "complexType": {
        "signature": "(index: number, speed?: number | undefined, runCallbacks?: boolean | undefined) => Promise<void>",
        "parameters": [{
            "tags": [{
                "text": "index The index of the slide to transition to.",
                "name": "param"
              }],
            "text": "The index of the slide to transition to."
          }, {
            "tags": [{
                "text": "speed The transition duration (in ms).",
                "name": "param"
              }],
            "text": "The transition duration (in ms)."
          }, {
            "tags": [{
                "text": "runCallbacks If true, the transition will produce [Transition/SlideChange][Start/End] transition events.",
                "name": "param"
              }],
            "text": "If true, the transition will produce [Transition/SlideChange][Start/End] transition events."
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<void>"
      },
      "docs": {
        "text": "Transition to the specified slide.",
        "tags": [{
            "name": "param",
            "text": "index The index of the slide to transition to."
          }, {
            "name": "param",
            "text": "speed The transition duration (in ms)."
          }, {
            "name": "param",
            "text": "runCallbacks If true, the transition will produce [Transition/SlideChange][Start/End] transition events."
          }]
      }
    },
    "slideNext": {
      "complexType": {
        "signature": "(speed?: number | undefined, runCallbacks?: boolean | undefined) => Promise<void>",
        "parameters": [{
            "tags": [{
                "text": "speed The transition duration (in ms).",
                "name": "param"
              }],
            "text": "The transition duration (in ms)."
          }, {
            "tags": [{
                "text": "runCallbacks If true, the transition will produce [Transition/SlideChange][Start/End] transition events.",
                "name": "param"
              }],
            "text": "If true, the transition will produce [Transition/SlideChange][Start/End] transition events."
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<void>"
      },
      "docs": {
        "text": "Transition to the next slide.",
        "tags": [{
            "name": "param",
            "text": "speed The transition duration (in ms)."
          }, {
            "name": "param",
            "text": "runCallbacks If true, the transition will produce [Transition/SlideChange][Start/End] transition events."
          }]
      }
    },
    "slidePrev": {
      "complexType": {
        "signature": "(speed?: number | undefined, runCallbacks?: boolean | undefined) => Promise<void>",
        "parameters": [{
            "tags": [{
                "text": "speed The transition duration (in ms).",
                "name": "param"
              }],
            "text": "The transition duration (in ms)."
          }, {
            "tags": [{
                "text": "runCallbacks If true, the transition will produce the [Transition/SlideChange][Start/End] transition events.",
                "name": "param"
              }],
            "text": "If true, the transition will produce the [Transition/SlideChange][Start/End] transition events."
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<void>"
      },
      "docs": {
        "text": "Transition to the previous slide.",
        "tags": [{
            "name": "param",
            "text": "speed The transition duration (in ms)."
          }, {
            "name": "param",
            "text": "runCallbacks If true, the transition will produce the [Transition/SlideChange][Start/End] transition events."
          }]
      }
    },
    "getActiveIndex": {
      "complexType": {
        "signature": "() => Promise<number>",
        "parameters": [],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<number>"
      },
      "docs": {
        "text": "Get the index of the active slide.",
        "tags": []
      }
    },
    "getPreviousIndex": {
      "complexType": {
        "signature": "() => Promise<number>",
        "parameters": [],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<number>"
      },
      "docs": {
        "text": "Get the index of the previous slide.",
        "tags": []
      }
    },
    "length": {
      "complexType": {
        "signature": "() => Promise<number>",
        "parameters": [],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<number>"
      },
      "docs": {
        "text": "Get the total number of slides.",
        "tags": []
      }
    },
    "isEnd": {
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
        "text": "Get whether or not the current slide is the last slide.",
        "tags": []
      }
    },
    "isBeginning": {
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
        "text": "Get whether or not the current slide is the first slide.",
        "tags": []
      }
    },
    "startAutoplay": {
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
        "text": "Start auto play.",
        "tags": []
      }
    },
    "stopAutoplay": {
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
        "text": "Stop auto play.",
        "tags": []
      }
    },
    "lockSwipeToNext": {
      "complexType": {
        "signature": "(lock: boolean) => Promise<void>",
        "parameters": [{
            "tags": [{
                "text": "lock If `true`, disable swiping to the next slide.",
                "name": "param"
              }],
            "text": "If `true`, disable swiping to the next slide."
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<void>"
      },
      "docs": {
        "text": "Lock or unlock the ability to slide to the next slide.",
        "tags": [{
            "name": "param",
            "text": "lock If `true`, disable swiping to the next slide."
          }]
      }
    },
    "lockSwipeToPrev": {
      "complexType": {
        "signature": "(lock: boolean) => Promise<void>",
        "parameters": [{
            "tags": [{
                "text": "lock If `true`, disable swiping to the previous slide.",
                "name": "param"
              }],
            "text": "If `true`, disable swiping to the previous slide."
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<void>"
      },
      "docs": {
        "text": "Lock or unlock the ability to slide to the previous slide.",
        "tags": [{
            "name": "param",
            "text": "lock If `true`, disable swiping to the previous slide."
          }]
      }
    },
    "lockSwipes": {
      "complexType": {
        "signature": "(lock: boolean) => Promise<void>",
        "parameters": [{
            "tags": [{
                "text": "lock If `true`, disable swiping to the next and previous slide.",
                "name": "param"
              }],
            "text": "If `true`, disable swiping to the next and previous slide."
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<void>"
      },
      "docs": {
        "text": "Lock or unlock the ability to slide to the next or previous slide.",
        "tags": [{
            "name": "param",
            "text": "lock If `true`, disable swiping to the next and previous slide."
          }]
      }
    },
    "getSwiper": {
      "complexType": {
        "signature": "() => Promise<any>",
        "parameters": [],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<any>"
      },
      "docs": {
        "text": "Get the Swiper instance.\nUse this to access the full Swiper API.\nSee https://idangero.us/swiper/api/ for all API options.",
        "tags": []
      }
    }
  }; }
  static get elementRef() { return "el"; }
  static get watchers() { return [{
      "propName": "options",
      "methodName": "optionsChanged"
    }]; }
}
const waitForSlides = (el) => {
  return Promise.all(Array.from(el.querySelectorAll('ion-slide')).map(s => new Promise(resolve => componentOnReady(s, resolve))));
};
