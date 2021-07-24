import { registerPlugin } from '@capacitor/core';
const Storage = registerPlugin('Storage', {
    web: () => import('./web').then(m => new m.StorageWeb()),
});
export * from './definitions';
export { Storage };
//# sourceMappingURL=index.js.map