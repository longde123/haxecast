/**
 * ...
 * @author JB
 */

package bravo.shout.tag;

import haxe.io.Bytes;
import haxe.io.BytesInput;
class FlvHeader 
{
	public static function flvheader(hasaudio : Bool, hasvideo : Bool) : Bytes
	{
		var ret = Bytes.alloc(13);
		ret.set(0, 0x46); // 'F'
		ret.set(1, 0x4C); // 'L'
		ret.set(2, 0x56); // 'V'
		ret.set(3, 1); //  1
		ret.set(4, (hasaudio ? 4 : 0) | (hasvideo ? 1 : 0)); // flags
		ret.set(5, 0); // 0
		ret.set(6, 0); // 0
		ret.set(7, 0); // 0
		ret.set(8, 9); // 9
		ret.set(9, 0); // 0
		ret.set(10, 0); // 0
		ret.set(11, 0); // 0
		ret.set(12, 0); // 0
		return ret;
	}
	public static function dumptagheader(t : Bytes) : String
	{
		var rdr = new BytesInput(t);
		rdr.bigEndian = true;
		var tag = rdr.readInt24();
		var vers = rdr.readByte();
		var flags = rdr.readByte();
		var length = rdr.readInt32();
		var zero = rdr.readInt32();
		return (StringTools.hex(tag,3) + "v" + vers + ":" + flags + ':' + length + ':' + zero);
	}
}