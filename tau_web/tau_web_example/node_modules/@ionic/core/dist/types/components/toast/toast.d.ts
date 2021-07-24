import { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import { AnimationBuilder, Color, OverlayEventDetail, OverlayInterface, ToastButton } from '../../interface';
import { IonicSafeString } from '../../utils/sanitization';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 *
 * @part button - Any button element that is displayed inside of the toast.
 * @part container - The element that wraps all child elements.
 * @part header - The header text of the toast.
 * @part message - The body text of the toast.
 */
export declare class Toast implements ComponentInterface, OverlayInterface {
  private durationTimeout;
  presented: boolean;
  el: HTMLIonToastElement;
  /**
   * @internal
   */
  overlayIndex: number;
  /**
   * The color to use from your application's color palette.
   * Default options are: `"primary"`, `"secondary"`, `"tertiary"`, `"success"`, `"warning"`, `"danger"`, `"light"`, `"medium"`, and `"dark"`.
   * For more information on colors, see [theming](/docs/theming/basics).
   */
  color?: Color;
  /**
   * Animation to use when the toast is presented.
   */
  enterAnimation?: AnimationBuilder;
  /**
   * Animation to use when the toast is dismissed.
   */
  leaveAnimation?: AnimationBuilder;
  /**
   * Additional classes to apply for custom CSS. If multiple classes are
   * provided they should be separated by spaces.
   */
  cssClass?: string | string[];
  /**
   * How many milliseconds to wait before hiding the toast. By default, it will show
   * until `dismiss()` is called.
   */
  duration: number;
  /**
   * Header to be shown in the toast.
   */
  header?: string;
  /**
   * Message to be shown in the toast.
   */
  message?: string | IonicSafeString;
  /**
   * If `true`, the keyboard will be automatically dismissed when the overlay is presented.
   */
  keyboardClose: boolean;
  /**
   * The position of the toast on the screen.
   */
  position: 'top' | 'bottom' | 'middle';
  /**
   * An array of buttons for the toast.
   */
  buttons?: (ToastButton | string)[];
  /**
   * If `true`, the toast will be translucent.
   * Only applies when the mode is `"ios"` and the device supports
   * [`backdrop-filter`](https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter#Browser_compatibility).
   */
  translucent: boolean;
  /**
   * If `true`, the toast will animate.
   */
  animated: boolean;
  /**
   * Emitted after the toast has presented.
   */
  didPresent: EventEmitter<void>;
  /**
   * Emitted before the toast has presented.
   */
  willPresent: EventEmitter<void>;
  /**
   * Emitted before the toast has dismissed.
   */
  willDismiss: EventEmitter<OverlayEventDetail>;
  /**
   * Emitted after the toast has dismissed.
   */
  didDismiss: EventEmitter<OverlayEventDetail>;
  connectedCallback(): void;
  /**
   * Present the toast overlay after it has been created.
   */
  present(): Promise<void>;
  /**
   * Dismiss the toast overlay after it has been presented.
   *
   * @param data Any data to emit in the dismiss events.
   * @param role The role of the element that is dismissing the toast.
   * This can be useful in a button handler for determining which button was
   * clicked to dismiss the toast.
   * Some examples include: ``"cancel"`, `"destructive"`, "selected"`, and `"backdrop"`.
   */
  dismiss(data?: any, role?: string): Promise<boolean>;
  /**
   * Returns a promise that resolves when the toast did dismiss.
   */
  onDidDismiss<T = any>(): Promise<OverlayEventDetail<T>>;
  /**
   * Returns a promise that resolves when the toast will dismiss.
   */
  onWillDismiss<T = any>(): Promise<OverlayEventDetail<T>>;
  private getButtons;
  private buttonClick;
  private callButtonHandler;
  private dispatchCancelHandler;
  renderButtons(buttons: ToastButton[], side: 'start' | 'end'): any;
  render(): any;
}
