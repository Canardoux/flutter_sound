import { ComponentInterface } from '../../stencil-public-runtime';
import { SpinnerTypes } from '../../interface';
import { IonicSafeString } from '../../utils/sanitization';
export declare class RefresherContent implements ComponentInterface {
  el: HTMLIonRefresherContentElement;
  /**
   * A static icon or a spinner to display when you begin to pull down.
   * A spinner name can be provided to gradually show tick marks
   * when pulling down on iOS devices.
   */
  pullingIcon?: SpinnerTypes | string | null;
  /**
   * The text you want to display when you begin to pull down.
   * `pullingText` can accept either plaintext or HTML as a string.
   * To display characters normally reserved for HTML, they
   * must be escaped. For example `<Ionic>` would become
   * `&lt;Ionic&gt;`
   *
   * For more information: [Security Documentation](https://ionicframework.com/docs/faq/security)
   */
  pullingText?: string | IonicSafeString;
  /**
   * An animated SVG spinner that shows when refreshing begins
   */
  refreshingSpinner?: SpinnerTypes | null;
  /**
   * The text you want to display when performing a refresh.
   * `refreshingText` can accept either plaintext or HTML as a string.
   * To display characters normally reserved for HTML, they
   * must be escaped. For example `<Ionic>` would become
   * `&lt;Ionic&gt;`
   *
   * For more information: [Security Documentation](https://ionicframework.com/docs/faq/security)
   */
  refreshingText?: string | IonicSafeString;
  componentWillLoad(): void;
  render(): any;
}
