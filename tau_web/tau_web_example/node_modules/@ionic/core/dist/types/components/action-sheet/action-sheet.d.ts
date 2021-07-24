import { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import { ActionSheetButton, AnimationBuilder, OverlayEventDetail, OverlayInterface } from '../../interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export declare class ActionSheet implements ComponentInterface, OverlayInterface {
  presented: boolean;
  lastFocus?: HTMLElement;
  animation?: any;
  private wrapperEl?;
  private groupEl?;
  private gesture?;
  el: HTMLIonActionSheetElement;
  /** @internal */
  overlayIndex: number;
  /**
   * If `true`, the keyboard will be automatically dismissed when the overlay is presented.
   */
  keyboardClose: boolean;
  /**
   * Animation to use when the action sheet is presented.
   */
  enterAnimation?: AnimationBuilder;
  /**
   * Animation to use when the action sheet is dismissed.
   */
  leaveAnimation?: AnimationBuilder;
  /**
   * An array of buttons for the action sheet.
   */
  buttons: (ActionSheetButton | string)[];
  /**
   * Additional classes to apply for custom CSS. If multiple classes are
   * provided they should be separated by spaces.
   */
  cssClass?: string | string[];
  /**
   * If `true`, the action sheet will be dismissed when the backdrop is clicked.
   */
  backdropDismiss: boolean;
  /**
   * Title for the action sheet.
   */
  header?: string;
  /**
   * Subtitle for the action sheet.
   */
  subHeader?: string;
  /**
   * If `true`, the action sheet will be translucent.
   * Only applies when the mode is `"ios"` and the device supports
   * [`backdrop-filter`](https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter#Browser_compatibility).
   */
  translucent: boolean;
  /**
   * If `true`, the action sheet will animate.
   */
  animated: boolean;
  /**
   * Emitted after the alert has presented.
   */
  didPresent: EventEmitter<void>;
  /**
   * Emitted before the alert has presented.
   */
  willPresent: EventEmitter<void>;
  /**
   * Emitted before the alert has dismissed.
   */
  willDismiss: EventEmitter<OverlayEventDetail>;
  /**
   * Emitted after the alert has dismissed.
   */
  didDismiss: EventEmitter<OverlayEventDetail>;
  /**
   * Present the action sheet overlay after it has been created.
   */
  present(): Promise<void>;
  connectedCallback(): void;
  /**
   * Dismiss the action sheet overlay after it has been presented.
   *
   * @param data Any data to emit in the dismiss events.
   * @param role The role of the element that is dismissing the action sheet.
   * This can be useful in a button handler for determining which button was
   * clicked to dismiss the action sheet.
   * Some examples include: ``"cancel"`, `"destructive"`, "selected"`, and `"backdrop"`.
   */
  dismiss(data?: any, role?: string): Promise<boolean>;
  /**
   * Returns a promise that resolves when the action sheet did dismiss.
   */
  onDidDismiss<T = any>(): Promise<OverlayEventDetail<T>>;
  /**
   * Returns a promise that resolves when the action sheet will dismiss.
   *
   */
  onWillDismiss<T = any>(): Promise<OverlayEventDetail<T>>;
  private buttonClick;
  private callButtonHandler;
  private getButtons;
  private onBackdropTap;
  private dispatchCancelHandler;
  disconnectedCallback(): void;
  componentDidLoad(): void;
  render(): any;
}
