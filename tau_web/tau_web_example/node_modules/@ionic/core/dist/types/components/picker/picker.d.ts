import { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import { AnimationBuilder, OverlayEventDetail, OverlayInterface, PickerButton, PickerColumn } from '../../interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export declare class Picker implements ComponentInterface, OverlayInterface {
  private durationTimeout;
  lastFocus?: HTMLElement;
  el: HTMLIonPickerElement;
  presented: boolean;
  /** @internal */
  overlayIndex: number;
  /**
   * If `true`, the keyboard will be automatically dismissed when the overlay is presented.
   */
  keyboardClose: boolean;
  /**
   * Animation to use when the picker is presented.
   */
  enterAnimation?: AnimationBuilder;
  /**
   * Animation to use when the picker is dismissed.
   */
  leaveAnimation?: AnimationBuilder;
  /**
   * Array of buttons to be displayed at the top of the picker.
   */
  buttons: PickerButton[];
  /**
   * Array of columns to be displayed in the picker.
   */
  columns: PickerColumn[];
  /**
   * Additional classes to apply for custom CSS. If multiple classes are
   * provided they should be separated by spaces.
   */
  cssClass?: string | string[];
  /**
   * Number of milliseconds to wait before dismissing the picker.
   */
  duration: number;
  /**
   * If `true`, a backdrop will be displayed behind the picker.
   */
  showBackdrop: boolean;
  /**
   * If `true`, the picker will be dismissed when the backdrop is clicked.
   */
  backdropDismiss: boolean;
  /**
   * If `true`, the picker will animate.
   */
  animated: boolean;
  /**
   * Emitted after the picker has presented.
   */
  didPresent: EventEmitter<void>;
  /**
   * Emitted before the picker has presented.
   */
  willPresent: EventEmitter<void>;
  /**
   * Emitted before the picker has dismissed.
   */
  willDismiss: EventEmitter<OverlayEventDetail>;
  /**
   * Emitted after the picker has dismissed.
   */
  didDismiss: EventEmitter<OverlayEventDetail>;
  connectedCallback(): void;
  /**
   * Present the picker overlay after it has been created.
   */
  present(): Promise<void>;
  /**
   * Dismiss the picker overlay after it has been presented.
   *
   * @param data Any data to emit in the dismiss events.
   * @param role The role of the element that is dismissing the picker.
   * This can be useful in a button handler for determining which button was
   * clicked to dismiss the picker.
   * Some examples include: ``"cancel"`, `"destructive"`, "selected"`, and `"backdrop"`.
   */
  dismiss(data?: any, role?: string): Promise<boolean>;
  /**
   * Returns a promise that resolves when the picker did dismiss.
   */
  onDidDismiss<T = any>(): Promise<OverlayEventDetail<T>>;
  /**
   * Returns a promise that resolves when the picker will dismiss.
   */
  onWillDismiss<T = any>(): Promise<OverlayEventDetail<T>>;
  /**
   * Get the column that matches the specified name.
   *
   * @param name The name of the column.
   */
  getColumn(name: string): Promise<PickerColumn | undefined>;
  private buttonClick;
  private callButtonHandler;
  private getSelected;
  private onBackdropTap;
  private dispatchCancelHandler;
  render(): any;
}
