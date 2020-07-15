/**
 * ...
 * @author JB
 */

package bravo.shout.tag;
import haxe.io.Bytes;

interface ITag 
{
	var tag(default, null) : Bytes;
	var tagtype(default, null) : Int;
	var thigh(default, null) : Int;
	var tlow(default, null) : Int;
	var rtmptagdata(default, null) : Bytes;
}