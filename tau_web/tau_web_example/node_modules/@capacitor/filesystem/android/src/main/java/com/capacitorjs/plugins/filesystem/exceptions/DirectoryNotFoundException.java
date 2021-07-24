package com.capacitorjs.plugins.filesystem.exceptions;

public class DirectoryNotFoundException extends Exception {

    public DirectoryNotFoundException(String s) {
        super(s);
    }

    public DirectoryNotFoundException(Throwable t) {
        super(t);
    }

    public DirectoryNotFoundException(String s, Throwable t) {
        super(s, t);
    }
}
