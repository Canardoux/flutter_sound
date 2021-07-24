import { EventEmitter } from '../../stencil.core';
export declare class PWACameraModal {
    onPhoto: EventEmitter;
    noDeviceError: EventEmitter;
    _modal: HTMLElement;
    present(): Promise<void>;
    dismiss(): Promise<void>;
    render(): any;
}
