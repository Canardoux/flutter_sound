import { EventEmitter } from '../../stencil.core';
import { ActionSheetOption } from '../../definitions';
export declare class PWAActionSheet {
    el: HTMLElement;
    header: string;
    cancelable: boolean;
    options: ActionSheetOption[];
    onSelection: EventEmitter;
    open: boolean;
    componentDidLoad(): void;
    dismiss(): void;
    close(): void;
    handleOptionClick(e: MouseEvent, i: number): void;
    render(): any;
}
