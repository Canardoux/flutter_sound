import { Component, Element, Host, Prop, h } from '@stencil/core';
import { config } from '../../global/config';
import { getIonMode } from '../../global/ionic-global';
import { createColorClasses, hostContext, openURL } from '../../utils/theme';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 *
 * @part native - The native HTML button element that wraps all child elements.
 * @part icon - The back button icon (uses ion-icon).
 * @part text - The back button text.
 */
export class BackButton {
  constructor() {
    /**
     * If `true`, the user cannot interact with the button.
     */
    this.disabled = false;
    /**
     * The type of the button.
     */
    this.type = 'button';
    this.onClick = async (ev) => {
      const nav = this.el.closest('ion-nav');
      ev.preventDefault();
      if (nav && await nav.canGoBack()) {
        return nav.pop({ animationBuilder: this.routerAnimation, skipIfBusy: true });
      }
      return openURL(this.defaultHref, ev, 'back', this.routerAnimation);
    };
  }
  componentWillLoad() {
    if (this.defaultHref === undefined) {
      this.defaultHref = config.get('backButtonDefaultHref');
    }
  }
  get backButtonIcon() {
    const icon = this.icon;
    if (icon != null) {
      // icon is set on the component or by the config
      return icon;
    }
    if (getIonMode(this) === 'ios') {
      // default ios back button icon
      return config.get('backButtonIcon', 'chevron-back');
    }
    // default md back button icon
    return config.get('backButtonIcon', 'arrow-back-sharp');
  }
  get backButtonText() {
    const defaultBackButtonText = getIonMode(this) === 'ios' ? 'Back' : null;
    return this.text != null ? this.text : config.get('backButtonText', defaultBackButtonText);
  }
  get hasIconOnly() {
    return this.backButtonIcon && !this.backButtonText;
  }
  get rippleType() {
    // If the button only has an icon we use the unbounded
    // "circular" ripple effect
    if (this.hasIconOnly) {
      return 'unbounded';
    }
    return 'bounded';
  }
  render() {
    const { color, defaultHref, disabled, type, hasIconOnly, backButtonIcon, backButtonText } = this;
    const showBackButton = defaultHref !== undefined;
    const mode = getIonMode(this);
    return (h(Host, { onClick: this.onClick, class: createColorClasses(color, {
        [mode]: true,
        'button': true,
        'back-button-disabled': disabled,
        'back-button-has-icon-only': hasIconOnly,
        'in-toolbar': hostContext('ion-toolbar', this.el),
        'in-toolbar-color': hostContext('ion-toolbar[color]', this.el),
        'ion-activatable': true,
        'ion-focusable': true,
        'show-back-button': showBackButton
      }) },
      h("button", { type: type, disabled: disabled, class: "button-native", part: "native", "aria-label": backButtonText || 'back' },
        h("span", { class: "button-inner" },
          backButtonIcon && h("ion-icon", { part: "icon", icon: backButtonIcon, "aria-hidden": "true", lazy: false }),
          backButtonText && h("span", { part: "text", "aria-hidden": "true", class: "button-text" }, backButtonText)),
        mode === 'md' && h("ion-ripple-effect", { type: this.rippleType }))));
  }
  static get is() { return "ion-back-button"; }
  static get encapsulation() { return "shadow"; }
  static get originalStyleUrls() { return {
    "ios": ["back-button.ios.scss"],
    "md": ["back-button.md.scss"]
  }; }
  static get styleUrls() { return {
    "ios": ["back-button.ios.css"],
    "md": ["back-button.md.css"]
  }; }
  static get properties() { return {
    "color": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "Color",
        "resolved": "string | undefined",
        "references": {
          "Color": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The color to use from your application's color palette.\nDefault options are: `\"primary\"`, `\"secondary\"`, `\"tertiary\"`, `\"success\"`, `\"warning\"`, `\"danger\"`, `\"light\"`, `\"medium\"`, and `\"dark\"`.\nFor more information on colors, see [theming](/docs/theming/basics)."
      },
      "attribute": "color",
      "reflect": true
    },
    "defaultHref": {
      "type": "string",
      "mutable": true,
      "complexType": {
        "original": "string",
        "resolved": "string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The url to navigate back to by default when there is no history."
      },
      "attribute": "default-href",
      "reflect": false
    },
    "disabled": {
      "type": "boolean",
      "mutable": false,
      "complexType": {
        "original": "boolean",
        "resolved": "boolean",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "If `true`, the user cannot interact with the button."
      },
      "attribute": "disabled",
      "reflect": true,
      "defaultValue": "false"
    },
    "icon": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string | null",
        "resolved": "null | string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The icon name to use for the back button."
      },
      "attribute": "icon",
      "reflect": false
    },
    "text": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "string | null",
        "resolved": "null | string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "The text to display in the back button."
      },
      "attribute": "text",
      "reflect": false
    },
    "type": {
      "type": "string",
      "mutable": false,
      "complexType": {
        "original": "'submit' | 'reset' | 'button'",
        "resolved": "\"button\" | \"reset\" | \"submit\"",
        "references": {}
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "The type of the button."
      },
      "attribute": "type",
      "reflect": false,
      "defaultValue": "'button'"
    },
    "routerAnimation": {
      "type": "unknown",
      "mutable": false,
      "complexType": {
        "original": "AnimationBuilder | undefined",
        "resolved": "((baseEl: any, opts?: any) => Animation) | undefined",
        "references": {
          "AnimationBuilder": {
            "location": "import",
            "path": "../../interface"
          }
        }
      },
      "required": false,
      "optional": false,
      "docs": {
        "tags": [],
        "text": "When using a router, it specifies the transition animation when navigating to\nanother page."
      }
    }
  }; }
  static get elementRef() { return "el"; }
}
