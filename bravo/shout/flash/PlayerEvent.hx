/**
 * ...
 * @author JB
 */

package bravo.shout.flash;
import flash.events.Event;
import flash.net.NetStream;

typedef VideoParameters =
{
	var width : Int;
	var height : Int;
	var rate : Float;
	var flip : Bool;
}
typedef VideoNetstream =
{
	var netstream : NetStream;
}
typedef BufferStatus =
{
	var bufferLength : Float;
	var bufferTime : Float;
}
typedef SongTitle =
{
	var StreamTitle : String;
	var StreamUrl : String;
}
typedef MetaData =
{
	var metadata : Dynamic;
}
typedef XmlMeta =
{
	var xmldata : Dynamic;
}
typedef StreamName =
{
	var name : String;
}

class PlayerEvent extends Event
{
	public static var VIDEO_PARAMETERS:String = "bravo.shout.flash.PlayerEvent.VIDEO_PARAMETERS";
	public static var STREAM_TITLE:String = "bravo.shout.flash.PlayerEvent.STREAM_TITLE";
	public static var SONG_TITLE:String = "bravo.shout.flash.PlayerEvent.SONG_TITLE";
	public static var CODEC_METADATA:String = "bravo.shout.flash.PlayerEvent.CODEC_METADATA";
	public static var SOCKET_OPEN:String = "bravo.shout.flash.PlayerEvent.SOCKET_OPEN";
	public static var SOCKET_FAIL:String = "bravo.shout.flash.PlayerEvent.SOCKET_FAIL";
	public static var URL_OPEN:String = "bravo.shout.flash.PlayerEvent.URL_OPEN";
	public static var URL_FAIL:String = "bravo.shout.flash.PlayerEvent.URL_FAIL";
	public static var BUFFER_STATUS:String = "bravo.shout.flash.PlayerEvent.BUFFER_STATUS";
	public static var XML_METADATA:String = "bravo.shout.flash.PlayerEvent.XML_METADATA";
	public static var STREAM_FAIL:String = "bravo.shout.flash.PlayerEvent.STREAM_FAIL";
	
	public static var NETSTREAM_VIDEO:String = "bravo.shout.flash.PlayerEvent.NETSTREAM_VIDEO";
	
	public static var PLAYER_EVENT:String = "bravo.shout.flash.PlayerEvent.PLAYER_EVENT";
	
	public var eventType:String;
	public var objVal:Dynamic;

	public function new(inEventType:String, ?inObj:Dynamic, ?inBubble:Bool=true)
	{
		super(inEventType, inBubble);
		eventType = inEventType;
		objVal = inObj;
	}
}