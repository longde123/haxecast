/**
 * ...
 * @author JB
 */

package bravo.shout.codec;

import bravo.shout.codec.CodecEvent;
import bravo.shout.tag.FlvHeader;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;

private enum NsvState {
	NSVWaitForFrame(prevChar : Int, prevChar1 : Int, prevChar2 : Int);
	NSVFrameHdr(isSync : Bool);
	NSVSyncFrame;
	NSVWholeFrame(vaSize : Int, aSize : Int, numAux : Int);
}

class Nsv extends CodecBase, implements ICodec
{
// Sync Frame
// NSVs vidx audx ww hh r ss
	public function new() 
	{
		codecName = 'NSV';
		super();
		myState = NSVWaitForFrame(0, 0, 0);
		audioStream = null;
		videoStream = null;
		AVbuffer = new Array();
		AVQ = 2;
		hadNsvSync = false;
		hasAudio = false;
		hasVideo = false;
		hasAV = false;
	}
	private var myState : NsvState;
	private var vid : String;
	private var aud : String;
	private var width : Int;
	private var height : Int;
	private var avsync : Int;
	private var hasAudio : Bool;
	private var hasVideo : Bool;
	private var videoFrameIncrement : Float;
	private var audioFrameIncrement : Float;
	private var hadNsvSync : Bool;
	private var hasAV : Bool;
	private var nsvFrameBuffer : Bytes;
	private var nsvAudioBuffer : Bytes;
	private var nsvFrameReader : BytesInput;
	
	var AVbuffer : Array<CodecEvent>;
	var AVQ : Int;

	private function addData(a : CodecEvent ) : Void 
	{
		if (a.msgtyp != CodHeader) // we send our own codec header
		{
			var maxPos = AVbuffer.length - 1;
			if (maxPos < 0) 
			{
				AVbuffer.push( a ); // buffer is empty
			} 
			else if (a.time < AVbuffer[0].time) // add to top of buffer
			{
				AVQ++;
				AVbuffer.unshift( a );
			} 
			else if ( a.time >= AVbuffer[maxPos].time) // add to end of buffer
			{
				AVbuffer.push( a );
			} 
			else // add to middle of buffer
			{
				for (i in 1...AVbuffer.length) 
				{
					if (a.time < AVbuffer[i].time) 
					{
						AVbuffer.insert(i, a);
						break;
					}
				}
			}
			if (AVbuffer.length > AVQ) 
			{
				var x = AVbuffer.shift();
				if(flvdata.isListenedTo)
				{
					flvdata.dispatch(x);
				}
			}
		}
	}
	var hdrbuffer : BytesOutput;
	public function process(buff : Bytes, pos : Int, len : Int) : Null<Int>
	{
		switch(myState)
		{
			case NSVWaitForFrame(prevChar, prevChar1, prevChar2):
				if( len < 1 )
				{
					return null;
				}
				var char = buff.get(pos);

				if (prevChar2 == 0x4e && prevChar1 == 0x53 && prevChar == 0x56 && char == 0x73) 
				{
					hdrbuffer = new BytesOutput();
					hdrbuffer.bigEndian = true;
					hdrbuffer.writeInt16(0x4e53);
					hdrbuffer.writeInt16(0x5673);
					myState = NSVSyncFrame;
				} 
				else if ( prevChar == 0xEF && char == 0xBE ) 
				{
					hdrbuffer = new BytesOutput();
					hdrbuffer.bigEndian = true;
					hdrbuffer.writeUInt16(0xEFBE);
					myState = NSVFrameHdr(false);
				} 
				else 
				{
					myState = NSVWaitForFrame(char, prevChar, prevChar1);
				}
				return 1;
			case NSVSyncFrame:
				if (len < 15)
				{
					return null;
				}
				hdrbuffer.writeBytes(buff, pos, 15);
				var screader = new BytesInput(buff, pos, 15);
				screader.bigEndian = false;
				var four : Bytes =  screader.read(4);
				vid = four.toString();
				four = screader.read(4);
				aud = four.toString();
				width = screader.readInt16();
				height = screader.readInt16();
				var xrate = screader.readByte();
				avsync = screader.readInt16();
				hasVideo = (vid != 'NONE');
				hasAudio = (aud != 'NONE');
				var div = if (xrate == 0) 
					{
						1000000.0;
					}
					else if (xrate < 127)
					{
						(xrate * 1.0);
					}
					else 
					{
						var r = switch(xrate & 0x03)
						{
							case 0 : 30.0000;
							case 1 : 30.0 * 1000.0 / 1001.0;
							case 2 : 25.0000;
							case 3 : 24.0 * 1000.0 / 1001.0;
						};
						var rate = ((xrate & 0x3c) >> 2) + 1;
						if ((xrate & 0x40) == 0) r / rate else r * rate;
					};
				videoFrameIncrement = 1000.0 / div;
				
				if (!hadNsvSync) 
				{
					if(flvdata.isListenedTo)
					{
						var codinfo = new BytesOutput();
						codinfo.bigEndian = false;
						codinfo.writeInt16(width);
						codinfo.writeInt16(height);
						codinfo.writeInt24(Std.int(div * 1000.0));
						codinfo.writeByte(vid.toUpperCase().substr(0, 3) == 'VP6' ? 1 : 0);
						flvdata.dispatch(new CodecEvent(CodInfo, codinfo.getBytes(), 0.0));
						flvdata.dispatch(new CodecEvent(CodHeader, FlvHeader.flvheader(hasAudio, hasVideo), 0.0));
					}
					hasAV = hasVideo && hasAudio;
					hadNsvSync = true;
				}

				if (videoStream == null && hasVideo) 
				{
					videoStream = CodecBase.makeCodec(vid, [videoFrameIncrement]);
					videoStream.flvdata.bind(addData);
				}
				if (audioStream == null && hasAudio)
				{
					audioStream = CodecBase.makeCodec(aud, []);
					audioStream.flvdata.bind(addData);
				}
		
				myState = NSVFrameHdr(true);
				return 15;
			case NSVFrameHdr(isSync):
				if( len < 5 )
				{
					return null;
				}
				hdrbuffer.writeBytes(buff, pos, 5);
				var screader = new BytesInput(buff, pos, 5);
				screader.bigEndian = false;
				var videoAuxSize = screader.readUInt24();
				var audioSize = screader.readUInt16();
				var numAux = videoAuxSize & 0x0F;
				videoAuxSize >>= 4;
				if (audioSize <= 32768 && videoAuxSize <= (524288 + numAux * (32768 + 6))) 
				{
					myState = NSVWholeFrame(videoAuxSize, audioSize, numAux);
				} 
				else 
				{
					myState = NSVWaitForFrame(buff.get(4), buff.get(3), buff.get(2));
				}
				return 5;
			case NSVWholeFrame(vaSize, aSize, numAux):
				if (len < (vaSize + aSize) )
				{
					return null;
				}
				var used = vaSize + aSize;
				var screader = new BytesInput(buff, pos, used);
				screader.bigEndian = false;
				nsvFrameBuffer = screader.read(vaSize);
				nsvAudioBuffer = screader.read(aSize);
				if(rawdata.isListenedTo)
				{
					rawdata.dispatch(
						new CodecEvent(
							CodVideoData, 
							hdrbuffer.getBytes(), 
							frameTime
						)
					);
					rawdata.dispatch(
						new CodecEvent(
							CodVideoData, 
							nsvFrameBuffer, 
							frameTime
						)
					);
					rawdata.dispatch(
						new CodecEvent(
							CodAudioData, 
							nsvAudioBuffer,
							frameTime
						)
					);
				}
				nsvFrameReader = new BytesInput(nsvFrameBuffer, 0, vaSize);
				//var used = 0;
				myState = NSVWaitForFrame(0, 0, 0);
				if (vaSize == 0 && aSize == 0) 
				{
					videoStream.addFrames(1);
				}
				else
				{
					if (hasAV)
					{
						if ((videoStream.frameTime < audioStream.frameTime && vaSize > 0) || (vaSize > 0 && aSize == 0)) 
						{
							NSVSendVideo(vaSize, numAux);
						} 
						else 
						{
							if (aSize > 0)
							{
								NSVSendAudio(aSize, numAux);
							}
							if (vaSize > 0)
							{
								NSVSendVideo(vaSize, numAux);
							}
						} 
					}
					else if (hasAudio && aSize > 0)
					{
						NSVSendAudio(aSize, numAux);
					}
					else if (hasVideo && vaSize > 0)
					{
						NSVSendVideo(vaSize, numAux);
					}
				}
				addFrames(1);
				return used;
		}
	}
	private function NSVSendVideo(vaSize, numAux)
	{
		while (numAux > 0) 
		{
			var len = nsvFrameReader.readInt16();
			var d = nsvFrameReader.read(len + 4);
			addData(new CodecEvent(CodMetaData, d, videoStream.frameTime));
			vaSize -= (6 + len);
			numAux--;
		}
		if ( vaSize > 0) 
		{
			videoStream.fill(nsvFrameReader.read(vaSize), 0, vaSize);
		}
		else
		{
			videoStream.addFrames(1);
		}
		return;
	}
	private function NSVSendAudio(aSize, numAux)
	{
		audioStream.fill(nsvAudioBuffer, 0, aSize);
		return;
	}		
	override public function cleanup()
	{
		if (audioStream != null)
		{
			audioStream.flvdata.unbind(addData);
			audioStream.cleanup();
		}
		if (videoStream != null)
		{
			videoStream.flvdata.unbind(addData);	
			videoStream.cleanup();
		}
	}
}