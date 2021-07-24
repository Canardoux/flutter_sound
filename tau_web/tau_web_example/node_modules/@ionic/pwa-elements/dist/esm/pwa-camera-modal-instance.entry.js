import { r as registerInstance, c as createEvent, h, g as getElement } from './core-f86805ad.js';

const PWACameraModal = class {
    constructor(hostRef) {
        registerInstance(this, hostRef);
        this.noDevicesText = 'No camera found';
        this.noDevicesButtonText = 'Choose image';
        this.handlePhoto = async (photo) => {
            this.onPhoto.emit(photo);
        };
        this.handleNoDeviceError = async (photo) => {
            this.noDeviceError.emit(photo);
        };
        this.onPhoto = createEvent(this, "onPhoto", 7);
        this.noDeviceError = createEvent(this, "noDeviceError", 7);
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
        return (h("div", { class: "wrapper", onClick: e => this.handleBackdropClick(e) }, h("div", { class: "content" }, h("pwa-camera", { onClick: e => this.handleComponentClick(e), handlePhoto: this.handlePhoto, handleNoDeviceError: this.handleNoDeviceError, noDevicesButtonText: this.noDevicesButtonText, noDevicesText: this.noDevicesText }))));
    }
    get el() { return getElement(this); }
    static get style() { return ":host{z-index:1000;position:fixed;top:0;left:0;width:100%;height:100%;contain:strict;--inset-width:600px;--inset-height:600px}.wrapper,:host{display:-ms-flexbox;display:flex}.wrapper{-ms-flex:1;flex:1;-ms-flex-align:center;align-items:center;-ms-flex-pack:center;justify-content:center;background-color:rgba(0,0,0,.15)}.content{-webkit-box-shadow:0 0 5px rgba(0,0,0,.2);box-shadow:0 0 5px rgba(0,0,0,.2);width:var(--inset-width);height:var(--inset-height);max-height:100%}\@media only screen and (max-width:600px){.content{width:100%;height:100%}}"; }
};

export { PWACameraModal as pwa_camera_modal_instance };
