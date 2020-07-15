/**
 * ...
 * @author JB
 */

package bravo.shout.stream;

import haxe.io.Bytes;

enum StreamMsgTypes
{
	StrStart;
	StrData;
	StrV1MetaData;
	StrError;
	//StrInformation;
	//StrV2MetaData;
	//StrEnd;
}
typedef StreamMsg =
{
	var msgtype : StreamMsgTypes;
	var uvoxtype : Int;
	var msgdata : Bytes;
	//var msgtime : Float;
}

class StreamEvent
{
	public var data(default, null) : Bytes;
	public var time(default, null) : Float;
	public var msgtyp(default, null) : StreamMsgTypes;
	public var uvoxtype(default, null) : Int;
	
	public function new(msgType : StreamMsgTypes, uVox : Int, Data : Bytes)
	{
		#if foras3
		time = untyped __new__ (Date);
		#else
		time = Date.now().getTime();
		#end
		msgtyp = msgType;
		uvoxtype = uVox;
		data = Data;
	}
}
