/**
 * ...
 * @author JB
 */
package bravo.shout.codec;

import bravo.shout.codec.CodecEvent;
import bravo.shout.tag.ITag;
import bravo.shout.tag.Tag;
import bravo.shout.tag.DataTag;
import haxe.io.Bytes;

enum TagAudioCodecs
{
	LinearPCMPlatform;// 0 = Linear PCM, platform endian
	ADPCM;
	MPEG3;
	LinearPCM;// , little endian
	NellymoserHigh;// 16 kHz mono
	NellymoserLow;// 8 kHz mono
	Nellymoser;
	ALaw;// logarithmic PCM
	MuLaw;//law logarithmic PCM
	Resvl; //9 = reserved
	AAC;//
	Speex;
	MP3low;// 8 kHz
	Device;//
}

enum TagAudioRates
{
	Rate5500;
	Rate11025;
	Rate22050;
	Rate44100;
	RateOther;
}

enum TagAudioSizes
{
	Size8bits;
	Size16bits;
	SizeOther;
}

enum TagAudioChannels
{
	ChannelsMono;
	ChannelsStereo;
	ChannelsOther;
}

class AudioTag extends Tag, implements ITag
{
	private static function getrate(rate : TagAudioRates) : Int
	{
		return (switch(rate)
		{
			case Rate5500 : 0;
			case Rate11025 : 1;
			case Rate22050 : 2;
			case Rate44100 : 3;
			case RateOther : 3;
		}) << 2;
	}
	
	private static function getsize(size : TagAudioSizes) : Int
	{
		return (switch(size)
		{
			case Size8bits : 0;
			case Size16bits : 1;
			case SizeOther : 1;
		}) << 1;
	}

	private static function getchannels(channels : TagAudioChannels) : Int
	{
		return (switch(channels)
		{
			case ChannelsMono : 0;
			case ChannelsStereo : 1;
			case ChannelsOther : 1;
		});
	}

	private static function getcodec(codec : TagAudioCodecs) : Int
	{
		return (switch(codec)
		{
			case LinearPCMPlatform: 0;
			case ADPCM: 1;
			case MPEG3: 2;
			case LinearPCM: 3;
			case NellymoserHigh: 4;
			case NellymoserLow: 5;
			case Nellymoser: 6;
			case ALaw: 7;
			case MuLaw: 8;
			case Resvl: 9;
			case AAC: 10;
			case Speex: 11;
			case MP3low: 14;
			case Device: 15;
		}) << 4;
	}
	public function new(data : Bytes, time : Float, codec : TagAudioCodecs, rate : TagAudioRates, size : TagAudioSizes, channels : TagAudioChannels)
	{
		super(TagAudioData, time);
		writeByte(getcodec(codec) | getrate(rate) | getsize(size) | getchannels(channels));
		endtag(data);
	}
}

class Audio extends CodecBase, implements ICodec
{
	private function new() 
	{
		super();
		videoStream = null;
		audioStream = this;
		codecType = CodAudioData;
	}
	public function process(buff : Bytes, pos : Int, len : Int) : Null<Int>
	{
		throw "process not overridden";
		return null;
	}
}

class DataTagAudio extends DataTag
{
	private static function getrate(rate : TagAudioRates) : Int
	{
		return (switch(rate)
		{
			case Rate5500 : 0;
			case Rate11025 : 1;
			case Rate22050 : 2;
			case Rate44100 : 3;
			case RateOther : 3;
		}) << 2;
	}
	
	private static function getsize(size : TagAudioSizes) : Int
	{
		return (switch(size)
		{
			case Size8bits : 0;
			case Size16bits : 1;
			case SizeOther : 1;
		}) << 1;
	}

	private static function getchannels(channels : TagAudioChannels) : Int
	{
		return (switch(channels)
		{
			case ChannelsMono : 0;
			case ChannelsStereo : 1;
			case ChannelsOther : 1;
		});
	}

	private static function getcodec(codec : TagAudioCodecs) : Int
	{
		return (switch(codec)
		{
			case LinearPCMPlatform: 0;
			case ADPCM: 1;
			case MPEG3: 2;
			case LinearPCM: 3;
			case NellymoserHigh: 4;
			case NellymoserLow: 5;
			case Nellymoser: 6;
			case ALaw: 7;
			case MuLaw: 8;
			case Resvl: 9;
			case AAC: 10;
			case Speex: 11;
			case MP3low: 14;
			case Device: 15;
		}) << 4;
	}
	public function new(time : Float, codec : TagAudioCodecs, rate : TagAudioRates, size : TagAudioSizes, channels : TagAudioChannels)
	{
		super(DataTagAudioData, time);
		writeByte(getcodec(codec) | getrate(rate) | getsize(size) | getchannels(channels), DTWFlv);
	}
}

