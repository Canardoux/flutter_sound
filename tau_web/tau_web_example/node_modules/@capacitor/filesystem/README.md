# @capacitor/filesystem

The Filesystem API provides a NodeJS-like API for working with files on the device.

## Install

```bash
npm install @capacitor/filesystem
npx cap sync
```

## Android

If using <a href="#directory">`Directory.Documents`</a> or
`Directory.ExternalStorage`, this API requires the following permissions be added to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

Read about [Setting Permissions](https://capacitorjs.com/docs/android/configuration#setting-permissions) in the [Android Guide](https://capacitorjs.com/docs/android) for more information on setting Android permissions.

Note that <a href="#directory">`Directory.Documents`</a> and
`Directory.ExternalStorage` are only available on Android 9 or older.

## Understanding Directories and Files

iOS and Android have additional layers of separation between files, such as special directories that are backed up to the Cloud, or ones for storing Documents. The Filesystem API offers a simple way to scope each operation to a specific special directory on the device.

Additionally, the Filesystem API supports using full `file://` paths, or reading `content://` files on Android. Simply leave out the `directory` param to use a full file path.

## Example

```typescript
import { Filesystem, Directory, Encoding } from '@capacitor/filesystem';

const writeSecretFile = async () => {
  await Filesystem.writeFile({
    path: 'secrets/text.txt',
    data: "This is a test",
    directory: Directory.Documents,
    encoding: Encoding.UTF8,
  });
};

const readSecretFile = async () => {
  const contents = await Filesystem.readFile({
    path: 'secrets/text.txt',
    directory: Directory.Documents,
    encoding: Encoding.UTF8,
  });

  console.log('secrets:', contents);
};

const deleteSecretFile = async () => {
  await Filesystem.deleteFile({
    path: 'secrets/text.txt',
    directory: Directory.Documents,
  });
};

const readFilePath = async () => {
  // Here's an example of reading a file with a full file path. Use this to
  // read binary data (base64 encoded) from plugins that return File URIs, such as
  // the Camera.
  const contents = await Filesystem.readFile({
    path: 'file:///var/mobile/Containers/Data/Application/22A433FD-D82D-4989-8BE6-9FC49DEA20BB/Documents/text.txt'
  });

  console.log('data:', contents);
};
```

## API

<docgen-index>

* [`readFile(...)`](#readfile)
* [`writeFile(...)`](#writefile)
* [`appendFile(...)`](#appendfile)
* [`deleteFile(...)`](#deletefile)
* [`mkdir(...)`](#mkdir)
* [`rmdir(...)`](#rmdir)
* [`readdir(...)`](#readdir)
* [`getUri(...)`](#geturi)
* [`stat(...)`](#stat)
* [`rename(...)`](#rename)
* [`copy(...)`](#copy)
* [`checkPermissions()`](#checkpermissions)
* [`requestPermissions()`](#requestpermissions)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)
* [Enums](#enums)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### readFile(...)

```typescript
readFile(options: ReadFileOptions) => Promise<ReadFileResult>
```

Read a file from disk

| Param         | Type                                                        |
| ------------- | ----------------------------------------------------------- |
| **`options`** | <code><a href="#readfileoptions">ReadFileOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#readfileresult">ReadFileResult</a>&gt;</code>

**Since:** 1.0.0

--------------------


### writeFile(...)

```typescript
writeFile(options: WriteFileOptions) => Promise<WriteFileResult>
```

Write a file to disk in the specified location on device

| Param         | Type                                                          |
| ------------- | ------------------------------------------------------------- |
| **`options`** | <code><a href="#writefileoptions">WriteFileOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#writefileresult">WriteFileResult</a>&gt;</code>

**Since:** 1.0.0

--------------------


### appendFile(...)

```typescript
appendFile(options: AppendFileOptions) => Promise<void>
```

Append to a file on disk in the specified location on device

| Param         | Type                                                            |
| ------------- | --------------------------------------------------------------- |
| **`options`** | <code><a href="#appendfileoptions">AppendFileOptions</a></code> |

**Since:** 1.0.0

--------------------


### deleteFile(...)

```typescript
deleteFile(options: DeleteFileOptions) => Promise<void>
```

Delete a file from disk

| Param         | Type                                                            |
| ------------- | --------------------------------------------------------------- |
| **`options`** | <code><a href="#deletefileoptions">DeleteFileOptions</a></code> |

**Since:** 1.0.0

--------------------


### mkdir(...)

```typescript
mkdir(options: MkdirOptions) => Promise<void>
```

Create a directory.

| Param         | Type                                                  |
| ------------- | ----------------------------------------------------- |
| **`options`** | <code><a href="#mkdiroptions">MkdirOptions</a></code> |

**Since:** 1.0.0

--------------------


### rmdir(...)

```typescript
rmdir(options: RmdirOptions) => Promise<void>
```

Remove a directory

| Param         | Type                                                  |
| ------------- | ----------------------------------------------------- |
| **`options`** | <code><a href="#rmdiroptions">RmdirOptions</a></code> |

**Since:** 1.0.0

--------------------


### readdir(...)

```typescript
readdir(options: ReaddirOptions) => Promise<ReaddirResult>
```

Return a list of files from the directory (not recursive)

| Param         | Type                                                      |
| ------------- | --------------------------------------------------------- |
| **`options`** | <code><a href="#readdiroptions">ReaddirOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#readdirresult">ReaddirResult</a>&gt;</code>

**Since:** 1.0.0

--------------------


### getUri(...)

```typescript
getUri(options: GetUriOptions) => Promise<GetUriResult>
```

Return full File URI for a path and directory

| Param         | Type                                                    |
| ------------- | ------------------------------------------------------- |
| **`options`** | <code><a href="#geturioptions">GetUriOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#geturiresult">GetUriResult</a>&gt;</code>

**Since:** 1.0.0

--------------------


### stat(...)

```typescript
stat(options: StatOptions) => Promise<StatResult>
```

Return data about a file

| Param         | Type                                                |
| ------------- | --------------------------------------------------- |
| **`options`** | <code><a href="#statoptions">StatOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#statresult">StatResult</a>&gt;</code>

**Since:** 1.0.0

--------------------


### rename(...)

```typescript
rename(options: RenameOptions) => Promise<void>
```

Rename a file or directory

| Param         | Type                                                |
| ------------- | --------------------------------------------------- |
| **`options`** | <code><a href="#copyoptions">CopyOptions</a></code> |

**Since:** 1.0.0

--------------------


### copy(...)

```typescript
copy(options: CopyOptions) => Promise<void>
```

Copy a file or directory

| Param         | Type                                                |
| ------------- | --------------------------------------------------- |
| **`options`** | <code><a href="#copyoptions">CopyOptions</a></code> |

**Since:** 1.0.0

--------------------


### checkPermissions()

```typescript
checkPermissions() => Promise<PermissionStatus>
```

Check read/write permissions.
Required on Android, only when using <a href="#directory">`Directory.Documents`</a> or
`Directory.ExternalStorage`.

**Returns:** <code>Promise&lt;<a href="#permissionstatus">PermissionStatus</a>&gt;</code>

**Since:** 1.0.0

--------------------


### requestPermissions()

```typescript
requestPermissions() => Promise<PermissionStatus>
```

Request read/write permissions.
Required on Android, only when using <a href="#directory">`Directory.Documents`</a> or
`Directory.ExternalStorage`.

**Returns:** <code>Promise&lt;<a href="#permissionstatus">PermissionStatus</a>&gt;</code>

**Since:** 1.0.0

--------------------


### Interfaces


#### ReadFileResult

| Prop       | Type                | Description                                                 | Since |
| ---------- | ------------------- | ----------------------------------------------------------- | ----- |
| **`data`** | <code>string</code> | The string representation of the data contained in the file | 1.0.0 |


#### ReadFileOptions

| Prop            | Type                                            | Description                                                                                                                                                                 | Since |
| --------------- | ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| **`path`**      | <code>string</code>                             | The path of the file to read                                                                                                                                                | 1.0.0 |
| **`directory`** | <code><a href="#directory">Directory</a></code> | The <a href="#directory">`Directory`</a> to read the file from                                                                                                              | 1.0.0 |
| **`encoding`**  | <code><a href="#encoding">Encoding</a></code>   | The encoding to read the file in, if not provided, data is read as binary and returned as base64 encoded. Pass <a href="#encoding">Encoding.UTF8</a> to read data as string | 1.0.0 |


#### WriteFileResult

| Prop      | Type                | Description                             | Since |
| --------- | ------------------- | --------------------------------------- | ----- |
| **`uri`** | <code>string</code> | The uri where the file was written into | 1.0.0 |


#### WriteFileOptions

| Prop            | Type                                            | Description                                                                                                                                               | Default            | Since |
| --------------- | ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ----- |
| **`path`**      | <code>string</code>                             | The path of the file to write                                                                                                                             |                    | 1.0.0 |
| **`data`**      | <code>string</code>                             | The data to write                                                                                                                                         |                    | 1.0.0 |
| **`directory`** | <code><a href="#directory">Directory</a></code> | The <a href="#directory">`Directory`</a> to store the file in                                                                                             |                    | 1.0.0 |
| **`encoding`**  | <code><a href="#encoding">Encoding</a></code>   | The encoding to write the file in. If not provided, data is written as base64 encoded. Pass <a href="#encoding">Encoding.UTF8</a> to write data as string |                    | 1.0.0 |
| **`recursive`** | <code>boolean</code>                            | Whether to create any missing parent directories.                                                                                                         | <code>false</code> | 1.0.0 |


#### AppendFileOptions

| Prop            | Type                                            | Description                                                                                                                                               | Since |
| --------------- | ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| **`path`**      | <code>string</code>                             | The path of the file to append                                                                                                                            | 1.0.0 |
| **`data`**      | <code>string</code>                             | The data to write                                                                                                                                         | 1.0.0 |
| **`directory`** | <code><a href="#directory">Directory</a></code> | The <a href="#directory">`Directory`</a> to store the file in                                                                                             | 1.0.0 |
| **`encoding`**  | <code><a href="#encoding">Encoding</a></code>   | The encoding to write the file in. If not provided, data is written as base64 encoded. Pass <a href="#encoding">Encoding.UTF8</a> to write data as string | 1.0.0 |


#### DeleteFileOptions

| Prop            | Type                                            | Description                                                      | Since |
| --------------- | ----------------------------------------------- | ---------------------------------------------------------------- | ----- |
| **`path`**      | <code>string</code>                             | The path of the file to delete                                   | 1.0.0 |
| **`directory`** | <code><a href="#directory">Directory</a></code> | The <a href="#directory">`Directory`</a> to delete the file from | 1.0.0 |


#### MkdirOptions

| Prop            | Type                                            | Description                                                           | Default            | Since |
| --------------- | ----------------------------------------------- | --------------------------------------------------------------------- | ------------------ | ----- |
| **`path`**      | <code>string</code>                             | The path of the new directory                                         |                    | 1.0.0 |
| **`directory`** | <code><a href="#directory">Directory</a></code> | The <a href="#directory">`Directory`</a> to make the new directory in |                    | 1.0.0 |
| **`recursive`** | <code>boolean</code>                            | Whether to create any missing parent directories as well.             | <code>false</code> | 1.0.0 |


#### RmdirOptions

| Prop            | Type                                            | Description                                                           | Default            | Since |
| --------------- | ----------------------------------------------- | --------------------------------------------------------------------- | ------------------ | ----- |
| **`path`**      | <code>string</code>                             | The path of the directory to remove                                   |                    | 1.0.0 |
| **`directory`** | <code><a href="#directory">Directory</a></code> | The <a href="#directory">`Directory`</a> to remove the directory from |                    | 1.0.0 |
| **`recursive`** | <code>boolean</code>                            | Whether to recursively remove the contents of the directory           | <code>false</code> | 1.0.0 |


#### ReaddirResult

| Prop        | Type                  | Description                                        | Since |
| ----------- | --------------------- | -------------------------------------------------- | ----- |
| **`files`** | <code>string[]</code> | List of files and directories inside the directory | 1.0.0 |


#### ReaddirOptions

| Prop            | Type                                            | Description                                                 | Since |
| --------------- | ----------------------------------------------- | ----------------------------------------------------------- | ----- |
| **`path`**      | <code>string</code>                             | The path of the directory to read                           | 1.0.0 |
| **`directory`** | <code><a href="#directory">Directory</a></code> | The <a href="#directory">`Directory`</a> to list files from | 1.0.0 |


#### GetUriResult

| Prop      | Type                | Description         | Since |
| --------- | ------------------- | ------------------- | ----- |
| **`uri`** | <code>string</code> | The uri of the file | 1.0.0 |


#### GetUriOptions

| Prop            | Type                                            | Description                                                    | Since |
| --------------- | ----------------------------------------------- | -------------------------------------------------------------- | ----- |
| **`path`**      | <code>string</code>                             | The path of the file to get the URI for                        | 1.0.0 |
| **`directory`** | <code><a href="#directory">Directory</a></code> | The <a href="#directory">`Directory`</a> to get the file under | 1.0.0 |


#### StatResult

| Prop        | Type                | Description                                                                          | Since |
| ----------- | ------------------- | ------------------------------------------------------------------------------------ | ----- |
| **`type`**  | <code>string</code> | Type of the file                                                                     | 1.0.0 |
| **`size`**  | <code>number</code> | Size of the file                                                                     | 1.0.0 |
| **`ctime`** | <code>number</code> | Time of creation in milliseconds. It's not available on Android 7 and older devices. | 1.0.0 |
| **`mtime`** | <code>number</code> | Time of last modification in milliseconds.                                           | 1.0.0 |
| **`uri`**   | <code>string</code> | The uri of the file                                                                  | 1.0.0 |


#### StatOptions

| Prop            | Type                                            | Description                                                    | Since |
| --------------- | ----------------------------------------------- | -------------------------------------------------------------- | ----- |
| **`path`**      | <code>string</code>                             | The path of the file to get data about                         | 1.0.0 |
| **`directory`** | <code><a href="#directory">Directory</a></code> | The <a href="#directory">`Directory`</a> to get the file under | 1.0.0 |


#### CopyOptions

| Prop              | Type                                            | Description                                                                                                                                                  | Since |
| ----------------- | ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----- |
| **`from`**        | <code>string</code>                             | The existing file or directory                                                                                                                               | 1.0.0 |
| **`to`**          | <code>string</code>                             | The destination file or directory                                                                                                                            | 1.0.0 |
| **`directory`**   | <code><a href="#directory">Directory</a></code> | The <a href="#directory">`Directory`</a> containing the existing file or directory                                                                           | 1.0.0 |
| **`toDirectory`** | <code><a href="#directory">Directory</a></code> | The <a href="#directory">`Directory`</a> containing the destination file or directory. If not supplied will use the 'directory' parameter as the destination | 1.0.0 |


#### PermissionStatus

| Prop                | Type                                                        |
| ------------------- | ----------------------------------------------------------- |
| **`publicStorage`** | <code><a href="#permissionstate">PermissionState</a></code> |


### Type Aliases


#### RenameOptions

<code><a href="#copyoptions">CopyOptions</a></code>


#### PermissionState

<code>'prompt' | 'prompt-with-rationale' | 'granted' | 'denied'</code>


### Enums


#### Directory

| Members               | Value                           | Description                                                                                                                                                                                                                                                                                                                                                                                                                                       | Since |
| --------------------- | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| **`Documents`**       | <code>'DOCUMENTS'</code>        | The Documents directory On iOS it's the app's documents directory. Use this directory to store user-generated content. On Android it's the Public Documents folder, so it's accessible from other apps. It's not accesible on Android 10 unless the app enables legacy External Storage by adding `android:requestLegacyExternalStorage="true"` in the `application` tag in the `AndroidManifest.xml`. It's not accesible on Android 11 or newer. | 1.0.0 |
| **`Data`**            | <code>'DATA'</code>             | The Data directory On iOS it will use the Documents directory On Android it's the directory holding application files. Files will be deleted when the application is uninstalled.                                                                                                                                                                                                                                                                 | 1.0.0 |
| **`Cache`**           | <code>'CACHE'</code>            | The Cache directory Can be deleted in cases of low memory, so use this directory to write app-specific files that your app can re-create easily.                                                                                                                                                                                                                                                                                                  | 1.0.0 |
| **`External`**        | <code>'EXTERNAL'</code>         | The external directory On iOS it will use the Documents directory On Android it's the directory on the primary shared/external storage device where the application can place persistent files it owns. These files are internal to the applications, and not typically visible to the user as media. Files will be deleted when the application is uninstalled.                                                                                  | 1.0.0 |
| **`ExternalStorage`** | <code>'EXTERNAL_STORAGE'</code> | The external storage directory On iOS it will use the Documents directory On Android it's the primary shared/external storage directory. It's not accesible on Android 10 unless the app enables legacy External Storage by adding `android:requestLegacyExternalStorage="true"` in the `application` tag in the `AndroidManifest.xml`. It's not accesible on Android 11 or newer.                                                                | 1.0.0 |


#### Encoding

| Members     | Value                | Description                                                                                                                              | Since |
| ----------- | -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| **`UTF8`**  | <code>'utf8'</code>  | Eight-bit UCS Transformation Format                                                                                                      | 1.0.0 |
| **`ASCII`** | <code>'ascii'</code> | Seven-bit ASCII, a.k.a. ISO646-US, a.k.a. the Basic Latin block of the Unicode character set This encoding is only supported on Android. | 1.0.0 |
| **`UTF16`** | <code>'utf16'</code> | Sixteen-bit UCS Transformation Format, byte order identified by an optional byte-order mark This encoding is only supported on Android.  | 1.0.0 |

</docgen-api>
