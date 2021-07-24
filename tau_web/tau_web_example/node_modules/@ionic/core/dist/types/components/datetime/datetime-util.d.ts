/**
 * Gets a date value given a format
 * Defaults to the current date if
 * no date given
 */
export declare const getDateValue: (date: DatetimeData, format: string) => number | string;
export declare const renderDatetime: (template: string, value: DatetimeData | undefined, locale: LocaleData) => string | undefined;
export declare const renderTextFormat: (format: string, value: any, date: DatetimeData | undefined, locale: LocaleData) => string | undefined;
export declare const dateValueRange: (format: string, min: DatetimeData, max: DatetimeData) => any[];
export declare const dateSortValue: (year: number | undefined, month: number | undefined, day: number | undefined, hour?: number, minute?: number) => number;
export declare const dateDataSortValue: (data: DatetimeData) => number;
export declare const daysInMonth: (month: number, year: number) => number;
export declare const isLeapYear: (year: number) => boolean;
export declare const parseDate: (val: string | undefined | null) => DatetimeData | undefined;
/**
 * Converts a valid UTC datetime string to JS Date time object.
 * By default uses the users local timezone, but an optional
 * timezone can be provided.
 * Note: This is not meant for time strings
 * such as "01:47"
 */
export declare const getDateTime: (dateString?: any, timeZone?: any) => Date;
export declare const getTimezoneOffset: (localDate: Date, timeZone: string) => number;
export declare const updateDate: (existingData: DatetimeData, newData: any, displayTimezone?: string | undefined) => boolean;
export declare const parseTemplate: (template: string) => string[];
export declare const getValueFromFormat: (date: DatetimeData, format: string) => any;
export declare const convertFormatToKey: (format: string) => string | undefined;
export declare const convertDataToISO: (data: DatetimeData) => string;
/**
 * Use to convert a string of comma separated strings or
 * an array of strings, and clean up any user input
 */
export declare const convertToArrayOfStrings: (input: string | string[] | undefined | null, type: string) => string[] | undefined;
/**
 * Use to convert a string of comma separated numbers or
 * an array of numbers, and clean up any user input
 */
export declare const convertToArrayOfNumbers: (input: any[] | string | number, type: string) => number[];
export interface DatetimeData {
  year?: number;
  month?: number;
  day?: number;
  hour?: number;
  minute?: number;
  second?: number;
  millisecond?: number;
  tzOffset?: number;
  ampm?: string;
}
export interface LocaleData {
  monthNames?: string[];
  monthShortNames?: string[];
  dayNames?: string[];
  dayShortNames?: string[];
}
