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

enum TagVideoCodecs
{
	Sorenson;
	Screen;
	VP6;
	VP6a;
	ScreenV2;
	xAVC;
}

enum TagVideoTypes
{
	Key;
	Inter;
	DisposableInter;
	GenKey;
	VideoInfo;
}

class VideoTag extends Tag, implements ITag
{
	private static function getcodec(codec : TagVideoCodecs) : Int
	{
		return switch(codec)
		{
			case Sorenson: 2;
			case Screen: 3;
			case VP6: 4;
			case VP6a: 5;
			case ScreenV2: 6;
			case xAVC: 7;
		}
	}
	private static function gettype(type : TagVideoTypes) : Int
	{
		return switch(type)
		{
			case Key: 1;
			case Inter: 2;
			case DisposableInter: 3;
			case GenKey: 4;
			case VideoInfo: 5;
		}
	}
	public function new(data : Bytes, time : Float, codec : TagVideoCodecs, type : TagVideoTypes)
	{
		super(TagVideoData, time);
		writeByte(gettype(type) << 4 | getcodec(codec));
		endtag(data);
	}
}

class Video extends CodecBase, implements ICodec
{
	private function new(?inc : Float = 0.0) 
	{
		super(inc);
		codecType = CodVideoData;
		audioStream = null;
		videoStream = this;
	}

	public function process(buff : Bytes, pos : Int, len : Int) : Null<Int>
	{
		throw "process not overridden";
		return null;
	}
}

class DataTagVideo extends DataTag
{
	private static function getcodec(codec : TagVideoCodecs) : Int
	{
		return switch(codec)
		{
			case Sorenson: 2;
			case Screen: 3;
			case VP6: 4;
			case VP6a: 5;
			case ScreenV2: 6;
			case xAVC: 7;
		}
	}
	private static function gettype(type : TagVideoTypes) : Int
	{
		return switch(type)
		{
			case Key: 1;
			case Inter: 2;
			case DisposableInter: 3;
			case GenKey: 4;
			case VideoInfo: 5;
		}
	}
	public function new(time : Float, codec : TagVideoCodecs, type : TagVideoTypes)
	{
		super(DataTagVideoData, time);
		writeByte(gettype(type) << 4 | getcodec(codec), DTWFlv);
	}
}

