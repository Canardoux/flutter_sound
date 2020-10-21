package com.dooboolab.TauEngine;
/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of the Tau project.
 *
 * Tau is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Tau is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with the Tau project.  If not, see <https://www.gnu.org/licenses/>.
 */


import java.util.HashMap;
import com.dooboolab.TauEngine.Flauto.t_CODEC;

public class FlautoTrack {
    private String path;
    private String title;
    private String author;
    private String albumArtUrl;
    private String albumArtAsset;
    private String albumArtFile;

    private byte[] dataBuffer;
    private Integer bufferCodecIndex;

    public FlautoTrack(HashMap<String, Object> map) {
        this.path = (String) map.get("path");
        this.author = (String) map.get("author");
        this.title = (String) map.get("title");
        this.albumArtUrl = (String) map.get("albumArtUrl");
        this.albumArtAsset = (String) map.get("albumArtAsset");
        this.albumArtFile = (String) map.get("albumArtFile");
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

    public String getAlbumArtFile() {
        return albumArtFile;
    }

    public void setAlbumArtFile(String albumArtAsset) {
        this.albumArtFile = albumArtFile;
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
     * Returns whether the audio file of this track is stored by a string or a
     * buffer.
     *
     * @return true if the audio file of this track is stored by a string, false if
     *         it is stored by a buffer.
     */
    public boolean isUsingPath() {
        return path != null;
    }
}
