/**
 * ...
 * @author JB
 */

package bravo.shout.codec;

import bravo.shout.codec.CodecEvent;
import bravo.shout.codec.Video;
import bravo.shout.tag.DataTag;
import bravo.shout.tag.IDataTag;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;

private enum AvcState {
	AvcWaitForFrame(prevChar : Int, prevChar1 : Int, prevChar2 : Int);
	AvcGetFullFrame(offset : Int);
	AvcProcessFrame(size : Int);
}

class Avc extends Video, implements ICodec
{
// Frame 0x00 0x00 0x00 0x01 .... 0x00 0x00 0x00 0x01
	public function new(?inc : Float = 0.0) 
	{
		codecName = 'AVC';
		super(inc);
		myState = AvcWaitForFrame(0xff, 0xff, 0xff);
		sentHdr = false;
		_PPS = null;
		_SPS = null;
	}
	private var myState : AvcState;
	private var sentHdr : Bool;
	private var _PPS : Bytes;
	private var _SPS : Bytes;
	
	override public function process(buff : Bytes, pos : Int, len : Int) : Null<Int>
	{
		switch(myState)
		{
			case AvcWaitForFrame(prevChar, prevChar1, prevChar2):
				if( len < 1 )
				{
					return null;
				}
				var char = buff.get(pos);

				if (prevChar2 == 0x00 && prevChar1 == 0x00 && prevChar == 0x00 && char == 0x01) 
				{
					myState = AvcGetFullFrame(0);
				} 
				else 
				{
					myState = AvcWaitForFrame(char, prevChar, prevChar1);
				}
				return 1;
			case AvcGetFullFrame(offset):
				if (len < 5)
				{
					return null;
				}
				var found = false;
				var srchlen = len - (pos + offset) - 3;
				for (i in offset...srchlen)
				{
					if (buff.get(pos + offset) == 0)
					{
						if (buff.get(pos + offset + 1) == 0)
						{
							if (buff.get(pos + offset + 2) == 0)
							{
								if (buff.get(pos + offset + 3) == 1)
								{
									myState = AvcProcessFrame(offset - pos);
									return 0;
									break;
								}
							}
						}
					}
				}
				myState = AvcGetFullFrame(offset + srchlen);
				return null;
			case AvcProcessFrame(size):
				var frmType = buff.get(pos) & 0x1f;
#if debug
				trace('Found frame, type = ' + frmType + ' len = ' + size);
#end
				// process the frame - if a frame is output addFrames(1);
				var raw = Bytes.alloc(size + 4);
				raw.set(3, 1);
				raw.blit(4, buff, pos, size);
				// flashdata: null
				// nekodata: null
				// codecdata: the raw data
				myState = AvcGetFullFrame(0);
				switch (frmType)
				{
					case 1,5: // CodedSlice, IDR
						addFrames(1);
						if (sentHdr)
						{
							// flashdata: [0x17] 0x01 0x000000 0xssssssss ......
							// nekodata: null
							// codecdata: the raw data
							var d = new BytesOutput();
							d.bigEndian = true;
							d.writeByte(0x01);
							d.writeUInt24(0);
							d.writeByte(size >> 24);
							d.writeUInt24(size & 0xffffff);
							d.writeBytes(buff, pos, size-1);
							d.writeByte(0);
							if(flvdata.isListenedTo)
							{
								flvdata.dispatch(
									new CodecEvent(
										codecType, 
										new VideoTag(_codecSetup, 0.0, xAVC, Key).tag, 
										frameTime
									)
								);
							}
						}
					case 7,8: // SPS, PPS
						if (!sentHdr)
						{
							if(frmType == 7)
							{
								_SPS = buff.sub(pos, size);
							}
							else
							{
								_PPS = buff.sub(pos, size);
							}
							if (_SPS != null && _PPS != null)
							{
								if (makeHeader())
								{
									// flashdata: [0x17] 0x00 0x000000 ......
									// nekodata: null
									// codecdata: the raw data
									if(flvdata.isListenedTo)
									{
										flvdata.dispatch(
											new CodecEvent(
												CodVideoPreData, 
												new VideoTag(_codecSetup, 0.0, xAVC, Key).tag, 
												frameTime
											)
										);
										sentHdr = true;
									}
								}
							}
						}
				}
				if(rawdata.isListenedTo)
				{
					rawdata.dispatch(
						new CodecEvent(
							CodVideoData, 
							raw, 
							frameTime
						)
					);
				}
				// ignore all other frame types !?!
				return size + 4;
		}
	}
	private var _codecSetupLength : Int;
	private var _codecSetup : Bytes;
	private function makeHeader():Bool
	{
		
		if (_PPS == null || _SPS == null) 
		{
			return false;
		}
		
		_codecSetupLength = 5 
			+ 8 
			+ _SPS.length 
			+ 3 
			+ _PPS.length; 
		
		_codecSetup = Bytes.alloc(_codecSetupLength);
		
		var cursor:Int = 0;
		
		var tBuff : BytesOutput = new BytesOutput();
		tBuff.bigEndian = true;
		// tBuff.writeByte(0x17); VideoTag will make this for us
		tBuff.writeByte(0);
		tBuff.writeUInt24(0x000000);
		tBuff.writeByte(0x01);
		tBuff.writeByte(_SPS.get(1));
		tBuff.writeByte(_SPS.get(2));
		tBuff.writeByte(_SPS.get(3));
		tBuff.writeUInt16(0x0301);
		tBuff.writeUInt16(_SPS.length);
		tBuff.writeBytes(_SPS, 0, _SPS.length);
		tBuff.writeByte(1);
		tBuff.writeUInt16(_PPS.length);
		tBuff.writeBytes(_PPS, 0, _PPS.length);
		_codecSetup = tBuff.getBytes();
		return true;
	}
}
class DataTagVideoAvc extends DataTagVideo, implements IDataTag
{
	public function new(flvPreData : Bytes, data : Bytes, time : Float, type : TagVideoTypes)
	{
		super(time, xAVC, type);
		if (flvPreData != null)
		{
			writeBytes(flvPreData, 0, flvPreData.length, DTWFlv);
		}
		if (data != null)
		{
			if (flvPreData != null)
			{
				writeBytes(data, 0, data.length, DTWBoth);
			}
			else
			{
				writeBytes(data, 0, data.length, DTWRaw);
			}
		}
		this.endtag();
	}
}
