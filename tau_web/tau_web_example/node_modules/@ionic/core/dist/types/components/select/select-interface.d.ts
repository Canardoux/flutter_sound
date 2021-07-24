export declare type SelectInterface = 'action-sheet' | 'popover' | 'alert';
export declare type SelectCompareFn = (currentValue: any, compareValue: any) => boolean;
export interface SelectChangeEventDetail<T = any> {
  value: T;
}
