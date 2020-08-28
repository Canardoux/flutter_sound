/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General License for more details.
 *
 * You should have received a copy of the GNU Lesser General License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */



import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/src/session.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;
import 'package:synchronized/synchronized.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/src/session.dart';


/**
 * This class represents the header of a WAVE format audio file, which usually
 * have a .wav suffix.  The following integer valued fields are contained:
 * <ul>
 * <li> format - usually PCM, ALAW or ULAW.
 * <li> numChannels - 1 for mono, 2 for stereo.
 * <li> sampleRate - usually 8000, 11025, 16000, 22050, or 44100 hz.
 * <li> bitsPerSample - usually 16 for PCM, 8 for ALAW, or 8 for ULAW.
 * <li> numBytes - size of audio data after this header, in bytes.
 * </ul>
 *
 * Not yet ready to be supported, so
 * @hide
 */



class WaveHeader
{
        // follows WAVE format in http://ccrma.stanford.edu/courses/422/projects/WaveFormat
        static final String TAG = "WaveHeader";

        static final int HEADER_LENGTH = 44;

        /** Indicates PCM format. */
        static final int FORMAT_PCM = 1;
        /** Indicates ALAW format. */
        static final int FORMAT_ALAW = 6;
        /** Indicates ULAW format. */
        static final int FORMAT_ULAW = 7;

        int mFormat;
        int mNumChannels;
        int mSampleRate;
        int mBitsPerSample;
        int mNumBytes;

   
        /**
         * Construct a WaveHeader, with fields initialized.
         * @param format format of audio data,
         * one of {@link #FORMAT_PCM}, {@link #FORMAT_ULAW}, or {@link #FORMAT_ALAW}.
         * @param numChannels 1 for mono, 2 for stereo.
         * @param sampleRate typically 8000, 11025, 16000, 22050, or 44100 hz.
         * @param bitsPerSample usually 16 for PCM, 8 for ULAW or 8 for ALAW.
         * @param numBytes size of audio data after this header, in bytes.
         */
        WaveHeader(int format, int numChannels, int sampleRate, int bitsPerSample, int numBytes)
        {
                mFormat = format;
                mSampleRate = sampleRate;
                mNumChannels = numChannels;
                mBitsPerSample = bitsPerSample;
                mNumBytes = numBytes;
        }

        /**
         * Get the format field.
         * @return format field,
         * one of {@link #FORMAT_PCM}, {@link #FORMAT_ULAW}, or {@link #FORMAT_ALAW}.
         */
        int getFormat()
        {
                return mFormat;
        }

        /**
         * Set the format field.
         * @param format
         * one of {@link #FORMAT_PCM}, {@link #FORMAT_ULAW}, or {@link #FORMAT_ALAW}.
         * @return reference to this WaveHeader instance.
         */
        WaveHeader setFormat(int format)
        {
                mFormat = format;
                return this;
        }

        /**
         * Get the number of channels.
         * @return number of channels, 1 for mono, 2 for stereo.
         */
        int getNumChannels()
        {
                return mNumChannels;
        }

        /**
         * Set the number of channels.
         * @param numChannels 1 for mono, 2 for stereo.
         * @return reference to this WaveHeader instance.
         */
        WaveHeader setNumChannels(int numChannels)
        {
                mNumChannels = numChannels;
                return this;
        }

        /**
         * Get the sample rate.
         * @return sample rate, typically 8000, 11025, 16000, 22050, or 44100 hz.
         */
        int getSampleRate()
        {
                return mSampleRate;
        }

        /**
         * Set the sample rate.
         * @param sampleRate sample rate, typically 8000, 11025, 16000, 22050, or 44100 hz.
         * @return reference to this WaveHeader instance.
         */
        WaveHeader setSampleRate(int sampleRate)
        {
                mSampleRate = sampleRate;
                return this;
        }

        /**
         * Get the number of bits per sample.
         * @return number of bits per sample,
         * usually 16 for PCM, 8 for ULAW or 8 for ALAW.
         */
        int getBitsPerSample()
        {
                return mBitsPerSample;
        }

        /**
         * Set the number of bits per sample.
         * @param bitsPerSample number of bits per sample,
         * usually 16 for PCM, 8 for ULAW or 8 for ALAW.
         * @return reference to this WaveHeader instance.
         */
        WaveHeader setBitsPerSample(int bitsPerSample)
        {
                mBitsPerSample = bitsPerSample;
                return this;
        }

        /**
         * Get the size of audio data after this header, in bytes.
         * @return size of audio data after this header, in bytes.
         */
        int getNumBytes()
        {
                return mNumBytes;
        }

        /**
         * Set the size of audio data after this header, in bytes.
         * @param numBytes size of audio data after this header, in bytes.
         * @return reference to this WaveHeader instance.
         */
        WaveHeader setNumBytes(int numBytes)
        {
                mNumBytes = numBytes;
                return this;
        }

        /**
         * Read and initialize a WaveHeader.
         * @param in {@link java.io.InputStream} to read from.
         * @return number of bytes consumed.
         * @throws IOException
         */
        /*
        int read(InputStream in) 
        {
                /* RIFF header */
                readId(in, "RIFF");
                int numBytes = readInt(in) - 36;
                readId(in, "WAVE");
                /* fmt chunk */
                readId(in, "fmt ");
                if (16 != readInt(in)) throw new Exception("fmt chunk length not 16");
                mFormat = readint(in);
                mNumChannels = readint(in);
                mSampleRate = readInt(in);
                int byteRate = readInt(in);
                int blockAlign = readint(in);
                mBitsPerSample = readint(in);
                if (byteRate != mNumChannels * mSampleRate * mBitsPerSample / 8)
                {
                        throw new Exception("fmt.ByteRate field inconsistent");
                }
                if (blockAlign != mNumChannels * mBitsPerSample / 8)
                {
                        throw new Exception("fmt.BlockAlign field inconsistent");
                }
                /* data chunk */
                readId(in, "data");
                mNumBytes = readInt(in);

                return HEADER_LENGTH;
        }

        static void readId(InputStream in, String id) 
        {
                for (int i = 0; i < id.length(); i++)
                {
                        if (id.charAt(i) != in.read()) throw Exception( id + " tag not present");
                }
        }


        static int readInt(InputStream in) throws IOException
        {
                return in.read() | (in.read() << 8) | (in.read() << 16) | (in.read() << 24);
        }

        static int readint(InputStream in) throws IOException
        {
                return (int)(in.read() | (in.read() << 8));
        }

         */

        /**
         * Write a WAVE file header.
         * @param out {@link java.io.OutputStream} to receive the header.
         * @return number of bytes written.
         * @throws IOException
         */
        int write(EventSink<List<int>> out)
        {
                /* RIFF header */
                writeId(out, "RIFF");
                writeInt(out, 36 + mNumBytes);
                writeId(out, "WAVE");
                /* fmt chunk */
                writeId(out, "fmt ");
                writeInt(out, 16);
                writeint(out, mFormat);
                writeint(out, mNumChannels);
                writeInt(out, mSampleRate);
                writeInt(out, (mNumChannels * mSampleRate * mBitsPerSample / 8).floor());
                writeint(out, (mNumChannels * mBitsPerSample / 8).floor());
                writeint(out, mBitsPerSample);
                /* data chunk */
                writeId(out, "data");
                writeInt(out, mNumBytes);

                return HEADER_LENGTH;
        }

        static void writeId(EventSink<List<int>> out, String id)
        {
                out.add(id.codeUnits);
        }


        static void writeInt(EventSink<List<int>>  out, int val)
        {
                out.add([val >> 0 , val >> 8 , val >> 16 , val >> 24]);
        }


        static void writeint(EventSink<List<int>> out, int val) async
        {
                out.add( [val >> 0 , val >> 8]);
        }

        String toString()
        {
          return "WaveHeader format=$mFormat numChannels=$mNumChannels sampleRate=$mSampleRate bitsPerSample=$mBitsPerSample numBytes=$mNumBytes";
        }
}
