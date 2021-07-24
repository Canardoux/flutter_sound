export declare function conform<T>(t?: T | T[]): T[];
export declare function concurrentFilter<T>(array: T[], callback: (currentValue: T) => Promise<boolean>): Promise<T[]>;
export declare function filter<T>(array: T[], callback: (currentValue: T, currentIndex: number, array: readonly T[]) => Promise<boolean>): Promise<T[]>;
export declare function filter<T>(array: readonly T[], callback: (currentValue: T, currentIndex: number, array: readonly T[]) => Promise<boolean>): Promise<readonly T[]>;
export declare function map<T, U>(array: T[], callback: (currentValue: T, currentIndex: number, array: readonly T[]) => Promise<U>): Promise<U[]>;
export declare function map<T, U>(array: T[], callback: (currentValue: T, currentIndex: number, array: readonly T[]) => Promise<U>): Promise<readonly U[]>;
export declare function map<T, U>(array: readonly T[], callback: (currentValue: T, currentIndex: number, array: readonly T[]) => Promise<U>): Promise<U[]>;
export declare function map<T, U>(array: readonly T[], callback: (currentValue: T, currentIndex: number, array: readonly T[]) => Promise<U>): Promise<readonly U[]>;
export declare function reduce<T>(array: T[], callback: (accumulator: T, currentValue: T, currentIndex: number, array: readonly T[]) => Promise<T>): Promise<T>;
export declare function reduce<T>(array: T[], callback: (accumulator: T, currentValue: T, currentIndex: number, array: readonly T[]) => Promise<T>, initialValue: T): Promise<T>;
export declare function reduce<T, R>(array: T[], callback: (accumulator: R, currentValue: T, currentIndex: number, array: readonly T[]) => Promise<R>): Promise<R>;
export declare function reduce<T, U>(array: T[], callback: (accumulator: U, currentValue: T, currentIndex: number, array: readonly T[]) => Promise<U>, initialValue: U): Promise<U>;
export declare function reduce<T>(array: readonly T[], callback: (accumulator: T, currentValue: T, currentIndex: number, array: readonly T[]) => Promise<T>): Promise<T>;
export declare function reduce<T>(array: readonly T[], callback: (accumulator: T, currentValue: T, currentIndex: number, array: readonly T[]) => Promise<T>, initialValue: T): Promise<T>;
export declare function reduce<T, R>(array: readonly T[], callback: (accumulator: R, currentValue: T, currentIndex: number, array: readonly T[]) => Promise<R>): Promise<R>;
export declare function reduce<T, U>(array: readonly T[], callback: (accumulator: U, currentValue: T, currentIndex: number, array: readonly T[]) => Promise<U>, initialValue: U): Promise<U>;
/**
 * Splice an array.
 *
 * This function will return a new array with the standard splice behavior
 * applied. Unlike the standard array splice, the array of removed items is not
 * returned.
 */
export declare function splice<T>(array: readonly T[], start: number, deleteCount?: number, ...items: T[]): T[];
/**
 * Move an item in an array by index.
 *
 * This function will return a new array with the item in the `fromIndex`
 * position moved to the `toIndex` position. If `fromIndex` or `toIndex` are
 * out of bounds, the array items remain unmoved.
 */
export declare function move<T>(array: readonly T[], fromIndex: number, toIndex: number): T[];
/**
 * Replace an item in an array by index.
 *
 * This function will return a new array with the item in the `index` position
 * replaced with `item`. If `index` is out of bounds, the item is not replaced.
 */
export declare function replace<T>(array: readonly T[], index: number, item: T): T[];
