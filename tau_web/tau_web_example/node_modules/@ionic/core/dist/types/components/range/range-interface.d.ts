export declare type KnobName = 'A' | 'B' | undefined;
export declare type RangeValue = number | {
  lower: number;
  upper: number;
};
export interface RangeChangeEventDetail {
  value: RangeValue;
}
