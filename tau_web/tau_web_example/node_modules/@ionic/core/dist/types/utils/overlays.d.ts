import { ActionSheetOptions, AlertOptions, Animation, AnimationBuilder, HTMLIonOverlayElement, IonicConfig, LoadingOptions, ModalOptions, OverlayInterface, PickerOptions, PopoverOptions, ToastOptions } from '../interface';
export declare const activeAnimations: WeakMap<OverlayInterface, Animation[]>;
export declare const alertController: {
  create(options: AlertOptions): Promise<HTMLIonAlertElement>;
  dismiss(data?: any, role?: string | undefined, id?: string | undefined): Promise<boolean>;
  getTop(): Promise<HTMLIonAlertElement | undefined>;
};
export declare const actionSheetController: {
  create(options: ActionSheetOptions): Promise<HTMLIonActionSheetElement>;
  dismiss(data?: any, role?: string | undefined, id?: string | undefined): Promise<boolean>;
  getTop(): Promise<HTMLIonActionSheetElement | undefined>;
};
export declare const loadingController: {
  create(options: LoadingOptions): Promise<HTMLIonLoadingElement>;
  dismiss(data?: any, role?: string | undefined, id?: string | undefined): Promise<boolean>;
  getTop(): Promise<HTMLIonLoadingElement | undefined>;
};
export declare const modalController: {
  create(options: ModalOptions<import("../interface").ComponentRef>): Promise<HTMLIonModalElement>;
  dismiss(data?: any, role?: string | undefined, id?: string | undefined): Promise<boolean>;
  getTop(): Promise<HTMLIonModalElement | undefined>;
};
export declare const pickerController: {
  create(options: PickerOptions): Promise<HTMLIonPickerElement>;
  dismiss(data?: any, role?: string | undefined, id?: string | undefined): Promise<boolean>;
  getTop(): Promise<HTMLIonPickerElement | undefined>;
};
export declare const popoverController: {
  create(options: PopoverOptions<import("../interface").ComponentRef>): Promise<HTMLIonPopoverElement>;
  dismiss(data?: any, role?: string | undefined, id?: string | undefined): Promise<boolean>;
  getTop(): Promise<HTMLIonPopoverElement | undefined>;
};
export declare const toastController: {
  create(options: ToastOptions): Promise<HTMLIonToastElement>;
  dismiss(data?: any, role?: string | undefined, id?: string | undefined): Promise<boolean>;
  getTop(): Promise<HTMLIonToastElement | undefined>;
};
export declare const prepareOverlay: <T extends HTMLIonOverlayElement>(el: T) => void;
export declare const createOverlay: <T extends HTMLIonOverlayElement>(tagName: string, opts: object | undefined) => Promise<T>;
export declare const connectListeners: (doc: Document) => void;
export declare const dismissOverlay: (doc: Document, data: any, role: string | undefined, overlayTag: string, id?: string | undefined) => Promise<boolean>;
export declare const getOverlays: (doc: Document, selector?: string | undefined) => HTMLIonOverlayElement[];
export declare const getOverlay: (doc: Document, overlayTag?: string | undefined, id?: string | undefined) => HTMLIonOverlayElement | undefined;
/**
 * When an overlay is presented, the main
 * focus is the overlay not the page content.
 * We need to remove the page content from the
 * accessibility tree otherwise when
 * users use "read screen from top" gestures with
 * TalkBack and VoiceOver, the screen reader will begin
 * to read the content underneath the overlay.
 *
 * We need a container where all page components
 * exist that is separate from where the overlays
 * are added in the DOM. For most apps, this element
 * is the top most ion-router-outlet. In the event
 * that devs are not using a router,
 * they will need to add the "ion-view-container-root"
 * id to the element that contains all of their views.
 *
 * TODO: If Framework supports having multiple top
 * level router outlets we would need to update this.
 * Example: One outlet for side menu and one outlet
 * for main content.
 */
export declare const setRootAriaHidden: (hidden?: boolean) => void;
export declare const present: (overlay: OverlayInterface, name: keyof IonicConfig, iosEnterAnimation: AnimationBuilder, mdEnterAnimation: AnimationBuilder, opts?: any) => Promise<void>;
export declare const dismiss: (overlay: OverlayInterface, data: any | undefined, role: string | undefined, name: keyof IonicConfig, iosLeaveAnimation: AnimationBuilder, mdLeaveAnimation: AnimationBuilder, opts?: any) => Promise<boolean>;
export declare const eventMethod: <T>(element: HTMLElement, eventName: string) => Promise<T>;
export declare const onceEvent: (element: HTMLElement, eventName: string, callback: (ev: Event) => void) => void;
export declare const isCancel: (role: string | undefined) => boolean;
export declare const safeCall: (handler: any, arg?: any) => any;
export declare const BACKDROP = "backdrop";
