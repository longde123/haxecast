/**
 * ...
 * @author JB
 */

package bravo.shout.codec;

import haxe.io.Bytes;
import bravo.shout.codec.CodecEvent;
import hsl.haxe.Signaler;

interface ICodec 
{
	function process(buff : Bytes, pos : Int, len : Int) : Null<Int>;
	function fill(buff : Bytes, pos : Int, len : Int) : Void;
	function addFrames(n : Int) : Void;
	function cleanup() : Void;
	var frameTime(default, null) : Float;
	var frames(default, null) : Float;
	var codecType(default, null) : CodecMsgTypes;
	var flvdata(default, null) : Signaler<CodecEvent>;
	var rawdata(default, null) : Signaler<CodecEvent>;
	var audioStream(default, null) : ICodec;
	var videoStream(default, null) : ICodec;
	var codecName(default, null) : String;
}