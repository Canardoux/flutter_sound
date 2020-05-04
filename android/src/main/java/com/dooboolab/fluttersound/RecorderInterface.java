package com.dooboolab.fluttersound;

import java.io.IOException;

public interface RecorderInterface
{
	public void _startRecorder
		(
			Integer numChannels,
			Integer sampleRate,
			Integer bitRate,
			FlutterSoundCodec codec,
			String path
		)
		throws
		IOException;
	public void _stopRecorder (  );
	public boolean pauseRecorder( );
	public boolean resumeRecorder(  );
	public double getMaxAmplitude ();

}
