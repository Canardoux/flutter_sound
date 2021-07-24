import { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import { AnimationBuilder, ComponentProps, ComponentRef, FrameworkDelegate, OverlayEventDetail, OverlayInterface } from '../../interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export declare class Popover implements ComponentInterface, OverlayInterface {
  private usersElement?;
  presented: boolean;
  lastFocus?: HTMLElement;
  el: HTMLIonPopoverElement;
  /** @internal */
  delegate?: FrameworkDelegate;
  /** @internal */
  overlayIndex: number;
  /**
   * Animation to use when the popover is presented.
   */
  enterAnimation?: AnimationBuilder;
  /**
   * Animation to use when the popover is dismissed.
   */
  leaveAnimation?: AnimationBuilder;
  /**
   * The component to display inside of the popover.
   */
  component: ComponentRef;
  /**
   * The data to pass to the popover component.
   */
  componentProps?: ComponentProps;
  /**
   * If `true`, the keyboard will be automatically dismissed when the overlay is presented.
   */
  keyboardClose: boolean;
  /**
   * Additional classes to apply for custom CSS. If multiple classes are
   * provided they should be separated by spaces.
   */
  cssClass?: string | string[];
  /**
   * If `true`, the popover will be dismissed when the backdrop is clicked.
   */
  backdropDismiss: boolean;
  /**
   * The event to pass to the popover animation.
   */
  event: any;
  /**
   * If `true`, a backdrop will be displayed behind the popover.
   */
  showBackdrop: boolean;
  /**
   * If `true`, the popover will be translucent.
   * Only applies when the mode is `"ios"` and the device supports
   * [`backdrop-filter`](https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter#Browser_compatibility).
   */
  translucent: boolean;
  /**
   * If `true`, the popover will animate.
   */
  animated: boolean;
  /**
   * Emitted after the popover has presented.
   */
  didPresent: EventEmitter<void>;
  /**
   * Emitted before the popover has presented.
   */
  willPresent: EventEmitter<void>;
  /**
   * Emitted before the popover has dismissed.
   */
  willDismiss: EventEmitter<OverlayEventDetail>;
  /**
   * Emitted after the popover has dismissed.
   */
  didDismiss: EventEmitter<OverlayEventDetail>;
  connectedCallback(): void;
  /**
   * Present the popover overlay after it has been created.
   */
  present(): Promise<void>;
  /**
   * Dismiss the popover overlay after it has been presented.
   *
   * @param data Any data to emit in the dismiss events.
   * @param role The role of the element that is dismissing the popover. For example, 'cancel' or 'backdrop'.
   */
  dismiss(data?: any, role?: string): Promise<boolean>;
  /**
   * Returns a promise that resolves when the popover did dismiss.
   */
  onDidDismiss<T = any>(): Promise<OverlayEventDetail<T>>;
  /**
   * Returns a promise that resolves when the popover will dismiss.
   */
  onWillDismiss<T = any>(): Promise<OverlayEventDetail<T>>;
  private onDismiss;
  private onBackdropTap;
  private onLifecycle;
  render(): any;
}
