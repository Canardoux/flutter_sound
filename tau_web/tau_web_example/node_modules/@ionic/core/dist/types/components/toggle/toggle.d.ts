import { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import { Color, StyleEventDetail, ToggleChangeEventDetail } from '../../interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 *
 * @part track - The background track of the toggle.
 * @part handle - The toggle handle, or knob, used to change the checked state.
 */
export declare class Toggle implements ComponentInterface {
  private inputId;
  private gesture?;
  private focusEl?;
  private lastDrag;
  el: HTMLElement;
  activated: boolean;
  /**
   * The color to use from your application's color palette.
   * Default options are: `"primary"`, `"secondary"`, `"tertiary"`, `"success"`, `"warning"`, `"danger"`, `"light"`, `"medium"`, and `"dark"`.
   * For more information on colors, see [theming](/docs/theming/basics).
   */
  color?: Color;
  /**
   * The name of the control, which is submitted with the form data.
   */
  name: string;
  /**
   * If `true`, the toggle is selected.
   */
  checked: boolean;
  /**
   * If `true`, the user cannot interact with the toggle.
   */
  disabled: boolean;
  /**
   * The value of the toggle does not mean if it's checked or not, use the `checked`
   * property for that.
   *
   * The value of a toggle is analogous to the value of a `<input type="checkbox">`,
   * it's only used when the toggle participates in a native `<form>`.
   */
  value?: string | null;
  /**
   * Emitted when the value property has changed.
   */
  ionChange: EventEmitter<ToggleChangeEventDetail>;
  /**
   * Emitted when the toggle has focus.
   */
  ionFocus: EventEmitter<void>;
  /**
   * Emitted when the toggle loses focus.
   */
  ionBlur: EventEmitter<void>;
  /**
   * Emitted when the styles change.
   * @internal
   */
  ionStyle: EventEmitter<StyleEventDetail>;
  checkedChanged(isChecked: boolean): void;
  disabledChanged(): void;
  connectedCallback(): Promise<void>;
  disconnectedCallback(): void;
  componentWillLoad(): void;
  private emitStyle;
  private onStart;
  private onMove;
  private onEnd;
  private getValue;
  private setFocus;
  private onClick;
  private onFocus;
  private onBlur;
  render(): any;
}
