export interface MediaSettingsRange {
    min: number;
    max: number;
    step: number;
}
export interface PhotoCapabilities {
    redEyeReduction: "never" | "always" | "controllable";
    imageHeight: MediaSettingsRange;
    imageWidth: MediaSettingsRange;
    fillLightMode: string[];
}
export declare type FlashMode = "auto" | "off" | "flash";
export interface ActionSheetOption {
    title: string;
}
