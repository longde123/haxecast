/**
 * ...
 * @author JB
 */

package bravo.playa.core;

import bravo.shout.flash.ShoutPlayer;
import bravo.shout.flash.PlayerEvent;
import control.BufferBar;
import control.PlayButton;
import control.PlayEvent;
import control.Volume;

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

class TextParamX
{
	public var size(default, null) : Float;
	public var color(default, null) : Int;
	public var alpha(default, null) : Float;
	public var y(default, null) : Float;
	public var speed(default, null) : Int;
	public var scale(default, null) : Float;
	
	public function new(inSize : Float, inColor : Int, inAlpha : Float, inYpos : Float, inSpeed : Int, ?inScale : Float = 1.0 )
	{
		size = inSize;
		color = inColor;
		alpha = inAlpha;
		y = inYpos;
		speed = inSpeed;
		scale = inScale;
	}
}
class FlashCoreX extends Sprite
{
	var texts : Array<Null<TextParamX>>;
	var eng : ShoutPlayer;
	
	var audioBg : Sprite;
	var videoBg : Sprite;
	var theHost : String;
	var thePort : Int;
	var theRes : String;
	var theLogoText : String;
	var bufferbar : BufferBar;
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
		removeChild(volume);
		volume = null;
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
			audioBg.removeEventListener(MouseEvent.MOUSE_DOWN, changeBeat);
	}
	function new(inHost : String, inPort : UInt, inRes : String, inLogoText : String, ?inBeat : Bool = false, ?inFont : String = "Arial", ?inEmbed : Bool = false)
	{
		useFont = inFont;
		isEmbed = inEmbed;
		theHost = inHost;
		thePort = inPort;
		theRes = inRes;
		theLogoText = inLogoText;
		usebeat = inBeat;
		bufferDiv = 8.0;
		if (texts == null)
		{
			texts = new Array<Null<TextParamX>>();
			if (theLogoText != null && theLogoText.length > 0)
			{
				texts.push(new TextParamX(112.0, 0xcccccc, 0.4, -35, -31415, 2.0));
			}
			else
			{
				texts.push(null);
			}
			texts.push(new TextParamX( 56.0, 0x888888, 0.8,   0,  14285)); // station2
			texts.push(new TextParamX( 28.0, 0x888888, 0.8, 170,  21212)); // song2
			texts.push(new TextParamX( 32.0, 0xffffff, 0.8,  40,  14285)); // station
			texts.push(new TextParamX( 18.0, 0xffffff, 0.8, 165,  21212)); // song
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
	var volume : Volume;
	var pp : PlayButton;
	var controlSurface : Sprite;
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
		addChild(videoBg);
		videoBg.graphics.lineStyle(0, 0xccccff);
		videoBg.graphics.beginFill(0xccccff);
		videoBg.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		videoBg.graphics.endFill();
		InfoDisplay();
		
		controlSurface = new Sprite();
		controlSurface.alpha = 0.0;
		bufferbar = new BufferBar(stage.stageWidth);
		controlSurface.addChild(bufferbar);
		controlSurface.addChild(volume = new Volume(stage.stageWidth - 20, 0, 20, stage.stageHeight, volcb));
		bufferbar.y = stage.stageHeight - BufferBar.ht;
		bufferbar.x = 0;
		bufferbar.setPart(1.0);
		addEventListener(MouseEvent.MOUSE_OVER, showBuffer );
		addEventListener(MouseEvent.MOUSE_OUT, showBuffer );
		addEventListener(MouseEvent.MOUSE_MOVE, domove );

		pp = new PlayButton(true);
		controlSurface.addChild(pp);
		pp.x = (stage.stageWidth - pp.width) / 2;
		pp.y = (stage.stageHeight - pp.height) / 2;
		pp.addEventListener(PlayEvent.PLAY_START, doPlay);
		pp.addEventListener(PlayEvent.PLAY_STOP, doStop);

		eng = new ShoutPlayer(theHost, thePort, theRes);
		
		eng.addEventListener(PlayerEvent.SONG_TITLE, song_title);
		eng.addEventListener(PlayerEvent.STREAM_TITLE, stream_title);
		eng.addEventListener(PlayerEvent.VIDEO_PARAMETERS, videoOn);
		eng.addEventListener(PlayerEvent.SOCKET_OPEN, listen);
		eng.addEventListener(PlayerEvent.SOCKET_FAIL, listen);
		eng.addEventListener(PlayerEvent.URL_OPEN, listen);
		eng.addEventListener(PlayerEvent.URL_FAIL, listen);
		eng.addEventListener(PlayerEvent.BUFFER_STATUS, buffer_status);
		videoBg.addChild(eng);
		volume.alpha = 0.9;
		addChild(controlSurface);

		pp.addEventListener(PlayEvent.PLAY_START, doPlay);
		pp.addEventListener(PlayEvent.PLAY_STOP, doStop);
		havePlayed = false;
		doPlay(null);
	}
	var havePlayed : Bool;
	function doPlay(e:PlayEvent)
	{
		eng.go();
		if (!havePlayed) 
		{
			havePlayed = true;
			volume.setPlay(0.5);
			volcb(0.5);
		}
		else
		{
			volcb(theVolume);
		}
	}
	function doStop(e:PlayEvent)
	{
		eng.stop();
	}
	static var div = -3.0;
	var theVolume : Float;
	function volcb(vol : Float)
	{
		theVolume = vol;
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
		if (e.type == MouseEvent.MOUSE_OUT)
		{
			volume.stopDragging();
		}
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
#if !debug
		if(texts.length > 1)
			txtStation2.text = name;
		if(texts.length > 3)
			txtStation.text = name;
#end
	}
	
	function setSongName(name : String)
	{
		if (name.substr(0, 1) == "'" || name.substr(0, 1) == '"')
		{
			name = name.substr(1, name.length - 2);
		}
#if !debug
		if(texts.length > 2)
			txtSong2.text = name;
		if(texts.length > 4)
			txtSong.text = name;
#end
	}
	
	function setSongUrl(name : String)
	{
		if (name.substr(0, 1) == "'" || name.substr(0, 1) == '"')
		{
			name = name.substr(1, name.length - 2);
		}
#if debug
		trace('songurl:'+name);
#end
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

	function setFontFormat( tfmt : TextParamX ) : { text : TextField, sprite : Sprite }
	{
		var fmt = new TextFormat(useFont, tfmt.size, tfmt.color, true);
		var txt = new TextField();
		txt.embedFonts = isEmbed;
		txt.defaultTextFormat = fmt;
		txt.autoSize = TextFieldAutoSize.LEFT;
		txt.text = '';
		txt.mouseEnabled = false;
		var spr = new Sprite();
		spr.addChild(txt);
		audioBg.addChild(spr);
		spr.alpha = tfmt.alpha;
		spr.cacheAsBitmap = true;
		spr.x = 0;
		spr.y = tfmt.y;
		spr.scaleY = tfmt.scale;
		return { text : txt, sprite : spr };
		
	}

	function seteffect(spr : Sprite, spd : Int)
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
		v.setTweenHandlers(function(p : Float)
		{
			spr.x = (w - p) - (p / w * spr.width);
		},
		function(p : Float)
		{
			v.start();
		});
		v.start();
	}
	
	function seteffect2(spr : Sprite, spr2 : Sprite, spd : Int)
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
		v.setTweenHandlers(function(p : Float)
		{
			spr.x = (w - p) - (p / w * spr.width);
			spr2.x = (w - p) - (p / w * spr2.width);
		},
		function(p : Float)
		{
			v.start();
		});
		v.start();
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
		graphics.lineStyle(0, 0x0);
		graphics.beginFill(0x0);
		graphics.drawRect(0, 0, width/2, height);
		graphics.endFill();
		graphics.lineStyle(0, 0xaaaaaa);
		graphics.beginFill(0xaaaaaa);
		graphics.drawRect(width/2, 0, width/2, height);
		graphics.endFill();

		var ret;
		if (texts.length > 0 && texts[0] != null)
		{
			ret = setFontFormat(texts[0]);
			txtLogo = ret.text;
			sprLogo = ret.sprite;
			txtLogo.text = theLogoText;
		}
		if (usebeat)
		{
			bt = new Beat(sprLogo, "alpha", 6, 0, 8, 48.0, 0.3);
			bt.enable(false);
			audioBg.addEventListener(MouseEvent.MOUSE_DOWN, changeBeat);
		}
		if (texts.length > 1)
		{
			ret = setFontFormat(texts[1]);
			txtStation2 = ret.text;
			sprStation2 = ret.sprite;
		}
		if (texts.length > 2)
		{
			ret = setFontFormat(texts[2]);
			txtSong2 = ret.text;
			sprSong2 = ret.sprite;
		}
		if (texts.length > 3)
		{
			ret = setFontFormat(texts[3]);
			txtStation = ret.text;
			sprStation = ret.sprite;
		}
		if (texts.length > 4)
		{
			ret = setFontFormat(texts[4]);
			txtSong = ret.text;
			sprSong = ret.sprite;
		}
		if (texts.length > 0 && texts[0] != null)
		{
			seteffect(sprLogo, texts[0].speed);
		}
		
		if (texts.length > 4)
		{
			seteffect2(sprSong, sprSong2, texts[2].speed);
		}
		else if (texts.length > 2)
		{
			seteffect(sprSong2, texts[2].speed);
		}
		
		if (texts.length > 3)
		{
			seteffect2(sprStation, sprStation2, texts[1].speed);
		}
		else if (texts.length > 1)
		{
			seteffect(sprStation2, texts[1].speed);
		}
#end
	}
	
	function videoOn(e : PlayerEvent)
	{
		audioBg.visible = false;
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
			bufferbar.setPart(1.0);
		}
		else
		{
			bufferbar.setPart((o.bufferLength / o.bufferTime) / bufferDiv );
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
				bufferbar.setColor(0x88cc88, 0xccffcc);
			case PlayerEvent.SOCKET_FAIL:
				bufferbar.setColor(0x000088, 0x0000ff);
			case PlayerEvent.URL_OPEN:
				bufferbar.setColor(0x888844, 0xffff88);
			case PlayerEvent.URL_FAIL:
				bufferbar.setColor(0x880000, 0xff0000);
		}
	}
}