/**
 * ...
 * @author JB
 */

package bravo.shout.protocol;

import haxe.io.Bytes;

enum ProtocolMsgTypes
{
	ProStart;
	ProName;
	ProHeader;
	ProStreamStart;
	ProCodecStart;
	ProData;
	ProMeta;
	ProHeaderError;
	ProError;
	
	ProUvoxBroadcaster;
	ProUvoxListener;
	ProUvoxCacheableMetadata;
	ProUvoxNonCacheableMetadata;
}
typedef ProtocolMsg =
{
	var msgtype : ProtocolMsgTypes;
	var msgdata : Dynamic;
	//var msgtime : Float;
}

class ProtocolEvent
{
	public var data(default, null) : Dynamic;
	public var time(default, null) : Float;
	public var msgtyp(default, null) : ProtocolMsgTypes;
	
	public function new(msgType : ProtocolMsgTypes, Data : Dynamic)
	{
		#if foras3
		time = untyped __new__ (Date);
		#else
		time = Date.now().getTime();
		#end
		msgtyp = msgType;
		data = Data;// Bytes.ofData(dat.getData());
	}
}
