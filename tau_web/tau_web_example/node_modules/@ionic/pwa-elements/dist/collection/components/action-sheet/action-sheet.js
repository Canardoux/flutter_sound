import { h } from "@stencil/core";
export class PWAActionSheet {
    constructor() {
        this.cancelable = true;
        this.options = [];
        this.open = false;
    }
    componentDidLoad() {
        requestAnimationFrame(() => {
            this.open = true;
        });
    }
    dismiss() {
        if (this.cancelable) {
            this.close();
        }
    }
    close() {
        this.open = false;
        setTimeout(() => {
            this.el.parentNode.removeChild(this.el);
        }, 500);
    }
    handleOptionClick(e, i) {
        e.stopPropagation();
        this.onSelection.emit(i);
        this.close();
    }
    render() {
        return (h("div", { class: `wrapper${this.open ? ' open' : ''}`, onClick: () => this.dismiss() },
            h("div", { class: "content" },
                h("div", { class: "title" }, this.header),
                this.options.map((option, i) => h("div", { class: "action-sheet-option", onClick: (e) => this.handleOptionClick(e, i) },
                    h("div", { class: "action-sheet-button" }, option.title))))));
    }
    static get is() { return "pwa-action-sheet"; }
    static get encapsulation() { return "shadow"; }
    static get originalStyleUrls() { return {
        "$": ["action-sheet.css"]
    }; }
    static get styleUrls() { return {
        "$": ["action-sheet.css"]
    }; }
    static get properties() { return {
        "header": {
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
                "text": ""
            },
            "attribute": "header",
            "reflect": false
        },
        "cancelable": {
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
                "text": ""
            },
            "attribute": "cancelable",
            "reflect": false,
            "defaultValue": "true"
        },
        "options": {
            "type": "unknown",
            "mutable": false,
            "complexType": {
                "original": "ActionSheetOption[]",
                "resolved": "ActionSheetOption[]",
                "references": {
                    "ActionSheetOption": {
                        "location": "import",
                        "path": "../../definitions"
                    }
                }
            },
            "required": false,
            "optional": false,
            "docs": {
                "tags": [],
                "text": ""
            },
            "defaultValue": "[]"
        }
    }; }
    static get states() { return {
        "open": {}
    }; }
    static get events() { return [{
            "method": "onSelection",
            "name": "onSelection",
            "bubbles": true,
            "cancelable": true,
            "composed": true,
            "docs": {
                "tags": [],
                "text": ""
            },
            "complexType": {
                "original": "any",
                "resolved": "any",
                "references": {}
            }
        }]; }
    static get elementRef() { return "el"; }
}
