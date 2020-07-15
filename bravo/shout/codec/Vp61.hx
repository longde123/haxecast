/**
 * ...
 * @author JB
 */
package bravo.shout.codec;

import haxe.io.Bytes;
import bravo.shout.codec.CodecEvent;

class Vp61 extends Vp6, implements ICodec
{
	public function new(?inc : Float = 0.0) 
	{
		codecName = 'VP61';
		super(inc);
	}
}