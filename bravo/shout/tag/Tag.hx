/**
 * ...
 * @author JB
 */

package bravo.shout.tag;

import haxe.Int32;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;

enum TagType 
{
	TagAudioData;
	TagVideoData;
	TagMetaData;
}

class Tag 
{
	public var tag(default, null) : Bytes;
	public var tagtype(default, null) : Int;
	public var thigh(default, null) : Int;
	public var tlow(default, null) : Int;
	public var rtmptagdata(default, null) : Bytes;
	var twrite : BytesOutput;
	
	public function new(type : TagType, time : Float) 
	{
		thigh = 0;
		while (time > 16777216.0)
		{
			thigh++;
			time -= 16777216.0;
		}
		tlow = Std.int(time);
		twrite = new BytesOutput();
		twrite.bigEndian = true;

		tagtype = switch(type)
			{
				case TagAudioData : 8;
				case TagVideoData : 9;
				case TagMetaData : 18;
			};
		twrite.writeByte(tagtype);
		twrite.writeInt24(0); // length of data ... filled in later = packet length - 15
		twrite.writeUInt24(tlow);
		twrite.writeByte(thigh);
		twrite.writeInt24(0);
	}
	function writeByte(v : Int)
	{
		twrite.writeByte(v);
	}
	
	function overwrite24(pos : Int, val : Int)
	{
		tag.set(pos, val >>> 16);
		tag.set(pos + 1, (val >>> 8) & 0xff);
		tag.set(pos + 2, val & 0xff);
	}
	
	function endtag(data : Null<Bytes>)
	{
		if (data != null && data.length > 0)
		{
			twrite.writeBytes(data, 0, data.length);
		}
		else
		{
#if debug
			//trace('no data');
#end
		}
		twrite.writeByte(0);
		twrite.writeInt24(0); // filled in later
		tag = twrite.getBytes();
		var size = tag.length - 4;
		var sizeData = size - 11;
		overwrite24(1, sizeData);
		overwrite24(tag.length - 3, size);
		rtmptagdata = tag.sub(11, sizeData);
	}
	
	public static function dumptag(t : Bytes) : String
	{
		var rdr = new BytesInput(t);
		rdr.bigEndian = true;
		var type : Int = -1;
		var size : Int = -1;
		var timlo : Int = -1;
		var timhi : Int = -1;
		var strid : Int = -1;
		var frst : Int = -1;
		var scnd : Int = -1;
		var data : Bytes;
		var end : Int32 = Int32.ofInt(1);
		try
		{
			type = rdr.readByte();
			if (type != 8 && type != 9 && type != 18)
			{
				throw "type error";
			}
			size = rdr.readInt24();
			timlo = rdr.readUInt24();
			timhi = rdr.readByte();
			strid = rdr.readInt24();
			frst = rdr.readUInt16();
			scnd = rdr.readUInt16();
			if (size != t.length - 15)
			{
				throw "size error";
			}
			var dummy : Bytes = Bytes.alloc(size - 4);
			if (size > 4)
			{
					var data = rdr.readFullBytes(dummy, 0, size - 4);
			}
			end = rdr.readInt32();
		}
		catch (e : Dynamic)
		{
			trace(e + ':' + type + ':' + t.length + ':' + size);
		}
		rdr.close();
		return ((StringTools.hex(timhi,2)+StringTools.hex(timlo,6)) + ":" + type + ':' + size + ':' + StringTools.hex(frst,4)+StringTools.hex(scnd,4) + ':' + end);
	}
}