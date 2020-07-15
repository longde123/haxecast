package bravo.shout.codec;

import bravo.shout.tag.IDataTag;
import haxe.io.Bytes;
import bravo.shout.codec.CodecEvent;
import bravo.shout.codec.Audio;
import bravo.shout.tag.FlvHeader;
import bravo.shout.tag.DataTag;

private enum Mp3PumpState
{
	psSync(prevChar : Int);
	psFrameHdr(char2 : Int);
	psFrame(framelen : Int);
}

class DataTagAudioMp3 extends DataTagAudio, implements IDataTag
{
	public function new(flvPreData : Bytes, data : Bytes, time : Float, rate : TagAudioRates, size : TagAudioSizes, channels : TagAudioChannels)
	{
		super(time, MPEG3, rate, size, channels);
		if (flvPreData != null)
		{
			writeBytes(flvPreData, 0, flvPreData.length, DTWFlv);
		}
		if (data != null)
		{
			writeBytes(data, 0, data.length, DTWBoth);
		}
		this.endtag();
	}
}

class Mp3 extends Audio, implements ICodec
{
	var myState : Mp3PumpState;
	var hdrBuff : Bytes;
	var firstFrame : Bool;
//
	public var audioVersionId(default, null):Int;
	public var layerDescription(default, null):Int;
	public var protectionBit(default, null):Bool;
	public var bitRateIndex(default, null):Int;
	public var samplingRateIndex(default, null):Int;
	public var paddingBit(default, null):Bool;
	public var mode(default, null):Int;
	public var sampleRate(default, null):Int;
	public var bitRate(default, null):Int;
	public var isStereo(default, null):Bool;
	public var FLVSampleRateFlag(default, null):TagAudioRates;
	public var frameSize(default, null):Int;
	public var frameDuration(default, null) : Float;
//
	public function new()
	{
		firstFrame = true;
		codecName = 'MP3';
		super();
		//hdr = new MP3Header();
		myState = psSync(0);
		hdrBuff = Bytes.alloc(4);
		hdrBuff.set(0, 255);
	}

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
				if (prevChar == 0xFF && ((char & 0xE0) == 0xE0)) 
				{
					myState = psFrameHdr(char);
				} 
				else 
				{
					myState = psSync(char);
				}
				return 1;
			case psFrameHdr(char2):
				if (len < 2)
				{
					return null;
				}
				var used = 2;
				readHeader( (char2 << 16) | (buff.get(pos) << 8) | buff.get(pos+1));
				if (sampleRate <= 0 || bitRate <= 0 || frameDuration <= 0 || frameSize <= 0 )
				{
					myState = psSync(char2);
					used = 0;
				}
				else
				{
					hdrBuff.set(1, char2);
					hdrBuff.blit(2, buff, pos, 2);
					myState = psFrame(frameSize-4);
					if (firstFrame)
					{
						if(flvdata.isListenedTo)
						{
							flvdata.dispatch(new CodecEvent(CodHeader, FlvHeader.flvheader(true, false)));
						}
						firstFrame = false;
					}
				}
				return used;
			case psFrame(framelen):
				if (len < framelen)
				{
					return null;
				}
				var data = Bytes.alloc(framelen + hdrBuff.length);
				data.blit(0, hdrBuff, 0, hdrBuff.length);
				data.blit(hdrBuff.length, buff, pos, framelen);
				if(flvdata.isListenedTo)
				{
					flvdata.dispatch(
						new CodecEvent(
							codecType, 
							new AudioTag(data, frameTime, MPEG3, FLVSampleRateFlag, Size16bits, isStereo ? ChannelsStereo : ChannelsMono).tag, 
							frameTime
						)
					);
				}
				if(rawdata.isListenedTo)
				{
					rawdata.dispatch(
						new CodecEvent(
							codecType, 
							data, 
							frameTime
						)
					);
				}
				frameIncrement = frameDuration;
				addFrames(1);
				myState = psSync(0);
				return framelen - 1;
		}
	}
//
	function readHeader(inData:Int):Void
	{			
		var data = inData & 0x1fffff;
		audioVersionId =  (data>>19) & 3;
		layerDescription =  (data>>17) & 3;
		protectionBit = ((data>>16) & 1) == 0 ;
		bitRateIndex =  (data>>12) & 15;
		samplingRateIndex =  (data>>10) & 3;
		paddingBit = ((data>>9) & 1) != 0 ;
		mode =  (data>>6) & 3;
		sampleRate = SAMPLERATES[audioVersionId][samplingRateIndex];
		bitRate = getBitRate();
		isStereo = mode != 3;
		FLVSampleRateFlag = getFLVSampleRateFlag();
		frameSize = getFrameSize();
		frameDuration = getFrameDuration();
	}
	
	function getFrameDuration():Float
	{
		return (
			switch (layerDescription) 
			{
				case 3:					
					384000;
					
				case 2,1:
					if (audioVersionId == 3) 
					{
						1152000;
					} 
					else 
					{
						576000;
					}					
				default:
					-sampleRate;
			}
		) / sampleRate;
	}
	
	function getFrameSize():Int 
	{
		return Std.int(
			switch (layerDescription) 
			{
				case 3:					
					(12 * bitRate / sampleRate + (paddingBit ? 1 : 0)) * 4;
					
				case 2, 1:
					if (audioVersionId == 3) 
					{						
						144 * bitRate / sampleRate + (paddingBit ? 1 : 0);
					} 
					else 
					{						
						72 * bitRate / sampleRate + (paddingBit ? 1 : 0);
					}
				default:					
					-1;
			}
		);
	}
	
	function getBitRate():Int 
	{
		return (switch (audioVersionId) 
		{
			case 1:
				-1;
				
			case 0,2:
				if (layerDescription == 3)
				{
					BITRATES[3][bitRateIndex];
				} 
				else if (layerDescription == 2 || layerDescription == 1) 
				{
					BITRATES[4][bitRateIndex];
				} 
				else 
				{
					return -1;
				}
			case 3:
				if (layerDescription == 3) 
				{
					BITRATES[0][bitRateIndex];
				} 
				else if (layerDescription == 2) 
				{
					BITRATES[1][bitRateIndex];
				}
				else if (layerDescription == 1) 
				{
					BITRATES[2][bitRateIndex];
				} 
				else 
				{
					-1;
				}
			default:
				-1;
		}) * 1000;
	}
	
	function getFLVSampleRateFlag():TagAudioRates
	{
		return switch(sampleRate) {
			case 5500: Rate5500;
			case 11025: Rate11025;
			case 22050: Rate22050;
			case 44100: Rate44100;
			default: RateOther;
		}
		
	}		
	static var BITRATES:Array<Array<Int>> = [
		[ 0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, -1 ],
		[ 0, 32, 48, 56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320, 384, -1 ],
		[ 0, 32, 40, 48,  56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320,	-1 ],
		[ 0, 32, 48, 56,  64,  80,  96, 112, 128, 144, 160, 176, 192, 224, 256, -1 ],
		[ 0,  8, 16, 24,  32,  40,  48,  56,  64,  80,  96, 112, 128, 144, 160, -1 ], 
	];
	
	
	static var SAMPLERATES:Array<Array<Int>> = [
		[ 11025, 12000,  8000, -1 ],
		[    -1,    -1,    -1, -1 ],
		[ 22050, 24000, 16000, -1 ],
		[ 44100, 48000, 32000, -1 ], 
	];	
}
