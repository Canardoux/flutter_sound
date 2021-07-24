import { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import { AnimationBuilder, BackButtonEvent, RouterDirection, RouterEventDetail } from '../../interface';
export declare class Router implements ComponentInterface {
  private previousPath;
  private busy;
  private state;
  private lastState;
  private waitPromise?;
  el: HTMLElement;
  /**
   * By default `ion-router` will match the routes at the root path ("/").
   * That can be changed when
   *
   */
  root: string;
  /**
   * The router can work in two "modes":
   * - With hash: `/index.html#/path/to/page`
   * - Without hash: `/path/to/page`
   *
   * Using one or another might depend in the requirements of your app and/or where it's deployed.
   *
   * Usually "hash-less" navigation works better for SEO and it's more user friendly too, but it might
   * requires additional server-side configuration in order to properly work.
   *
   * On the other side hash-navigation is much easier to deploy, it even works over the file protocol.
   *
   * By default, this property is `true`, change to `false` to allow hash-less URLs.
   */
  useHash: boolean;
  /**
   * Event emitted when the route is about to change
   */
  ionRouteWillChange: EventEmitter<RouterEventDetail>;
  /**
   * Emitted when the route had changed
   */
  ionRouteDidChange: EventEmitter<RouterEventDetail>;
  componentWillLoad(): Promise<void>;
  componentDidLoad(): void;
  protected onPopState(): Promise<boolean>;
  protected onBackButton(ev: BackButtonEvent): void;
  /** @internal */
  canTransition(): Promise<string | boolean>;
  /**
   * Navigate to the specified URL.
   *
   * @param url The url to navigate to.
   * @param direction The direction of the animation. Defaults to `"forward"`.
   */
  push(url: string, direction?: RouterDirection, animation?: AnimationBuilder): Promise<boolean>;
  /**
   * Go back to previous page in the window.history.
   */
  back(): Promise<void>;
  /** @internal */
  printDebug(): Promise<void>;
  /** @internal */
  navChanged(direction: RouterDirection): Promise<boolean>;
  private onRedirectChanged;
  private onRoutesChanged;
  private historyDirection;
  private writeNavStateRoot;
  private safeWriteNavState;
  private lock;
  private runGuards;
  private writeNavState;
  private setPath;
  private getPath;
  private routeChangeEvent;
}
