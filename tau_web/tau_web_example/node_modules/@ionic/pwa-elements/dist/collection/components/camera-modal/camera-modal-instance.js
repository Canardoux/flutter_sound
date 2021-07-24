import { h } from "@stencil/core";
export class PWACameraModal {
    constructor() {
        this.noDevicesText = 'No camera found';
        this.noDevicesButtonText = 'Choose image';
        this.handlePhoto = async (photo) => {
            this.onPhoto.emit(photo);
        };
        this.handleNoDeviceError = async (photo) => {
            this.noDeviceError.emit(photo);
        };
    }
    handleBackdropClick(e) {
        if (e.target !== this.el) {
            this.onPhoto.emit(null);
        }
    }
    handleComponentClick(e) {
        e.stopPropagation();
    }
    handleBackdropKeyUp(e) {
        if (e.key === "Escape") {
            this.onPhoto.emit(null);
        }
    }
    render() {
        return (h("div", { class: "wrapper", onClick: e => this.handleBackdropClick(e) },
            h("div", { class: "content" },
                h("pwa-camera", { onClick: e => this.handleComponentClick(e), handlePhoto: this.handlePhoto, handleNoDeviceError: this.handleNoDeviceError, noDevicesButtonText: this.noDevicesButtonText, noDevicesText: this.noDevicesText }))));
    }
    static get is() { return "pwa-camera-modal-instance"; }
    static get encapsulation() { return "shadow"; }
    static get originalStyleUrls() { return {
        "$": ["camera-modal-instance.css"]
    }; }
    static get styleUrls() { return {
        "$": ["camera-modal-instance.css"]
    }; }
    static get properties() { return {
        "noDevicesText": {
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
            "attribute": "no-devices-text",
            "reflect": false,
            "defaultValue": "'No camera found'"
        },
        "noDevicesButtonText": {
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
            "attribute": "no-devices-button-text",
            "reflect": false,
            "defaultValue": "'Choose image'"
        }
    }; }
    static get events() { return [{
            "method": "onPhoto",
            "name": "onPhoto",
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
        }, {
            "method": "noDeviceError",
            "name": "noDeviceError",
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
    static get listeners() { return [{
            "name": "keyup",
            "method": "handleBackdropKeyUp",
            "target": "body",
            "capture": false,
            "passive": false
        }]; }
}
