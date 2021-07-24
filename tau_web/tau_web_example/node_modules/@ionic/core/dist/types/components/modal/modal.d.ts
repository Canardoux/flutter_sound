import { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import { Animation, AnimationBuilder, ComponentProps, ComponentRef, FrameworkDelegate, OverlayEventDetail, OverlayInterface } from '../../interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export declare class Modal implements ComponentInterface, OverlayInterface {
  private gesture?;
  private usersElement?;
  private gestureAnimationDismissing;
  presented: boolean;
  lastFocus?: HTMLElement;
  animation?: Animation;
  el: HTMLIonModalElement;
  /** @internal */
  overlayIndex: number;
  /** @internal */
  delegate?: FrameworkDelegate;
  /**
   * If `true`, the keyboard will be automatically dismissed when the overlay is presented.
   */
  keyboardClose: boolean;
  /**
   * Animation to use when the modal is presented.
   */
  enterAnimation?: AnimationBuilder;
  /**
   * Animation to use when the modal is dismissed.
   */
  leaveAnimation?: AnimationBuilder;
  /**
   * The component to display inside of the modal.
   */
  component: ComponentRef;
  /**
   * The data to pass to the modal component.
   */
  componentProps?: ComponentProps;
  /**
   * Additional classes to apply for custom CSS. If multiple classes are
   * provided they should be separated by spaces.
   */
  cssClass?: string | string[];
  /**
   * If `true`, the modal will be dismissed when the backdrop is clicked.
   */
  backdropDismiss: boolean;
  /**
   * If `true`, a backdrop will be displayed behind the modal.
   */
  showBackdrop: boolean;
  /**
   * If `true`, the modal will animate.
   */
  animated: boolean;
  /**
   * If `true`, the modal can be swiped to dismiss. Only applies in iOS mode.
   */
  swipeToClose: boolean;
  /**
   * The element that presented the modal. This is used for card presentation effects
   * and for stacking multiple modals on top of each other. Only applies in iOS mode.
   */
  presentingElement?: HTMLElement;
  /**
   * Emitted after the modal has presented.
   */
  didPresent: EventEmitter<void>;
  /**
   * Emitted before the modal has presented.
   */
  willPresent: EventEmitter<void>;
  /**
   * Emitted before the modal has dismissed.
   */
  willDismiss: EventEmitter<OverlayEventDetail>;
  /**
   * Emitted after the modal has dismissed.
   */
  didDismiss: EventEmitter<OverlayEventDetail>;
  swipeToCloseChanged(enable: boolean): void;
  connectedCallback(): void;
  /**
   * Present the modal overlay after it has been created.
   */
  present(): Promise<void>;
  private initSwipeToClose;
  /**
   * Dismiss the modal overlay after it has been presented.
   *
   * @param data Any data to emit in the dismiss events.
   * @param role The role of the element that is dismissing the modal. For example, 'cancel' or 'backdrop'.
   */
  dismiss(data?: any, role?: string): Promise<boolean>;
  /**
   * Returns a promise that resolves when the modal did dismiss.
   */
  onDidDismiss<T = any>(): Promise<OverlayEventDetail<T>>;
  /**
   * Returns a promise that resolves when the modal will dismiss.
   */
  onWillDismiss<T = any>(): Promise<OverlayEventDetail<T>>;
  private onBackdropTap;
  private onDismiss;
  private onLifecycle;
  render(): any;
}
