import { WebPlugin } from '@capacitor/core';
import type { CameraPlugin, ImageOptions, PermissionStatus, Photo } from './definitions';
export declare class CameraWeb extends WebPlugin implements CameraPlugin {
    getPhoto(options: ImageOptions): Promise<Photo>;
    private cameraExperience;
    private fileInputExperience;
    private _getCameraPhoto;
    checkPermissions(): Promise<PermissionStatus>;
    requestPermissions(): Promise<PermissionStatus>;
}
declare const Camera: CameraWeb;
export { Camera };
