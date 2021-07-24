import { Build, Component, Element, Event, Method, Prop, Watch, h } from '@stencil/core';
import { config } from '../../global/config';
import { getIonMode } from '../../global/ionic-global';
import { getTimeGivenProgression } from '../../utils/animation/cubic-bezier';
import { assert } from '../../utils/helpers';
import { lifecycle, setPageHidden, transition } from '../../utils/transition';
import { LIFECYCLE_DID_LEAVE, LIFECYCLE_WILL_LEAVE, LIFECYCLE_WILL_UNLOAD } from './constants';
import { VIEW_STATE_ATTACHED, VIEW_STATE_DESTROYED, VIEW_STATE_NEW, convertToViews, matches } from './view-controller';
export class Nav {
  constructor() {
    this.transInstr = [];
    this.animationEnabled = true;
    this.useRouter = false;
    this.isTransitioning = false;
    this.destroyed = false;
    this.views = [];
    /**
     * If `true`, the nav should animate the transition of components.
     */
    this.animated = true;
  }
  swipeGestureChanged() {
    if (this.gesture) {
      this.gesture.enable(this.swipeGesture === true);
    }
  }
  rootChanged() {
    const isDev = Build.isDev;
    if (this.root !== undefined) {
      if (!this.useRouter) {
        this.setRoot(this.root, this.rootParams);
      }
      else if (isDev) {
        console.warn('<ion-nav> does not support a root attribute when using ion-router.');
      }
    }
  }
  componentWillLoad() {
    this.useRouter =
      !!document.querySelector('ion-router') &&
        !this.el.closest('[no-router]');
    if (this.swipeGesture === undefined) {
      const mode = getIonMode(this);
      this.swipeGesture = config.getBoolean('swipeBackEnabled', mode === 'ios');
    }
    this.ionNavWillLoad.emit();
  }
  async componentDidLoad() {
    this.rootChanged();
    this.gesture = (await import('../../utils/gesture/swipe-back')).createSwipeBackGesture(this.el, this.canStart.bind(this), this.onStart.bind(this), this.onMove.bind(this), this.onEnd.bind(this));
    this.swipeGestureChanged();
  }
  disconnectedCallback() {
    for (const view of this.views) {
      lifecycle(view.element, LIFECYCLE_WILL_UNLOAD);
      view._destroy();
    }
    if (this.gesture) {
      this.gesture.destroy();
      this.gesture = undefined;
    }
    // release swipe back gesture and transition
    this.transInstr.length = this.views.length = 0;
    this.destroyed = true;
  }
  /**
   * Push a new component onto the current navigation stack. Pass any additional
   * information along as an object. This additional information is accessible
   * through NavParams.
   *
   * @param component The component to push onto the navigation stack.
   * @param componentProps Any properties of the component.
   * @param opts The navigation options.
   * @param done The transition complete function.
   */
  push(component, componentProps, opts, done) {
    return this.queueTrns({
      insertStart: -1,
      insertViews: [{ component, componentProps }],
      opts
    }, done);
  }
  /**
   * Inserts a component into the navigation stack at the specified index.
   * This is useful to add a component at any point in the navigation stack.
   *
   * @param insertIndex The index to insert the component at in the stack.
   * @param component The component to insert into the navigation stack.
   * @param componentProps Any properties of the component.
   * @param opts The navigation options.
   * @param done The transition complete function.
   */
  insert(insertIndex, component, componentProps, opts, done) {
    return this.queueTrns({
      insertStart: insertIndex,
      insertViews: [{ component, componentProps }],
      opts
    }, done);
  }
  /**
   * Inserts an array of components into the navigation stack at the specified index.
   * The last component in the array will become instantiated as a view, and animate
   * in to become the active view.
   *
   * @param insertIndex The index to insert the components at in the stack.
   * @param insertComponents The components to insert into the navigation stack.
   * @param opts The navigation options.
   * @param done The transition complete function.
   */
  insertPages(insertIndex, insertComponents, opts, done) {
    return this.queueTrns({
      insertStart: insertIndex,
      insertViews: insertComponents,
      opts
    }, done);
  }
  /**
   * Pop a component off of the navigation stack. Navigates back from the current
   * component.
   *
   * @param opts The navigation options.
   * @param done The transition complete function.
   */
  pop(opts, done) {
    return this.queueTrns({
      removeStart: -1,
      removeCount: 1,
      opts
    }, done);
  }
  /**
   * Pop to a specific index in the navigation stack.
   *
   * @param indexOrViewCtrl The index or view controller to pop to.
   * @param opts The navigation options.
   * @param done The transition complete function.
   */
  popTo(indexOrViewCtrl, opts, done) {
    const tiConfig = {
      removeStart: -1,
      removeCount: -1,
      opts
    };
    if (typeof indexOrViewCtrl === 'object' && indexOrViewCtrl.component) {
      tiConfig.removeView = indexOrViewCtrl;
      tiConfig.removeStart = 1;
    }
    else if (typeof indexOrViewCtrl === 'number') {
      tiConfig.removeStart = indexOrViewCtrl + 1;
    }
    return this.queueTrns(tiConfig, done);
  }
  /**
   * Navigate back to the root of the stack, no matter how far back that is.
   *
   * @param opts The navigation options.
   * @param done The transition complete function.
   */
  popToRoot(opts, done) {
    return this.queueTrns({
      removeStart: 1,
      removeCount: -1,
      opts
    }, done);
  }
  /**
   * Removes a component from the navigation stack at the specified index.
   *
   * @param startIndex The number to begin removal at.
   * @param removeCount The number of components to remove.
   * @param opts The navigation options.
   * @param done The transition complete function.
   */
  removeIndex(startIndex, removeCount = 1, opts, done) {
    return this.queueTrns({
      removeStart: startIndex,
      removeCount,
      opts
    }, done);
  }
  /**
   * Set the root for the current navigation stack to a component.
   *
   * @param component The component to set as the root of the navigation stack.
   * @param componentProps Any properties of the component.
   * @param opts The navigation options.
   * @param done The transition complete function.
   */
  setRoot(component, componentProps, opts, done) {
    return this.setPages([{ component, componentProps }], opts, done);
  }
  /**
   * Set the views of the current navigation stack and navigate to the last view.
   * By default animations are disabled, but they can be enabled by passing options
   * to the navigation controller. Navigation parameters can also be passed to the
   * individual pages in the array.
   *
   * @param views The list of views to set as the navigation stack.
   * @param opts The navigation options.
   * @param done The transition complete function.
   */
  setPages(views, opts, done) {
    if (opts == null) {
      opts = {};
    }
    // if animation wasn't set to true then default it to NOT animate
    if (opts.animated !== true) {
      opts.animated = false;
    }
    return this.queueTrns({
      insertStart: 0,
      insertViews: views,
      removeStart: 0,
      removeCount: -1,
      opts
    }, done);
  }
  /** @internal */
  setRouteId(id, params, direction, animation) {
    const active = this.getActiveSync();
    if (matches(active, id, params)) {
      return Promise.resolve({
        changed: false,
        element: active.element
      });
    }
    let resolve;
    const promise = new Promise(r => (resolve = r));
    let finish;
    const commonOpts = {
      updateURL: false,
      viewIsReady: enteringEl => {
        let mark;
        const p = new Promise(r => (mark = r));
        resolve({
          changed: true,
          element: enteringEl,
          markVisible: async () => {
            mark();
            await finish;
          }
        });
        return p;
      }
    };
    if (direction === 'root') {
      finish = this.setRoot(id, params, commonOpts);
    }
    else {
      const viewController = this.views.find(v => matches(v, id, params));
      if (viewController) {
        finish = this.popTo(viewController, Object.assign(Object.assign({}, commonOpts), { direction: 'back', animationBuilder: animation }));
      }
      else if (direction === 'forward') {
        finish = this.push(id, params, Object.assign(Object.assign({}, commonOpts), { animationBuilder: animation }));
      }
      else if (direction === 'back') {
        finish = this.setRoot(id, params, Object.assign(Object.assign({}, commonOpts), { direction: 'back', animated: true, animationBuilder: animation }));
      }
    }
    return promise;
  }
  /** @internal */
  async getRouteId() {
    const active = this.getActiveSync();
    return active
      ? {
        id: active.element.tagName,
        params: active.params,
        element: active.element
      }
      : undefined;
  }
  /**
   * Get the active view.
   */
  getActive() {
    return Promise.resolve(this.getActiveSync());
  }
  /**
   * Get the view at the specified index.
   *
   * @param index The index of the view.
   */
  getByIndex(index) {
    return Promise.resolve(this.views[index]);
  }
  /**
   * Returns `true` if the current view can go back.
   *
   * @param view The view to check.
   */
  canGoBack(view) {
    return Promise.resolve(this.canGoBackSync(view));
  }
  /**
   * Get the previous view.
   *
   * @param view The view to get.
   */
  getPrevious(view) {
    return Promise.resolve(this.getPreviousSync(view));
  }
  getLength() {
    return this.views.length;
  }
  getActiveSync() {
    return this.views[this.views.length - 1];
  }
  canGoBackSync(view = this.getActiveSync()) {
    return !!(view && this.getPreviousSync(view));
  }
  getPreviousSync(view = this.getActiveSync()) {
    if (!view) {
      return undefined;
    }
    const views = this.views;
    const index = views.indexOf(view);
    return index > 0 ? views[index - 1] : undefined;
  }
  // _queueTrns() adds a navigation stack change to the queue and schedules it to run:
  // 1. _nextTrns(): consumes the next transition in the queue
  // 2. _viewInit(): initializes enteringView if required
  // 3. _viewTest(): ensures canLeave/canEnter Returns `true`, so the operation can continue
  // 4. _postViewInit(): add/remove the views from the navigation stack
  // 5. _transitionInit(): initializes the visual transition if required and schedules it to run
  // 6. _viewAttachToDOM(): attaches the enteringView to the DOM
  // 7. _transitionStart(): called once the transition actually starts, it initializes the Animation underneath.
  // 8. _transitionFinish(): called once the transition finishes
  // 9. _cleanup(): syncs the navigation internal state with the DOM. For example it removes the pages from the DOM or hides/show them.
  async queueTrns(ti, done) {
    if (this.isTransitioning && ti.opts != null && ti.opts.skipIfBusy) {
      return Promise.resolve(false);
    }
    const promise = new Promise((resolve, reject) => {
      ti.resolve = resolve;
      ti.reject = reject;
    });
    ti.done = done;
    /**
     * If using router, check to see if navigation hooks
     * will allow us to perform this transition. This
     * is required in order for hooks to work with
     * the ion-back-button or swipe to go back.
     */
    if (ti.opts && ti.opts.updateURL !== false && this.useRouter) {
      const router = document.querySelector('ion-router');
      if (router) {
        const canTransition = await router.canTransition();
        if (canTransition === false) {
          return Promise.resolve(false);
        }
        else if (typeof canTransition === 'string') {
          router.push(canTransition, ti.opts.direction || 'back');
          return Promise.resolve(false);
        }
      }
    }
    // Normalize empty
    if (ti.insertViews && ti.insertViews.length === 0) {
      ti.insertViews = undefined;
    }
    // Enqueue transition instruction
    this.transInstr.push(ti);
    // if there isn't a transition already happening
    // then this will kick off this transition
    this.nextTrns();
    return promise;
  }
  success(result, ti) {
    if (this.destroyed) {
      this.fireError('nav controller was destroyed', ti);
      return;
    }
    if (ti.done) {
      ti.done(result.hasCompleted, result.requiresTransition, result.enteringView, result.leavingView, result.direction);
    }
    ti.resolve(result.hasCompleted);
    if (ti.opts.updateURL !== false && this.useRouter) {
      const router = document.querySelector('ion-router');
      if (router) {
        const direction = result.direction === 'back' ? 'back' : 'forward';
        router.navChanged(direction);
      }
    }
  }
  failed(rejectReason, ti) {
    if (this.destroyed) {
      this.fireError('nav controller was destroyed', ti);
      return;
    }
    this.transInstr.length = 0;
    this.fireError(rejectReason, ti);
  }
  fireError(rejectReason, ti) {
    if (ti.done) {
      ti.done(false, false, rejectReason);
    }
    if (ti.reject && !this.destroyed) {
      ti.reject(rejectReason);
    }
    else {
      ti.resolve(false);
    }
  }
  nextTrns() {
    // this is the framework's bread 'n butta function
    // only one transition is allowed at any given time
    if (this.isTransitioning) {
      return false;
    }
    // there is no transition happening right now
    // get the next instruction
    const ti = this.transInstr.shift();
    if (!ti) {
      return false;
    }
    this.runTransition(ti);
    return true;
  }
  async runTransition(ti) {
    try {
      // set that this nav is actively transitioning
      this.ionNavWillChange.emit();
      this.isTransitioning = true;
      this.prepareTI(ti);
      const leavingView = this.getActiveSync();
      const enteringView = this.getEnteringView(ti, leavingView);
      if (!leavingView && !enteringView) {
        throw new Error('no views in the stack to be removed');
      }
      if (enteringView && enteringView.state === VIEW_STATE_NEW) {
        await enteringView.init(this.el);
      }
      this.postViewInit(enteringView, leavingView, ti);
      // Needs transition?
      const requiresTransition = (ti.enteringRequiresTransition || ti.leavingRequiresTransition) &&
        enteringView !== leavingView;
      if (requiresTransition && ti.opts && leavingView) {
        const isBackDirection = ti.opts.direction === 'back';
        /**
         * If heading back, use the entering page's animation
         * unless otherwise specified by the developer.
         */
        if (isBackDirection) {
          ti.opts.animationBuilder = ti.opts.animationBuilder || (enteringView && enteringView.animationBuilder);
        }
        leavingView.animationBuilder = ti.opts.animationBuilder;
      }
      const result = requiresTransition
        ? await this.transition(enteringView, leavingView, ti)
        : {
          // transition is not required, so we are already done!
          // they're inserting/removing the views somewhere in the middle or
          // beginning, so visually nothing needs to animate/transition
          // resolve immediately because there's no animation that's happening
          hasCompleted: true,
          requiresTransition: false
        };
      this.success(result, ti);
      this.ionNavDidChange.emit();
    }
    catch (rejectReason) {
      this.failed(rejectReason, ti);
    }
    this.isTransitioning = false;
    this.nextTrns();
  }
  prepareTI(ti) {
    const viewsLength = this.views.length;
    ti.opts = ti.opts || {};
    if (ti.opts.delegate === undefined) {
      ti.opts.delegate = this.delegate;
    }
    if (ti.removeView !== undefined) {
      assert(ti.removeStart !== undefined, 'removeView needs removeStart');
      assert(ti.removeCount !== undefined, 'removeView needs removeCount');
      const index = this.views.indexOf(ti.removeView);
      if (index < 0) {
        throw new Error('removeView was not found');
      }
      ti.removeStart += index;
    }
    if (ti.removeStart !== undefined) {
      if (ti.removeStart < 0) {
        ti.removeStart = viewsLength - 1;
      }
      if (ti.removeCount < 0) {
        ti.removeCount = viewsLength - ti.removeStart;
      }
      ti.leavingRequiresTransition =
        ti.removeCount > 0 && ti.removeStart + ti.removeCount === viewsLength;
    }
    if (ti.insertViews) {
      // allow -1 to be passed in to auto push it on the end
      // and clean up the index if it's larger then the size of the stack
      if (ti.insertStart < 0 || ti.insertStart > viewsLength) {
        ti.insertStart = viewsLength;
      }
      ti.enteringRequiresTransition = ti.insertStart === viewsLength;
    }
    const insertViews = ti.insertViews;
    if (!insertViews) {
      return;
    }
    assert(insertViews.length > 0, 'length can not be zero');
    const viewControllers = convertToViews(insertViews);
    if (viewControllers.length === 0) {
      throw new Error('invalid views to insert');
    }
    // Check all the inserted view are correct
    for (const view of viewControllers) {
      view.delegate = ti.opts.delegate;
      const nav = view.nav;
      if (nav && nav !== this) {
        throw new Error('inserted view was already inserted');
      }
      if (view.state === VIEW_STATE_DESTROYED) {
        throw new Error('inserted view was already destroyed');
      }
    }
    ti.insertViews = viewControllers;
  }
  getEnteringView(ti, leavingView) {
    const insertViews = ti.insertViews;
    if (insertViews !== undefined) {
      // grab the very last view of the views to be inserted
      // and initialize it as the new entering view
      return insertViews[insertViews.length - 1];
    }
    const removeStart = ti.removeStart;
    if (removeStart !== undefined) {
      const views = this.views;
      const removeEnd = removeStart + ti.removeCount;
      for (let i = views.length - 1; i >= 0; i--) {
        const view = views[i];
        if ((i < removeStart || i >= removeEnd) && view !== leavingView) {
          return view;
        }
      }
    }
    return undefined;
  }
  postViewInit(enteringView, leavingView, ti) {
    assert(leavingView || enteringView, 'Both leavingView and enteringView are null');
    assert(ti.resolve, 'resolve must be valid');
    assert(ti.reject, 'reject must be valid');
    const opts = ti.opts;
    const insertViews = ti.insertViews;
    const removeStart = ti.removeStart;
    const removeCount = ti.removeCount;
    let destroyQueue;
    // there are views to remove
    if (removeStart !== undefined && removeCount !== undefined) {
      assert(removeStart >= 0, 'removeStart can not be negative');
      assert(removeCount >= 0, 'removeCount can not be negative');
      destroyQueue = [];
      for (let i = 0; i < removeCount; i++) {
        const view = this.views[i + removeStart];
        if (view && view !== enteringView && view !== leavingView) {
          destroyQueue.push(view);
        }
      }
      // default the direction to "back"
      opts.direction = opts.direction || 'back';
    }
    const finalBalance = this.views.length +
      (insertViews !== undefined ? insertViews.length : 0) -
      (removeCount !== undefined ? removeCount : 0);
    assert(finalBalance >= 0, 'final balance can not be negative');
    if (finalBalance === 0) {
      console.warn(`You can't remove all the pages in the navigation stack. nav.pop() is probably called too many times.`, this, this.el);
      throw new Error('navigation stack needs at least one root page');
    }
    // At this point the transition can not be rejected, any throw should be an error
    // there are views to insert
    if (insertViews) {
      // add the views to the
      let insertIndex = ti.insertStart;
      for (const view of insertViews) {
        this.insertViewAt(view, insertIndex);
        insertIndex++;
      }
      if (ti.enteringRequiresTransition) {
        // default to forward if not already set
        opts.direction = opts.direction || 'forward';
      }
    }
    // if the views to be removed are in the beginning or middle
    // and there is not a view that needs to visually transition out
    // then just destroy them and don't transition anything
    // batch all of lifecycles together
    // let's make sure, callbacks are zoned
    if (destroyQueue && destroyQueue.length > 0) {
      for (const view of destroyQueue) {
        lifecycle(view.element, LIFECYCLE_WILL_LEAVE);
        lifecycle(view.element, LIFECYCLE_DID_LEAVE);
        lifecycle(view.element, LIFECYCLE_WILL_UNLOAD);
      }
      // once all lifecycle events has been delivered, we can safely detroy the views
      for (const view of destroyQueue) {
        this.destroyView(view);
      }
    }
  }
  async transition(enteringView, leavingView, ti) {
    // we should animate (duration > 0) if the pushed page is not the first one (startup)
    // or if it is a portal (modal, actionsheet, etc.)
    const opts = ti.opts;
    const progressCallback = opts.progressAnimation
      ? (ani) => this.sbAni = ani
      : undefined;
    const mode = getIonMode(this);
    const enteringEl = enteringView.element;
    const leavingEl = leavingView && leavingView.element;
    const animationOpts = Object.assign({ mode, showGoBack: this.canGoBackSync(enteringView), baseEl: this.el, animationBuilder: this.animation || opts.animationBuilder || config.get('navAnimation'), progressCallback, animated: this.animated && config.getBoolean('animated', true), enteringEl,
      leavingEl }, opts);
    const { hasCompleted } = await transition(animationOpts);
    return this.transitionFinish(hasCompleted, enteringView, leavingView, opts);
  }
  transitionFinish(hasCompleted, enteringView, leavingView, opts) {
    const cleanupView = hasCompleted ? enteringView : leavingView;
    if (cleanupView) {
      this.cleanup(cleanupView);
    }
    return {
      hasCompleted,
      requiresTransition: true,
      enteringView,
      leavingView,
      direction: opts.direction
    };
  }
  insertViewAt(view, index) {
    const views = this.views;
    const existingIndex = views.indexOf(view);
    if (existingIndex > -1) {
      // this view is already in the stack!!
      // move it to its new location
      assert(view.nav === this, 'view is not part of the nav');
      views.splice(index, 0, views.splice(existingIndex, 1)[0]);
    }
    else {
      assert(!view.nav, 'nav is used');
      // this is a new view to add to the stack
      // create the new entering view
      view.nav = this;
      // insert the entering view into the correct index in the stack
      views.splice(index, 0, view);
    }
  }
  removeView(view) {
    assert(view.state === VIEW_STATE_ATTACHED || view.state === VIEW_STATE_DESTROYED, 'view state should be loaded or destroyed');
    const views = this.views;
    const index = views.indexOf(view);
    assert(index > -1, 'view must be part of the stack');
    if (index >= 0) {
      views.splice(index, 1);
    }
  }
  destroyView(view) {
    view._destroy();
    this.removeView(view);
  }
  /**
   * DOM WRITE
   */
  cleanup(activeView) {
    // ok, cleanup time!! Destroy all of the views that are
    // INACTIVE and come after the active view
    // only do this if the views exist, though
    if (this.destroyed) {
      return;
    }
    const views = this.views;
    const activeViewIndex = views.indexOf(activeView);
    for (let i = views.length - 1; i >= 0; i--) {
      const view = views[i];
      /**
       * When inserting multiple views via insertPages
       * the last page will be transitioned to, but the
       * others will not be. As a result, a DOM element
       * will only be created for the last page inserted.
       * As a result, it is possible to have views in the
       * stack that do not have `view.element` yet.
       */
      const element = view.element;
      if (element) {
        if (i > activeViewIndex) {
          // this view comes after the active view
          // let's unload it
          lifecycle(element, LIFECYCLE_WILL_UNLOAD);
          this.destroyView(view);
        }
        else if (i < activeViewIndex) {
          // this view comes before the active view
          // and it is not a portal then ensure it is hidden
          setPageHidden(element, true);
        }
      }
    }
  }
  canStart() {
    return (!!this.swipeGesture &&
      !this.isTransitioning &&
      this.transInstr.length === 0 &&
      this.animationEnabled &&
      this.canGoBackSync());
  }
  onStart() {
    this.queueTrns({
      removeStart: -1,
      removeCount: 1,
      opts: {
        direction: 'back',
        progressAnimation: true
      }
    }, undefined);
  }
  onMove(stepValue) {
    if (this.sbAni) {
      this.sbAni.progressStep(stepValue);
    }
  }
  onEnd(shouldComplete, stepValue, dur) {
    if (this.sbAni) {
      this.animationEnabled = false;
      this.sbAni.onFinish(() => {
        this.animationEnabled = true;
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
        this.sbAni.easing('cubic-bezier(1, 0, 0.68, 0.28)');
        newStepValue += getTimeGivenProgression([0, 0], [1, 0], [0.68, 0.28], [1, 1], stepValue)[0];
      }
      else {
        newStepValue += getTimeGivenProgression([0, 0], [0.32, 0.72], [0, 1], [1, 1], stepValue)[0];
      }
      this.sbAni.progressEnd(shouldComplete ? 1 : 0, newStepValue, dur);
    }
  }
  render() {
    return (h("slot", null));
  }
  static get is() { return "ion-nav"; }
  static get encapsulation() { return "shadow"; }
  static get originalStyleUrls() { return {
    "$": ["nav.scss"]
  }; }
  static get styleUrls() { return {
    "$": ["nav.css"]
  }; }
  static get properties() { return {
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
    "swipeGesture": {
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
        "text": "If the nav component should allow for swipe-to-go-back."
      },
      "attribute": "swipe-gesture",
      "reflect": false
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
        "text": "If `true`, the nav should animate the transition of components."
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
    "rootParams": {
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
        "text": "Any parameters for the root component"
      }
    },
    "root": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "NavComponent",
        "resolved": "Function | HTMLElement | ViewController | null | string | undefined",
        "references": {
          "NavComponent": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Root NavComponent to load"
      },
      "attribute": "root",
      "reflect": false
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
        "text": "Event fired when Nav will load a component"
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
        "tags": [],
        "text": "Event fired when the nav will change components"
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
        "tags": [],
        "text": "Event fired when the nav has changed components"
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }]; }
  static get methods() { return {
    "push": {
      "complexType": {
        "signature": "<T extends NavComponent>(component: T, componentProps?: ComponentProps<T> | null | undefined, opts?: NavOptions | null | undefined, done?: TransitionDoneFn | undefined) => Promise<boolean>",
        "parameters": [{
            "tags": [{
                "text": "component The component to push onto the navigation stack.",
                "name": "param"
              }],
            "text": "The component to push onto the navigation stack."
          }, {
            "tags": [{
                "text": "componentProps Any properties of the component.",
                "name": "param"
              }],
            "text": "Any properties of the component."
          }, {
            "tags": [{
                "text": "opts The navigation options.",
                "name": "param"
              }],
            "text": "The navigation options."
          }, {
            "tags": [{
                "text": "done The transition complete function.",
                "name": "param"
              }],
            "text": "The transition complete function."
          }],
        "references": {
          "Promise": {
            "location": "global"
          },
          "NavComponent": {
            "location": "import",
            "path": "../../interface"
          },
          "T": {
            "location": "global"
          },
          "ComponentProps": {
            "location": "import",
            "path": "../../interface"
          },
          "NavOptions": {
            "location": "import",
            "path": "../../interface"
          },
          "TransitionDoneFn": {
            "location": "import",
            "path": "../../interface"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "Push a new component onto the current navigation stack. Pass any additional\ninformation along as an object. This additional information is accessible\nthrough NavParams.",
        "tags": [{
            "name": "param",
            "text": "component The component to push onto the navigation stack."
          }, {
            "name": "param",
            "text": "componentProps Any properties of the component."
          }, {
            "name": "param",
            "text": "opts The navigation options."
          }, {
            "name": "param",
            "text": "done The transition complete function."
          }]
      }
    },
    "insert": {
      "complexType": {
        "signature": "<T extends NavComponent>(insertIndex: number, component: T, componentProps?: ComponentProps<T> | null | undefined, opts?: NavOptions | null | undefined, done?: TransitionDoneFn | undefined) => Promise<boolean>",
        "parameters": [{
            "tags": [{
                "text": "insertIndex The index to insert the component at in the stack.",
                "name": "param"
              }],
            "text": "The index to insert the component at in the stack."
          }, {
            "tags": [{
                "text": "component The component to insert into the navigation stack.",
                "name": "param"
              }],
            "text": "The component to insert into the navigation stack."
          }, {
            "tags": [{
                "text": "componentProps Any properties of the component.",
                "name": "param"
              }],
            "text": "Any properties of the component."
          }, {
            "tags": [{
                "text": "opts The navigation options.",
                "name": "param"
              }],
            "text": "The navigation options."
          }, {
            "tags": [{
                "text": "done The transition complete function.",
                "name": "param"
              }],
            "text": "The transition complete function."
          }],
        "references": {
          "Promise": {
            "location": "global"
          },
          "NavComponent": {
            "location": "import",
            "path": "../../interface"
          },
          "T": {
            "location": "global"
          },
          "ComponentProps": {
            "location": "import",
            "path": "../../interface"
          },
          "NavOptions": {
            "location": "import",
            "path": "../../interface"
          },
          "TransitionDoneFn": {
            "location": "import",
            "path": "../../interface"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "Inserts a component into the navigation stack at the specified index.\nThis is useful to add a component at any point in the navigation stack.",
        "tags": [{
            "name": "param",
            "text": "insertIndex The index to insert the component at in the stack."
          }, {
            "name": "param",
            "text": "component The component to insert into the navigation stack."
          }, {
            "name": "param",
            "text": "componentProps Any properties of the component."
          }, {
            "name": "param",
            "text": "opts The navigation options."
          }, {
            "name": "param",
            "text": "done The transition complete function."
          }]
      }
    },
    "insertPages": {
      "complexType": {
        "signature": "(insertIndex: number, insertComponents: NavComponent[] | NavComponentWithProps[], opts?: NavOptions | null | undefined, done?: TransitionDoneFn | undefined) => Promise<boolean>",
        "parameters": [{
            "tags": [{
                "text": "insertIndex The index to insert the components at in the stack.",
                "name": "param"
              }],
            "text": "The index to insert the components at in the stack."
          }, {
            "tags": [{
                "text": "insertComponents The components to insert into the navigation stack.",
                "name": "param"
              }],
            "text": "The components to insert into the navigation stack."
          }, {
            "tags": [{
                "text": "opts The navigation options.",
                "name": "param"
              }],
            "text": "The navigation options."
          }, {
            "tags": [{
                "text": "done The transition complete function.",
                "name": "param"
              }],
            "text": "The transition complete function."
          }],
        "references": {
          "Promise": {
            "location": "global"
          },
          "NavComponent": {
            "location": "import",
            "path": "../../interface"
          },
          "NavComponentWithProps": {
            "location": "import",
            "path": "../../interface"
          },
          "NavOptions": {
            "location": "import",
            "path": "../../interface"
          },
          "TransitionDoneFn": {
            "location": "import",
            "path": "../../interface"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "Inserts an array of components into the navigation stack at the specified index.\nThe last component in the array will become instantiated as a view, and animate\nin to become the active view.",
        "tags": [{
            "name": "param",
            "text": "insertIndex The index to insert the components at in the stack."
          }, {
            "name": "param",
            "text": "insertComponents The components to insert into the navigation stack."
          }, {
            "name": "param",
            "text": "opts The navigation options."
          }, {
            "name": "param",
            "text": "done The transition complete function."
          }]
      }
    },
    "pop": {
      "complexType": {
        "signature": "(opts?: NavOptions | null | undefined, done?: TransitionDoneFn | undefined) => Promise<boolean>",
        "parameters": [{
            "tags": [{
                "text": "opts The navigation options.",
                "name": "param"
              }],
            "text": "The navigation options."
          }, {
            "tags": [{
                "text": "done The transition complete function.",
                "name": "param"
              }],
            "text": "The transition complete function."
          }],
        "references": {
          "Promise": {
            "location": "global"
          },
          "NavOptions": {
            "location": "import",
            "path": "../../interface"
          },
          "TransitionDoneFn": {
            "location": "import",
            "path": "../../interface"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "Pop a component off of the navigation stack. Navigates back from the current\ncomponent.",
        "tags": [{
            "name": "param",
            "text": "opts The navigation options."
          }, {
            "name": "param",
            "text": "done The transition complete function."
          }]
      }
    },
    "popTo": {
      "complexType": {
        "signature": "(indexOrViewCtrl: number | ViewController, opts?: NavOptions | null | undefined, done?: TransitionDoneFn | undefined) => Promise<boolean>",
        "parameters": [{
            "tags": [{
                "text": "indexOrViewCtrl The index or view controller to pop to.",
                "name": "param"
              }],
            "text": "The index or view controller to pop to."
          }, {
            "tags": [{
                "text": "opts The navigation options.",
                "name": "param"
              }],
            "text": "The navigation options."
          }, {
            "tags": [{
                "text": "done The transition complete function.",
                "name": "param"
              }],
            "text": "The transition complete function."
          }],
        "references": {
          "Promise": {
            "location": "global"
          },
          "ViewController": {
            "location": "import",
            "path": "../../interface"
          },
          "NavOptions": {
            "location": "import",
            "path": "../../interface"
          },
          "TransitionDoneFn": {
            "location": "import",
            "path": "../../interface"
          },
          "TransitionInstruction": {
            "location": "import",
            "path": "../../interface"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "Pop to a specific index in the navigation stack.",
        "tags": [{
            "name": "param",
            "text": "indexOrViewCtrl The index or view controller to pop to."
          }, {
            "name": "param",
            "text": "opts The navigation options."
          }, {
            "name": "param",
            "text": "done The transition complete function."
          }]
      }
    },
    "popToRoot": {
      "complexType": {
        "signature": "(opts?: NavOptions | null | undefined, done?: TransitionDoneFn | undefined) => Promise<boolean>",
        "parameters": [{
            "tags": [{
                "text": "opts The navigation options.",
                "name": "param"
              }],
            "text": "The navigation options."
          }, {
            "tags": [{
                "text": "done The transition complete function.",
                "name": "param"
              }],
            "text": "The transition complete function."
          }],
        "references": {
          "Promise": {
            "location": "global"
          },
          "NavOptions": {
            "location": "import",
            "path": "../../interface"
          },
          "TransitionDoneFn": {
            "location": "import",
            "path": "../../interface"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "Navigate back to the root of the stack, no matter how far back that is.",
        "tags": [{
            "name": "param",
            "text": "opts The navigation options."
          }, {
            "name": "param",
            "text": "done The transition complete function."
          }]
      }
    },
    "removeIndex": {
      "complexType": {
        "signature": "(startIndex: number, removeCount?: number, opts?: NavOptions | null | undefined, done?: TransitionDoneFn | undefined) => Promise<boolean>",
        "parameters": [{
            "tags": [{
                "text": "startIndex The number to begin removal at.",
                "name": "param"
              }],
            "text": "The number to begin removal at."
          }, {
            "tags": [{
                "text": "removeCount The number of components to remove.",
                "name": "param"
              }],
            "text": "The number of components to remove."
          }, {
            "tags": [{
                "text": "opts The navigation options.",
                "name": "param"
              }],
            "text": "The navigation options."
          }, {
            "tags": [{
                "text": "done The transition complete function.",
                "name": "param"
              }],
            "text": "The transition complete function."
          }],
        "references": {
          "Promise": {
            "location": "global"
          },
          "NavOptions": {
            "location": "import",
            "path": "../../interface"
          },
          "TransitionDoneFn": {
            "location": "import",
            "path": "../../interface"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "Removes a component from the navigation stack at the specified index.",
        "tags": [{
            "name": "param",
            "text": "startIndex The number to begin removal at."
          }, {
            "name": "param",
            "text": "removeCount The number of components to remove."
          }, {
            "name": "param",
            "text": "opts The navigation options."
          }, {
            "name": "param",
            "text": "done The transition complete function."
          }]
      }
    },
    "setRoot": {
      "complexType": {
        "signature": "<T extends NavComponent>(component: T, componentProps?: ComponentProps<T> | null | undefined, opts?: NavOptions | null | undefined, done?: TransitionDoneFn | undefined) => Promise<boolean>",
        "parameters": [{
            "tags": [{
                "text": "component The component to set as the root of the navigation stack.",
                "name": "param"
              }],
            "text": "The component to set as the root of the navigation stack."
          }, {
            "tags": [{
                "text": "componentProps Any properties of the component.",
                "name": "param"
              }],
            "text": "Any properties of the component."
          }, {
            "tags": [{
                "text": "opts The navigation options.",
                "name": "param"
              }],
            "text": "The navigation options."
          }, {
            "tags": [{
                "text": "done The transition complete function.",
                "name": "param"
              }],
            "text": "The transition complete function."
          }],
        "references": {
          "Promise": {
            "location": "global"
          },
          "NavComponent": {
            "location": "import",
            "path": "../../interface"
          },
          "T": {
            "location": "global"
          },
          "ComponentProps": {
            "location": "import",
            "path": "../../interface"
          },
          "NavOptions": {
            "location": "import",
            "path": "../../interface"
          },
          "TransitionDoneFn": {
            "location": "import",
            "path": "../../interface"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "Set the root for the current navigation stack to a component.",
        "tags": [{
            "name": "param",
            "text": "component The component to set as the root of the navigation stack."
          }, {
            "name": "param",
            "text": "componentProps Any properties of the component."
          }, {
            "name": "param",
            "text": "opts The navigation options."
          }, {
            "name": "param",
            "text": "done The transition complete function."
          }]
      }
    },
    "setPages": {
      "complexType": {
        "signature": "(views: NavComponent[] | NavComponentWithProps[], opts?: NavOptions | null | undefined, done?: TransitionDoneFn | undefined) => Promise<boolean>",
        "parameters": [{
            "tags": [{
                "text": "views The list of views to set as the navigation stack.",
                "name": "param"
              }],
            "text": "The list of views to set as the navigation stack."
          }, {
            "tags": [{
                "text": "opts The navigation options.",
                "name": "param"
              }],
            "text": "The navigation options."
          }, {
            "tags": [{
                "text": "done The transition complete function.",
                "name": "param"
              }],
            "text": "The transition complete function."
          }],
        "references": {
          "Promise": {
            "location": "global"
          },
          "NavComponent": {
            "location": "import",
            "path": "../../interface"
          },
          "NavComponentWithProps": {
            "location": "import",
            "path": "../../interface"
          },
          "NavOptions": {
            "location": "import",
            "path": "../../interface"
          },
          "TransitionDoneFn": {
            "location": "import",
            "path": "../../interface"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "Set the views of the current navigation stack and navigate to the last view.\nBy default animations are disabled, but they can be enabled by passing options\nto the navigation controller. Navigation parameters can also be passed to the\nindividual pages in the array.",
        "tags": [{
            "name": "param",
            "text": "views The list of views to set as the navigation stack."
          }, {
            "name": "param",
            "text": "opts The navigation options."
          }, {
            "name": "param",
            "text": "done The transition complete function."
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
          },
          "NavOptions": {
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
    },
    "getActive": {
      "complexType": {
        "signature": "() => Promise<ViewController | undefined>",
        "parameters": [],
        "references": {
          "Promise": {
            "location": "global"
          },
          "ViewController": {
            "location": "import",
            "path": "../../interface"
          }
        },
        "return": "Promise<ViewController | undefined>"
      },
      "docs": {
        "text": "Get the active view.",
        "tags": []
      }
    },
    "getByIndex": {
      "complexType": {
        "signature": "(index: number) => Promise<ViewController | undefined>",
        "parameters": [{
            "tags": [{
                "text": "index The index of the view.",
                "name": "param"
              }],
            "text": "The index of the view."
          }],
        "references": {
          "Promise": {
            "location": "global"
          },
          "ViewController": {
            "location": "import",
            "path": "../../interface"
          }
        },
        "return": "Promise<ViewController | undefined>"
      },
      "docs": {
        "text": "Get the view at the specified index.",
        "tags": [{
            "name": "param",
            "text": "index The index of the view."
          }]
      }
    },
    "canGoBack": {
      "complexType": {
        "signature": "(view?: ViewController | undefined) => Promise<boolean>",
        "parameters": [{
            "tags": [{
                "text": "view The view to check.",
                "name": "param"
              }],
            "text": "The view to check."
          }],
        "references": {
          "Promise": {
            "location": "global"
          },
          "ViewController": {
            "location": "import",
            "path": "../../interface"
          }
        },
        "return": "Promise<boolean>"
      },
      "docs": {
        "text": "Returns `true` if the current view can go back.",
        "tags": [{
            "name": "param",
            "text": "view The view to check."
          }]
      }
    },
    "getPrevious": {
      "complexType": {
        "signature": "(view?: ViewController | undefined) => Promise<ViewController | undefined>",
        "parameters": [{
            "tags": [{
                "text": "view The view to get.",
                "name": "param"
              }],
            "text": "The view to get."
          }],
        "references": {
          "Promise": {
            "location": "global"
          },
          "ViewController": {
            "location": "import",
            "path": "../../interface"
          }
        },
        "return": "Promise<ViewController | undefined>"
      },
      "docs": {
        "text": "Get the previous view.",
        "tags": [{
            "name": "param",
            "text": "view The view to get."
          }]
      }
    }
  }; }
  static get elementRef() { return "el"; }
  static get watchers() { return [{
      "propName": "swipeGesture",
      "methodName": "swipeGestureChanged"
    }, {
      "propName": "root",
      "methodName": "rootChanged"
    }]; }
}
