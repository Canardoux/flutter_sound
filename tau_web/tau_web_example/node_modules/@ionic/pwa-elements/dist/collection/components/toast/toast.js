import { h } from "@stencil/core";
export class PWAToast {
    constructor() {
        this.duration = 2000;
        this.closing = null;
    }
    hostData() {
        const classes = {
            out: !!this.closing
        };
        if (this.closing !== null) {
            classes['in'] = !this.closing;
        }
        return {
            class: classes
        };
    }
    componentDidLoad() {
        setTimeout(() => {
            this.closing = false;
        });
        setTimeout(() => {
            this.close();
        }, this.duration);
    }
    close() {
        this.closing = true;
        setTimeout(() => {
            this.el.parentNode.removeChild(this.el);
        }, 1000);
    }
    render() {
        return (h("div", { class: "wrapper" },
            h("div", { class: "toast" }, this.message)));
    }
    static get is() { return "pwa-toast"; }
    static get encapsulation() { return "shadow"; }
    static get originalStyleUrls() { return {
        "$": ["toast.css"]
    }; }
    static get styleUrls() { return {
        "$": ["toast.css"]
    }; }
    static get properties() { return {
        "message": {
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
            "attribute": "message",
            "reflect": false
        },
        "duration": {
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
                "text": ""
            },
            "attribute": "duration",
            "reflect": false,
            "defaultValue": "2000"
        }
    }; }
    static get states() { return {
        "closing": {}
    }; }
    static get elementRef() { return "el"; }
}
