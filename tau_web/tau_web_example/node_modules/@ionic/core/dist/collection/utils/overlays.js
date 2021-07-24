import { config } from '../global/config';
import { getIonMode } from '../global/ionic-global';
import { OVERLAY_BACK_BUTTON_PRIORITY } from './hardware-back-button';
import { addEventListener, componentOnReady, getElementRoot, removeEventListener } from './helpers';
let lastId = 0;
export const activeAnimations = new WeakMap();
const createController = (tagName) => {
  return {
    create(options) {
      return createOverlay(tagName, options);
    },
    dismiss(data, role, id) {
      return dismissOverlay(document, data, role, tagName, id);
    },
    async getTop() {
      return getOverlay(document, tagName);
    }
  };
};
export const alertController = /*@__PURE__*/ createController('ion-alert');
export const actionSheetController = /*@__PURE__*/ createController('ion-action-sheet');
export const loadingController = /*@__PURE__*/ createController('ion-loading');
export const modalController = /*@__PURE__*/ createController('ion-modal');
export const pickerController = /*@__PURE__*/ createController('ion-picker');
export const popoverController = /*@__PURE__*/ createController('ion-popover');
export const toastController = /*@__PURE__*/ createController('ion-toast');
export const prepareOverlay = (el) => {
  /* tslint:disable-next-line */
  if (typeof document !== 'undefined') {
    connectListeners(document);
  }
  const overlayIndex = lastId++;
  el.overlayIndex = overlayIndex;
  if (!el.hasAttribute('id')) {
    el.id = `ion-overlay-${overlayIndex}`;
  }
};
export const createOverlay = (tagName, opts) => {
  /* tslint:disable-next-line */
  if (typeof customElements !== 'undefined') {
    return customElements.whenDefined(tagName).then(() => {
      const element = document.createElement(tagName);
      element.classList.add('overlay-hidden');
      // convert the passed in overlay options into props
      // that get passed down into the new overlay
      Object.assign(element, opts);
      // append the overlay element to the document body
      getAppRoot(document).appendChild(element);
      return new Promise(resolve => componentOnReady(element, resolve));
    });
  }
  return Promise.resolve();
};
const focusableQueryString = '[tabindex]:not([tabindex^="-"]), input:not([type=hidden]):not([tabindex^="-"]), textarea:not([tabindex^="-"]), button:not([tabindex^="-"]), select:not([tabindex^="-"]), .ion-focusable:not([tabindex^="-"])';
const innerFocusableQueryString = 'input:not([type=hidden]), textarea, button, select';
const focusFirstDescendant = (ref, overlay) => {
  let firstInput = ref.querySelector(focusableQueryString);
  const shadowRoot = firstInput && firstInput.shadowRoot;
  if (shadowRoot) {
    // If there are no inner focusable elements, just focus the host element.
    firstInput = shadowRoot.querySelector(innerFocusableQueryString) || firstInput;
  }
  if (firstInput) {
    firstInput.focus();
  }
  else {
    // Focus overlay instead of letting focus escape
    overlay.focus();
  }
};
const focusLastDescendant = (ref, overlay) => {
  const inputs = Array.from(ref.querySelectorAll(focusableQueryString));
  let lastInput = inputs.length > 0 ? inputs[inputs.length - 1] : null;
  const shadowRoot = lastInput && lastInput.shadowRoot;
  if (shadowRoot) {
    // If there are no inner focusable elements, just focus the host element.
    lastInput = shadowRoot.querySelector(innerFocusableQueryString) || lastInput;
  }
  if (lastInput) {
    lastInput.focus();
  }
  else {
    // Focus overlay instead of letting focus escape
    overlay.focus();
  }
};
/**
 * Traps keyboard focus inside of overlay components.
 * Based on https://w3c.github.io/aria-practices/examples/dialog-modal/alertdialog.html
 * This includes the following components: Action Sheet, Alert, Loading, Modal,
 * Picker, and Popover.
 * Should NOT include: Toast
 */
const trapKeyboardFocus = (ev, doc) => {
  const lastOverlay = getOverlay(doc);
  const target = ev.target;
  // If no active overlay, ignore this event
  if (!lastOverlay || !target) {
    return;
  }
  /**
   * If we are focusing the overlay, clear
   * the last focused element so that hitting
   * tab activates the first focusable element
   * in the overlay wrapper.
   */
  if (lastOverlay === target) {
    lastOverlay.lastFocus = undefined;
    /**
     * Otherwise, we must be focusing an element
     * inside of the overlay. The two possible options
     * here are an input/button/etc or the ion-focus-trap
     * element. The focus trap element is used to prevent
     * the keyboard focus from leaving the overlay when
     * using Tab or screen assistants.
     */
  }
  else {
    /**
     * We do not want to focus the traps, so get the overlay
     * wrapper element as the traps live outside of the wrapper.
     */
    const overlayRoot = getElementRoot(lastOverlay);
    if (!overlayRoot.contains(target)) {
      return;
    }
    const overlayWrapper = overlayRoot.querySelector('.ion-overlay-wrapper');
    if (!overlayWrapper) {
      return;
    }
    /**
     * If the target is inside the wrapper, let the browser
     * focus as normal and keep a log of the last focused element.
     */
    if (overlayWrapper.contains(target)) {
      lastOverlay.lastFocus = target;
    }
    else {
      /**
       * Otherwise, we must have focused one of the focus traps.
       * We need to wrap the focus to either the first element
       * or the last element.
       */
      /**
       * Once we call `focusFirstDescendant` and focus the first
       * descendant, another focus event will fire which will
       * cause `lastOverlay.lastFocus` to be updated before
       * we can run the code after that. We will cache the value
       * here to avoid that.
       */
      const lastFocus = lastOverlay.lastFocus;
      // Focus the first element in the overlay wrapper
      focusFirstDescendant(overlayWrapper, lastOverlay);
      /**
       * If the cached last focused element is the
       * same as the active element, then we need
       * to wrap focus to the last descendant. This happens
       * when the first descendant is focused, and the user
       * presses Shift + Tab. The previous line will focus
       * the same descendant again (the first one), causing
       * last focus to equal the active element.
       */
      if (lastFocus === doc.activeElement) {
        focusLastDescendant(overlayWrapper, lastOverlay);
      }
      lastOverlay.lastFocus = doc.activeElement;
    }
  }
};
export const connectListeners = (doc) => {
  if (lastId === 0) {
    lastId = 1;
    doc.addEventListener('focus', ev => trapKeyboardFocus(ev, doc), true);
    // handle back-button click
    doc.addEventListener('ionBackButton', ev => {
      const lastOverlay = getOverlay(doc);
      if (lastOverlay && lastOverlay.backdropDismiss) {
        ev.detail.register(OVERLAY_BACK_BUTTON_PRIORITY, () => {
          return lastOverlay.dismiss(undefined, BACKDROP);
        });
      }
    });
    // handle ESC to close overlay
    doc.addEventListener('keyup', ev => {
      if (ev.key === 'Escape') {
        const lastOverlay = getOverlay(doc);
        if (lastOverlay && lastOverlay.backdropDismiss) {
          lastOverlay.dismiss(undefined, BACKDROP);
        }
      }
    });
  }
};
export const dismissOverlay = (doc, data, role, overlayTag, id) => {
  const overlay = getOverlay(doc, overlayTag, id);
  if (!overlay) {
    return Promise.reject('overlay does not exist');
  }
  return overlay.dismiss(data, role);
};
export const getOverlays = (doc, selector) => {
  if (selector === undefined) {
    selector = 'ion-alert,ion-action-sheet,ion-loading,ion-modal,ion-picker,ion-popover,ion-toast';
  }
  return Array.from(doc.querySelectorAll(selector))
    .filter(c => c.overlayIndex > 0);
};
export const getOverlay = (doc, overlayTag, id) => {
  const overlays = getOverlays(doc, overlayTag);
  return (id === undefined)
    ? overlays[overlays.length - 1]
    : overlays.find(o => o.id === id);
};
/**
 * When an overlay is presented, the main
 * focus is the overlay not the page content.
 * We need to remove the page content from the
 * accessibility tree otherwise when
 * users use "read screen from top" gestures with
 * TalkBack and VoiceOver, the screen reader will begin
 * to read the content underneath the overlay.
 *
 * We need a container where all page components
 * exist that is separate from where the overlays
 * are added in the DOM. For most apps, this element
 * is the top most ion-router-outlet. In the event
 * that devs are not using a router,
 * they will need to add the "ion-view-container-root"
 * id to the element that contains all of their views.
 *
 * TODO: If Framework supports having multiple top
 * level router outlets we would need to update this.
 * Example: One outlet for side menu and one outlet
 * for main content.
 */
export const setRootAriaHidden = (hidden = false) => {
  const root = getAppRoot(document);
  const viewContainer = root.querySelector('ion-router-outlet, ion-nav, #ion-view-container-root');
  if (!viewContainer) {
    return;
  }
  if (hidden) {
    viewContainer.setAttribute('aria-hidden', 'true');
  }
  else {
    viewContainer.removeAttribute('aria-hidden');
  }
};
export const present = async (overlay, name, iosEnterAnimation, mdEnterAnimation, opts) => {
  if (overlay.presented) {
    return;
  }
  setRootAriaHidden(true);
  overlay.presented = true;
  overlay.willPresent.emit();
  const mode = getIonMode(overlay);
  // get the user's animation fn if one was provided
  const animationBuilder = (overlay.enterAnimation)
    ? overlay.enterAnimation
    : config.get(name, mode === 'ios' ? iosEnterAnimation : mdEnterAnimation);
  const completed = await overlayAnimation(overlay, animationBuilder, overlay.el, opts);
  if (completed) {
    overlay.didPresent.emit();
  }
  /**
   * When an overlay that steals focus
   * is dismissed, focus should be returned
   * to the element that was focused
   * prior to the overlay opening. Toast
   * does not steal focus and is excluded
   * from returning focus as a result.
   */
  if (overlay.el.tagName !== 'ION-TOAST') {
    focusPreviousElementOnDismiss(overlay.el);
  }
  if (overlay.keyboardClose) {
    overlay.el.focus();
  }
};
/**
 * When an overlay component is dismissed,
 * focus should be returned to the element
 * that presented the overlay. Otherwise
 * focus will be set on the body which
 * means that people using screen readers
 * or tabbing will need to re-navigate
 * to where they were before they
 * opened the overlay.
 */
const focusPreviousElementOnDismiss = async (overlayEl) => {
  let previousElement = document.activeElement;
  if (!previousElement) {
    return;
  }
  const shadowRoot = previousElement && previousElement.shadowRoot;
  if (shadowRoot) {
    // If there are no inner focusable elements, just focus the host element.
    previousElement = shadowRoot.querySelector(innerFocusableQueryString) || previousElement;
  }
  await overlayEl.onDidDismiss();
  previousElement.focus();
};
export const dismiss = async (overlay, data, role, name, iosLeaveAnimation, mdLeaveAnimation, opts) => {
  if (!overlay.presented) {
    return false;
  }
  setRootAriaHidden(false);
  overlay.presented = false;
  try {
    // Overlay contents should not be clickable during dismiss
    overlay.el.style.setProperty('pointer-events', 'none');
    overlay.willDismiss.emit({ data, role });
    const mode = getIonMode(overlay);
    const animationBuilder = (overlay.leaveAnimation)
      ? overlay.leaveAnimation
      : config.get(name, mode === 'ios' ? iosLeaveAnimation : mdLeaveAnimation);
    // If dismissed via gesture, no need to play leaving animation again
    if (role !== 'gesture') {
      await overlayAnimation(overlay, animationBuilder, overlay.el, opts);
    }
    overlay.didDismiss.emit({ data, role });
    activeAnimations.delete(overlay);
  }
  catch (err) {
    console.error(err);
  }
  overlay.el.remove();
  return true;
};
const getAppRoot = (doc) => {
  return doc.querySelector('ion-app') || doc.body;
};
const overlayAnimation = async (overlay, animationBuilder, baseEl, opts) => {
  // Make overlay visible in case it's hidden
  baseEl.classList.remove('overlay-hidden');
  const aniRoot = baseEl.shadowRoot || overlay.el;
  const animation = animationBuilder(aniRoot, opts);
  if (!overlay.animated || !config.getBoolean('animated', true)) {
    animation.duration(0);
  }
  if (overlay.keyboardClose) {
    animation.beforeAddWrite(() => {
      const activeElement = baseEl.ownerDocument.activeElement;
      if (activeElement && activeElement.matches('input, ion-input, ion-textarea')) {
        activeElement.blur();
      }
    });
  }
  const activeAni = activeAnimations.get(overlay) || [];
  activeAnimations.set(overlay, [...activeAni, animation]);
  await animation.play();
  return true;
};
export const eventMethod = (element, eventName) => {
  let resolve;
  const promise = new Promise(r => resolve = r);
  onceEvent(element, eventName, (event) => {
    resolve(event.detail);
  });
  return promise;
};
export const onceEvent = (element, eventName, callback) => {
  const handler = (ev) => {
    removeEventListener(element, eventName, handler);
    callback(ev);
  };
  addEventListener(element, eventName, handler);
};
export const isCancel = (role) => {
  return role === 'cancel' || role === BACKDROP;
};
const defaultGate = (h) => h();
export const safeCall = (handler, arg) => {
  if (typeof handler === 'function') {
    const jmp = config.get('_zoneGate', defaultGate);
    return jmp(() => {
      try {
        return handler(arg);
      }
      catch (e) {
        console.error(e);
      }
    });
  }
  return undefined;
};
export const BACKDROP = 'backdrop';
