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


import android.content.Context;
import android.graphics.Bitmap;
import android.support.v4.media.MediaDescriptionCompat;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.session.MediaControllerCompat;
import android.support.v4.media.session.MediaSessionCompat;
import android.support.v4.media.session.PlaybackStateCompat;
import androidx.core.app.NotificationCompat;
import androidx.core.content.ContextCompat;
import androidx.media.app.NotificationCompat.MediaStyle;
import androidx.media.session.MediaButtonReceiver;


/**
 * Helper APIs for constructing MediaStyle notifications
 */
public class FlautoMediaStyleHelper {

        private static MediaMetadataCompat initMediaSessionMetadata(Bitmap albumArt)
        {
                // Build the metadata of the currently playing audio file
                MediaMetadataCompat.Builder metadataBuilder = new MediaMetadataCompat.Builder();

                // Add the track duration
                metadataBuilder.putLong(MediaMetadataCompat.METADATA_KEY_DURATION, 100);

                // Include the other metadata if the audio player features should be included
                // Add the display icon and the album art
                metadataBuilder.putBitmap(MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON, albumArt);
                metadataBuilder.putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, albumArt);

                // lock screen icon for pre lollipop
                metadataBuilder.putBitmap(MediaMetadataCompat.METADATA_KEY_ART, albumArt);
                metadataBuilder.putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE, "toto");
                metadataBuilder.putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, "zozo");
                // metadataBuilder.putLong(MediaMetadataCompat.METADATA_KEY_TRACK_NUMBER, 1);
                // metadataBuilder.putLong(MediaMetadataCompat.METADATA_KEY_NUM_TRACKS, 1);

                // Pass the metadata of the currently playing audio file to the media session
                // mMediaSessionCompat.setMetadata(metadataBuilder.build());
                MediaMetadataCompat r = metadataBuilder.build();
                return r;
        }

        /**
         * Build a notification using the information from the given media session.
         * Makes heavy use of {@link MediaMetadataCompat#getDescription()} to extract
         * the appropriate information.
         *
         * @param context      Context used to construct the notification.
         * @param mediaSession Media session to get information.
         * @return A pre-built notification with information from the given media
         *         session.
         */
        public static NotificationCompat.Builder from(Context context, MediaSessionCompat mediaSession)
        {
                MediaControllerCompat controller = mediaSession.getController();

                mediaSession.setMetadata(initMediaSessionMetadata(null));

                MediaMetadataCompat mediaMetadata = controller.getMetadata();
                MediaDescriptionCompat description = mediaMetadata.getDescription();

                NotificationCompat.Builder builder = new NotificationCompat.Builder(context, FlautoBackgroundAudioService.notificationChannelId);
                builder.setContentTitle(description.getTitle()).setContentText(description.getSubtitle())
                                .setSubText(description.getDescription()).setLargeIcon(description.getIconBitmap())
                                .setContentIntent(controller.getSessionActivity())
                                .setDeleteIntent(MediaButtonReceiver.buildMediaButtonPendingIntent(context,
                                                PlaybackStateCompat.ACTION_STOP))
                                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

                                // Add an app icon and set its accent color
                                // Be careful about the color
                                .setSmallIcon(android.R.drawable.ic_media_pause)
                                .setColor(ContextCompat.getColor(context, R.color.colorPrimaryDark))

                                // Add a pause button
                                .addAction(new NotificationCompat.Action(android.R.drawable.ic_media_pause, "pause",
                                                MediaButtonReceiver.buildMediaButtonPendingIntent(context,
                                                                PlaybackStateCompat.ACTION_PLAY_PAUSE)))

                                // Take advantage of MediaStyle features
                                .setStyle(new MediaStyle().setMediaSession(mediaSession.getSessionToken())
                                                .setShowActionsInCompactView(0)

                                                // Add a cancel button
                                                .setShowCancelButton(true)
                                                .setCancelButtonIntent(MediaButtonReceiver
                                                                .buildMediaButtonPendingIntent(context,
                                                                                PlaybackStateCompat.ACTION_STOP)));

                // Display the notification and place the service in the foreground
                // startForeground(id, builder.build());

                return builder;
        }
}
