/**
 * ...
 * @author JB
 */

package bravo.shout.protocol;

import bravo.shout.codec.ICodec;
import bravo.shout.stream.IStream;
import haxe.io.Bytes;
import bravo.shout.protocol.ProtocolEvent;
import hsl.haxe.Signaler;

interface IProtocol
{
	function process(buff : Bytes, pos : Int, len : Int) : Null<Int>;
	function fill(buff : Bytes, pos : Int, len : Int) : Void;
	function cleanup() : Void;
	var protodata(default, null) : Signaler<ProtocolEvent>;
	var stream(default, null) : IStream;
	var codec(default, null) : ICodec;
	var protocolName(default, null) : String;
	var params(default, null) : Hash<String>;
}