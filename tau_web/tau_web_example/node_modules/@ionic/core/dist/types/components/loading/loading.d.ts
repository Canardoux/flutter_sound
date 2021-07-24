import { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import { AnimationBuilder, OverlayEventDetail, OverlayInterface, SpinnerTypes } from '../../interface';
import { IonicSafeString } from '../../utils/sanitization';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export declare class Loading implements ComponentInterface, OverlayInterface {
  private durationTimeout;
  presented: boolean;
  lastFocus?: HTMLElement;
  el: HTMLIonLoadingElement;
  /** @internal */
  overlayIndex: number;
  /**
   * If `true`, the keyboard will be automatically dismissed when the overlay is presented.
   */
  keyboardClose: boolean;
  /**
   * Animation to use when the loading indicator is presented.
   */
  enterAnimation?: AnimationBuilder;
  /**
   * Animation to use when the loading indicator is dismissed.
   */
  leaveAnimation?: AnimationBuilder;
  /**
   * Optional text content to display in the loading indicator.
   */
  message?: string | IonicSafeString;
  /**
   * Additional classes to apply for custom CSS. If multiple classes are
   * provided they should be separated by spaces.
   */
  cssClass?: string | string[];
  /**
   * Number of milliseconds to wait before dismissing the loading indicator.
   */
  duration: number;
  /**
   * If `true`, the loading indicator will be dismissed when the backdrop is clicked.
   */
  backdropDismiss: boolean;
  /**
   * If `true`, a backdrop will be displayed behind the loading indicator.
   */
  showBackdrop: boolean;
  /**
   * The name of the spinner to display.
   */
  spinner?: SpinnerTypes | null;
  /**
   * If `true`, the loading indicator will be translucent.
   * Only applies when the mode is `"ios"` and the device supports
   * [`backdrop-filter`](https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter#Browser_compatibility).
   */
  translucent: boolean;
  /**
   * If `true`, the loading indicator will animate.
   */
  animated: boolean;
  /**
   * Emitted after the loading has presented.
   */
  didPresent: EventEmitter<void>;
  /**
   * Emitted before the loading has presented.
   */
  willPresent: EventEmitter<void>;
  /**
   * Emitted before the loading has dismissed.
   */
  willDismiss: EventEmitter<OverlayEventDetail>;
  /**
   * Emitted after the loading has dismissed.
   */
  didDismiss: EventEmitter<OverlayEventDetail>;
  connectedCallback(): void;
  componentWillLoad(): void;
  /**
   * Present the loading overlay after it has been created.
   */
  present(): Promise<void>;
  /**
   * Dismiss the loading overlay after it has been presented.
   *
   * @param data Any data to emit in the dismiss events.
   * @param role The role of the element that is dismissing the loading.
   * This can be useful in a button handler for determining which button was
   * clicked to dismiss the loading.
   * Some examples include: ``"cancel"`, `"destructive"`, "selected"`, and `"backdrop"`.
   */
  dismiss(data?: any, role?: string): Promise<boolean>;
  /**
   * Returns a promise that resolves when the loading did dismiss.
   */
  onDidDismiss<T = any>(): Promise<OverlayEventDetail<T>>;
  /**
   * Returns a promise that resolves when the loading will dismiss.
   */
  onWillDismiss<T = any>(): Promise<OverlayEventDetail<T>>;
  private onBackdropTap;
  render(): any;
}
