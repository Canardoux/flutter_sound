package com.capacitorjs.plugins.filesystem;

import android.content.Context;
import android.net.Uri;
import android.os.Environment;
import android.util.Base64;
import com.capacitorjs.plugins.filesystem.exceptions.CopyFailedException;
import com.capacitorjs.plugins.filesystem.exceptions.DirectoryExistsException;
import com.capacitorjs.plugins.filesystem.exceptions.DirectoryNotFoundException;
import java.io.*;
import java.nio.channels.FileChannel;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;

public class Filesystem {

    private Context context;

    Filesystem(Context context) {
        this.context = context;
    }

    public String readFile(String path, String directory, Charset charset) throws IOException {
        InputStream is = getInputStream(path, directory);
        String dataStr;
        if (charset != null) {
            dataStr = readFileAsString(is, charset.name());
        } else {
            dataStr = readFileAsBase64EncodedData(is);
        }
        return dataStr;
    }

    public void saveFile(File file, String data, Charset charset, Boolean append) throws IOException {
        // if charset is not null assume its a plain text file the user wants to save
        if (charset != null) {
            BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(file, append), charset));
            writer.write(data);
            writer.close();
        } else {
            //remove header from dataURL
            if (data.contains(",")) {
                data = data.split(",")[1];
            }
            FileOutputStream fos = new FileOutputStream(file, append);
            fos.write(Base64.decode(data, Base64.NO_WRAP));
            fos.close();
        }
    }

    public boolean deleteFile(String file, String directory) throws FileNotFoundException {
        File fileObject = getFileObject(file, directory);
        if (!fileObject.exists()) {
            throw new FileNotFoundException("File does not exist");
        }
        return fileObject.delete();
    }

    public boolean mkdir(String path, String directory, Boolean recursive) throws DirectoryExistsException {
        File fileObject = getFileObject(path, directory);

        if (fileObject.exists()) {
            throw new DirectoryExistsException("Directory exists");
        }

        boolean created = false;
        if (recursive) {
            created = fileObject.mkdirs();
        } else {
            created = fileObject.mkdir();
        }
        return created;
    }

    public String[] readdir(String path, String directory) throws DirectoryNotFoundException {
        String[] files = null;
        File fileObject = getFileObject(path, directory);
        if (fileObject != null && fileObject.exists()) {
            files = fileObject.list();
        } else {
            throw new DirectoryNotFoundException("Directory does not exist");
        }
        return files;
    }

    public boolean copy(String from, String directory, String to, String toDirectory, boolean doRename)
        throws IOException, CopyFailedException {
        if (toDirectory == null) {
            toDirectory = directory;
        }

        File fromObject = getFileObject(from, directory);
        File toObject = getFileObject(to, toDirectory);

        if (fromObject == null) {
            throw new CopyFailedException("from file is null");
        }
        if (toObject == null) {
            throw new CopyFailedException("to file is null");
        }

        if (toObject.equals(fromObject)) {
            return true;
        }

        if (!fromObject.exists()) {
            throw new CopyFailedException("The source object does not exist");
        }

        if (toObject.getParentFile().isFile()) {
            throw new CopyFailedException("The parent object of the destination is a file");
        }

        if (!toObject.getParentFile().exists()) {
            throw new CopyFailedException("The parent object of the destination does not exist");
        }

        if (toObject.isDirectory()) {
            throw new CopyFailedException("Cannot overwrite a directory");
        }

        toObject.delete();

        if (doRename) {
            boolean modified = fromObject.renameTo(toObject);
            if (!modified) {
                throw new CopyFailedException("Unable to rename, unknown reason");
            }
        } else {
            copyRecursively(fromObject, toObject);
        }

        return true;
    }

    public InputStream getInputStream(String path, String directory) throws IOException {
        if (directory == null) {
            Uri u = Uri.parse(path);
            if (u.getScheme().equals("content")) {
                return this.context.getContentResolver().openInputStream(u);
            } else {
                return new FileInputStream(new File(u.getPath()));
            }
        }

        File androidDirectory = this.getDirectory(directory);

        if (androidDirectory == null) {
            throw new IOException("Directory not found");
        }

        return new FileInputStream(new File(androidDirectory, path));
    }

    public String readFileAsString(InputStream is, String encoding) throws IOException {
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();

        byte[] buffer = new byte[1024];
        int length = 0;

        while ((length = is.read(buffer)) != -1) {
            outputStream.write(buffer, 0, length);
        }

        return outputStream.toString(encoding);
    }

    public String readFileAsBase64EncodedData(InputStream is) throws IOException {
        FileInputStream fileInputStreamReader = (FileInputStream) is;
        ByteArrayOutputStream byteStream = new ByteArrayOutputStream();

        byte[] buffer = new byte[1024];

        int c;
        while ((c = fileInputStreamReader.read(buffer)) != -1) {
            byteStream.write(buffer, 0, c);
        }
        fileInputStreamReader.close();

        return Base64.encodeToString(byteStream.toByteArray(), Base64.NO_WRAP);
    }

    public File getDirectory(String directory) {
        Context c = this.context;
        switch (directory) {
            case "DOCUMENTS":
                return Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS);
            case "DATA":
                return c.getFilesDir();
            case "CACHE":
                return c.getCacheDir();
            case "EXTERNAL":
                return c.getExternalFilesDir(null);
            case "EXTERNAL_STORAGE":
                return Environment.getExternalStorageDirectory();
        }
        return null;
    }

    public File getFileObject(String path, String directory) {
        if (directory == null) {
            Uri u = Uri.parse(path);
            if (u.getScheme() == null || u.getScheme().equals("file")) {
                return new File(u.getPath());
            }
        }

        File androidDirectory = this.getDirectory(directory);

        if (androidDirectory == null) {
            return null;
        } else {
            if (!androidDirectory.exists()) {
                androidDirectory.mkdir();
            }
        }

        return new File(androidDirectory, path);
    }

    public Charset getEncoding(String encoding) {
        if (encoding == null) {
            return null;
        }

        switch (encoding) {
            case "utf8":
                return StandardCharsets.UTF_8;
            case "utf16":
                return StandardCharsets.UTF_16;
            case "ascii":
                return StandardCharsets.US_ASCII;
        }
        return null;
    }

    /**
     * Helper function to recursively delete a directory
     *
     * @param file The file or directory to recursively delete
     * @throws IOException
     */
    public void deleteRecursively(File file) throws IOException {
        if (file.isFile()) {
            file.delete();
            return;
        }

        for (File f : file.listFiles()) {
            deleteRecursively(f);
        }

        file.delete();
    }

    /**
     * Helper function to recursively copy a directory structure (or just a file)
     *
     * @param src The source location
     * @param dst The destination location
     * @throws IOException
     */
    public void copyRecursively(File src, File dst) throws IOException {
        if (src.isDirectory()) {
            dst.mkdir();

            for (String file : src.list()) {
                copyRecursively(new File(src, file), new File(dst, file));
            }

            return;
        }

        if (!dst.getParentFile().exists()) {
            dst.getParentFile().mkdirs();
        }

        if (!dst.exists()) {
            dst.createNewFile();
        }

        try (FileChannel source = new FileInputStream(src).getChannel(); FileChannel destination = new FileOutputStream(dst).getChannel()) {
            destination.transferFrom(source, 0, source.size());
        }
    }
}
