import { Component, Element, Host, Listen, Method, Prop, State, Watch, forceUpdate, h, readTask, writeTask } from '@stencil/core';
import { componentOnReady } from '../../utils/helpers';
import { CELL_TYPE_FOOTER, CELL_TYPE_HEADER, CELL_TYPE_ITEM } from './constants';
import { calcCells, calcHeightIndex, doRender, findCellIndex, getRange, getShouldUpdate, getViewport, inplaceUpdate, positionForIndex, resizeBuffer, updateVDom } from './virtual-scroll-utils';
export class VirtualScroll {
  constructor() {
    this.range = { offset: 0, length: 0 };
    this.viewportHeight = 0;
    this.cells = [];
    this.virtualDom = [];
    this.isEnabled = false;
    this.viewportOffset = 0;
    this.currentScrollTop = 0;
    this.indexDirty = 0;
    this.lastItemLen = 0;
    this.totalHeight = 0;
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
    this.approxItemHeight = 45;
    /**
     * The approximate height of each header template's cell.
     * This dimension is used to help determine how many cells should
     * be created when initialized, and to help calculate the height of
     * the scrollable area. This height value can only use `px` units.
     * Note that the actual rendered size of each cell comes from the
     * app's CSS, whereas this approximation is used to help calculate
     * initial dimensions before the item has been rendered.
     */
    this.approxHeaderHeight = 30;
    /**
     * The approximate width of each footer template's cell.
     * This dimension is used to help determine how many cells should
     * be created when initialized, and to help calculate the height of
     * the scrollable area. This height value can only use `px` units.
     * Note that the actual rendered size of each cell comes from the
     * app's CSS, whereas this approximation is used to help calculate
     * initial dimensions before the item has been rendered.
     */
    this.approxFooterHeight = 30;
    this.onScroll = () => {
      this.updateVirtualScroll();
    };
  }
  itemsChanged() {
    this.calcCells();
    this.updateVirtualScroll();
  }
  async connectedCallback() {
    const contentEl = this.el.closest('ion-content');
    if (!contentEl) {
      console.error('<ion-virtual-scroll> must be used inside an <ion-content>');
      return;
    }
    this.scrollEl = await contentEl.getScrollElement();
    this.contentEl = contentEl;
    this.calcCells();
    this.updateState();
  }
  componentDidUpdate() {
    this.updateState();
  }
  disconnectedCallback() {
    this.scrollEl = undefined;
  }
  onResize() {
    this.calcCells();
    this.updateVirtualScroll();
  }
  /**
   * Returns the position of the virtual item at the given index.
   */
  positionForItem(index) {
    return Promise.resolve(positionForIndex(index, this.cells, this.getHeightIndex()));
  }
  /**
   * This method marks a subset of items as dirty, so they can be re-rendered. Items should be marked as
   * dirty any time the content or their style changes.
   *
   * The subset of items to be updated can are specifing by an offset and a length.
   */
  async checkRange(offset, len = -1) {
    // TODO: kind of hacky how we do in-place updated of the cells
    // array. this part needs a complete refactor
    if (!this.items) {
      return;
    }
    const length = (len === -1)
      ? this.items.length - offset
      : len;
    const cellIndex = findCellIndex(this.cells, offset);
    const cells = calcCells(this.items, this.itemHeight, this.headerHeight, this.footerHeight, this.headerFn, this.footerFn, this.approxHeaderHeight, this.approxFooterHeight, this.approxItemHeight, cellIndex, offset, length);
    this.cells = inplaceUpdate(this.cells, cells, cellIndex);
    this.lastItemLen = this.items.length;
    this.indexDirty = Math.max(offset - 1, 0);
    this.scheduleUpdate();
  }
  /**
   * This method marks the tail the items array as dirty, so they can be re-rendered.
   *
   * It's equivalent to calling:
   *
   * ```js
   * virtualScroll.checkRange(lastItemLen);
   * ```
   */
  async checkEnd() {
    if (this.items) {
      this.checkRange(this.lastItemLen);
    }
  }
  updateVirtualScroll() {
    // do nothing if virtual-scroll is disabled
    if (!this.isEnabled || !this.scrollEl) {
      return;
    }
    // unschedule future updates
    if (this.timerUpdate) {
      clearTimeout(this.timerUpdate);
      this.timerUpdate = undefined;
    }
    // schedule DOM operations into the stencil queue
    readTask(this.readVS.bind(this));
    writeTask(this.writeVS.bind(this));
  }
  readVS() {
    const { contentEl, scrollEl, el } = this;
    let topOffset = 0;
    let node = el;
    while (node && node !== contentEl) {
      topOffset += node.offsetTop;
      node = node.offsetParent;
    }
    this.viewportOffset = topOffset;
    if (scrollEl) {
      this.viewportHeight = scrollEl.offsetHeight;
      this.currentScrollTop = scrollEl.scrollTop;
    }
  }
  writeVS() {
    const dirtyIndex = this.indexDirty;
    // get visible viewport
    const scrollTop = this.currentScrollTop - this.viewportOffset;
    const viewport = getViewport(scrollTop, this.viewportHeight, 100);
    // compute lazily the height index
    const heightIndex = this.getHeightIndex();
    // get array bounds of visible cells base in the viewport
    const range = getRange(heightIndex, viewport, 2);
    // fast path, do nothing
    const shouldUpdate = getShouldUpdate(dirtyIndex, this.range, range);
    if (!shouldUpdate) {
      return;
    }
    this.range = range;
    // in place mutation of the virtual DOM
    updateVDom(this.virtualDom, heightIndex, this.cells, range);
    // Write DOM
    // Different code paths taken depending of the render API used
    if (this.nodeRender) {
      doRender(this.el, this.nodeRender, this.virtualDom, this.updateCellHeight.bind(this));
    }
    else if (this.domRender) {
      this.domRender(this.virtualDom);
    }
    else if (this.renderItem) {
      forceUpdate(this);
    }
  }
  updateCellHeight(cell, node) {
    const update = () => {
      if (node['$ionCell'] === cell) {
        const style = window.getComputedStyle(node);
        const height = node.offsetHeight + parseFloat(style.getPropertyValue('margin-bottom'));
        this.setCellHeight(cell, height);
      }
    };
    if (node) {
      componentOnReady(node, update);
    }
    else {
      update();
    }
  }
  setCellHeight(cell, height) {
    const index = cell.i;
    // the cell might changed since the height update was scheduled
    if (cell !== this.cells[index]) {
      return;
    }
    if (cell.height !== height || cell.visible !== true) {
      cell.visible = true;
      cell.height = height;
      this.indexDirty = Math.min(this.indexDirty, index);
      this.scheduleUpdate();
    }
  }
  scheduleUpdate() {
    clearTimeout(this.timerUpdate);
    this.timerUpdate = setTimeout(() => this.updateVirtualScroll(), 100);
  }
  updateState() {
    const shouldEnable = !!(this.scrollEl &&
      this.cells);
    if (shouldEnable !== this.isEnabled) {
      this.enableScrollEvents(shouldEnable);
      if (shouldEnable) {
        this.updateVirtualScroll();
      }
    }
  }
  calcCells() {
    if (!this.items) {
      return;
    }
    this.lastItemLen = this.items.length;
    this.cells = calcCells(this.items, this.itemHeight, this.headerHeight, this.footerHeight, this.headerFn, this.footerFn, this.approxHeaderHeight, this.approxFooterHeight, this.approxItemHeight, 0, 0, this.lastItemLen);
    this.indexDirty = 0;
  }
  getHeightIndex() {
    if (this.indexDirty !== Infinity) {
      this.calcHeightIndex(this.indexDirty);
    }
    return this.heightIndex;
  }
  calcHeightIndex(index = 0) {
    // TODO: optimize, we don't need to calculate all the cells
    this.heightIndex = resizeBuffer(this.heightIndex, this.cells.length);
    this.totalHeight = calcHeightIndex(this.heightIndex, this.cells, index);
    this.indexDirty = Infinity;
  }
  enableScrollEvents(shouldListen) {
    if (this.rmEvent) {
      this.rmEvent();
      this.rmEvent = undefined;
    }
    const scrollEl = this.scrollEl;
    if (scrollEl) {
      this.isEnabled = shouldListen;
      scrollEl.addEventListener('scroll', this.onScroll);
      this.rmEvent = () => {
        scrollEl.removeEventListener('scroll', this.onScroll);
      };
    }
  }
  renderVirtualNode(node) {
    const { type, value, index } = node.cell;
    switch (type) {
      case CELL_TYPE_ITEM: return this.renderItem(value, index);
      case CELL_TYPE_HEADER: return this.renderHeader(value, index);
      case CELL_TYPE_FOOTER: return this.renderFooter(value, index);
    }
  }
  render() {
    return (h(Host, { style: {
        height: `${this.totalHeight}px`
      } }, this.renderItem && (h(VirtualProxy, { dom: this.virtualDom }, this.virtualDom.map(node => this.renderVirtualNode(node))))));
  }
  static get is() { return "ion-virtual-scroll"; }
  static get originalStyleUrls() { return {
    "$": ["virtual-scroll.scss"]
  }; }
  static get styleUrls() { return {
    "$": ["virtual-scroll.css"]
  }; }
  static get properties() { return {
    "approxItemHeight": {
      "type": "number",
      "mutable": false,
      "complexType": {
        "original": "number",
        "resolved": "number",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "It is important to provide this\nif virtual item height will be significantly larger than the default\nThe approximate height of each virtual item template's cell.\nThis dimension is used to help determine how many cells should\nbe created when initialized, and to help calculate the height of\nthe scrollable area. This height value can only use `px` units.\nNote that the actual rendered size of each cell comes from the\napp's CSS, whereas this approximation is used to help calculate\ninitial dimensions before the item has been rendered."
      },
      "attribute": "approx-item-height",
      "reflect": false,
      "defaultValue": "45"
    },
    "approxHeaderHeight": {
      "type": "number",
      "mutable": false,
      "complexType": {
        "original": "number",
        "resolved": "number",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "The approximate height of each header template's cell.\nThis dimension is used to help determine how many cells should\nbe created when initialized, and to help calculate the height of\nthe scrollable area. This height value can only use `px` units.\nNote that the actual rendered size of each cell comes from the\napp's CSS, whereas this approximation is used to help calculate\ninitial dimensions before the item has been rendered."
      },
      "attribute": "approx-header-height",
      "reflect": false,
      "defaultValue": "30"
    },
    "approxFooterHeight": {
      "type": "number",
      "mutable": false,
      "complexType": {
        "original": "number",
        "resolved": "number",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "The approximate width of each footer template's cell.\nThis dimension is used to help determine how many cells should\nbe created when initialized, and to help calculate the height of\nthe scrollable area. This height value can only use `px` units.\nNote that the actual rendered size of each cell comes from the\napp's CSS, whereas this approximation is used to help calculate\ninitial dimensions before the item has been rendered."
      },
      "attribute": "approx-footer-height",
      "reflect": false,
      "defaultValue": "30"
    },
    "headerFn": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "HeaderFn",
        "resolved": "((item: any, index: number, items: any[]) => string | null | undefined) | undefined",
        "references": {
          "HeaderFn": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Section headers and the data used within its given\ntemplate can be dynamically created by passing a function to `headerFn`.\nFor example, a large list of contacts usually has dividers between each\nletter in the alphabet. App's can provide their own custom `headerFn`\nwhich is called with each record within the dataset. The logic within\nthe header function can decide if the header template should be used,\nand what data to give to the header template. The function must return\n`null` if a header cell shouldn't be created."
      }
    },
    "footerFn": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "HeaderFn",
        "resolved": "((item: any, index: number, items: any[]) => string | null | undefined) | undefined",
        "references": {
          "HeaderFn": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Section footers and the data used within its given\ntemplate can be dynamically created by passing a function to `footerFn`.\nThe logic within the footer function can decide if the footer template\nshould be used, and what data to give to the footer template. The function\nmust return `null` if a footer cell shouldn't be created."
      }
    },
    "items": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "any[]",
        "resolved": "any[] | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The data that builds the templates within the virtual scroll.\nIt's important to note that when this data has changed, then the\nentire virtual scroll is reset, which is an expensive operation and\nshould be avoided if possible."
      }
    },
    "itemHeight": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "ItemHeightFn",
        "resolved": "((item: any, index: number) => number) | undefined",
        "references": {
          "ItemHeightFn": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "An optional function that maps each item within their height.\nWhen this function is provides, heavy optimizations and fast path can be taked by\n`ion-virtual-scroll` leading to massive performance improvements.\n\nThis function allows to skip all DOM reads, which can be Doing so leads\nto massive performance"
      }
    },
    "headerHeight": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "HeaderHeightFn",
        "resolved": "((item: any, index: number) => number) | undefined",
        "references": {
          "HeaderHeightFn": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "An optional function that maps each item header within their height."
      }
    },
    "footerHeight": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "FooterHeightFn",
        "resolved": "((item: any, index: number) => number) | undefined",
        "references": {
          "FooterHeightFn": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "An optional function that maps each item footer within their height."
      }
    },
    "renderItem": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "(item: any, index: number) => any",
        "resolved": "((item: any, index: number) => any) | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "NOTE: only JSX API for stencil.\n\nProvide a render function for the items to be rendered. Returns a JSX virtual-dom."
      }
    },
    "renderHeader": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "(item: any, index: number) => any",
        "resolved": "((item: any, index: number) => any) | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "NOTE: only JSX API for stencil.\n\nProvide a render function for the header to be rendered. Returns a JSX virtual-dom."
      }
    },
    "renderFooter": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "(item: any, index: number) => any",
        "resolved": "((item: any, index: number) => any) | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "NOTE: only JSX API for stencil.\n\nProvide a render function for the footer to be rendered. Returns a JSX virtual-dom."
      }
    },
    "nodeRender": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "ItemRenderFn",
        "resolved": "((el: HTMLElement | null, cell: Cell, domIndex: number) => HTMLElement) | undefined",
        "references": {
          "ItemRenderFn": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "NOTE: only Vanilla JS API."
      }
    },
    "domRender": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "DomRenderFn",
        "resolved": "((dom: VirtualNode[]) => void) | undefined",
        "references": {
          "DomRenderFn": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [{
            "text": undefined,
            "name": "internal"
          }],
        "text": ""
      }
    }
  }; }
  static get states() { return {
    "totalHeight": {}
  }; }
  static get methods() { return {
    "positionForItem": {
      "complexType": {
        "signature": "(index: number) => Promise<number>",
        "parameters": [{
            "tags": [],
            "text": ""
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<number>"
      },
      "docs": {
        "text": "Returns the position of the virtual item at the given index.",
        "tags": []
      }
    },
    "checkRange": {
      "complexType": {
        "signature": "(offset: number, len?: number) => Promise<void>",
        "parameters": [{
            "tags": [],
            "text": ""
          }, {
            "tags": [],
            "text": ""
          }],
        "references": {
          "Promise": {
            "location": "global"
          }
        },
        "return": "Promise<void>"
      },
      "docs": {
        "text": "This method marks a subset of items as dirty, so they can be re-rendered. Items should be marked as\ndirty any time the content or their style changes.\n\nThe subset of items to be updated can are specifing by an offset and a length.",
        "tags": []
      }
    },
    "checkEnd": {
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
        "text": "This method marks the tail the items array as dirty, so they can be re-rendered.\n\nIt's equivalent to calling:\n\n```js\nvirtualScroll.checkRange(lastItemLen);\n```",
        "tags": []
      }
    }
  }; }
  static get elementRef() { return "el"; }
  static get watchers() { return [{
      "propName": "itemHeight",
      "methodName": "itemsChanged"
    }, {
      "propName": "headerHeight",
      "methodName": "itemsChanged"
    }, {
      "propName": "footerHeight",
      "methodName": "itemsChanged"
    }, {
      "propName": "items",
      "methodName": "itemsChanged"
    }]; }
  static get listeners() { return [{
      "name": "resize",
      "method": "onResize",
      "target": "window",
      "capture": false,
      "passive": true
    }]; }
}
const VirtualProxy = ({ dom }, children, utils) => {
  return utils.map(children, (child, i) => {
    const node = dom[i];
    const vattrs = child.vattrs || {};
    let classes = vattrs.class || '';
    classes += 'virtual-item ';
    if (!node.visible) {
      classes += 'virtual-loading';
    }
    return Object.assign(Object.assign({}, child), { vattrs: Object.assign(Object.assign({}, vattrs), { class: classes, style: Object.assign(Object.assign({}, vattrs.style), { transform: `translate3d(0,${node.top}px,0)` }) }) });
  });
};
