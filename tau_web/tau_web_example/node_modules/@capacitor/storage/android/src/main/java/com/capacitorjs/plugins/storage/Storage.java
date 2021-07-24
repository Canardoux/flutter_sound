package com.capacitorjs.plugins.storage;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import java.util.Set;

public class Storage {

    private SharedPreferences preferences;

    private interface StorageOperation {
        void execute(SharedPreferences.Editor editor);
    }

    Storage(Context context, StorageConfiguration configuration) {
        this.preferences = context.getSharedPreferences(configuration.group, Activity.MODE_PRIVATE);
    }

    public String get(String key) {
        return preferences.getString(key, null);
    }

    public void set(String key, String value) {
        executeOperation(editor -> editor.putString(key, value));
    }

    public void remove(String key) {
        executeOperation(editor -> editor.remove(key));
    }

    public Set<String> keys() {
        return preferences.getAll().keySet();
    }

    public void clear() {
        executeOperation(SharedPreferences.Editor::clear);
    }

    private void executeOperation(StorageOperation op) {
        SharedPreferences.Editor editor = preferences.edit();
        op.execute(editor);
        editor.apply();
    }
}
