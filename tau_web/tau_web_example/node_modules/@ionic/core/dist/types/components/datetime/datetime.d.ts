import { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import { DatetimeChangeEventDetail, DatetimeOptions, StyleEventDetail } from '../../interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 *
 * @part text - The value of the datetime.
 * @part placeholder - The placeholder of the datetime.
 */
export declare class Datetime implements ComponentInterface {
  private inputId;
  private locale;
  private datetimeMin;
  private datetimeMax;
  private datetimeValue;
  private buttonEl?;
  el: HTMLIonDatetimeElement;
  isExpanded: boolean;
  /**
   * The name of the control, which is submitted with the form data.
   */
  name: string;
  /**
   * If `true`, the user cannot interact with the datetime.
   */
  disabled: boolean;
  /**
   * If `true`, the datetime appears normal but is not interactive.
   */
  readonly: boolean;
  protected disabledChanged(): void;
  /**
   * The minimum datetime allowed. Value must be a date string
   * following the
   * [ISO 8601 datetime format standard](https://www.w3.org/TR/NOTE-datetime),
   * such as `1996-12-19`. The format does not have to be specific to an exact
   * datetime. For example, the minimum could just be the year, such as `1994`.
   * Defaults to the beginning of the year, 100 years ago from today.
   */
  min?: string;
  /**
   * The maximum datetime allowed. Value must be a date string
   * following the
   * [ISO 8601 datetime format standard](https://www.w3.org/TR/NOTE-datetime),
   * `1996-12-19`. The format does not have to be specific to an exact
   * datetime. For example, the maximum could just be the year, such as `1994`.
   * Defaults to the end of this year.
   */
  max?: string;
  /**
   * The display format of the date and time as text that shows
   * within the item. When the `pickerFormat` input is not used, then the
   * `displayFormat` is used for both display the formatted text, and determining
   * the datetime picker's columns. See the `pickerFormat` input description for
   * more info. Defaults to `MMM D, YYYY`.
   */
  displayFormat: string;
  /**
   * The timezone to use for display purposes only. See
   * [Date.prototype.toLocaleString()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/toLocaleString)
   * for a list of supported timezones. If no value is provided, the
   * component will default to displaying times in the user's local timezone.
   */
  displayTimezone?: string;
  /**
   * The format of the date and time picker columns the user selects.
   * A datetime input can have one or many datetime parts, each getting their
   * own column which allow individual selection of that particular datetime part. For
   * example, year and month columns are two individually selectable columns which help
   * choose an exact date from the datetime picker. Each column follows the string
   * parse format. Defaults to use `displayFormat`.
   */
  pickerFormat?: string;
  /**
   * The text to display on the picker's cancel button.
   */
  cancelText: string;
  /**
   * The text to display on the picker's "Done" button.
   */
  doneText: string;
  /**
   * Values used to create the list of selectable years. By default
   * the year values range between the `min` and `max` datetime inputs. However, to
   * control exactly which years to display, the `yearValues` input can take a number, an array
   * of numbers, or string of comma separated numbers. For example, to show upcoming and
   * recent leap years, then this input's value would be `yearValues="2024,2020,2016,2012,2008"`.
   */
  yearValues?: number[] | number | string;
  /**
   * Values used to create the list of selectable months. By default
   * the month values range from `1` to `12`. However, to control exactly which months to
   * display, the `monthValues` input can take a number, an array of numbers, or a string of
   * comma separated numbers. For example, if only summer months should be shown, then this
   * input value would be `monthValues="6,7,8"`. Note that month numbers do *not* have a
   * zero-based index, meaning January's value is `1`, and December's is `12`.
   */
  monthValues?: number[] | number | string;
  /**
   * Values used to create the list of selectable days. By default
   * every day is shown for the given month. However, to control exactly which days of
   * the month to display, the `dayValues` input can take a number, an array of numbers, or
   * a string of comma separated numbers. Note that even if the array days have an invalid
   * number for the selected month, like `31` in February, it will correctly not show
   * days which are not valid for the selected month.
   */
  dayValues?: number[] | number | string;
  /**
   * Values used to create the list of selectable hours. By default
   * the hour values range from `0` to `23` for 24-hour, or `1` to `12` for 12-hour. However,
   * to control exactly which hours to display, the `hourValues` input can take a number, an
   * array of numbers, or a string of comma separated numbers.
   */
  hourValues?: number[] | number | string;
  /**
   * Values used to create the list of selectable minutes. By default
   * the minutes range from `0` to `59`. However, to control exactly which minutes to display,
   * the `minuteValues` input can take a number, an array of numbers, or a string of comma
   * separated numbers. For example, if the minute selections should only be every 15 minutes,
   * then this input value would be `minuteValues="0,15,30,45"`.
   */
  minuteValues?: number[] | number | string;
  /**
   * Full names for each month name. This can be used to provide
   * locale month names. Defaults to English.
   */
  monthNames?: string[] | string;
  /**
   * Short abbreviated names for each month name. This can be used to provide
   * locale month names. Defaults to English.
   */
  monthShortNames?: string[] | string;
  /**
   * Full day of the week names. This can be used to provide
   * locale names for each day in the week. Defaults to English.
   */
  dayNames?: string[] | string;
  /**
   * Short abbreviated day of the week names. This can be used to provide
   * locale names for each day in the week. Defaults to English.
   * Defaults to: `['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']`
   */
  dayShortNames?: string[] | string;
  /**
   * Any additional options that the picker interface can accept.
   * See the [Picker API docs](../picker) for the picker options.
   */
  pickerOptions?: DatetimeOptions;
  /**
   * The text to display when there's no date selected yet.
   * Using lowercase to match the input attribute
   */
  placeholder?: string | null;
  /**
   * The value of the datetime as a valid ISO 8601 datetime string.
   */
  value?: string | null;
  /**
   * Update the datetime value when the value changes
   */
  protected valueChanged(): void;
  /**
   * Emitted when the datetime selection was cancelled.
   */
  ionCancel: EventEmitter<void>;
  /**
   * Emitted when the value (selected date) has changed.
   */
  ionChange: EventEmitter<DatetimeChangeEventDetail>;
  /**
   * Emitted when the datetime has focus.
   */
  ionFocus: EventEmitter<void>;
  /**
   * Emitted when the datetime loses focus.
   */
  ionBlur: EventEmitter<void>;
  /**
   * Emitted when the styles change.
   * @internal
   */
  ionStyle: EventEmitter<StyleEventDetail>;
  componentWillLoad(): void;
  /**
   * Opens the datetime overlay.
   */
  open(): Promise<void>;
  private emitStyle;
  private updateDatetimeValue;
  private generatePickerOptions;
  private generateColumns;
  private validateColumns;
  private calcMinMax;
  private validateColumn;
  private get text();
  private hasValue;
  private setFocus;
  private onClick;
  private onFocus;
  private onBlur;
  render(): any;
}
