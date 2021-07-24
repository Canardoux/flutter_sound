import { a as patchEsm, b as bootstrapLazy } from './core-f86805ad.js';

const defineCustomElements = (win, options) => {
  return patchEsm().then(() => {
    bootstrapLazy([["pwa-camera-modal",[[1,"pwa-camera-modal",{"present":[64],"dismiss":[64]}]]],["pwa-action-sheet",[[1,"pwa-action-sheet",{"header":[1],"cancelable":[4],"options":[16],"open":[32]}]]],["pwa-toast",[[1,"pwa-toast",{"message":[1],"duration":[2],"closing":[32]}]]],["pwa-camera",[[1,"pwa-camera",{"facingMode":[1,"facing-mode"],"handlePhoto":[16],"handleNoDeviceError":[16],"noDevicesText":[1,"no-devices-text"],"noDevicesButtonText":[1,"no-devices-button-text"],"photo":[32],"photoSrc":[32],"showShutterOverlay":[32],"flashIndex":[32],"hasCamera":[32],"rotation":[32],"deviceError":[32]}]]],["pwa-camera-modal-instance",[[1,"pwa-camera-modal-instance",{"noDevicesText":[1,"no-devices-text"],"noDevicesButtonText":[1,"no-devices-button-text"]},[[32,"keyup","handleBackdropKeyUp"]]]]]], options);
  });
};

export { defineCustomElements };
