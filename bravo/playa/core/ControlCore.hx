/**
 * ...
 * @author JB
 */

package bravo.playa.core;

import bravo.shout.flash.PlayerEvent;
import bravo.playa.control.Controller;
import bravo.playa.control.PlayEvent;
import bravo.playa.control.VolumeEvent;

import flash.display.MovieClip;

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

import bravo.playa.core.Core;

class TextParam
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
			txt.width = TextConfig.width - x;// par.stage.stageWidth - x;
		}
		return { text : txt, sprite : spr };
		
	}
}
class TextConfig
{
	public static var leftColor : Int = 0x000000;
	public static var rightColor : Int = 0x666666;
	public static var useFont : String = "Arial";
	public static var isEmbed : Bool = false;
	public static var logo =         new TextParam(80.0, 0xcccccc, 0.2, 0.0,  30.0, -21414, 2.0);
	public static var stationLarge = new TextParam(56.0, 0x888888, 0.8, 0.0,   0.0,  14285);
	public static var stationSmall = new TextParam(32.0, 0xffffff, 0.8, 0.0,  30.0,  14285);
	public static var songLarge =    new TextParam(28.0, 0x888888, 0.8, 0.0, 195.0,  12121);
	public static var songSmall =    new TextParam(18.0, 0xffffff, 0.8, 0.0, 190.0,  12121);
	public static var useBeat : Bool = false;
	public static var showbufferbar : Bool = true;
	public static var wantVideo : Bool = true;
	public static var width : Float = -1.0;
	public static var height : Float = -1.0;
}

class ControlCore extends Core
{
	var texts : Array<Null<TextParam>>;
	var theLogoText : String;
	var useFont : String;
	var isEmbed : Bool;
	var usebeat : Bool;
	public var controlSurface(default, null) : Controller;

	override function cleanup()
	{
		super.cleanup();
		removeEventListener(MouseEvent.MOUSE_OVER, showControl );
		removeEventListener(MouseEvent.MOUSE_OUT, showControl );
		removeEventListener(MouseEvent.MOUSE_MOVE, domove );
		if(usebeat)
		{
			audioBg.removeEventListener(MouseEvent.MOUSE_DOWN, changeBeat);
		}
	}
	function new(inHost : String, inPort : UInt, inRes : String, inLogoText : String)
	{
		useFont = TextConfig.useFont;
		isEmbed = TextConfig.isEmbed;
		theHost = inHost;
		thePort = inPort;
		theRes = inRes;
		theLogoText = inLogoText;
		usebeat = TextConfig.useBeat;
		bufferDiv = 8.0;
		if (texts == null)
		{
			texts = new Array<Null<TextParam>>();
			if (theLogoText != null && theLogoText.length > 0)
			{
				texts.push(TextConfig.logo);
			}
			else
			{
				texts.push(null);
			}
			texts.push(TextConfig.stationLarge);
			texts.push(TextConfig.songLarge);
			texts.push(TextConfig.stationSmall);
			texts.push(TextConfig.songSmall);
		}
		if (texts.length < 1 || texts[0] == null)
		{
			usebeat = false;
		}
		super(inHost, inPort, inRes);
	}
	
	override function init() 
	{
		if (TextConfig.width < 0) 
		{
			TextConfig.width = stage.stageWidth;
		}
		if (TextConfig.height < 0) 
		{
			TextConfig.height = stage.stageHeight;
		}
		audioBg.graphics.lineStyle(0, 0, 0);
		audioBg.graphics.beginFill(0, 0);
		audioBg.graphics.drawRect(0, 0, TextConfig.width, TextConfig.height);
		audioBg.graphics.endFill();
		videoBg.visible = false;
		videoBg.graphics.lineStyle(0, 0xccccff);
		videoBg.graphics.beginFill(0xccccff);
		videoBg.graphics.drawRect(0, 0, TextConfig.width, TextConfig.height);
		videoBg.graphics.endFill();
		InfoDisplay();
		controlSurface = new Controller(TextConfig.width, TextConfig.height);
		controlSurface.alpha = 0.0;
		controlSurface.bufferbar.visible = TextConfig.showbufferbar;
		addEventListener(MouseEvent.MOUSE_OVER, showControl );
		addEventListener(MouseEvent.MOUSE_OUT, showControl );
		addEventListener(MouseEvent.MOUSE_MOVE, domove );
		controlSurface.addEventListener(PlayEvent.PLAY_START, onPlay);
		controlSurface.addEventListener(PlayEvent.PLAY_STOP, onStop);
		controlSurface.addEventListener(VolumeEvent.VOLUME_SET, onVolume);
		
		addChild(controlSurface);
		doPlay();
	}

	function onPlay(e:PlayEvent)
	{
		doPlay();
	}
	override function doPlay()
	{
		var sv = havePlayed;
		if (txtLogo != null)
		{
			txtLogo.text = theLogoText;
		}
		super.doPlay();
		if (!sv)
		{
			controlSurface.setVolume(0.5);
		}
		else
		{
			controlSurface.setVolume(controlSurface.theVolume);
		}
	}
	function onStop(e:PlayEvent)
	{
		doStop();
	}
	
	override function doStop()
	{
		setSongName("");
		setStreamTitle("");
		super.doStop();
	}

	function onVolume(e: VolumeEvent)
	{
		doVolume(e.volume);
	}
	
	var timer : Timer;
	
	function showControl(e : MouseEvent)
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
	override function setStreamTitle(name : String)
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
	
	override function setSongName(name : String)
	{
		if (name != null)
		{
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
	
	override function setSongUrl(name : String)
	{
		if (name != null)
		{
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
			var w = TextConfig.width;
			var v =
			if (spd < 0)
			{
				new Tween(w, 0, -spd, Linear.easeInOut);
			}
			else
			{
				new Tween(0, w, spd, Linear.easeInOut);
			}
			v.onUpdate(
				function(p : Float)
				{
					spr.x = (w - p) - (p / w * spr.width);
				}
			).onFinish(
				function()
				{
					v.start();
				}
			).start();
		}
	}
	
	function seteffect2(spr : Sprite, spr2 : Sprite, spd : Int)
	{
		if (spd != 0)
		{
			var w = TextConfig.width;
			var v =
			if (spd < 0)
			{
				new Tween(w, 0, -spd, Linear.easeInOut);
			}
			else
			{
				new Tween(0, w, spd, Linear.easeInOut);
			}
			v.onUpdate(
				function(p : Float)
				{
					spr.x = (w - p) - (p / w * spr.width);
					spr2.x = (w - p) - (p / w * spr2.width);
				}
			).onFinish(
				function()
				{
					v.start();
				}
			).start();
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
	var masker : Sprite;
	var infoholder : Sprite;
	function InfoDisplay()
	{
#if !debug
		masker = new Sprite();
		masker.graphics.beginFill(0, 0);
		masker.graphics.drawRect(0, 0, TextConfig.width, TextConfig.height);
		masker.graphics.endFill();
		addChild(masker);
		mask = masker;
		infoholder = new Sprite();
		audioBg.addChild(infoholder);
		graphics.lineStyle(0, TextConfig.leftColor);
		graphics.beginFill(TextConfig.leftColor);
		graphics.drawRect(0, 0, width / 2, height);
		graphics.endFill();
		graphics.lineStyle(0, TextConfig.rightColor);
		graphics.beginFill(TextConfig.rightColor);
		graphics.drawRect(width / 2, 0, width / 2, height);
		graphics.endFill();

		var ret;
		if (texts.length > 0 && texts[0] != null)
		{
			ret = texts[0].setFontFormat(useFont, isEmbed, infoholder);
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
			ret = texts[1].setFontFormat(useFont, isEmbed, infoholder);
			txtStation2 = ret.text;
			sprStation2 = ret.sprite;
		}
		if (texts.length > 2 && texts[2] != null)
		{
			ret = texts[2].setFontFormat(useFont, isEmbed, infoholder);
			txtSong2 = ret.text;
			sprSong2 = ret.sprite;
		}
		if (texts.length > 3 && texts[3] != null)
		{
			ret = texts[3].setFontFormat(useFont, isEmbed, infoholder);
			txtStation = ret.text;
			sprStation = ret.sprite;
		}
		if (texts.length > 4 && texts[4] != null)
		{
			ret = texts[4].setFontFormat(useFont, isEmbed, infoholder);
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
	
	override function videoOn(params : VideoParameters)
	{
		videoBg.visible = TextConfig.wantVideo;
		audioBg.visible = !TextConfig.wantVideo;
	}
	
	public var bufferDiv : Float;
	
	override function bufferStatus(o : BufferStatus)
	{
		if (o.bufferLength >= o.bufferTime * bufferDiv)
		{
			controlSurface.setPart(1.0);
		}
		else
		{
			controlSurface.setPart((o.bufferLength / o.bufferTime) / bufferDiv );
		}
	}

	override function connectState(state:ConnectState)
	{
		switch(state)
		{
			case SOCKET_OPEN:
				controlSurface.setColor(0x88cc88, 0xccffcc);
			case SOCKET_FAIL:
				controlSurface.setColor(0x000088, 0x0000ff);
			case URL_OPEN:
				controlSurface.setColor(0x888844, 0xffff88);
			case URL_FAIL:
				controlSurface.setColor(0x880000, 0xff0000);
		}
	}
}