package com.dooboolab.fluttersound;

import androidx.annotation.Nullable;

import java.util.HashMap;

public class Track {
    private String path;
    private String title;
    private String author;
    private String albumArtUrl;
    private String albumArtAsset;

    private byte[] dataBuffer;
    private Integer bufferCodecIndex;

    Track(HashMap<String, Object> map) {
        this.path = (String) map.get("path");
        this.author = (String) map.get("author");
        this.title = (String) map.get("title");
        this.albumArtUrl = (String) map.get("albumArtUrl");
        this.albumArtAsset = (String) map.get("albumArtAsset");
        this.dataBuffer = (byte[]) map.get("dataBuffer");
        this.bufferCodecIndex = (int) map.get("bufferCodecIndex");
    }

    public String getPath() {
        return path;
    }

    public void setPath(String path) {
        this.path = path;
    }

    public String getAuthor() {
        return author;
    }

    public void setAuthor(String author) {
        this.author = author;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getAlbumArtUrl() {
        return albumArtUrl;
    }

    public void setAlbumArtUrl(String albumArtUrl) {
        this.albumArtUrl = albumArtUrl;
    }

    public String getAlbumArtAsset() {
        return albumArtAsset;
    }

    public void setAlbumArtAsset(String albumArtAsset) {
        this.albumArtAsset = albumArtAsset;
    }


    public byte[] getDataBuffer() {
        return dataBuffer;
    }

    public int getBufferCodecIndex() {
        return bufferCodecIndex;
    }

    public t_CODEC getBufferCodec() {
        return t_CODEC.values()[bufferCodecIndex != null ? bufferCodecIndex : 0];
    }

    /**
     * Returns whether the audio file of this track is stored by a string or a buffer.
     *
     * @return true if the audio file of this track is stored by a string, false if it is stored
     * by a buffer.
     */
    public boolean isUsingPath() {
        return path != null;
    }
}
