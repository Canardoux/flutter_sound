import { Component, Host, h } from '@stencil/core';
import { getIonMode } from '../../global/ionic-global';
export class Thumbnail {
  render() {
    return (h(Host, { class: getIonMode(this) },
      h("slot", null)));
  }
  static get is() { return "ion-thumbnail"; }
  static get encapsulation() { return "shadow"; }
  static get originalStyleUrls() { return {
    "$": ["thumbnail.scss"]
  }; }
  static get styleUrls() { return {
    "$": ["thumbnail.css"]
  }; }
}
