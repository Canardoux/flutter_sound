export declare class PWAToast {
    el: HTMLElement;
    message: string;
    duration: number;
    closing: any;
    hostData(): {
        class: {
            out: boolean;
        };
    };
    componentDidLoad(): void;
    close(): void;
    render(): any;
}
