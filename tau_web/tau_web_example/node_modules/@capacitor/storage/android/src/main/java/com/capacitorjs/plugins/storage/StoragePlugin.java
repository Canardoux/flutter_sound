package com.capacitorjs.plugins.storage;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import org.json.JSONException;

@CapacitorPlugin(name = "Storage")
public class StoragePlugin extends Plugin {

    private Storage storage;

    @Override
    public void load() {
        storage = new Storage(getContext(), StorageConfiguration.DEFAULTS);
    }

    @PluginMethod
    public void configure(PluginCall call) {
        try {
            StorageConfiguration configuration = StorageConfiguration.DEFAULTS.clone();
            configuration.group = call.getString("group", StorageConfiguration.DEFAULTS.group);

            storage = new Storage(getContext(), configuration);
        } catch (CloneNotSupportedException e) {
            call.reject("Error while configuring", e);
            return;
        }
        call.resolve();
    }

    @PluginMethod
    public void get(PluginCall call) {
        String key = call.getString("key");
        if (key == null) {
            call.reject("Must provide key");
            return;
        }

        String value = storage.get(key);

        JSObject ret = new JSObject();
        ret.put("value", value == null ? JSObject.NULL : value);
        call.resolve(ret);
    }

    @PluginMethod
    public void set(PluginCall call) {
        String key = call.getString("key");
        if (key == null) {
            call.reject("Must provide key");
            return;
        }

        String value = call.getString("value");
        storage.set(key, value);

        call.resolve();
    }

    @PluginMethod
    public void remove(PluginCall call) {
        String key = call.getString("key");
        if (key == null) {
            call.reject("Must provide key");
            return;
        }

        storage.remove(key);

        call.resolve();
    }

    @PluginMethod
    public void keys(PluginCall call) {
        Set<String> keySet = storage.keys();
        String[] keys = keySet.toArray(new String[0]);

        JSObject ret = new JSObject();
        try {
            ret.put("keys", new JSArray(keys));
        } catch (JSONException ex) {
            call.reject("Unable to serialize response.", ex);
            return;
        }
        call.resolve(ret);
    }

    @PluginMethod
    public void clear(PluginCall call) {
        storage.clear();
        call.resolve();
    }

    @PluginMethod
    public void migrate(PluginCall call) {
        List<String> migrated = new ArrayList<>();
        List<String> existing = new ArrayList<>();
        Storage oldStorage = new Storage(getContext(), StorageConfiguration.DEFAULTS);

        for (String key : oldStorage.keys()) {
            String value = oldStorage.get(key);
            String currentValue = storage.get(key);

            if (currentValue == null) {
                storage.set(key, value);
                migrated.add(key);
            } else {
                existing.add(key);
            }
        }

        JSObject ret = new JSObject();
        ret.put("migrated", new JSArray(migrated));
        ret.put("existing", new JSArray(existing));
        call.resolve(ret);
    }
}
