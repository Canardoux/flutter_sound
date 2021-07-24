import { Component, Element, Event, Host, Prop, State, Watch, h, writeTask } from '@stencil/core';
import { config } from '../../global/config';
import { getIonMode } from '../../global/ionic-global';
import { pointerCoord } from '../../utils/helpers';
import { createColorClasses, hostContext } from '../../utils/theme';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export class Segment {
  constructor() {
    this.didInit = false;
    this.activated = false;
    /**
     * If `true`, the user cannot interact with the segment.
     */
    this.disabled = false;
    /**
     * If `true`, the segment buttons will overflow and the user can swipe to see them.
     * In addition, this will disable the gesture to drag the indicator between the buttons
     * in order to swipe to see hidden buttons.
     */
    this.scrollable = false;
    /**
     * If `true`, users will be able to swipe between segment buttons to activate them.
     */
    this.swipeGesture = true;
    this.onClick = (ev) => {
      const current = ev.target;
      const previous = this.checked;
      // If the current element is a segment then that means
      // the user tried to swipe to a segment button and
      // click a segment button at the same time so we should
      // not update the checked segment button
      if (current.tagName === 'ION-SEGMENT') {
        return;
      }
      this.value = current.value;
      if (this.scrollable || !this.swipeGesture) {
        if (previous) {
          this.checkButton(previous, current);
        }
        else {
          this.setCheckedClasses();
        }
      }
      this.checked = current;
    };
  }
  colorChanged(value, oldValue) {
    /**
     * If color is set after not having
     * previously been set (or vice versa),
     * we need to emit style so the segment-buttons
     * can apply their color classes properly.
     */
    if ((oldValue === undefined && value !== undefined) ||
      (oldValue !== undefined && value === undefined)) {
      this.emitStyle();
    }
  }
  swipeGestureChanged() {
    this.gestureChanged();
  }
  valueChanged(value, oldValue) {
    this.ionSelect.emit({ value });
    if (oldValue !== '' || this.didInit) {
      if (!this.activated) {
        this.ionChange.emit({ value });
      }
      else {
        this.valueAfterGesture = value;
      }
    }
  }
  disabledChanged() {
    this.gestureChanged();
    const buttons = this.getButtons();
    for (const button of buttons) {
      button.disabled = this.disabled;
    }
  }
  gestureChanged() {
    if (this.gesture) {
      this.gesture.enable(!this.scrollable && !this.disabled && this.swipeGesture);
    }
  }
  connectedCallback() {
    this.emitStyle();
  }
  componentWillLoad() {
    this.emitStyle();
  }
  async componentDidLoad() {
    this.setCheckedClasses();
    this.gesture = (await import('../../utils/gesture')).createGesture({
      el: this.el,
      gestureName: 'segment',
      gesturePriority: 100,
      threshold: 0,
      passive: false,
      onStart: ev => this.onStart(ev),
      onMove: ev => this.onMove(ev),
      onEnd: ev => this.onEnd(ev),
    });
    this.gestureChanged();
    if (this.disabled) {
      this.disabledChanged();
    }
    this.didInit = true;
  }
  onStart(detail) {
    this.activate(detail);
  }
  onMove(detail) {
    this.setNextIndex(detail);
  }
  onEnd(detail) {
    this.setActivated(false);
    const checkedValidButton = this.setNextIndex(detail, true);
    detail.event.stopImmediatePropagation();
    if (checkedValidButton) {
      this.addRipple(detail);
    }
    const value = this.valueAfterGesture;
    if (value !== undefined) {
      this.ionChange.emit({ value });
      this.valueAfterGesture = undefined;
    }
  }
  getButtons() {
    return Array.from(this.el.querySelectorAll('ion-segment-button'));
  }
  /**
   * The gesture blocks the segment button ripple. This
   * function adds the ripple based on the checked segment
   * and where the cursor ended.
   */
  addRipple(detail) {
    const useRippleEffect = config.getBoolean('animated', true) && config.getBoolean('rippleEffect', true);
    if (!useRippleEffect) {
      return;
    }
    const buttons = this.getButtons();
    const checked = buttons.find(button => button.value === this.value);
    const root = checked.shadowRoot || checked;
    const ripple = root.querySelector('ion-ripple-effect');
    if (!ripple) {
      return;
    }
    const { x, y } = pointerCoord(detail.event);
    ripple.addRipple(x, y).then(remove => remove());
  }
  /*
   * Activate both the segment and the buttons
   * due to a bug with ::slotted in Safari
   */
  setActivated(activated) {
    const buttons = this.getButtons();
    buttons.forEach(button => {
      if (activated) {
        button.classList.add('segment-button-activated');
      }
      else {
        button.classList.remove('segment-button-activated');
      }
    });
    this.activated = activated;
  }
  activate(detail) {
    const clicked = detail.event.target;
    const buttons = this.getButtons();
    const checked = buttons.find(button => button.value === this.value);
    // Make sure we are only checking for activation on a segment button
    // since disabled buttons will get the click on the segment
    if (clicked.tagName !== 'ION-SEGMENT-BUTTON') {
      return;
    }
    // If there are no checked buttons, set the current button to checked
    if (!checked) {
      this.value = clicked.value;
      this.setCheckedClasses();
    }
    // If the gesture began on the clicked button with the indicator
    // then we should activate the indicator
    if (this.value === clicked.value) {
      this.setActivated(true);
    }
  }
  getIndicator(button) {
    const root = button.shadowRoot || button;
    return root.querySelector('.segment-button-indicator');
  }
  checkButton(previous, current) {
    const previousIndicator = this.getIndicator(previous);
    const currentIndicator = this.getIndicator(current);
    if (previousIndicator === null || currentIndicator === null) {
      return;
    }
    const previousClientRect = previousIndicator.getBoundingClientRect();
    const currentClientRect = currentIndicator.getBoundingClientRect();
    const widthDelta = previousClientRect.width / currentClientRect.width;
    const xPosition = previousClientRect.left - currentClientRect.left;
    // Scale the indicator width to match the previous indicator width
    // and translate it on top of the previous indicator
    const transform = `translate3d(${xPosition}px, 0, 0) scaleX(${widthDelta})`;
    writeTask(() => {
      // Remove the transition before positioning on top of the previous indicator
      currentIndicator.classList.remove('segment-button-indicator-animated');
      currentIndicator.style.setProperty('transform', transform);
      // Force a repaint to ensure the transform happens
      currentIndicator.getBoundingClientRect();
      // Add the transition to move the indicator into place
      currentIndicator.classList.add('segment-button-indicator-animated');
      // Remove the transform to slide the indicator back to the button clicked
      currentIndicator.style.setProperty('transform', '');
    });
    this.value = current.value;
    this.setCheckedClasses();
  }
  setCheckedClasses() {
    const buttons = this.getButtons();
    const index = buttons.findIndex(button => button.value === this.value);
    const next = index + 1;
    // Keep track of the currently checked button
    this.checked = buttons.find(button => button.value === this.value);
    for (const button of buttons) {
      button.classList.remove('segment-button-after-checked');
    }
    if (next < buttons.length) {
      buttons[next].classList.add('segment-button-after-checked');
    }
  }
  setNextIndex(detail, isEnd = false) {
    const isRTL = document.dir === 'rtl';
    const activated = this.activated;
    const buttons = this.getButtons();
    const index = buttons.findIndex(button => button.value === this.value);
    const previous = buttons[index];
    let current;
    let nextIndex;
    if (index === -1) {
      return;
    }
    // Get the element that the touch event started on in case
    // it was the checked button, then we will move the indicator
    const rect = previous.getBoundingClientRect();
    const left = rect.left;
    const width = rect.width;
    // Get the element that the gesture is on top of based on the currentX of the
    // gesture event and the Y coordinate of the starting element, since the gesture
    // can move up and down off of the segment
    const currentX = detail.currentX;
    const previousY = rect.top + (rect.height / 2);
    const nextEl = document.elementFromPoint(currentX, previousY);
    const decreaseIndex = isRTL ? currentX > (left + width) : currentX < left;
    const increaseIndex = isRTL ? currentX < left : currentX > (left + width);
    // If the indicator is currently activated then we have started the gesture
    // on top of the checked button so we need to slide the indicator
    // by checking the button next to it as we move
    if (activated && !isEnd) {
      // Decrease index, move left in LTR & right in RTL
      if (decreaseIndex) {
        const newIndex = index - 1;
        if (newIndex >= 0) {
          nextIndex = newIndex;
        }
        // Increase index, moves right in LTR & left in RTL
      }
      else if (increaseIndex) {
        if (activated && !isEnd) {
          const newIndex = index + 1;
          if (newIndex < buttons.length) {
            nextIndex = newIndex;
          }
        }
      }
      if (nextIndex !== undefined && !buttons[nextIndex].disabled) {
        current = buttons[nextIndex];
      }
    }
    // If the indicator is not activated then we will just set the indicator
    // to the element where the gesture ended
    if (!activated && isEnd) {
      current = nextEl;
    }
    /* tslint:disable-next-line */
    if (current != null) {
      /**
       * If current element is ion-segment then that means
       * user tried to select a disabled ion-segment-button,
       * and we should not update the ripple.
       */
      if (current.tagName === 'ION-SEGMENT') {
        return false;
      }
      if (previous !== current) {
        this.checkButton(previous, current);
      }
    }
    return true;
  }
  emitStyle() {
    this.ionStyle.emit({
      'segment': true
    });
  }
  render() {
    const mode = getIonMode(this);
    return (h(Host, { role: "tablist", onClick: this.onClick, class: createColorClasses(this.color, {
        [mode]: true,
        'in-toolbar': hostContext('ion-toolbar', this.el),
        'in-toolbar-color': hostContext('ion-toolbar[color]', this.el),
        'segment-activated': this.activated,
        'segment-disabled': this.disabled,
        'segment-scrollable': this.scrollable
      }) },
      h("slot", null)));
  }
  static get is() { return "ion-segment"; }
  static get encapsulation() { return "shadow"; }
  static get originalStyleUrls() { return {
    "ios": ["segment.ios.scss"],
    "md": ["segment.md.scss"]
  }; }
  static get styleUrls() { return {
    "ios": ["segment.ios.css"],
    "md": ["segment.md.css"]
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
        "text": "If `true`, the user cannot interact with the segment."
      },
      "attribute": "disabled",
      "reflect": false,
      "defaultValue": "false"
    },
    "scrollable": {
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
        "text": "If `true`, the segment buttons will overflow and the user can swipe to see them.\nIn addition, this will disable the gesture to drag the indicator between the buttons\nin order to swipe to see hidden buttons."
      },
      "attribute": "scrollable",
      "reflect": false,
      "defaultValue": "false"
    },
    "swipeGesture": {
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
        "text": "If `true`, users will be able to swipe between segment buttons to activate them."
      },
      "attribute": "swipe-gesture",
      "reflect": false,
      "defaultValue": "true"
    },
    "value": {
      "type": "string",
      "mutable": true,
      "complexType": {
        "original": "string | null",
        "resolved": "null | string | undefined",
        "references": {}
      },
      "required": false,
      "optional": true,
      "docs": {
        "tags": [],
        "text": "the value of the segment."
      },
      "attribute": "value",
      "reflect": false
    }
  }; }
  static get states() { return {
    "activated": {}
  }; }
  static get events() { return [{
      "method": "ionChange",
      "name": "ionChange",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [],
        "text": "Emitted when the value property has changed and any\ndragging pointer has been released from `ion-segment`."
      },
      "complexType": {
        "original": "SegmentChangeEventDetail",
        "resolved": "SegmentChangeEventDetail",
        "references": {
          "SegmentChangeEventDetail": {
            "location": "import",
            "path": "../../interface"
          }
        }
      }
    }, {
      "method": "ionSelect",
      "name": "ionSelect",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [{
            "text": undefined,
            "name": "internal"
          }],
        "text": "Emitted when user has dragged over a new button"
      },
      "complexType": {
        "original": "SegmentChangeEventDetail",
        "resolved": "SegmentChangeEventDetail",
        "references": {
          "SegmentChangeEventDetail": {
            "location": "import",
            "path": "../../interface"
          }
        }
      }
    }, {
      "method": "ionStyle",
      "name": "ionStyle",
      "bubbles": true,
      "cancelable": true,
      "composed": true,
      "docs": {
        "tags": [{
            "text": undefined,
            "name": "internal"
          }],
        "text": "Emitted when the styles change."
      },
      "complexType": {
        "original": "StyleEventDetail",
        "resolved": "StyleEventDetail",
        "references": {
          "StyleEventDetail": {
            "location": "import",
            "path": "../../interface"
          }
        }
      }
    }]; }
  static get elementRef() { return "el"; }
  static get watchers() { return [{
      "propName": "color",
      "methodName": "colorChanged"
    }, {
      "propName": "swipeGesture",
      "methodName": "swipeGestureChanged"
    }, {
      "propName": "value",
      "methodName": "valueChanged"
    }, {
      "propName": "disabled",
      "methodName": "disabledChanged"
    }]; }
}
