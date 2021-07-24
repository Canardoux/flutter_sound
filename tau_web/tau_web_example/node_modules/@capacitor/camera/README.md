# @capacitor/camera

The Camera API provides the ability to take a photo with the camera or choose an existing one from the photo album.

## Install

```bash
npm install @capacitor/camera
npx cap sync
```

## iOS

iOS requires the following usage description be added and filled out for your app in `Info.plist`:

- `NSCameraUsageDescription` (`Privacy - Camera Usage Description`)
- `NSPhotoLibraryAddUsageDescription` (`Privacy - Photo Library Additions Usage Description`)
- `NSPhotoLibraryUsageDescription` (`Privacy - Photo Library Usage Description`)

Read about [Configuring `Info.plist`](https://capacitorjs.com/docs/ios/configuration#configuring-infoplist) in the [iOS Guide](https://capacitorjs.com/docs/ios) for more information on setting iOS permissions in Xcode

## Android

This API requires the following permissions be added to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

The storage permissions are for reading/saving photo files.

Read about [Setting Permissions](https://capacitorjs.com/docs/android/configuration#setting-permissions) in the [Android Guide](https://capacitorjs.com/docs/android) for more information on setting Android permissions.

Additionally, because the Camera API launches a separate Activity to handle taking the photo, you should listen for `appRestoredResult` in the `App` plugin to handle any camera data that was sent in the case your app was terminated by the operating system while the Activity was running.

### Variables

This plugin will use the following project variables (defined in your app's `variables.gradle` file):

- `$androidxExifInterfaceVersion`: version of `androidx.exifinterface:exifinterface` (default: `1.3.2`)
- `$androidxMaterialVersion`: version of `com.google.android.material:material` (default: `1.3.0`)

## PWA Notes

[PWA Elements](https://capacitorjs.com/docs/web/pwa-elements) are required for Camera plugin to work.

## Example

```typescript
import { Camera, CameraResultType } from '@capacitor/camera';

const takePicture = async () => {
  const image = await Camera.getPhoto({
    quality: 90,
    allowEditing: true,
    resultType: CameraResultType.Uri
  });

  // image.webPath will contain a path that can be set as an image src.
  // You can access the original file using image.path, which can be
  // passed to the Filesystem API to read the raw data of the image,
  // if desired (or pass resultType: CameraResultType.Base64 to getPhoto)
  var imageUrl = image.webPath;

  // Can be set to the src of an image now
  imageElement.src = imageUrl;
};
```

## API

<docgen-index>

* [`getPhoto(...)`](#getphoto)
* [`checkPermissions()`](#checkpermissions)
* [`requestPermissions(...)`](#requestpermissions)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)
* [Enums](#enums)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### getPhoto(...)

```typescript
getPhoto(options: ImageOptions) => Promise<Photo>
```

Prompt the user to pick a photo from an album, or take a new photo
with the camera.

| Param         | Type                                                  |
| ------------- | ----------------------------------------------------- |
| **`options`** | <code><a href="#imageoptions">ImageOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#photo">Photo</a>&gt;</code>

**Since:** 1.0.0

--------------------


### checkPermissions()

```typescript
checkPermissions() => Promise<PermissionStatus>
```

Check camera and photo album permissions

**Returns:** <code>Promise&lt;<a href="#permissionstatus">PermissionStatus</a>&gt;</code>

**Since:** 1.0.0

--------------------


### requestPermissions(...)

```typescript
requestPermissions(permissions?: CameraPluginPermissions | undefined) => Promise<PermissionStatus>
```

Request camera and photo album permissions

| Param             | Type                                                                        |
| ----------------- | --------------------------------------------------------------------------- |
| **`permissions`** | <code><a href="#camerapluginpermissions">CameraPluginPermissions</a></code> |

**Returns:** <code>Promise&lt;<a href="#permissionstatus">PermissionStatus</a>&gt;</code>

**Since:** 1.0.0

--------------------


### Interfaces


#### Photo

| Prop               | Type                | Description                                                                                                                                                                   | Since |
| ------------------ | ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| **`base64String`** | <code>string</code> | The base64 encoded string representation of the image, if using <a href="#cameraresulttype">CameraResultType.Base64</a>.                                                      | 1.0.0 |
| **`dataUrl`**      | <code>string</code> | The url starting with 'data:image/jpeg;base64,' and the base64 encoded string representation of the image, if using <a href="#cameraresulttype">CameraResultType.DataUrl</a>. | 1.0.0 |
| **`path`**         | <code>string</code> | If using <a href="#cameraresulttype">CameraResultType.Uri</a>, the path will contain a full, platform-specific file URL that can be read later using the Filsystem API.       | 1.0.0 |
| **`webPath`**      | <code>string</code> | webPath returns a path that can be used to set the src attribute of an image for efficient loading and rendering.                                                             | 1.0.0 |
| **`exif`**         | <code>any</code>    | Exif data, if any, retrieved from the image                                                                                                                                   | 1.0.0 |
| **`format`**       | <code>string</code> | The format of the image, ex: jpeg, png, gif. iOS and Android only support jpeg. Web supports jpeg and png. gif is only supported if using file input.                         | 1.0.0 |


#### ImageOptions

| Prop                      | Type                                                          | Description                                                                                                                                                                                                                                                            | Default                             | Since |
| ------------------------- | ------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- | ----- |
| **`quality`**             | <code>number</code>                                           | The quality of image to return as JPEG, from 0-100                                                                                                                                                                                                                     |                                     | 1.0.0 |
| **`allowEditing`**        | <code>boolean</code>                                          | Whether to allow the user to crop or make small edits (platform specific)                                                                                                                                                                                              |                                     | 1.0.0 |
| **`resultType`**          | <code><a href="#cameraresulttype">CameraResultType</a></code> | How the data should be returned. Currently, only 'Base64', 'DataUrl' or 'Uri' is supported                                                                                                                                                                             |                                     | 1.0.0 |
| **`saveToGallery`**       | <code>boolean</code>                                          | Whether to save the photo to the gallery. If the photo was picked from the gallery, it will only be saved if edited.                                                                                                                                                   | <code>: false</code>                | 1.0.0 |
| **`width`**               | <code>number</code>                                           | The width of the saved image                                                                                                                                                                                                                                           |                                     | 1.0.0 |
| **`height`**              | <code>number</code>                                           | The height of the saved image                                                                                                                                                                                                                                          |                                     | 1.0.0 |
| **`preserveAspectRatio`** | <code>boolean</code>                                          | This setting has no effect. Picture resizing always preserve aspect ratio.                                                                                                                                                                                             |                                     | 1.0.0 |
| **`correctOrientation`**  | <code>boolean</code>                                          | Whether to automatically rotate the image "up" to correct for orientation in portrait mode                                                                                                                                                                             | <code>: true</code>                 | 1.0.0 |
| **`source`**              | <code><a href="#camerasource">CameraSource</a></code>         | The source to get the photo from. By default this prompts the user to select either the photo album or take a photo.                                                                                                                                                   | <code>: CameraSource.Prompt</code>  | 1.0.0 |
| **`direction`**           | <code><a href="#cameradirection">CameraDirection</a></code>   | iOS and Web only: The camera direction.                                                                                                                                                                                                                                | <code>: CameraDirection.Rear</code> | 1.0.0 |
| **`presentationStyle`**   | <code>'fullscreen' \| 'popover'</code>                        | iOS only: The presentation style of the Camera.                                                                                                                                                                                                                        | <code>: 'fullscreen'</code>         | 1.0.0 |
| **`webUseInput`**         | <code>boolean</code>                                          | Web only: Whether to use the PWA Element experience or file input. The default is to use PWA Elements if installed and fall back to file input. To always use file input, set this to `true`. Learn more about PWA Elements: https://capacitorjs.com/docs/pwa-elements |                                     | 1.0.0 |
| **`promptLabelHeader`**   | <code>string</code>                                           | Text value to use when displaying the prompt.                                                                                                                                                                                                                          | <code>: 'Photo'</code>              | 1.0.0 |
| **`promptLabelCancel`**   | <code>string</code>                                           | Text value to use when displaying the prompt. iOS only: The label of the 'cancel' button.                                                                                                                                                                              | <code>: 'Cancel'</code>             | 1.0.0 |
| **`promptLabelPhoto`**    | <code>string</code>                                           | Text value to use when displaying the prompt. The label of the button to select a saved image.                                                                                                                                                                         | <code>: 'From Photos'</code>        | 1.0.0 |
| **`promptLabelPicture`**  | <code>string</code>                                           | Text value to use when displaying the prompt. The label of the button to open the camera.                                                                                                                                                                              | <code>: 'Take Picture'</code>       | 1.0.0 |


#### PermissionStatus

| Prop         | Type                                                                    |
| ------------ | ----------------------------------------------------------------------- |
| **`camera`** | <code><a href="#camerapermissionstate">CameraPermissionState</a></code> |
| **`photos`** | <code><a href="#camerapermissionstate">CameraPermissionState</a></code> |


#### CameraPluginPermissions

| Prop              | Type                                |
| ----------------- | ----------------------------------- |
| **`permissions`** | <code>CameraPermissionType[]</code> |


### Type Aliases


#### CameraPermissionState

<code><a href="#permissionstate">PermissionState</a> | 'limited'</code>


#### PermissionState

<code>'prompt' | 'prompt-with-rationale' | 'granted' | 'denied'</code>


#### CameraPermissionType

<code>'camera' | 'photos'</code>


### Enums


#### CameraResultType

| Members       | Value                  |
| ------------- | ---------------------- |
| **`Uri`**     | <code>'uri'</code>     |
| **`Base64`**  | <code>'base64'</code>  |
| **`DataUrl`** | <code>'dataUrl'</code> |


#### CameraSource

| Members      | Value                 |
| ------------ | --------------------- |
| **`Prompt`** | <code>'PROMPT'</code> |
| **`Camera`** | <code>'CAMERA'</code> |
| **`Photos`** | <code>'PHOTOS'</code> |


#### CameraDirection

| Members     | Value                |
| ----------- | -------------------- |
| **`Rear`**  | <code>'REAR'</code>  |
| **`Front`** | <code>'FRONT'</code> |

</docgen-api>
