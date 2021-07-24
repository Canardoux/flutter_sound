export interface Cell {
  i: number;
  index: number;
  value: any;
  type: CellType;
  height: number;
  reads: number;
  visible: boolean;
}
export interface VirtualNode {
  cell: Cell;
  top: number;
  change: NodeChange;
  d: boolean;
  visible: boolean;
}
export declare type CellType = 'item' | 'header' | 'footer';
export declare type NodeChange = number;
export declare type HeaderFn = (item: any, index: number, items: any[]) => string | null | undefined;
export declare type ItemHeightFn = (item: any, index: number) => number;
export declare type HeaderHeightFn = (item: any, index: number) => number;
export declare type FooterHeightFn = (item: any, index: number) => number;
export declare type ItemRenderFn = (el: HTMLElement | null, cell: Cell, domIndex: number) => HTMLElement;
export declare type DomRenderFn = (dom: VirtualNode[]) => void;
