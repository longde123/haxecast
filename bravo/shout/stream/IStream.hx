/**
 * ...
 * @author JB
 */

package bravo.shout.stream;

import haxe.io.Bytes;
import bravo.shout.stream.StreamEvent;
import hsl.haxe.Signaler;

interface IStream
{
	function process(buff : Bytes, pos : Int, len : Int) : Null<Int>;
	function fill(buff : Bytes, pos : Int, len : Int) : Void;
	function cleanup() : Void;
	var streamdata(default, null) : Signaler<StreamEvent>;
	var streamName(default, null) : String;
}