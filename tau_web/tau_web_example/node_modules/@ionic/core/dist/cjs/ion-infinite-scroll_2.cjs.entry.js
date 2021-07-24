'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

const index = require('./index-a0a08b2a.js');
const ionicGlobal = require('./ionic-global-06f21c1a.js');
const index$1 = require('./index-e1bb33c3.js');

const infiniteScrollCss = "ion-infinite-scroll{display:none;width:100%}.infinite-scroll-enabled{display:block}";

const InfiniteScroll = class {
  constructor(hostRef) {
    index.registerInstance(this, hostRef);
    this.ionInfinite = index.createEvent(this, "ionInfinite", 7);
    this.thrPx = 0;
    this.thrPc = 0;
    this.didFire = false;
    this.isBusy = false;
    this.isLoading = false;
    /**
     * The threshold distance from the bottom
     * of the content to call the `infinite` output event when scrolled.
     * The threshold value can be either a percent, or
     * in pixels. For example, use the value of `10%` for the `infinite`
     * output event to get called when the user has scrolled 10%
     * from the bottom of the page. Use the value `100px` when the
     * scroll is within 100 pixels from the bottom of the page.
     */
    this.threshold = '15%';
    /**
     * If `true`, the infinite scroll will be hidden and scroll event listeners
     * will be removed.
     *
     * Set this to true to disable the infinite scroll from actively
     * trying to receive new data while scrolling. This is useful
     * when it is known that there is no more data that can be added, and
     * the infinite scroll is no longer needed.
     */
    this.disabled = false;
    /**
     * The position of the infinite scroll element.
     * The value can be either `top` or `bottom`.
     */
    this.position = 'bottom';
    this.onScroll = () => {
      const scrollEl = this.scrollEl;
      if (!scrollEl || !this.canStart()) {
        return 1;
      }
      const infiniteHeight = this.el.offsetHeight;
      if (infiniteHeight === 0) {
        // if there is no height of this element then do nothing
        return 2;
      }
      const scrollTop = scrollEl.scrollTop;
      const scrollHeight = scrollEl.scrollHeight;
      const height = scrollEl.offsetHeight;
      const threshold = this.thrPc !== 0 ? (height * this.thrPc) : this.thrPx;
      const distanceFromInfinite = (this.position === 'bottom')
        ? scrollHeight - infiniteHeight - scrollTop - threshold - height
        : scrollTop - infiniteHeight - threshold;
      if (distanceFromInfinite < 0) {
        if (!this.didFire) {
          this.isLoading = true;
          this.didFire = true;
          this.ionInfinite.emit();
          return 3;
        }
      }
      else {
        this.didFire = false;
      }
      return 4;
    };
  }
  thresholdChanged() {
    const val = this.threshold;
    if (val.lastIndexOf('%') > -1) {
      this.thrPx = 0;
      this.thrPc = (parseFloat(val) / 100);
    }
    else {
      this.thrPx = parseFloat(val);
      this.thrPc = 0;
    }
  }
  disabledChanged() {
    const disabled = this.disabled;
    if (disabled) {
      this.isLoading = false;
      this.isBusy = false;
    }
    this.enableScrollEvents(!disabled);
  }
  async connectedCallback() {
    const contentEl = this.el.closest('ion-content');
    if (!contentEl) {
      console.error('<ion-infinite-scroll> must be used inside an <ion-content>');
      return;
    }
    this.scrollEl = await contentEl.getScrollElement();
    this.thresholdChanged();
    this.disabledChanged();
    if (this.position === 'top') {
      index.writeTask(() => {
        if (this.scrollEl) {
          this.scrollEl.scrollTop = this.scrollEl.scrollHeight - this.scrollEl.clientHeight;
        }
      });
    }
  }
  disconnectedCallback() {
    this.enableScrollEvents(false);
    this.scrollEl = undefined;
  }
  /**
   * Call `complete()` within the `ionInfinite` output event handler when
   * your async operation has completed. For example, the `loading`
   * state is while the app is performing an asynchronous operation,
   * such as receiving more data from an AJAX request to add more items
   * to a data list. Once the data has been received and UI updated, you
   * then call this method to signify that the loading has completed.
   * This method will change the infinite scroll's state from `loading`
   * to `enabled`.
   */
  async complete() {
    const scrollEl = this.scrollEl;
    if (!this.isLoading || !scrollEl) {
      return;
    }
    this.isLoading = false;
    if (this.position === 'top') {
      /**
       * New content is being added at the top, but the scrollTop position stays the same,
       * which causes a scroll jump visually. This algorithm makes sure to prevent this.
       * (Frame 1)
       *    - complete() is called, but the UI hasn't had time to update yet.
       *    - Save the current content dimensions.
       *    - Wait for the next frame using _dom.read, so the UI will be updated.
       * (Frame 2)
       *    - Read the new content dimensions.
       *    - Calculate the height difference and the new scroll position.
       *    - Delay the scroll position change until other possible dom reads are done using _dom.write to be performant.
       * (Still frame 2, if I'm correct)
       *    - Change the scroll position (= visually maintain the scroll position).
       *    - Change the state to re-enable the InfiniteScroll.
       *    - This should be after changing the scroll position, or it could
       *    cause the InfiniteScroll to be triggered again immediately.
       * (Frame 3)
       *    Done.
       */
      this.isBusy = true;
      // ******** DOM READ ****************
      // Save the current content dimensions before the UI updates
      const prev = scrollEl.scrollHeight - scrollEl.scrollTop;
      // ******** DOM READ ****************
      requestAnimationFrame(() => {
        index.readTask(() => {
          // UI has updated, save the new content dimensions
          const scrollHeight = scrollEl.scrollHeight;
          // New content was added on top, so the scroll position should be changed immediately to prevent it from jumping around
          const newScrollTop = scrollHeight - prev;
          // ******** DOM WRITE ****************
          requestAnimationFrame(() => {
            index.writeTask(() => {
              scrollEl.scrollTop = newScrollTop;
              this.isBusy = false;
            });
          });
        });
      });
    }
  }
  canStart() {
    return (!this.disabled &&
      !this.isBusy &&
      !!this.scrollEl &&
      !this.isLoading);
  }
  enableScrollEvents(shouldListen) {
    if (this.scrollEl) {
      if (shouldListen) {
        this.scrollEl.addEventListener('scroll', this.onScroll);
      }
      else {
        this.scrollEl.removeEventListener('scroll', this.onScroll);
      }
    }
  }
  render() {
    const mode = ionicGlobal.getIonMode(this);
    const disabled = this.disabled;
    return (index.h(index.Host, { class: {
        [mode]: true,
        'infinite-scroll-loading': this.isLoading,
        'infinite-scroll-enabled': !disabled
      } }));
  }
  get el() { return index.getElement(this); }
  static get watchers() { return {
    "threshold": ["thresholdChanged"],
    "disabled": ["disabledChanged"]
  }; }
};
InfiniteScroll.style = infiniteScrollCss;

const infiniteScrollContentIosCss = "ion-infinite-scroll-content{display:-ms-flexbox;display:flex;-ms-flex-direction:column;flex-direction:column;-ms-flex-pack:center;justify-content:center;min-height:84px;text-align:center;-webkit-user-select:none;-moz-user-select:none;-ms-user-select:none;user-select:none}.infinite-loading{margin-left:0;margin-right:0;margin-top:0;margin-bottom:32px;display:none;width:100%}.infinite-loading-text{margin-left:32px;margin-right:32px;margin-top:4px;margin-bottom:0}@supports ((-webkit-margin-start: 0) or (margin-inline-start: 0)) or (-webkit-margin-start: 0){.infinite-loading-text{margin-left:unset;margin-right:unset;-webkit-margin-start:32px;margin-inline-start:32px;-webkit-margin-end:32px;margin-inline-end:32px}}.infinite-scroll-loading ion-infinite-scroll-content>.infinite-loading{display:block}.infinite-scroll-content-ios .infinite-loading-text{color:var(--ion-color-step-600, #666666)}.infinite-scroll-content-ios .infinite-loading-spinner .spinner-lines-ios line,.infinite-scroll-content-ios .infinite-loading-spinner .spinner-lines-small-ios line,.infinite-scroll-content-ios .infinite-loading-spinner .spinner-crescent circle{stroke:var(--ion-color-step-600, #666666)}.infinite-scroll-content-ios .infinite-loading-spinner .spinner-bubbles circle,.infinite-scroll-content-ios .infinite-loading-spinner .spinner-circles circle,.infinite-scroll-content-ios .infinite-loading-spinner .spinner-dots circle{fill:var(--ion-color-step-600, #666666)}";

const infiniteScrollContentMdCss = "ion-infinite-scroll-content{display:-ms-flexbox;display:flex;-ms-flex-direction:column;flex-direction:column;-ms-flex-pack:center;justify-content:center;min-height:84px;text-align:center;-webkit-user-select:none;-moz-user-select:none;-ms-user-select:none;user-select:none}.infinite-loading{margin-left:0;margin-right:0;margin-top:0;margin-bottom:32px;display:none;width:100%}.infinite-loading-text{margin-left:32px;margin-right:32px;margin-top:4px;margin-bottom:0}@supports ((-webkit-margin-start: 0) or (margin-inline-start: 0)) or (-webkit-margin-start: 0){.infinite-loading-text{margin-left:unset;margin-right:unset;-webkit-margin-start:32px;margin-inline-start:32px;-webkit-margin-end:32px;margin-inline-end:32px}}.infinite-scroll-loading ion-infinite-scroll-content>.infinite-loading{display:block}.infinite-scroll-content-md .infinite-loading-text{color:var(--ion-color-step-600, #666666)}.infinite-scroll-content-md .infinite-loading-spinner .spinner-lines-md line,.infinite-scroll-content-md .infinite-loading-spinner .spinner-lines-small-md line,.infinite-scroll-content-md .infinite-loading-spinner .spinner-crescent circle{stroke:var(--ion-color-step-600, #666666)}.infinite-scroll-content-md .infinite-loading-spinner .spinner-bubbles circle,.infinite-scroll-content-md .infinite-loading-spinner .spinner-circles circle,.infinite-scroll-content-md .infinite-loading-spinner .spinner-dots circle{fill:var(--ion-color-step-600, #666666)}";

const InfiniteScrollContent = class {
  constructor(hostRef) {
    index.registerInstance(this, hostRef);
  }
  componentDidLoad() {
    if (this.loadingSpinner === undefined) {
      const mode = ionicGlobal.getIonMode(this);
      this.loadingSpinner = ionicGlobal.config.get('infiniteLoadingSpinner', ionicGlobal.config.get('spinner', mode === 'ios' ? 'lines' : 'crescent'));
    }
  }
  render() {
    const mode = ionicGlobal.getIonMode(this);
    return (index.h(index.Host, { class: {
        [mode]: true,
        // Used internally for styling
        [`infinite-scroll-content-${mode}`]: true
      } }, index.h("div", { class: "infinite-loading" }, this.loadingSpinner && (index.h("div", { class: "infinite-loading-spinner" }, index.h("ion-spinner", { name: this.loadingSpinner }))), this.loadingText && (index.h("div", { class: "infinite-loading-text", innerHTML: index$1.sanitizeDOMString(this.loadingText) })))));
  }
};
InfiniteScrollContent.style = {
  ios: infiniteScrollContentIosCss,
  md: infiniteScrollContentMdCss
};

exports.ion_infinite_scroll = InfiniteScroll;
exports.ion_infinite_scroll_content = InfiniteScrollContent;
