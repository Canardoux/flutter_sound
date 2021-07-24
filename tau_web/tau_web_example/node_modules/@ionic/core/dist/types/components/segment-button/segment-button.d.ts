import { ComponentInterface } from '../../stencil-public-runtime';
import { SegmentButtonLayout } from '../../interface';
import { ButtonInterface } from '../../utils/element-interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 *
 * @part native - The native HTML button element that wraps all child elements.
 * @part indicator - The indicator displayed on the checked segment button.
 * @part indicator-background - The background element for the indicator displayed on the checked segment button.
 */
export declare class SegmentButton implements ComponentInterface, ButtonInterface {
  private segmentEl;
  el: HTMLElement;
  checked: boolean;
  /**
   * If `true`, the user cannot interact with the segment button.
   */
  disabled: boolean;
  /**
   * Set the layout of the text and icon in the segment.
   */
  layout?: SegmentButtonLayout;
  /**
   * The type of the button.
   */
  type: 'submit' | 'reset' | 'button';
  /**
   * The value of the segment button.
   */
  value: string;
  connectedCallback(): void;
  disconnectedCallback(): void;
  private get hasLabel();
  private get hasIcon();
  private updateStyle;
  private updateState;
  private get tabIndex();
  render(): any;
}
