import { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import { Color, TabBarChangedEventDetail } from '../../interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export declare class TabBar implements ComponentInterface {
  private keyboardWillShowHandler?;
  private keyboardWillHideHandler?;
  el: HTMLElement;
  keyboardVisible: boolean;
  /**
   * The color to use from your application's color palette.
   * Default options are: `"primary"`, `"secondary"`, `"tertiary"`, `"success"`, `"warning"`, `"danger"`, `"light"`, `"medium"`, and `"dark"`.
   * For more information on colors, see [theming](/docs/theming/basics).
   */
  color?: Color;
  /**
   * The selected tab component
   */
  selectedTab?: string;
  selectedTabChanged(): void;
  /**
   * If `true`, the tab bar will be translucent.
   * Only applies when the mode is `"ios"` and the device supports
   * [`backdrop-filter`](https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter#Browser_compatibility).
   */
  translucent: boolean;
  /** @internal */
  ionTabBarChanged: EventEmitter<TabBarChangedEventDetail>;
  componentWillLoad(): void;
  connectedCallback(): void;
  disconnectedCallback(): void;
  render(): any;
}
