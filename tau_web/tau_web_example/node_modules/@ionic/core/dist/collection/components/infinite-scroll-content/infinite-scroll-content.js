import { Component, Host, Prop, h } from '@stencil/core';
import { config } from '../../global/config';
import { getIonMode } from '../../global/ionic-global';
import { sanitizeDOMString } from '../../utils/sanitization';
export class InfiniteScrollContent {
  componentDidLoad() {
    if (this.loadingSpinner === undefined) {
      const mode = getIonMode(this);
      this.loadingSpinner = config.get('infiniteLoadingSpinner', config.get('spinner', mode === 'ios' ? 'lines' : 'crescent'));
    }
  }
  render() {
    const mode = getIonMode(this);
    return (h(Host, { class: {
        [mode]: true,
        // Used internally for styling
        [`infinite-scroll-content-${mode}`]: true
      } },
      h("div", { class: "infinite-loading" },
        this.loadingSpinner && (h("div", { class: "infinite-loading-spinner" },
          h("ion-spinner", { name: this.loadingSpinner }))),
        this.loadingText && (h("div", { class: "infinite-loading-text", innerHTML: sanitizeDOMString(this.loadingText) })))));
  }
  static get is() { return "ion-infinite-scroll-content"; }
  static get originalStyleUrls() { return {
    "ios": ["infinite-scroll-content.ios.scss"],
    "md": ["infinite-scroll-content.md.scss"]
  }; }
  static get styleUrls() { return {
    "ios": ["infinite-scroll-content.ios.css"],
    "md": ["infinite-scroll-content.md.css"]
  }; }
  static get properties() { return {
    "loadingSpinner": {
      "type": "string",
      "mutable": true,
      "complexType": {
        "original": "SpinnerTypes | null",
        "resolved": "\"bubbles\" | \"circles\" | \"circular\" | \"crescent\" | \"dots\" | \"lines\" | \"lines-small\" | null | undefined",
        "references": {
          "SpinnerTypes": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "An animated SVG spinner that shows while loading."
      },
      "attribute": "loading-spinner",
      "reflect": false
    },
    "loadingText": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string | IonicSafeString",
        "resolved": "IonicSafeString | string | undefined",
        "references": {
          "IonicSafeString": {
            "location": "import",
            "path": "../../utils/sanitization"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "Optional text to display while loading.\n`loadingText` can accept either plaintext or HTML as a string.\nTo display characters normally reserved for HTML, they\nmust be escaped. For example `<Ionic>` would become\n`&lt;Ionic&gt;`\n\nFor more information: [Security Documentation](https://ionicframework.com/docs/faq/security)"
      },
      "attribute": "loading-text",
      "reflect": false
    }
  }; }
}
