"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.replace = exports.move = exports.splice = exports.reduce = exports.map = exports.filter = exports.concurrentFilter = exports.conform = void 0;
function conform(t) {
    if (typeof t === 'undefined') {
        return [];
    }
    if (!Array.isArray(t)) {
        return [t];
    }
    return t;
}
exports.conform = conform;
async function concurrentFilter(array, callback) {
    const mapper = async (v) => [v, await callback(v)];
    const mapped = await Promise.all(array.map(mapper));
    return mapped
        .filter(([, f]) => f)
        .map(([v]) => v);
}
exports.concurrentFilter = concurrentFilter;
async function filter(array, callback) {
    const initial = [];
    return reduce(array, async (acc, v, i, arr) => {
        if (await callback(v, i, arr)) {
            acc.push(v);
        }
        return acc;
    }, initial);
}
exports.filter = filter;
async function map(array, callback) {
    const initial = [];
    return reduce(array, async (acc, v, i, arr) => {
        acc.push(await callback(v, i, arr));
        return acc;
    }, initial);
}
exports.map = map;
async function reduce(array, callback, initialValue) {
    const hadInitialValue = typeof initialValue === 'undefined';
    const startingIndex = hadInitialValue ? 1 : 0;
    if (typeof initialValue === 'undefined') {
        if (array.length === 0) {
            throw new TypeError('Reduce of empty array with no initial value');
        }
        initialValue = array[0];
    }
    let value = initialValue;
    for (let i = startingIndex; i < array.length; i++) {
        const v = await callback(value, array[i], i, array);
        value = v;
    }
    return value;
}
exports.reduce = reduce;
/**
 * Splice an array.
 *
 * This function will return a new array with the standard splice behavior
 * applied. Unlike the standard array splice, the array of removed items is not
 * returned.
 */
function splice(array, start, deleteCount = array.length - start, ...items) {
    const result = [...array];
    result.splice(start, deleteCount, ...items);
    return result;
}
exports.splice = splice;
/**
 * Move an item in an array by index.
 *
 * This function will return a new array with the item in the `fromIndex`
 * position moved to the `toIndex` position. If `fromIndex` or `toIndex` are
 * out of bounds, the array items remain unmoved.
 */
function move(array, fromIndex, toIndex) {
    const element = array[fromIndex];
    if (fromIndex < 0 || toIndex < 0 || fromIndex >= array.length || toIndex >= array.length) {
        return [...array];
    }
    return splice(splice(array, fromIndex, 1), toIndex, 0, element);
}
exports.move = move;
/**
 * Replace an item in an array by index.
 *
 * This function will return a new array with the item in the `index` position
 * replaced with `item`. If `index` is out of bounds, the item is not replaced.
 */
function replace(array, index, item) {
    if (index < 0 || index > array.length) {
        return [...array];
    }
    return splice(array, index, 1, item);
}
exports.replace = replace;
