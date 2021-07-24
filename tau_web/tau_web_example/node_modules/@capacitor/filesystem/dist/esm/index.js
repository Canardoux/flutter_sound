import { registerPlugin } from '@capacitor/core';
const Filesystem = registerPlugin('Filesystem', {
    web: () => import('./web').then(m => new m.FilesystemWeb()),
});
export * from './definitions';
export { Filesystem };
//# sourceMappingURL=index.js.map