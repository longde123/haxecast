/**
 * ...
 * @author JB
 */

package bravo.playa.simplecore;

import bravo.shout.flash.ShoutPlayer;
import bravo.shout.flash.PlayerEvent;
import control.Controller;
import control.PlayEvent;
import control.VolumeEvent;

import bravo.audio.Beat;

import flash.display.Sprite;
import flash.Lib;

import flash.text.TextFormat;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;

import flash.events.Event;
import flash.events.MouseEvent;

import feffects.easing.Linear;
import feffects.Tween;
import haxe.Timer;

import flash.ui.ContextMenu;
import flash.ui.ContextMenuItem;

class VTextParam
{
	public var size : Float;
	public var color : Int;
	public var alpha : Float;
	public var y : Float;
	public var x : Float;
	public var speed : Int;
	public var scale : Float;
	public var multiline : Bool;
	
	public function new(inSize : Float, inColor : Int, inAlpha : Float, inXpos : Float, inYpos : Float, inSpeed : Int, ?inScale : Float = 1.0, ?inMulti : Bool = false )
	{
		size = inSize;
		color = inColor;
		alpha = inAlpha;
		y = inYpos;
		x = inXpos;
		speed = inSpeed;
		scale = inScale;
		multiline = inMulti;
	}
	public function setFontFormat(font : String, isEmbed : Bool, par : Sprite) : { text : TextField, sprite : Sprite }
	{
		var fmt = new TextFormat(font, size, color, true);
		var txt = new TextField();
		txt.embedFonts = isEmbed;
		txt.defaultTextFormat = fmt;
		txt.autoSize = TextFieldAutoSize.LEFT;
		txt.text = '';
		txt.mouseEnabled = false;
		var spr = new Sprite();
		spr.addChild(txt);
		par.addChild(spr);
		spr.alpha = alpha;
		spr.cacheAsBitmap = true;
		spr.x = (par.width - txt.textWidth) / 2.0;
		spr.x = x;
		spr.y = y;
		spr.scaleY = scale;
		txt.multiline = multiline;
		if (txt.multiline)
		{
			txt.wordWrap = true;
			txt.width = par.stage.stageWidth - x;
		}
		return { text : txt, sprite : spr };
		
	}
}
class VTextConfig
{
	public static var leftColor : Int = 0x000000;
	public static var rightColor : Int = 0x666666;
	public static var useFont : String = "Arial";
	public static var isEmbed : Bool = false;
	public static var logo =         new VTextParam(80.0, 0xcccccc, 0.2, 0.0,  30.0, -21414, 2.0);
	public static var stationLarge = new VTextParam(56.0, 0x888888, 0.8, 0.0,   0.0,  14285);
	public static var stationSmall = new VTextParam(32.0, 0xffffff, 0.8, 0.0,  30.0,  14285);
	public static var songLarge =    new VTextParam(28.0, 0x888888, 0.8, 0.0, 195.0,  12121);
	public static var songSmall =    new VTextParam(18.0, 0xffffff, 0.8, 0.0, 190.0,  12121);
	public static var useBeat : Bool = false;
	public static var showbufferbar : Bool = true;
	public static var wantVideo : Bool = true;

}

class VideoCore extends Sprite
{
	var texts : Array<Null<VTextParam>>;
	var eng : ShoutPlayer;
	
	var audioBg : Sprite;
	var videoBg : Sprite;
	var theHost : String;
	var thePort : Int;
	var theRes : String;
	var theLogoText : String;
	var useFont : String;
	var isEmbed : Bool;
	var usebeat : Bool;
	function cleanup(e:Event)
	{
		trace('cleaning');
		while (getChildAt(0) != null)
		{
			removeChildAt(0);
		}
		removeEventListener(Event.UNLOAD, cleanup);
		removeEventListener(MouseEvent.MOUSE_OVER, showBuffer );
		removeEventListener(MouseEvent.MOUSE_OUT, showBuffer );
		removeEventListener(MouseEvent.MOUSE_MOVE, domove );
		eng.removeEventListener(PlayerEvent.SONG_TITLE, song_title);
		eng.removeEventListener(PlayerEvent.STREAM_TITLE, stream_title);
		eng.removeEventListener(PlayerEvent.VIDEO_PARAMETERS, videoOn);
		eng.removeEventListener(PlayerEvent.SOCKET_OPEN, listen);
		eng.removeEventListener(PlayerEvent.SOCKET_FAIL, listen);
		eng.removeEventListener(PlayerEvent.URL_OPEN, listen);
		eng.removeEventListener(PlayerEvent.URL_FAIL, listen);
		eng.removeEventListener(PlayerEvent.BUFFER_STATUS, buffer_status);
		if(usebeat)
		{
			audioBg.removeEventListener(MouseEvent.MOUSE_DOWN, changeBeat);
		}
	}
	function new(inHost : String, inPort : UInt, inRes : String, inLogoText : String)
	{
		useFont = VTextConfig.useFont;
		isEmbed = VTextConfig.isEmbed;
		theHost = inHost;
		thePort = inPort;
		theRes = inRes;
		theLogoText = inLogoText;
		usebeat = VTextConfig.useBeat;
		bufferDiv = 8.0;
		if (texts == null)
		{
			texts = new Array<Null<VTextParam>>();
			if (theLogoText != null && theLogoText.length > 0)
			{
				texts.push(VTextConfig.logo);
			}
			else
			{
				texts.push(null);
			}
			texts.push(VTextConfig.stationLarge);
			texts.push(VTextConfig.songLarge);
			texts.push(VTextConfig.stationSmall);
			texts.push(VTextConfig.songSmall);
		}
		if (texts.length < 1 || texts[0] == null)
		{
			usebeat = false;
		}
		super();
		addEventListener(Event.UNLOAD, cleanup);
		if (stage == null || stage.stageWidth == 0)
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		else
		{
			init(null);
		}
	}
	var controlSurface : Controller;
	public function init(e:Dynamic) 
	{
		if (e != null)
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}
		//var syn = new Synaesthesia(320, 240, 1, 1);
		//addChild(syn);
		audioBg = new Sprite();
		audioBg.graphics.lineStyle(0, 0, 0);
		audioBg.graphics.beginFill(0, 0);
		audioBg.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		audioBg.graphics.endFill();
		addChild(audioBg);
		videoBg = new Sprite();
		videoBg.visible = false;
		addChild(videoBg);
		videoBg.graphics.lineStyle(0, 0xccccff);
		videoBg.graphics.beginFill(0xccccff);
		videoBg.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		videoBg.graphics.endFill();
		InfoDisplay();
		
		controlSurface = new Controller(stage.stageWidth, stage.stageHeight);
		controlSurface.alpha = 0.0;
		controlSurface.bufferbar.visible = VTextConfig.showbufferbar;
		addEventListener(MouseEvent.MOUSE_OVER, showBuffer );
		addEventListener(MouseEvent.MOUSE_OUT, showBuffer );
		addEventListener(MouseEvent.MOUSE_MOVE, domove );

		controlSurface.addEventListener(PlayEvent.PLAY_START, doPlay);
		controlSurface.addEventListener(PlayEvent.PLAY_STOP, doStop);
		controlSurface.addEventListener(VolumeEvent.VOLUME_SET, doVolume);
		
		addChild(controlSurface);
		havePlayed = false;
		doPlay(null);
	}
	function doeng()
	{
		videoBg.addChild(eng = new ShoutPlayer(theHost, thePort, theRes, false, VTextConfig.wantVideo));
		
		eng.addEventListener(PlayerEvent.SONG_TITLE, song_title);
		eng.addEventListener(PlayerEvent.STREAM_TITLE, stream_title);
		eng.addEventListener(PlayerEvent.VIDEO_PARAMETERS, videoOn);
		eng.addEventListener(PlayerEvent.SOCKET_OPEN, listen);
		eng.addEventListener(PlayerEvent.SOCKET_FAIL, listen);
		eng.addEventListener(PlayerEvent.URL_OPEN, listen);
		eng.addEventListener(PlayerEvent.URL_FAIL, listen);
		eng.addEventListener(PlayerEvent.BUFFER_STATUS, buffer_status);
	}
	var havePlayed : Bool;
	function doPlay(e:PlayEvent)
	{
		if (eng == null)
		{
			doeng();
		}
		eng.go();
		if (!havePlayed) 
		{
			havePlayed = true;
			controlSurface.setVolume(0.5);
		}
		else
		{
			controlSurface.setVolume(controlSurface.theVolume);
		}
	}
	function doStop(e:PlayEvent)
	{
		setSongName("");
		setStationName("");
		if(eng != null)
		{
			eng.stop();
		}
	}
	static var div = -Math.PI;
	function doVolume(e: VolumeEvent)
	{
		var vol = e.volume;
		
		if (vol > 0.95) 
		{
			vol = 1.0;
		}
		else if (vol < 0.05)
		{
			vol = 0.0;
		}
		else
		{
			vol = Math.log(1 - vol) / div;
			//vol = Math.pow(vol, 3);
		}
		if (vol > 1.0) 
		{
			vol = 1.0;
		}
		else if (vol < 0.00)
		{
			vol = 0.0;
		}
		eng.setVolume(vol);
	}
	var timer : Timer;
	
	function showBuffer(e : MouseEvent)
	{
		dotimer(e.type == MouseEvent.MOUSE_OVER);
	}

	function dotimer(b : Null<Bool>)
	{
		if (b == null || b == true)
		{
			controlSurface.alpha = 1.0;
			if (timer == null || b == null)
			{
				if (b == null)
				{
					timer.stop();
				}
				timer = new Timer(2000);
				timer.run=timeout;
			}
		}
		else
		{
			controlSurface.alpha = 0.0;
			if (timer != null)
			{
				timer.stop();
				timer = null;
			}
		}
	}
	function domove(e : MouseEvent)
	{
		if (timer == null)
		{
			dotimer(true);
		}
		else
		{
			dotimer(null);
		}
	}
	function timeout()
	{
		controlSurface.alpha = 0.0;
		if (timer != null)
		{
			timer.stop();
			timer = null;
		}
	}
	var bt : Beat;
	function setStationName(name : String)
	{
		if (name != null)
		{
#if !debug
			if(txtStation2 != null)
			{
				txtStation2.text = name;
			}
			if(txtStation != null)
			{
				txtStation.text = name;
			}
#end
		}
	}
	
	function setSongName(name : String)
	{
		if (name != null)
		{
			if (name.substr(0, 1) == "'" || name.substr(0, 1) == '"')
			{
				name = name.substr(1, name.length - 2);
			}
#if !debug
			if(txtSong2 != null)
			{
				txtSong2.text = name;
			}
			if(txtSong != null)
			{
				txtSong.text = name;
			}
#end
		}
	}
	
	function setSongUrl(name : String)
	{
		if (name != null)
		{
			if (name.substr(0, 1) == "'" || name.substr(0, 1) == '"')
			{
				name = name.substr(1, name.length - 2);
			}
#if debug
			trace('songurl:'+name);
#end
		}
	}
	var txtStation : TextField;
	var sprStation : Sprite;
	var txtSong : TextField;
	var sprSong : Sprite;

	var txtStation2 : TextField;
	var sprStation2 : Sprite;
	var txtSong2 : TextField;
	var sprSong2 : Sprite;

	var txtLogo : TextField;
	var sprLogo : Sprite;

	function seteffect(spr : Sprite, spd : Int)
	{
		if (spd != 0)
		{
			var w = stage.stageWidth;
			var v =
			if (spd < 0)
			{
				new Tween(w, 0, -spd, Linear.easeInOut);
			}
			else
			{
				new Tween(0, w, spd, Linear.easeInOut);
			}
			v.setTweenHandlers(
				function(p : Float)
				{
					spr.x = (w - p) - (p / w * spr.width);
				},
				function(p : Float)
				{
					v.start();
				}
			);
			v.start();
		}
	}
	
	function seteffect2(spr : Sprite, spr2 : Sprite, spd : Int)
	{
		if (spd != 0)
		{
			var w = stage.stageWidth;
			var v =
			if (spd < 0)
			{
				new Tween(w, 0, -spd, Linear.easeInOut);
			}
			else
			{
				new Tween(0, w, spd, Linear.easeInOut);
			}
			v.setTweenHandlers(
				function(p : Float)
				{
					spr.x = (w - p) - (p / w * spr.width);
					spr2.x = (w - p) - (p / w * spr2.width);
				},
				function(p : Float)
				{
					v.start();
				}
			);
			v.start();
		}
	}
	
	function changeBeat(e:MouseEvent) 
	{
		if (usebeat)
		{
			bt.enable();
			if (!bt.enabled)
			{
				sprLogo.alpha = texts[0].alpha;
			}
			sprLogo.cacheAsBitmap = !bt.enabled;
		}
	}
	function InfoDisplay()
	{
#if !debug
		graphics.lineStyle(0, VTextConfig.leftColor);
		graphics.beginFill(VTextConfig.leftColor);
		graphics.drawRect(0, 0, width/2, height);
		graphics.endFill();
		graphics.lineStyle(0, VTextConfig.rightColor);
		graphics.beginFill(VTextConfig.rightColor);
		graphics.drawRect(width/2, 0, width/2, height);
		graphics.endFill();

		var ret;
		if (texts.length > 0 && texts[0] != null)
		{
			ret = texts[0].setFontFormat(useFont, isEmbed, audioBg);
			txtLogo = ret.text;
			sprLogo = ret.sprite;
			txtLogo.text = theLogoText;
			sprLogo.x = (audioBg.width - sprLogo.width) / 2;
		}
		if (usebeat)
		{
			bt = new Beat(sprLogo, "alpha", 6, 0, 8, 48.0, 0.3);
			bt.enable(false);
			audioBg.addEventListener(MouseEvent.MOUSE_DOWN, changeBeat);
		}
		if (texts.length > 1 && texts[1] != null)
		{
			ret = texts[1].setFontFormat(useFont, isEmbed, audioBg);
			txtStation2 = ret.text;
			sprStation2 = ret.sprite;
		}
		if (texts.length > 2 && texts[2] != null)
		{
			ret = texts[2].setFontFormat(useFont, isEmbed, audioBg);
			txtSong2 = ret.text;
			sprSong2 = ret.sprite;
		}
		if (texts.length > 3 && texts[3] != null)
		{
			ret = texts[3].setFontFormat(useFont, isEmbed, audioBg);
			txtStation = ret.text;
			sprStation = ret.sprite;
		}
		if (texts.length > 4 && texts[4] != null)
		{
			ret = texts[4].setFontFormat(useFont, isEmbed, audioBg);
			txtSong = ret.text;
			sprSong = ret.sprite;
		}
		if (sprLogo != null)
		{
			seteffect(sprLogo, texts[0].speed);
		}
		
		if (sprSong != null && sprSong2 != null && texts[2].speed == texts[4].speed)
		{
			seteffect2(sprSong, sprSong2, texts[2].speed);
		}
		else 
		{
			if (sprSong2 != null)
			{
				seteffect(sprSong2, texts[2].speed);
			}
			if (sprSong != null)
			{
				seteffect(sprSong, texts[4].speed);
			}
		}
		if (sprStation != null && sprStation2 != null && texts[1].speed == texts[3].speed)
		{
			seteffect2(sprStation, sprStation2, texts[1].speed);
		}
		else 
		{
			if (sprStation2 != null)
			{
				seteffect(sprStation2, texts[1].speed);
			}
			if (sprStation != null)
			{
				seteffect(sprStation, texts[3].speed);
			}
		}
#end
	}
	
	function videoOn(e : PlayerEvent)
	{
		videoBg.visible = VTextConfig.wantVideo;
		audioBg.visible = !VTextConfig.wantVideo;
	}
	function song_title(e : PlayerEvent)
	{
		var o : SongTitle = e.objVal;
		setSongName(o.StreamTitle);
		setSongUrl(o.StreamUrl);
	}
	function stream_title(e: PlayerEvent)
	{
		var o : StreamName = e.objVal;
		setStationName(o.name);
	}
	public var bufferDiv : Float;
	function buffer_status(e : PlayerEvent)
	{
		var o : BufferStatus = e.objVal;
		if (o.bufferLength >= o.bufferTime * bufferDiv)
		{
			controlSurface.setPart(1.0);
		}
		else
		{
			controlSurface.setPart((o.bufferLength / o.bufferTime) / bufferDiv );
		}
	}
	function listen(e : PlayerEvent)
	{
		switch(e.eventType)
		{
			case PlayerEvent.CODEC_METADATA:
				//var o : MetaData = e.objVal;
			case PlayerEvent.XML_METADATA:
				//var o : XmlMeta = e.objVal;
			case PlayerEvent.SONG_TITLE:
				//var o : SongTitle = e.objVal;
			case PlayerEvent.STREAM_TITLE:
				//var o : StreamName = e.objVal;
			case PlayerEvent.VIDEO_PARAMETERS:
				//var o : VideoParameters = e.objVal;
			case PlayerEvent.BUFFER_STATUS:
				//var o : BufferStatus = e.objVal;
			case PlayerEvent.SOCKET_OPEN:
				controlSurface.setColor(0x88cc88, 0xccffcc);
			case PlayerEvent.SOCKET_FAIL:
				controlSurface.setColor(0x000088, 0x0000ff);
			case PlayerEvent.URL_OPEN:
				controlSurface.setColor(0x888844, 0xffff88);
			case PlayerEvent.URL_FAIL:
				controlSurface.setColor(0x880000, 0xff0000);
		}
	}
}