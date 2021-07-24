import { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import { RadioGroupChangeEventDetail } from '../../interface';
export declare class RadioGroup implements ComponentInterface {
  private inputId;
  private labelId;
  private label?;
  el: HTMLElement;
  /**
   * If `true`, the radios can be deselected.
   */
  allowEmptySelection: boolean;
  /**
   * The name of the control, which is submitted with the form data.
   */
  name: string;
  /**
   * the value of the radio group.
   */
  value?: any | null;
  valueChanged(value: any | undefined): void;
  /**
   * Emitted when the value has changed.
   */
  ionChange: EventEmitter<RadioGroupChangeEventDetail>;
  componentDidLoad(): void;
  private setRadioTabindex;
  connectedCallback(): Promise<void>;
  private getRadios;
  private onClick;
  onKeydown(ev: any): void;
  render(): any;
}
