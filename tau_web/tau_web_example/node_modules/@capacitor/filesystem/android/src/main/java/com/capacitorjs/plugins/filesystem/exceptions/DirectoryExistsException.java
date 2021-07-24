package com.capacitorjs.plugins.filesystem.exceptions;

public class DirectoryExistsException extends Exception {

    public DirectoryExistsException(String s) {
        super(s);
    }

    public DirectoryExistsException(Throwable t) {
        super(t);
    }

    public DirectoryExistsException(String s, Throwable t) {
        super(s, t);
    }
}
