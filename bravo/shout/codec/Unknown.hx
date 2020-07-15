/**
 * ...
 * @author JB
 */

package bravo.shout.codec;

import haxe.io.Bytes;
import bravo.shout.codec.CodecEvent;
import bravo.shout.codec.ICodec;

class Unknown extends CodecBase, implements ICodec
{
	public function process(buff : Bytes, pos : Int, len : Int) : Null<Int>
	{
		return len;
	}
}