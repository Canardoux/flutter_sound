package com.capacitorjs.plugins.storage;

public class StorageConfiguration implements Cloneable {

    static final StorageConfiguration DEFAULTS;

    static {
        DEFAULTS = new StorageConfiguration();
        DEFAULTS.group = "CapacitorStorage";
    }

    String group;

    @Override
    public StorageConfiguration clone() throws CloneNotSupportedException {
        return (StorageConfiguration) super.clone();
    }
}
