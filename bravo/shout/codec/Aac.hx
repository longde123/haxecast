/**
 * ...
 * @author JB
 */

package bravo.shout.codec;

import bravo.shout.tag.IDataTag;
import haxe.io.Bytes;
import bravo.shout.codec.CodecEvent;
import bravo.shout.codec.Audio;
import bravo.shout.tag.FlvHeader;
import bravo.shout.tag.DataTag;

private enum AacPumpState
{
	psSync(prevChar : Int);
	psFrameHdr(char2 : Int);
	psFrame(framelen : Int);
}

class DataTagAudioAac extends DataTagAudio, implements IDataTag
{
	public function new(flvPreData : Bytes, rawPreData : Bytes, data : Bytes, time : Float, rate : TagAudioRates, size : TagAudioSizes, channels : TagAudioChannels)
	{
		super(time, AAC, rate, size, channels);
		if (flvPreData != null)
		{
			writeBytes(flvPreData, 0, flvPreData.length, DTWFlv);
		}
		if (rawPreData != null)
		{
			writeBytes(rawPreData, 0, rawPreData.length, DTWRaw);
		}
		if (data != null)
		{
			writeBytes(data, 0, data.length, DTWBoth);
		}
		this.endtag();
	}
}

class Aac extends Audio, implements ICodec
{
	private static var samplingFrequencyTable : Array<Int> = 
	[
		96000, 88200, 64000, 48000,	
		44100, 32000, 24000, 22050,
		16000, 12000, 11025,  8000,
		 7350,     0,     0,     0
	];

	var myState : AacPumpState;
	var hdrBuff : Bytes;
	
	var audioBytes : Int;
	var audioRequireSampleRate : Bool;
	var audioRequireBitRate : Bool;
	var audioRateIndex : Int;
	var audioChannels : Int;
	var audioProfile : Int;
	var audioSampleRate : Int;
	var audioSpecificConfig : Int;
	var audioFirstChunk : Bytes;
	var prevBRS : Int;
	var audioBitRate : Int;

	public function new() 
	{
		codecName = 'AAC';
		super();
		myState = psSync(0);
		audioFirstChunk = Bytes.alloc(3);
		audioFirstChunk.set(0, 0);
		audioRequireBitRate = true;
		audioRequireSampleRate = true;
		prevBRS = -1;
		hdrBuff = Bytes.alloc(7);
		hdrBuff.set(0, 0xFF);
		audioBytes = 0;
	}

	var fcount : Int;
	override public function process(buff : Bytes, pos : Int, len : Int) : Null<Int>
	{
		switch(myState)
		{
			case psSync(prevChar):
				if( len < 1 )
				{
					return null;
				}
				var char = buff.get(pos);
				if (prevChar == 0xFF && ((char & 0xF6) == 0xF0)) 
				{
					myState = psFrameHdr(char);
				} 
				else 
				{
					myState = psSync(char);
				}
				return 1;
			case psFrameHdr(char2):
				if (len < 5)
				{
					return null;
				}
				hdrBuff.blit(2, buff, pos, 5);
				hdrBuff.set(1, char2);

				var frameLen = (((hdrBuff.get(3) & 0x03) << 11) + (hdrBuff.get(4) << 3) + ((hdrBuff.get(5) >> 5) & 0x07)) - 7;
				audioBytes += frameLen;
				if (audioRequireSampleRate) 
				{
					if(flvdata.isListenedTo)
					{
						flvdata.dispatch(new CodecEvent(CodHeader, FlvHeader.flvheader(true, false)));
					}
					audioRateIndex = (hdrBuff.get(2) & 0x3c) >>> 2;
					audioChannels = ((hdrBuff.get(2) & 0x01) << 2) + ((hdrBuff.get(3) & 0xc0) >>> 6);
					audioProfile = (hdrBuff.get(2) & 0xC0) >>> 6;
					audioSampleRate = samplingFrequencyTable[audioRateIndex];
					if (audioSampleRate == 0)
					{
						if(flvdata.isListenedTo)
						{
							flvdata.dispatch(
								new CodecEvent(CodError, Bytes.ofString("Unknown sample rate index=" + audioRateIndex), frameTime)
							);
						}
					}
					else
					{
						frameIncrement = 1024000.0 / audioSampleRate;
						var profile = audioProfile + 1;
						audioSpecificConfig = 
							(profile << 11) + 
							(audioRateIndex << 7) +
							(audioChannels << 3);
						audioFirstChunk.set(1, (audioSpecificConfig >> 8) & 0xFF);
						audioFirstChunk.set(2, audioSpecificConfig & 0xFF);
						audioRequireSampleRate = false;
						//	0 0 P P P R R R : R 0 C C C 0 0 0
						if(flvdata.isListenedTo)
						{
							flvdata.dispatch(
								new CodecEvent(
									CodAudioPreData, 
									new AudioTag(audioFirstChunk, 0.0, AAC, RateOther, SizeOther, ChannelsOther).tag, 
									frameTime
								)
							);
						}
					}
				}
				fcount = (hdrBuff.get(6) & 0x03) + 1;
				if (audioRequireBitRate) 
				{
					var audioFullness = ((hdrBuff.get(6) & 0xFC) >>> 2) + ((hdrBuff.get(5) & 0x1F) << 6);
					var SR = audioSampleRate;

					var BRS = audioFullness * audioChannels * 32;
					var FBR = Std.int(1.0 * (audioBytes / (frames + 1)) * SR / (fcount * 128.0));
					var RBR = FBR;
					if (prevBRS >= 0) 
					{
						RBR = Std.int((BRS + (frameLen / fcount + 7) * 8.0 - prevBRS) * SR / 1024.0);
					}
					prevBRS = BRS;
					audioBitRate = calcAACStreamBitRate(RBR);
					audioRequireBitRate = false;
				}

				myState = psFrame(frameLen);
				return 5;
			case psFrame(framelen):
				if (len < framelen)
				{
					return null;
				}
				var msgBuff : Bytes = Bytes.alloc(framelen + 1);
				msgBuff.set(0, 1);
				msgBuff.blit(1, buff, pos, framelen);
				var rawFrame = Bytes.alloc(framelen + hdrBuff.length);
				rawFrame.blit(0, hdrBuff, 0, hdrBuff.length);
				rawFrame.blit(hdrBuff.length, buff, pos, framelen);
				if(flvdata.isListenedTo)
				{
					flvdata.dispatch(
						new CodecEvent(
							codecType, 
							new AudioTag(msgBuff, frameTime, AAC, RateOther, SizeOther, ChannelsOther).tag, 
							frameTime
						)
					);
				}
				if(rawdata.isListenedTo)
				{
					rawdata.dispatch(
						new CodecEvent(
							codecType, 
							rawFrame, 
							frameTime
						)
					);
				}
				addFrames(fcount);
				myState = psSync(0);
				return framelen;
		}
	}

	private static function calcAACStreamBitRate(r : Int) : Int 
	{
		if (r < 8500) 
		{
			r = 8000;
		} 
		else if (r < 10500) 
		{
			r = 10000;
		} 
		else if (r < 13000) 
		{
			r = 12000;
		} 
		else if (r < 17000) 
		{
			r = 16000;
		} 
		else if (r < 21000) 
		{
			r = 20000;
		} 
		else if (r < 35000)
		{
			r = 24000;
		} 
		else if (r < 29000)
		{
			r = 28000;
		} 
		else if (r < 34000) 
		{
			r = 32000;
		} 
		else if (r < 42000)
		{
			r = 40000;
		} 
		else if (r < 50000) 
		{
			r = 48000;
		} 
		else if (r < 58000) 
		{
			r = 56000;
		} 
		else if (r < 68000) 
		{
			r = 64000;
		} 
		else if (r < 88000) 
		{
			r = 80000;
		} 
		else if (r < 100000)
		{
			r = 96000;
		}
		else if (r < 116000)
		{
			r = 112000;
		}
		else if (r < 140000)
		{
			r = 128000;
		} 
		else if (r < 176000)
		{
			r = 160000;
		} 
		else if (r < 208000)
		{
			r = 192000;
		} 
		else if (r < 240000)
		{
			r = 224000;
		}
		else if (r < 272000)
		{
			r = 256000;
		} 
		else if (r < 304000)
		{
			r = 288000;
		} 
		else {
			r = 320000;
		}
		return r;
	}
}