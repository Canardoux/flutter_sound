import { ComponentInterface } from '../../stencil-public-runtime';
import { DomRenderFn, FooterHeightFn, HeaderFn, HeaderHeightFn, ItemHeightFn, ItemRenderFn } from '../../interface';
export declare class VirtualScroll implements ComponentInterface {
  private contentEl?;
  private scrollEl?;
  private range;
  private timerUpdate;
  private heightIndex?;
  private viewportHeight;
  private cells;
  private virtualDom;
  private isEnabled;
  private viewportOffset;
  private currentScrollTop;
  private indexDirty;
  private lastItemLen;
  private rmEvent;
  el: HTMLIonVirtualScrollElement;
  totalHeight: number;
  /**
   * It is important to provide this
   * if virtual item height will be significantly larger than the default
   * The approximate height of each virtual item template's cell.
   * This dimension is used to help determine how many cells should
   * be created when initialized, and to help calculate the height of
   * the scrollable area. This height value can only use `px` units.
   * Note that the actual rendered size of each cell comes from the
   * app's CSS, whereas this approximation is used to help calculate
   * initial dimensions before the item has been rendered.
   */
  approxItemHeight: number;
  /**
   * The approximate height of each header template's cell.
   * This dimension is used to help determine how many cells should
   * be created when initialized, and to help calculate the height of
   * the scrollable area. This height value can only use `px` units.
   * Note that the actual rendered size of each cell comes from the
   * app's CSS, whereas this approximation is used to help calculate
   * initial dimensions before the item has been rendered.
   */
  approxHeaderHeight: number;
  /**
   * The approximate width of each footer template's cell.
   * This dimension is used to help determine how many cells should
   * be created when initialized, and to help calculate the height of
   * the scrollable area. This height value can only use `px` units.
   * Note that the actual rendered size of each cell comes from the
   * app's CSS, whereas this approximation is used to help calculate
   * initial dimensions before the item has been rendered.
   */
  approxFooterHeight: number;
  /**
   * Section headers and the data used within its given
   * template can be dynamically created by passing a function to `headerFn`.
   * For example, a large list of contacts usually has dividers between each
   * letter in the alphabet. App's can provide their own custom `headerFn`
   * which is called with each record within the dataset. The logic within
   * the header function can decide if the header template should be used,
   * and what data to give to the header template. The function must return
   * `null` if a header cell shouldn't be created.
   */
  headerFn?: HeaderFn;
  /**
   * Section footers and the data used within its given
   * template can be dynamically created by passing a function to `footerFn`.
   * The logic within the footer function can decide if the footer template
   * should be used, and what data to give to the footer template. The function
   * must return `null` if a footer cell shouldn't be created.
   */
  footerFn?: HeaderFn;
  /**
   * The data that builds the templates within the virtual scroll.
   * It's important to note that when this data has changed, then the
   * entire virtual scroll is reset, which is an expensive operation and
   * should be avoided if possible.
   */
  items?: any[];
  /**
   * An optional function that maps each item within their height.
   * When this function is provides, heavy optimizations and fast path can be taked by
   * `ion-virtual-scroll` leading to massive performance improvements.
   *
   * This function allows to skip all DOM reads, which can be Doing so leads
   * to massive performance
   */
  itemHeight?: ItemHeightFn;
  /**
   * An optional function that maps each item header within their height.
   */
  headerHeight?: HeaderHeightFn;
  /**
   * An optional function that maps each item footer within their height.
   */
  footerHeight?: FooterHeightFn;
  /**
   * NOTE: only JSX API for stencil.
   *
   * Provide a render function for the items to be rendered. Returns a JSX virtual-dom.
   */
  renderItem?: (item: any, index: number) => any;
  /**
   * NOTE: only JSX API for stencil.
   *
   * Provide a render function for the header to be rendered. Returns a JSX virtual-dom.
   */
  renderHeader?: (item: any, index: number) => any;
  /**
   * NOTE: only JSX API for stencil.
   *
   * Provide a render function for the footer to be rendered. Returns a JSX virtual-dom.
   */
  renderFooter?: (item: any, index: number) => any;
  /**
   * NOTE: only Vanilla JS API.
   */
  nodeRender?: ItemRenderFn;
  /** @internal */
  domRender?: DomRenderFn;
  itemsChanged(): void;
  connectedCallback(): Promise<void>;
  componentDidUpdate(): void;
  disconnectedCallback(): void;
  onResize(): void;
  /**
   * Returns the position of the virtual item at the given index.
   */
  positionForItem(index: number): Promise<number>;
  /**
   * This method marks a subset of items as dirty, so they can be re-rendered. Items should be marked as
   * dirty any time the content or their style changes.
   *
   * The subset of items to be updated can are specifing by an offset and a length.
   */
  checkRange(offset: number, len?: number): Promise<void>;
  /**
   * This method marks the tail the items array as dirty, so they can be re-rendered.
   *
   * It's equivalent to calling:
   *
   * ```js
   * virtualScroll.checkRange(lastItemLen);
   * ```
   */
  checkEnd(): Promise<void>;
  private onScroll;
  private updateVirtualScroll;
  private readVS;
  private writeVS;
  private updateCellHeight;
  private setCellHeight;
  private scheduleUpdate;
  private updateState;
  private calcCells;
  private getHeightIndex;
  private calcHeightIndex;
  private enableScrollEvents;
  private renderVirtualNode;
  render(): any;
}
