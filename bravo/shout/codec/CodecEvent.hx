/**
 * ...
 * @author JB
 */

package bravo.shout.codec;
import haxe.io.Bytes;

enum CodecMsgTypes
{
	CodHeader;
	CodInfo;
	CodStart;
	CodAudioPreData;
	CodVideoPreData;
	CodAudioData;
	CodVideoData;
	CodMetaData;
	CodError;
	//CodInformation;
	//CodUnknown;
}

typedef CodecMsg =
{
	var msgdata : Null<Bytes>;
	var msgtype : CodecMsgTypes;
	var chunktime : Float;
}

typedef XCodecData =
{
	var isDataFrame : Bool;
	var isInitData : Bool;
	var isOnceOnly : Bool;
	var flashheader : Bytes;
	var rawheader : Bytes;
	var data : Bytes;
	var message : String;
}

class CodecEvent
{
	public var data(default, null) : Bytes; // CodecData
	
	public var time(default, null) : Float;
	public var msgtyp(default, null) : CodecMsgTypes;
	public var chunktime(default, null) : Float;
	public function new(msgType : CodecMsgTypes, Data : Bytes, ?ChunkTime : Float = 0.0)
	{
		#if foras3
		time = untyped __new__ (Date);
		#else
		time = Date.now().getTime();
		#end
		msgtyp = msgType;
		data = Data;// Bytes.ofData(Data.getData());
		chunktime = ChunkTime;
	}
}
