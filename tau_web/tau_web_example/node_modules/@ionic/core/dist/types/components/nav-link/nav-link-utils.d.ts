import { AnimationBuilder, ComponentProps, NavComponent } from '../../interface';
import { RouterDirection } from '../router/utils/interface';
export declare const navLink: (el: HTMLElement, routerDirection: RouterDirection, component?: NavComponent | undefined, componentProps?: ComponentProps<null> | undefined, routerAnimation?: AnimationBuilder | undefined) => Promise<boolean>;
