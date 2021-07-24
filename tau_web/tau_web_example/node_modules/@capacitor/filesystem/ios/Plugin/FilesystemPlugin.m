#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(FilesystemPlugin, "Filesystem",
           CAP_PLUGIN_METHOD(readFile, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(writeFile, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(appendFile, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(deleteFile, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(mkdir, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(rmdir, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(readdir, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(getUri, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(stat, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(rename, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(copy, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(checkPermissions, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(requestPermissions, CAPPluginReturnPromise);
)
