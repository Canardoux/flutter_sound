import { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import { Color, SegmentChangeEventDetail, StyleEventDetail } from '../../interface';
import { GestureDetail } from '../../utils/gesture';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export declare class Segment implements ComponentInterface {
  private gesture?;
  private didInit;
  private checked?;
  private valueAfterGesture?;
  el: HTMLIonSegmentElement;
  activated: boolean;
  /**
   * The color to use from your application's color palette.
   * Default options are: `"primary"`, `"secondary"`, `"tertiary"`, `"success"`, `"warning"`, `"danger"`, `"light"`, `"medium"`, and `"dark"`.
   * For more information on colors, see [theming](/docs/theming/basics).
   */
  color?: Color;
  protected colorChanged(value?: Color, oldValue?: Color): void;
  /**
   * If `true`, the user cannot interact with the segment.
   */
  disabled: boolean;
  /**
   * If `true`, the segment buttons will overflow and the user can swipe to see them.
   * In addition, this will disable the gesture to drag the indicator between the buttons
   * in order to swipe to see hidden buttons.
   */
  scrollable: boolean;
  /**
   * If `true`, users will be able to swipe between segment buttons to activate them.
   */
  swipeGesture: boolean;
  swipeGestureChanged(): void;
  /**
   * the value of the segment.
   */
  value?: string | null;
  protected valueChanged(value: string | undefined, oldValue: string | undefined | null): void;
  /**
   * Emitted when the value property has changed and any
   * dragging pointer has been released from `ion-segment`.
   */
  ionChange: EventEmitter<SegmentChangeEventDetail>;
  /**
   * Emitted when user has dragged over a new button
   * @internal
   */
  ionSelect: EventEmitter<SegmentChangeEventDetail>;
  /**
   * Emitted when the styles change.
   * @internal
   */
  ionStyle: EventEmitter<StyleEventDetail>;
  disabledChanged(): void;
  private gestureChanged;
  connectedCallback(): void;
  componentWillLoad(): void;
  componentDidLoad(): Promise<void>;
  onStart(detail: GestureDetail): void;
  onMove(detail: GestureDetail): void;
  onEnd(detail: GestureDetail): void;
  private getButtons;
  /**
   * The gesture blocks the segment button ripple. This
   * function adds the ripple based on the checked segment
   * and where the cursor ended.
   */
  private addRipple;
  private setActivated;
  private activate;
  private getIndicator;
  private checkButton;
  private setCheckedClasses;
  private setNextIndex;
  private emitStyle;
  private onClick;
  render(): any;
}
