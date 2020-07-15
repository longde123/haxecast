/**
 * ...
 * @author JB
 */

package bravo.shout.tag;

import bravo.shout.tag.Tag;
import haxe.io.Bytes;

class TagMeta extends Tag, implements ITag
{
	public function new(data : Bytes, time : Float)
	{
		super(TagMetaData, time);
		endtag(data);
	}
}