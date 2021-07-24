import { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import { AutocompleteTypes, Color, InputChangeEventDetail, StyleEventDetail, TextFieldTypes } from '../../interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export declare class Input implements ComponentInterface {
  private nativeInput?;
  private inputId;
  private didBlurAfterEdit;
  private inheritedAttributes;
  /**
   * This is required for a WebKit bug which requires us to
   * blur and focus an input to properly focus the input in
   * an item with delegatesFocus. It will no longer be needed
   * with iOS 14.
   *
   * @internal
   */
  fireFocusEvents: boolean;
  hasFocus: boolean;
  el: HTMLElement;
  /**
   * The color to use from your application's color palette.
   * Default options are: `"primary"`, `"secondary"`, `"tertiary"`, `"success"`, `"warning"`, `"danger"`, `"light"`, `"medium"`, and `"dark"`.
   * For more information on colors, see [theming](/docs/theming/basics).
   */
  color?: Color;
  /**
   * If the value of the type attribute is `"file"`, then this attribute will indicate the types of files that the server accepts, otherwise it will be ignored. The value must be a comma-separated list of unique content type specifiers.
   */
  accept?: string;
  /**
   * Indicates whether and how the text value should be automatically capitalized as it is entered/edited by the user.
   * Available options: `"off"`, `"none"`, `"on"`, `"sentences"`, `"words"`, `"characters"`.
   */
  autocapitalize: string;
  /**
   * Indicates whether the value of the control can be automatically completed by the browser.
   */
  autocomplete: AutocompleteTypes;
  /**
   * Whether auto correction should be enabled when the user is entering/editing the text value.
   */
  autocorrect: 'on' | 'off';
  /**
   * This Boolean attribute lets you specify that a form control should have input focus when the page loads.
   */
  autofocus: boolean;
  /**
   * If `true`, a clear icon will appear in the input when there is a value. Clicking it clears the input.
   */
  clearInput: boolean;
  /**
   * If `true`, the value will be cleared after focus upon edit. Defaults to `true` when `type` is `"password"`, `false` for all other types.
   */
  clearOnEdit?: boolean;
  /**
   * Set the amount of time, in milliseconds, to wait to trigger the `ionChange` event after each keystroke. This also impacts form bindings such as `ngModel` or `v-model`.
   */
  debounce: number;
  protected debounceChanged(): void;
  /**
   * If `true`, the user cannot interact with the input.
   */
  disabled: boolean;
  protected disabledChanged(): void;
  /**
   * A hint to the browser for which enter key to display.
   * Possible values: `"enter"`, `"done"`, `"go"`, `"next"`,
   * `"previous"`, `"search"`, and `"send"`.
   */
  enterkeyhint?: 'enter' | 'done' | 'go' | 'next' | 'previous' | 'search' | 'send';
  /**
   * A hint to the browser for which keyboard to display.
   * Possible values: `"none"`, `"text"`, `"tel"`, `"url"`,
   * `"email"`, `"numeric"`, `"decimal"`, and `"search"`.
   */
  inputmode?: 'none' | 'text' | 'tel' | 'url' | 'email' | 'numeric' | 'decimal' | 'search';
  /**
   * The maximum value, which must not be less than its minimum (min attribute) value.
   */
  max?: string;
  /**
   * If the value of the type attribute is `text`, `email`, `search`, `password`, `tel`, or `url`, this attribute specifies the maximum number of characters that the user can enter.
   */
  maxlength?: number;
  /**
   * The minimum value, which must not be greater than its maximum (max attribute) value.
   */
  min?: string;
  /**
   * If the value of the type attribute is `text`, `email`, `search`, `password`, `tel`, or `url`, this attribute specifies the minimum number of characters that the user can enter.
   */
  minlength?: number;
  /**
   * If `true`, the user can enter more than one value. This attribute applies when the type attribute is set to `"email"` or `"file"`, otherwise it is ignored.
   */
  multiple?: boolean;
  /**
   * The name of the control, which is submitted with the form data.
   */
  name: string;
  /**
   * A regular expression that the value is checked against. The pattern must match the entire value, not just some subset. Use the title attribute to describe the pattern to help the user. This attribute applies when the value of the type attribute is `"text"`, `"search"`, `"tel"`, `"url"`, `"email"`, `"date"`, or `"password"`, otherwise it is ignored. When the type attribute is `"date"`, `pattern` will only be used in browsers that do not support the `"date"` input type natively. See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/date for more information.
   */
  pattern?: string;
  /**
   * Instructional text that shows before the input has a value.
   */
  placeholder?: string | null;
  /**
   * If `true`, the user cannot modify the value.
   */
  readonly: boolean;
  /**
   * If `true`, the user must fill in a value before submitting a form.
   */
  required: boolean;
  /**
   * If `true`, the element will have its spelling and grammar checked.
   */
  spellcheck: boolean;
  /**
   * Works with the min and max attributes to limit the increments at which a value can be set.
   * Possible values are: `"any"` or a positive floating point number.
   */
  step?: string;
  /**
   * The initial size of the control. This value is in pixels unless the value of the type attribute is `"text"` or `"password"`, in which case it is an integer number of characters. This attribute applies only when the `type` attribute is set to `"text"`, `"search"`, `"tel"`, `"url"`, `"email"`, or `"password"`, otherwise it is ignored.
   */
  size?: number;
  /**
   * The type of control to display. The default type is text.
   */
  type: TextFieldTypes;
  /**
   * The value of the input.
   */
  value?: string | number | null;
  /**
   * Emitted when a keyboard input occurred.
   */
  ionInput: EventEmitter<KeyboardEvent>;
  /**
   * Emitted when the value has changed.
   */
  ionChange: EventEmitter<InputChangeEventDetail>;
  /**
   * Emitted when the input loses focus.
   */
  ionBlur: EventEmitter<FocusEvent>;
  /**
   * Emitted when the input has focus.
   */
  ionFocus: EventEmitter<FocusEvent>;
  /**
   * Emitted when the styles change.
   * @internal
   */
  ionStyle: EventEmitter<StyleEventDetail>;
  /**
   * Update the item classes when the placeholder changes
   */
  protected placeholderChanged(): void;
  /**
   * Update the native input element when the value changes
   */
  protected valueChanged(): void;
  componentWillLoad(): void;
  connectedCallback(): void;
  disconnectedCallback(): void;
  /**
   * Sets focus on the native `input` in `ion-input`. Use this method instead of the global
   * `input.focus()`.
   */
  setFocus(): Promise<void>;
  /**
   * Sets blur on the native `input` in `ion-input`. Use this method instead of the global
   * `input.blur()`.
   * @internal
   */
  setBlur(): Promise<void>;
  /**
   * Returns the native `<input>` element used under the hood.
   */
  getInputElement(): Promise<HTMLInputElement>;
  private shouldClearOnEdit;
  private getValue;
  private emitStyle;
  private onInput;
  private onBlur;
  private onFocus;
  private onKeydown;
  private clearTextOnEnter;
  private clearTextInput;
  private focusChanged;
  private hasValue;
  render(): any;
}
