import { Cell, HeaderFn, ItemHeightFn, ItemRenderFn, VirtualNode } from '../../interface';
import { FooterHeightFn, HeaderHeightFn } from './virtual-scroll-interface';
export interface Viewport {
  top: number;
  bottom: number;
}
export interface Range {
  offset: number;
  length: number;
}
export declare const updateVDom: (dom: VirtualNode[], heightIndex: Uint32Array, cells: Cell[], range: Range) => void;
export declare const doRender: (el: HTMLElement, nodeRender: ItemRenderFn, dom: VirtualNode[], updateCellHeight: (cell: Cell, node: HTMLElement) => void) => void;
export declare const getViewport: (scrollTop: number, vierportHeight: number, margin: number) => Viewport;
export declare const getRange: (heightIndex: Uint32Array, viewport: Viewport, buffer: number) => Range;
export declare const getShouldUpdate: (dirtyIndex: number, currentRange: Range, range: Range) => boolean;
export declare const findCellIndex: (cells: Cell[], index: number) => number;
export declare const inplaceUpdate: (dst: Cell[], src: Cell[], offset: number) => Cell[];
export declare const calcCells: (items: any[], itemHeight: ItemHeightFn | undefined, headerHeight: HeaderHeightFn | undefined, footerHeight: FooterHeightFn | undefined, headerFn: HeaderFn | undefined, footerFn: HeaderFn | undefined, approxHeaderHeight: number, approxFooterHeight: number, approxItemHeight: number, j: number, offset: number, len: number) => Cell[];
export declare const calcHeightIndex: (buf: Uint32Array, cells: Cell[], index: number) => number;
export declare const resizeBuffer: (buf: Uint32Array | undefined, len: number) => Uint32Array;
export declare const positionForIndex: (index: number, cells: Cell[], heightIndex: Uint32Array) => number;
