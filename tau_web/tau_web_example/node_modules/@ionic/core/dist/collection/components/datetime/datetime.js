import { Component, Element, Event, Host, Method, Prop, State, Watch, h } from '@stencil/core';
import { getIonMode } from '../../global/ionic-global';
import { addEventListener, clamp, findItemLabel, renderHiddenInput } from '../../utils/helpers';
import { pickerController } from '../../utils/overlays';
import { hostContext } from '../../utils/theme';
import { convertDataToISO, convertFormatToKey, convertToArrayOfNumbers, convertToArrayOfStrings, dateDataSortValue, dateSortValue, dateValueRange, daysInMonth, getDateValue, getTimezoneOffset, parseDate, parseTemplate, renderDatetime, renderTextFormat, updateDate } from './datetime-util';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 *
 * @part text - The value of the datetime.
 * @part placeholder - The placeholder of the datetime.
 */
export class Datetime {
  constructor() {
    this.inputId = `ion-dt-${datetimeIds++}`;
    this.locale = {};
    this.datetimeMin = {};
    this.datetimeMax = {};
    this.datetimeValue = {};
    this.isExpanded = false;
    /**
     * The name of the control, which is submitted with the form data.
     */
    this.name = this.inputId;
    /**
     * If `true`, the user cannot interact with the datetime.
     */
    this.disabled = false;
    /**
     * If `true`, the datetime appears normal but is not interactive.
     */
    this.readonly = false;
    /**
     * The display format of the date and time as text that shows
     * within the item. When the `pickerFormat` input is not used, then the
     * `displayFormat` is used for both display the formatted text, and determining
     * the datetime picker's columns. See the `pickerFormat` input description for
     * more info. Defaults to `MMM D, YYYY`.
     */
    this.displayFormat = 'MMM D, YYYY';
    /**
     * The text to display on the picker's cancel button.
     */
    this.cancelText = 'Cancel';
    /**
     * The text to display on the picker's "Done" button.
     */
    this.doneText = 'Done';
    this.onClick = () => {
      this.setFocus();
      this.open();
    };
    this.onFocus = () => {
      this.ionFocus.emit();
    };
    this.onBlur = () => {
      this.ionBlur.emit();
    };
  }
  disabledChanged() {
    this.emitStyle();
  }
  /**
   * Update the datetime value when the value changes
   */
  valueChanged() {
    this.updateDatetimeValue(this.value);
    this.emitStyle();
    this.ionChange.emit({
      value: this.value
    });
  }
  componentWillLoad() {
    // first see if locale names were provided in the inputs
    // then check to see if they're in the config
    // if neither were provided then it will use default English names
    this.locale = {
      // this.locale[type] = convertToArrayOfStrings((this[type] ? this[type] : this.config.get(type), type);
      monthNames: convertToArrayOfStrings(this.monthNames, 'monthNames'),
      monthShortNames: convertToArrayOfStrings(this.monthShortNames, 'monthShortNames'),
      dayNames: convertToArrayOfStrings(this.dayNames, 'dayNames'),
      dayShortNames: convertToArrayOfStrings(this.dayShortNames, 'dayShortNames')
    };
    this.updateDatetimeValue(this.value);
    this.emitStyle();
  }
  /**
   * Opens the datetime overlay.
   */
  async open() {
    if (this.disabled || this.isExpanded) {
      return;
    }
    const pickerOptions = this.generatePickerOptions();
    const picker = await pickerController.create(pickerOptions);
    this.isExpanded = true;
    picker.onDidDismiss().then(() => {
      this.isExpanded = false;
      this.setFocus();
    });
    addEventListener(picker, 'ionPickerColChange', async (event) => {
      const data = event.detail;
      const colSelectedIndex = data.selectedIndex;
      const colOptions = data.options;
      const changeData = {};
      changeData[data.name] = {
        value: colOptions[colSelectedIndex].value
      };
      if (data.name !== 'ampm' && this.datetimeValue.ampm !== undefined) {
        changeData['ampm'] = {
          value: this.datetimeValue.ampm
        };
      }
      this.updateDatetimeValue(changeData);
      picker.columns = this.generateColumns();
    });
    await picker.present();
  }
  emitStyle() {
    this.ionStyle.emit({
      'interactive': true,
      'datetime': true,
      'has-placeholder': this.placeholder != null,
      'has-value': this.hasValue(),
      'interactive-disabled': this.disabled,
    });
  }
  updateDatetimeValue(value) {
    updateDate(this.datetimeValue, value, this.displayTimezone);
  }
  generatePickerOptions() {
    const mode = getIonMode(this);
    this.locale = {
      monthNames: convertToArrayOfStrings(this.monthNames, 'monthNames'),
      monthShortNames: convertToArrayOfStrings(this.monthShortNames, 'monthShortNames'),
      dayNames: convertToArrayOfStrings(this.dayNames, 'dayNames'),
      dayShortNames: convertToArrayOfStrings(this.dayShortNames, 'dayShortNames')
    };
    const pickerOptions = Object.assign(Object.assign({ mode }, this.pickerOptions), { columns: this.generateColumns() });
    // If the user has not passed in picker buttons,
    // add a cancel and ok button to the picker
    const buttons = pickerOptions.buttons;
    if (!buttons || buttons.length === 0) {
      pickerOptions.buttons = [
        {
          text: this.cancelText,
          role: 'cancel',
          handler: () => {
            this.updateDatetimeValue(this.value);
            this.ionCancel.emit();
          }
        },
        {
          text: this.doneText,
          handler: (data) => {
            this.updateDatetimeValue(data);
            /**
             * Prevent convertDataToISO from doing any
             * kind of transformation based on timezone
             * This cancels out any change it attempts to make
             *
             * Important: Take the timezone offset based on
             * the date that is currently selected, otherwise
             * there can be 1 hr difference when dealing w/ DST
             */
            const date = new Date(convertDataToISO(this.datetimeValue));
            // If a custom display timezone is provided, use that tzOffset value instead
            this.datetimeValue.tzOffset = (this.displayTimezone !== undefined && this.displayTimezone.length > 0)
              ? ((getTimezoneOffset(date, this.displayTimezone)) / 1000 / 60) * -1
              : date.getTimezoneOffset() * -1;
            this.value = convertDataToISO(this.datetimeValue);
          }
        }
      ];
    }
    return pickerOptions;
  }
  generateColumns() {
    // if a picker format wasn't provided, then fallback
    // to use the display format
    let template = this.pickerFormat || this.displayFormat || DEFAULT_FORMAT;
    if (template.length === 0) {
      return [];
    }
    // make sure we've got up to date sizing information
    this.calcMinMax();
    // does not support selecting by day name
    // automatically remove any day name formats
    template = template.replace('DDDD', '{~}').replace('DDD', '{~}');
    if (template.indexOf('D') === -1) {
      // there is not a day in the template
      // replace the day name with a numeric one if it exists
      template = template.replace('{~}', 'D');
    }
    // make sure no day name replacer is left in the string
    template = template.replace(/{~}/g, '');
    // parse apart the given template into an array of "formats"
    const columns = parseTemplate(template).map((format) => {
      // loop through each format in the template
      // create a new picker column to build up with data
      const key = convertFormatToKey(format);
      let values;
      // check if they have exact values to use for this date part
      // otherwise use the default date part values
      const self = this;
      values = self[key + 'Values']
        ? convertToArrayOfNumbers(self[key + 'Values'], key)
        : dateValueRange(format, this.datetimeMin, this.datetimeMax);
      const colOptions = values.map(val => {
        return {
          value: val,
          text: renderTextFormat(format, val, undefined, this.locale),
        };
      });
      // cool, we've loaded up the columns with options
      // preselect the option for this column
      const optValue = getDateValue(this.datetimeValue, format);
      const selectedIndex = colOptions.findIndex(opt => opt.value === optValue);
      return {
        name: key,
        selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
        options: colOptions
      };
    });
    // Normalize min/max
    const min = this.datetimeMin;
    const max = this.datetimeMax;
    ['month', 'day', 'hour', 'minute']
      .filter(name => !columns.find(column => column.name === name))
      .forEach(name => {
      min[name] = 0;
      max[name] = 0;
    });
    return this.validateColumns(divyColumns(columns));
  }
  validateColumns(columns) {
    const today = new Date();
    const minCompareVal = dateDataSortValue(this.datetimeMin);
    const maxCompareVal = dateDataSortValue(this.datetimeMax);
    const yearCol = columns.find(c => c.name === 'year');
    let selectedYear = today.getFullYear();
    if (yearCol) {
      // default to the first value if the current year doesn't exist in the options
      if (!yearCol.options.find(col => col.value === today.getFullYear())) {
        selectedYear = yearCol.options[0].value;
      }
      const selectedIndex = yearCol.selectedIndex;
      if (selectedIndex !== undefined) {
        const yearOpt = yearCol.options[selectedIndex];
        if (yearOpt) {
          // they have a selected year value
          selectedYear = yearOpt.value;
        }
      }
    }
    const selectedMonth = this.validateColumn(columns, 'month', 1, minCompareVal, maxCompareVal, [selectedYear, 0, 0, 0, 0], [selectedYear, 12, 31, 23, 59]);
    const numDaysInMonth = daysInMonth(selectedMonth, selectedYear);
    const selectedDay = this.validateColumn(columns, 'day', 2, minCompareVal, maxCompareVal, [selectedYear, selectedMonth, 0, 0, 0], [selectedYear, selectedMonth, numDaysInMonth, 23, 59]);
    const selectedHour = this.validateColumn(columns, 'hour', 3, minCompareVal, maxCompareVal, [selectedYear, selectedMonth, selectedDay, 0, 0], [selectedYear, selectedMonth, selectedDay, 23, 59]);
    this.validateColumn(columns, 'minute', 4, minCompareVal, maxCompareVal, [selectedYear, selectedMonth, selectedDay, selectedHour, 0], [selectedYear, selectedMonth, selectedDay, selectedHour, 59]);
    return columns;
  }
  calcMinMax() {
    const todaysYear = new Date().getFullYear();
    if (this.yearValues !== undefined) {
      const years = convertToArrayOfNumbers(this.yearValues, 'year');
      if (this.min === undefined) {
        this.min = Math.min(...years).toString();
      }
      if (this.max === undefined) {
        this.max = Math.max(...years).toString();
      }
    }
    else {
      if (this.min === undefined) {
        this.min = (todaysYear - 100).toString();
      }
      if (this.max === undefined) {
        this.max = todaysYear.toString();
      }
    }
    const min = this.datetimeMin = parseDate(this.min);
    const max = this.datetimeMax = parseDate(this.max);
    min.year = min.year || todaysYear;
    max.year = max.year || todaysYear;
    min.month = min.month || 1;
    max.month = max.month || 12;
    min.day = min.day || 1;
    max.day = max.day || 31;
    min.hour = min.hour || 0;
    max.hour = max.hour === undefined ? 23 : max.hour;
    min.minute = min.minute || 0;
    max.minute = max.minute === undefined ? 59 : max.minute;
    min.second = min.second || 0;
    max.second = max.second === undefined ? 59 : max.second;
    // Ensure min/max constraints
    if (min.year > max.year) {
      console.error('min.year > max.year');
      min.year = max.year - 100;
    }
    if (min.year === max.year) {
      if (min.month > max.month) {
        console.error('min.month > max.month');
        min.month = 1;
      }
      else if (min.month === max.month && min.day > max.day) {
        console.error('min.day > max.day');
        min.day = 1;
      }
    }
  }
  validateColumn(columns, name, index, min, max, lowerBounds, upperBounds) {
    const column = columns.find(c => c.name === name);
    if (!column) {
      return 0;
    }
    const lb = lowerBounds.slice();
    const ub = upperBounds.slice();
    const options = column.options;
    let indexMin = options.length - 1;
    let indexMax = 0;
    for (let i = 0; i < options.length; i++) {
      const opts = options[i];
      const value = opts.value;
      lb[index] = opts.value;
      ub[index] = opts.value;
      const disabled = opts.disabled = (value < lowerBounds[index] ||
        value > upperBounds[index] ||
        dateSortValue(ub[0], ub[1], ub[2], ub[3], ub[4]) < min ||
        dateSortValue(lb[0], lb[1], lb[2], lb[3], lb[4]) > max);
      if (!disabled) {
        indexMin = Math.min(indexMin, i);
        indexMax = Math.max(indexMax, i);
      }
    }
    const selectedIndex = column.selectedIndex = clamp(indexMin, column.selectedIndex, indexMax);
    const opt = column.options[selectedIndex];
    if (opt) {
      return opt.value;
    }
    return 0;
  }
  get text() {
    // create the text of the formatted data
    const template = this.displayFormat || this.pickerFormat || DEFAULT_FORMAT;
    if (this.value === undefined ||
      this.value === null ||
      this.value.length === 0) {
      return;
    }
    return renderDatetime(template, this.datetimeValue, this.locale);
  }
  hasValue() {
    return this.text !== undefined;
  }
  setFocus() {
    if (this.buttonEl) {
      this.buttonEl.focus();
    }
  }
  render() {
    const { inputId, text, disabled, readonly, isExpanded, el, placeholder } = this;
    const mode = getIonMode(this);
    const labelId = inputId + '-lbl';
    const label = findItemLabel(el);
    const addPlaceholderClass = (text === undefined && placeholder != null) ? true : false;
    // If selected text has been passed in, use that first
    // otherwise use the placeholder
    const datetimeText = text === undefined
      ? (placeholder != null ? placeholder : '')
      : text;
    const datetimeTextPart = text === undefined
      ? (placeholder != null ? 'placeholder' : undefined)
      : 'text';
    if (label) {
      label.id = labelId;
    }
    renderHiddenInput(true, el, this.name, this.value, this.disabled);
    return (h(Host, { onClick: this.onClick, "aria-disabled": disabled ? 'true' : null, "aria-expanded": `${isExpanded}`, "aria-haspopup": "true", "aria-labelledby": label ? labelId : null, class: {
        [mode]: true,
        'datetime-disabled': disabled,
        'datetime-readonly': readonly,
        'datetime-placeholder': addPlaceholderClass,
        'in-item': hostContext('ion-item', el)
      } },
      h("div", { class: "datetime-text", part: datetimeTextPart }, datetimeText),
      h("button", { type: "button", onFocus: this.onFocus, onBlur: this.onBlur, disabled: this.disabled, ref: btnEl => this.buttonEl = btnEl })));
  }
  static get is() { return "ion-datetime"; }
  static get encapsulation() { return "shadow"; }
  static get originalStyleUrls() { return {
    "ios": ["datetime.ios.scss"],
    "md": ["datetime.md.scss"]
  }; }
  static get styleUrls() { return {
    "ios": ["datetime.ios.css"],
    "md": ["datetime.md.css"]
  }; }
  static get properties() { return {
    "name": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string",
        "resolved": "string",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "The name of the control, which is submitted with the form data."
      },
      "attribute": "name",
      "reflect": false,
      "defaultValue": "this.inputId"
    },
    "disabled": {
      "type": "boolean",
      "mutable": false,
      "complexType": {
        "original": "boolean",
        "resolved": "boolean",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "If `true`, the user cannot interact with the datetime."
      },
      "attribute": "disabled",
      "reflect": false,
      "defaultValue": "false"
    },
    "readonly": {
      "type": "boolean",
      "mutable": false,
      "complexType": {
        "original": "boolean",
        "resolved": "boolean",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "If `true`, the datetime appears normal but is not interactive."
      },
      "attribute": "readonly",
      "reflect": false,
      "defaultValue": "false"
    },
    "min": {
      "type": "string",
      "mutable": true,
      "complexType": {
        "original": "string",
        "resolved": "string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The minimum datetime allowed. Value must be a date string\nfollowing the\n[ISO 8601 datetime format standard](https://www.w3.org/TR/NOTE-datetime),\nsuch as `1996-12-19`. The format does not have to be specific to an exact\ndatetime. For example, the minimum could just be the year, such as `1994`.\nDefaults to the beginning of the year, 100 years ago from today."
      },
      "attribute": "min",
      "reflect": false
    },
    "max": {
      "type": "string",
      "mutable": true,
      "complexType": {
        "original": "string",
        "resolved": "string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The maximum datetime allowed. Value must be a date string\nfollowing the\n[ISO 8601 datetime format standard](https://www.w3.org/TR/NOTE-datetime),\n`1996-12-19`. The format does not have to be specific to an exact\ndatetime. For example, the maximum could just be the year, such as `1994`.\nDefaults to the end of this year."
      },
      "attribute": "max",
      "reflect": false
    },
    "displayFormat": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string",
        "resolved": "string",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "The display format of the date and time as text that shows\nwithin the item. When the `pickerFormat` input is not used, then the\n`displayFormat` is used for both display the formatted text, and determining\nthe datetime picker's columns. See the `pickerFormat` input description for\nmore info. Defaults to `MMM D, YYYY`."
      },
      "attribute": "display-format",
      "reflect": false,
      "defaultValue": "'MMM D, YYYY'"
    },
    "displayTimezone": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string",
        "resolved": "string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The timezone to use for display purposes only. See\n[Date.prototype.toLocaleString()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/toLocaleString)\nfor a list of supported timezones. If no value is provided, the\ncomponent will default to displaying times in the user's local timezone."
      },
      "attribute": "display-timezone",
      "reflect": false
    },
    "pickerFormat": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string",
        "resolved": "string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The format of the date and time picker columns the user selects.\nA datetime input can have one or many datetime parts, each getting their\nown column which allow individual selection of that particular datetime part. For\nexample, year and month columns are two individually selectable columns which help\nchoose an exact date from the datetime picker. Each column follows the string\nparse format. Defaults to use `displayFormat`."
      },
      "attribute": "picker-format",
      "reflect": false
    },
    "cancelText": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string",
        "resolved": "string",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "The text to display on the picker's cancel button."
      },
      "attribute": "cancel-text",
      "reflect": false,
      "defaultValue": "'Cancel'"
    },
    "doneText": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string",
        "resolved": "string",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "The text to display on the picker's \"Done\" button."
      },
      "attribute": "done-text",
      "reflect": false,
      "defaultValue": "'Done'"
    },
    "yearValues": {
      "type": "any",
      "mutable": false,
      "complexType": {
        "original": "number[] | number | string",
        "resolved": "number | number[] | string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Values used to create the list of selectable years. By default\nthe year values range between the `min` and `max` datetime inputs. However, to\ncontrol exactly which years to display, the `yearValues` input can take a number, an array\nof numbers, or string of comma separated numbers. For example, to show upcoming and\nrecent leap years, then this input's value would be `yearValues=\"2024,2020,2016,2012,2008\"`."
      },
      "attribute": "year-values",
      "reflect": false
    },
    "monthValues": {
      "type": "any",
      "mutable": false,
      "complexType": {
        "original": "number[] | number | string",
        "resolved": "number | number[] | string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Values used to create the list of selectable months. By default\nthe month values range from `1` to `12`. However, to control exactly which months to\ndisplay, the `monthValues` input can take a number, an array of numbers, or a string of\ncomma separated numbers. For example, if only summer months should be shown, then this\ninput value would be `monthValues=\"6,7,8\"`. Note that month numbers do *not* have a\nzero-based index, meaning January's value is `1`, and December's is `12`."
      },
      "attribute": "month-values",
      "reflect": false
    },
    "dayValues": {
      "type": "any",
      "mutable": false,
      "complexType": {
        "original": "number[] | number | string",
        "resolved": "number | number[] | string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Values used to create the list of selectable days. By default\nevery day is shown for the given month. However, to control exactly which days of\nthe month to display, the `dayValues` input can take a number, an array of numbers, or\na string of comma separated numbers. Note that even if the array days have an invalid\nnumber for the selected month, like `31` in February, it will correctly not show\ndays which are not valid for the selected month."
      },
      "attribute": "day-values",
      "reflect": false
    },
    "hourValues": {
      "type": "any",
      "mutable": false,
      "complexType": {
        "original": "number[] | number | string",
        "resolved": "number | number[] | string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Values used to create the list of selectable hours. By default\nthe hour values range from `0` to `23` for 24-hour, or `1` to `12` for 12-hour. However,\nto control exactly which hours to display, the `hourValues` input can take a number, an\narray of numbers, or a string of comma separated numbers."
      },
      "attribute": "hour-values",
      "reflect": false
    },
    "minuteValues": {
      "type": "any",
      "mutable": false,
      "complexType": {
        "original": "number[] | number | string",
        "resolved": "number | number[] | string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Values used to create the list of selectable minutes. By default\nthe minutes range from `0` to `59`. However, to control exactly which minutes to display,\nthe `minuteValues` input can take a number, an array of numbers, or a string of comma\nseparated numbers. For example, if the minute selections should only be every 15 minutes,\nthen this input value would be `minuteValues=\"0,15,30,45\"`."
      },
      "attribute": "minute-values",
      "reflect": false
    },
    "monthNames": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string[] | string",
        "resolved": "string | string[] | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Full names for each month name. This can be used to provide\nlocale month names. Defaults to English."
      },
      "attribute": "month-names",
      "reflect": false
    },
    "monthShortNames": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string[] | string",
        "resolved": "string | string[] | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Short abbreviated names for each month name. This can be used to provide\nlocale month names. Defaults to English."
      },
      "attribute": "month-short-names",
      "reflect": false
    },
    "dayNames": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string[] | string",
        "resolved": "string | string[] | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Full day of the week names. This can be used to provide\nlocale names for each day in the week. Defaults to English."
      },
      "attribute": "day-names",
      "reflect": false
    },
    "dayShortNames": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string[] | string",
        "resolved": "string | string[] | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Short abbreviated day of the week names. This can be used to provide\nlocale names for each day in the week. Defaults to English.\nDefaults to: `['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']`"
      },
      "attribute": "day-short-names",
      "reflect": false
    },
    "pickerOptions": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "DatetimeOptions",
        "resolved": "undefined | { columns?: PickerColumn[] | undefined; buttons?: PickerButton[] | undefined; cssClass?: string | string[] | undefined; showBackdrop?: boolean | undefined; backdropDismiss?: boolean | undefined; animated?: boolean | undefined; mode?: Mode | undefined; keyboardClose?: boolean | undefined; id?: string | undefined; enterAnimation?: AnimationBuilder | undefined; leaveAnimation?: AnimationBuilder | undefined; }",
        "references": {
          "DatetimeOptions": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Any additional options that the picker interface can accept.\nSee the [Picker API docs](../picker) for the picker options."
      }
    },
    "placeholder": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string | null",
        "resolved": "null | string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The text to display when there's no date selected yet.\nUsing lowercase to match the input attribute"
      },
      "attribute": "placeholder",
      "reflect": false
    },
    "value": {
      "type": "string",
      "mutable": true,
      "complexType": {
        "original": "string | null",
        "resolved": "null | string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The value of the datetime as a valid ISO 8601 datetime string."
      },
      "attribute": "value",
      "reflect": false
    }
  }; }
  static get states() { return {
    "isExpanded": {}
  }; }
  static get events() { return [{
      "method": "ionCancel",
      "name": "ionCancel",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the datetime selection was cancelled."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionChange",
      "name": "ionChange",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the value (selected date) has changed."
      },
      "complexType": {
        "original": "DatetimeChangeEventDetail",
        "resolved": "DatetimeChangeEventDetail",
        "references": {
          "DatetimeChangeEventDetail": {
            "location": "import",
            "path": "../../interface"
          }
        }
      }
    }, {
      "method": "ionFocus",
      "name": "ionFocus",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the datetime has focus."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionBlur",
      "name": "ionBlur",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the datetime loses focus."
      },
      "complexType": {
        "original": "void",
        "resolved": "void",
        "references": {}
      }
    }, {
      "method": "ionStyle",
      "name": "ionStyle",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [{
            "text": undefined,
            "name": "internal"
          }],
        "text": "Emitted when the styles change."
      },
      "complexType": {
        "original": "StyleEventDetail",
        "resolved": "StyleEventDetail",
        "references": {
          "StyleEventDetail": {
            "location": "import",
            "path": "../../interface"
          }
        }
      }
    }]; }
  static get methods() { return {
    "open": {
      "complexType": {
        "signature": "() => Promise<void>",
        "parameters": [],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<void>"
      },
      "docs": {
        "text": "Opens the datetime overlay.",
        "tags": []
      }
    }
  }; }
  static get elementRef() { return "el"; }
  static get watchers() { return [{
      "propName": "disabled",
      "methodName": "disabledChanged"
    }, {
      "propName": "value",
      "methodName": "valueChanged"
    }]; }
}
const divyColumns = (columns) => {
  const columnsWidth = [];
  let col;
  let width;
  for (let i = 0; i < columns.length; i++) {
    col = columns[i];
    columnsWidth.push(0);
    for (const option of col.options) {
      width = option.text.length;
      if (width > columnsWidth[i]) {
        columnsWidth[i] = width;
      }
    }
  }
  if (columnsWidth.length === 2) {
    width = Math.max(columnsWidth[0], columnsWidth[1]);
    columns[0].align = 'right';
    columns[1].align = 'left';
    columns[0].optionsWidth = columns[1].optionsWidth = `${width * 17}px`;
  }
  else if (columnsWidth.length === 3) {
    width = Math.max(columnsWidth[0], columnsWidth[2]);
    columns[0].align = 'right';
    columns[1].columnWidth = `${columnsWidth[1] * 17}px`;
    columns[0].optionsWidth = columns[2].optionsWidth = `${width * 17}px`;
    columns[2].align = 'left';
  }
  return columns;
};
const DEFAULT_FORMAT = 'MMM D, YYYY';
let datetimeIds = 0;
