"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.runOnDevice = exports.getConnectedDevices = void 0;
const Debug = require("debug");
const fs_1 = require("fs");
const path = require("path");
const errors_1 = require("../../errors");
const process_1 = require("../../utils/process");
const lib_1 = require("../lib");
const xcode_1 = require("./xcode");
const debug = Debug('native-run:ios:utils:device');
async function getConnectedDevices() {
    const usbmuxClient = new lib_1.UsbmuxdClient(lib_1.UsbmuxdClient.connectUsbmuxdSocket());
    const usbmuxDevices = await usbmuxClient.getDevices();
    usbmuxClient.socket.end();
    return Promise.all(usbmuxDevices.map(async (d) => {
        const socket = await new lib_1.UsbmuxdClient(lib_1.UsbmuxdClient.connectUsbmuxdSocket()).connect(d, 62078);
        const device = await new lib_1.LockdowndClient(socket).getAllValues();
        socket.end();
        return device;
    }));
}
exports.getConnectedDevices = getConnectedDevices;
async function runOnDevice(udid, appPath, bundleId, waitForApp) {
    const clientManager = await lib_1.ClientManager.create(udid);
    try {
        await mountDeveloperDiskImage(clientManager);
        const packageName = path.basename(appPath);
        const destPackagePath = path.join('PublicStaging', packageName);
        await uploadApp(clientManager, appPath, destPackagePath);
        const installer = await clientManager.getInstallationProxyClient();
        await installer.installApp(destPackagePath, bundleId);
        const { [bundleId]: appInfo } = await installer.lookupApp([bundleId]);
        // launch fails with EBusy or ENotFound if you try to launch immediately after install
        await process_1.wait(200);
        const debugServerClient = await launchApp(clientManager, appInfo);
        if (waitForApp) {
            process_1.onBeforeExit(async () => {
                // causes continue() to return
                debugServerClient.halt();
                // give continue() time to return response
                await process_1.wait(64);
            });
            debug(`Waiting for app to close...\n`);
            const result = await debugServerClient.continue();
            // TODO: I have no idea what this packet means yet (successful close?)
            // if not a close (ie, most likely due to halt from onBeforeExit), then kill the app
            if (result !== 'W00') {
                await debugServerClient.kill();
            }
        }
    }
    finally {
        clientManager.end();
    }
}
exports.runOnDevice = runOnDevice;
async function mountDeveloperDiskImage(clientManager) {
    const imageMounter = await clientManager.getMobileImageMounterClient();
    // Check if already mounted. If not, mount.
    if (!(await imageMounter.lookupImage()).ImageSignature) {
        // verify DeveloperDiskImage exists (TODO: how does this work on Windows/Linux?)
        // TODO: if windows/linux, download?
        const version = await (await clientManager.getLockdowndClient()).getValue('ProductVersion');
        const developerDiskImagePath = await xcode_1.getDeveloperDiskImagePath(version);
        const developerDiskImageSig = fs_1.readFileSync(`${developerDiskImagePath}.signature`);
        await imageMounter.uploadImage(developerDiskImagePath, developerDiskImageSig);
        await imageMounter.mountImage(developerDiskImagePath, developerDiskImageSig);
    }
}
async function uploadApp(clientManager, srcPath, destinationPath) {
    const afcClient = await clientManager.getAFCClient();
    try {
        await afcClient.getFileInfo('PublicStaging');
    }
    catch (err) {
        if (err instanceof lib_1.AFCError && err.status === lib_1.AFC_STATUS.OBJECT_NOT_FOUND) {
            await afcClient.makeDirectory('PublicStaging');
        }
        else {
            throw err;
        }
    }
    await afcClient.uploadDirectory(srcPath, destinationPath);
}
async function launchApp(clientManager, appInfo) {
    let tries = 0;
    while (tries < 3) {
        const debugServerClient = await clientManager.getDebugserverClient();
        await debugServerClient.setMaxPacketSize(1024);
        await debugServerClient.setWorkingDir(appInfo.Container);
        await debugServerClient.launchApp(appInfo.Path, appInfo.CFBundleExecutable);
        const result = await debugServerClient.checkLaunchSuccess();
        if (result === 'OK') {
            return debugServerClient;
        }
        else if (result === 'EBusy' || result === 'ENotFound') {
            debug('Device busy or app not found, trying to launch again in .5s...');
            tries++;
            debugServerClient.socket.end();
            await process_1.wait(500);
        }
        else {
            throw new errors_1.Exception(`There was an error launching app: ${result}`);
        }
    }
    throw new errors_1.Exception('Unable to launch app, number of tries exceeded');
}
