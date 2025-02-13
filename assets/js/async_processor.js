/*
 * Copyright 2024 Canardoux.
 *
 * This file is part of the τ project.
 *
 * τ is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 (GPL3), as published by
 * the Free Software Foundation.
 *
 * τ is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with τ.  If not, see <https://www.gnu.org/licenses/>.
 */

/*
 * Copyright 2024 Canardoux.
 *
 * This file is part of the τ project.
 *
 * τ is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 (GPL3), as published by
 * the Free Software Foundation.
 *
 * τ is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with τ.  If not, see <https://www.gnu.org/licenses/>.
 */


// The number of ouputs is either 0 or one. We do not handdle the case where number of outputs > 1

class AsyncProcessor extends AudioWorkletProcessor {

  chunk = null;

  constructor(...args) {
    super(...args);
    this.chunksArray = [];
    this.port.onmessage = (e) => {
      //console.log('Rcv ' + e.data);
      //this.port.postMessage("pong (" + e.data + ")");
      let msg = e.data;
      let msgType = msg['msgType'];
      let outputNo = msg['outputNo'];
      let data = msg['data'];
      switch (msgType)
      {
        case 'SEND_DATA': this.send(outputNo, data); break;
        case 'STOP': this.stop(); break;
      }

    };
  }

  stop()
  {
        chunksArray = [];
  }

  bufferUnderflow(outputNo)
  {
    this.port.postMessage({'messageType' : 'AUDIO_BUFFER_UNDERFLOW',  'inputNo' : -1, 'outputNo' : outputNo});
  }


  send( outputNo, data)
  {
      while (outputNo >= this.chunksArray.length)
      {
            this.chunksArray.push([]);
      }
      this.chunksArray[outputNo].push(data);
  }

  receive(inNo, data)
  {
    this.port.postMessage({ 'messageType' : 'RECEIVE_DATA', 'inputNo' : inNo, 'outputNo' : -1, 'data': data});
  }

  getFloats(output, nextChunk,  ln, outNo)
  {
      //if (chunks.length == 0) // No more data
      //{
        //return null; // No more chunks
      //}

      //let ch = chunks[0]; // Current chunk (the oldest one)
      let numberOfChannels = nextChunk.length;
      let numberOfChannelsRequested = output.length;
      console.assert (numberOfChannels == numberOfChannelsRequested)
      let numberOfFrames = nextChunk[0].length; // Number of frames in the chunk (First channel)
      if (ln >= numberOfFrames)
      {
        this.chunksArray[outNo].shift(); // Remove the next chunk
        return nextChunk;
      }
      let r = [];
      let channelNo = 0;
      nextChunk.forEach((d)=> // For each requested channel
      {
            console.assert(numberOfFrames == d.length, "chunk length mismatch");
            r.push(d.subarray(0, ln));
            nextChunk[channelNo] = d.subarray(ln, numberOfFrames);
            ++channelNo;
      });
      return r;
  }

  processOutput(output, outNo) // Process the requested output
  {
    let numberOfChunks = this.chunksArray[outNo].length; // Just for debugging
    if (numberOfChunks == 0)
    {
      this.bufferUnderflow(0); // don't do that when debugging!!!
      return; // No more data
    }
    let nextChunk = this.chunksArray[outNo][0];
    let numberOfChannels = nextChunk.length; // The number of channels in the next chunk
    let numberOfChannelsRequested = output.length;// just for debugging
    console.assert (numberOfChannels == numberOfChannelsRequested);
    if (numberOfChannelsRequested == 0)
    {
        return; // No channels requested
    }

    //console.assert (numberOfChannels == numberOfChannelsRequested); // Just for debugging

    output.forEach((dataChannel) => // For each wanted channels
    {
      console.assert(dataChannel.length == output[0].length, 'Number of frames not same for all channels');
    });
    let x = 0;
    let sizeOfChunk = nextChunk[0].length; // Size for the first channel
    let numberOfFramesWanted =  output[0].length - x;
    while (x < numberOfFramesWanted) // for each wanted frames in the first channel
    {
            if (this.chunksArray[outNo].length == 0)
            {
                return;
            }
            let nextChunk = this.chunksArray[outNo][0];
            let d = this.getFloats(output, nextChunk, numberOfFramesWanted - x, outNo);
            if (d == null)
            {
              this.bufferUnderflow(outputNo);
              return; // No more data
            }
            let numberOfFramesGot = d[0].length; // Size got for the first channel
            console.assert(d.length == numberOfChannels, 'Chunk Length not equal to number of channels');
            for (let channelNo = 0; channelNo < numberOfChannels; ++channelNo)
            {
              console.assert(d[0].length == d[channelNo].length, 'Frames not same for all channels');
              output[channelNo].set(d[channelNo], x);
            }
            x += d[0].length;
        
    }




  }
     
  process(inputs, outputs, parameters) {

      let numberOfOutputs = this.chunksArray.length; // Just for debugging
      let numberOfOutputsRequested = outputs.length;
      if (outputs.length > numberOfOutputs)
      {
         this.chunksArray.push([]);
      }
      let outNo = 0;
      outputs.forEach((output) => // For each output. Probably just one output
      {

             this.processOutput(output, outNo);
             ++ outNo;
      });

      let inNo = 0;
      inputs.forEach((input) => // For each input (Probably just one input)
      {
            this.receive(inNo, input);
            ++ inNo;
      });
      
      
    return true;
  }

  static get asyncProcessor() {
    return [
     {
        name: "momo",
        defaultValue: '3.14',
      },
      {
        name: "mimi",
        defaultValue: 123,
        minValue: 0,
        maxValue: 1000,
        automationRate: "a-rate",

      }
    ];
  }
}

// Actually just 4 processors registered. It can be changed.
registerProcessor("async-processor-1", AsyncProcessor);
registerProcessor("async-processor-2", AsyncProcessor);
registerProcessor("async-processor-3", AsyncProcessor);
registerProcessor("async-processor-4", AsyncProcessor);