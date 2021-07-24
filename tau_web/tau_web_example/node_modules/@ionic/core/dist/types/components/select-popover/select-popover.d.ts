import { ComponentInterface } from '../../stencil-public-runtime';
import { SelectPopoverOption } from '../../interface';
/**
 * @internal
 */
export declare class SelectPopover implements ComponentInterface {
  /** Header text for the popover */
  header?: string;
  /** Subheader text for the popover */
  subHeader?: string;
  /** Text for popover body */
  message?: string;
  /** Array of options for the popover */
  options: SelectPopoverOption[];
  onSelect(ev: any): void;
  render(): any;
}
