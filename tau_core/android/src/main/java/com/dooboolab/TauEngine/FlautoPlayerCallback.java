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

import com.dooboolab.TauEngine.Flauto.t_PLAYER_STATE;

public interface FlautoPlayerCallback
{
  	abstract public void openPlayerCompleted(boolean success);
	abstract public void closePlayerCompleted(boolean success);
	abstract public void stopPlayerCompleted(boolean success);
	abstract public void pausePlayerCompleted(boolean success);
	abstract public void resumePlayerCompleted(boolean success);
	abstract public void startPlayerCompleted (boolean success, long duration);
	abstract public void needSomeFood (int ln);
	abstract public void updateProgress(long position, long duration);
	abstract public void audioPlayerDidFinishPlaying (boolean flag);
	abstract public void pause();
	abstract public void resume();
	abstract public void skipForward();
	abstract public void skipBackward();
	abstract public void updatePlaybackState(t_PLAYER_STATE newState);
}