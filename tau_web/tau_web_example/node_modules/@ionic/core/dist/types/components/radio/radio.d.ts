import { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import { Color, StyleEventDetail } from '../../interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 *
 * @part container - The container for the radio mark.
 * @part mark - The checkmark or dot used to indicate the checked state.
 */
export declare class Radio implements ComponentInterface {
  private inputId;
  private radioGroup;
  el: HTMLIonRadioElement;
  /**
   * If `true`, the radio is selected.
   */
  checked: boolean;
  /**
   * The tabindex of the radio button.
   * @internal
   */
  buttonTabindex: number;
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
   * If `true`, the user cannot interact with the radio.
   */
  disabled: boolean;
  /**
   * the value of the radio.
   */
  value?: any | null;
  /**
   * Emitted when the styles change.
   * @internal
   */
  ionStyle: EventEmitter<StyleEventDetail>;
  /**
   * Emitted when the radio button has focus.
   */
  ionFocus: EventEmitter<void>;
  /**
   * Emitted when the radio button loses focus.
   */
  ionBlur: EventEmitter<void>;
  /** @internal */
  setFocus(ev: any): Promise<void>;
  /** @internal */
  setButtonTabindex(value: number): Promise<void>;
  connectedCallback(): void;
  disconnectedCallback(): void;
  componentWillLoad(): void;
  emitStyle(): void;
  private updateState;
  private onFocus;
  private onBlur;
  render(): any;
}
