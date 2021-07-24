import { Component, Host, h } from '@stencil/core';
import { getIonMode } from '../../global/ionic-global';
export class Slide {
  render() {
    const mode = getIonMode(this);
    return (h(Host, { class: {
        [mode]: true,
        'swiper-slide': true,
        'swiper-zoom-container': true
      } }));
  }
  static get is() { return "ion-slide"; }
  static get originalStyleUrls() { return {
    "$": ["slide.scss"]
  }; }
  static get styleUrls() { return {
    "$": ["slide.css"]
  }; }
}
