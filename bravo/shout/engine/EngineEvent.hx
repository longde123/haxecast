/**
 * ...
 * @author JB
 */

package bravo.shout.engine;

import haxe.io.Bytes;

enum EngineMsgTypes
{
	EngHeader;
	EngStreamName;
	EngInformation;
	EngAudioData;
	EngVideoData;
	EngAudioPreData;
	EngVideoPreData;
	EngMetaData;
	EngError;
	EngStreamStartError;
	EngUvoxProtocol;
	
	EngStreamBegin;
	EngCodecBegin;
	
	//EngPreData;
	//EngUnknownEngine;
	//EngStreamEnd;
	//EngCodecEnd;
}

class EngineEvent
{
	public var data(default, null) : Bytes;
	public var time(default, null) : Float;
	public var msgtyp(default, null) : EngineMsgTypes;
	public var chunktime(default, null) : Float;
	public var object(default, null) : Dynamic;
	
	public function new(msgType : EngineMsgTypes, Data : Bytes, Object : Null<Dynamic>, ?ChunkTime : Float = 0.0)
	{
		#if foras3
		time = untyped __new__ (Date);
		#else
		time = Date.now().getTime();
		#end
		msgtyp = msgType;
		chunktime = ChunkTime;
		object = Object;
		data = Data;// Bytes.ofData(Data.getData());
	}
}
