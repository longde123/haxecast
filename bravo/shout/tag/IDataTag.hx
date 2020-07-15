/**
 * ...
 * @author JB
 */

package bravo.shout.tag;
import haxe.io.Bytes;

interface IDataTag 
{
	var rawdata(default, null) : Bytes;
	var flvdata(default, null) : Bytes;
	var tagtype(default, null) : Int;
	var thigh(default, null) : Int;
	var tlow(default, null) : Int;
}