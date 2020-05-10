package com.dooboolab.fluttersound;
/*
 * This file is part of Flutter-Sound (Flauto).
 *
 *   Flutter-Sound (Flauto) is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound (Flauto) is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound (Flauto).  If not, see <https://www.gnu.org/licenses/>.
 */


import java.util.HashMap;

public class Track {
    private String path;
    private String title;
    private String artist;
    private String albumArtUrl;
    private String albumArtAsset;
    private String albumArtFile;

    private byte[] dataBuffer;
    private Integer bufferCodecIndex;

    Track(HashMap<String, Object> map) {
        this.path = (String) map.get("path");
        this.artist = (String) map.get("artist");
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

    public String getArtist() {
        return artist;
    }

    public void getArtist(String artist) {
            this.artist = artist;
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

    public void setAlbumArtFile(String albumArtFile) {
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
