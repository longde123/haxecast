/**
 * ...
 * @author JB
 */

package bravo.shout.tag;

import haxe.Int32;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;

enum DataTagType 
{
	DataTagAudioData;
	DataTagVideoData;
	DataTagMetaData;
}

enum DTWhere
{
	DTWFlv;
	DTWRaw;
	DTWBoth;
}
class DataTag 
{
	public var rawdata(default, null) : Bytes;
	public var flvdata(default, null) : Bytes;
	
	public var tagtype(default, null) : Int;
	public var thigh(default, null) : Int;
	public var tlow(default, null) : Int;

	var flvwrite : BytesOutput;
	var rawwrite : BytesOutput;
	
	public function new(type : DataTagType, time : Float) 
	{
		thigh = 0;
		while (time > 16777216.0)
		{
			thigh++;
			time -= 16777216.0;
		}
		tlow = Std.int(time);
		flvwrite = new BytesOutput();
		flvwrite.bigEndian = true;
		rawwrite = new BytesOutput();
		rawwrite.bigEndian = true;
		tagtype = switch(type)
			{
				case DataTagAudioData : 8;
				case DataTagVideoData : 9;
				case DataTagMetaData : 18;
			};
		flvwrite.writeByte(tagtype);
		flvwrite.writeInt24(0); // length of data ... filled in later = packet length - 15
		flvwrite.writeUInt24(tlow);
		flvwrite.writeByte(thigh);
		flvwrite.writeInt24(0);
	}
	function writeByte(v : Int, where : DTWhere)
	{
		if (where == DTWFlv || where == DTWBoth)
		{
			flvwrite.writeByte(v);
		}
		if (where == DTWRaw || where == DTWBoth)
		{
			rawwrite.writeByte(v);
		}
	}
	
	function writeBytes(buf : Bytes, pos : Int, len : Int, where : DTWhere)
	{
		if (where == DTWFlv || where == DTWBoth)
		{
			flvwrite.writeBytes(buf, pos, len);
		}
		if (where == DTWRaw || where == DTWBoth)
		{
			rawwrite.writeBytes(buf, pos, len);
		}
	}

	function overwrite24(pos : Int, val : Int)
	{
		flvdata.set(pos, val >>> 16);
		flvdata.set(pos + 1, (val >>> 8) & 0xff);
		flvdata.set(pos + 2, val & 0xff);
	}
	
	function endtag()
	{
		flvwrite.writeByte(0);
		flvwrite.writeInt24(0); // filled in later
		flvdata = flvwrite.getBytes();
		var size = flvdata.length - 4;
		var sizeData = size - 11;
		overwrite24(1, sizeData);
		overwrite24(flvdata.length - 3, size);
		rawdata = rawwrite.getBytes();
		flvwrite.close();
		rawwrite.close();
		flvwrite = null;
		rawwrite = null;
	}
}