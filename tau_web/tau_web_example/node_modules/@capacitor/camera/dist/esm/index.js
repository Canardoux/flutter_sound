import { registerPlugin } from '@capacitor/core';
const Camera = registerPlugin('Camera', {
    web: () => import('./web').then(m => new m.CameraWeb()),
});
export * from './definitions';
export { Camera };
//# sourceMappingURL=index.js.map