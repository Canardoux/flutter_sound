import { ComponentRef, FrameworkDelegate } from '../interface';
export declare const attachComponent: (delegate: FrameworkDelegate | undefined, container: Element, component: ComponentRef, cssClasses?: string[] | undefined, componentProps?: {
  [key: string]: any;
} | undefined) => Promise<HTMLElement>;
export declare const detachComponent: (delegate: FrameworkDelegate | undefined, element: HTMLElement | undefined) => Promise<void>;
