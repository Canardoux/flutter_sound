import { ComponentInterface } from '../../stencil-public-runtime';
import { SpinnerTypes } from '../../interface';
import { IonicSafeString } from '../../utils/sanitization';
export declare class InfiniteScrollContent implements ComponentInterface {
  /**
   * An animated SVG spinner that shows while loading.
   */
  loadingSpinner?: SpinnerTypes | null;
  /**
   * Optional text to display while loading.
   * `loadingText` can accept either plaintext or HTML as a string.
   * To display characters normally reserved for HTML, they
   * must be escaped. For example `<Ionic>` would become
   * `&lt;Ionic&gt;`
   *
   * For more information: [Security Documentation](https://ionicframework.com/docs/faq/security)
   */
  loadingText?: string | IonicSafeString;
  componentDidLoad(): void;
  render(): any;
}
