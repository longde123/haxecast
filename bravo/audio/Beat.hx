package bravo.audio;
import flash.events.Event;
import flash.Lib;
import flash.media.SoundMixer;
import flash.utils.ByteArray;

/**
 * ...
 * @author JB
 */

class Beat 
{

	var _obj : Dynamic;
	var _prop : String;
	var _stretch : Int;
	var _low : Int;
	var _hi : Int;
	var _div : Float;
	var _add : Float;
	
	public function new(obj : Dynamic, prop : String, ?stretch : Int = 1, ?low : Int = 0, ?hi : Int = 8, ?div : Float = 32.0, ?add : Float = 1.0) 
	{
		retry = 10;
		_obj = obj;
		_prop = prop;
		_stretch = stretch;
		_low = low;
		_hi = hi;
		_div = div;
		_add = add;
		specFloat = new Array();
		spectrum = new ByteArray();
        Lib.current.addEventListener( Event.ENTER_FRAME, loop );
		enabled = true;
	}
	public var enabled(default, null) : Bool;
	private var retry : Int;
	var spectrum:ByteArray;
	var specFloat : Array<Float>;
	public function enable(?b : Null<Bool> = null)
	{
		if (b == null)
		{
			enabled = !enabled;
		}
		else
		{
			enabled = b;
		}
	}
	private function loop( e : Event ): Void 
	{
		if (!enabled || retry < 1)
		{
			return;
		}
		try 
		{
			SoundMixer.computeSpectrum(spectrum, true, _stretch);
		} catch (e:Dynamic) {
			retry--;
			return;
		}
		for (i in 0...256) {
			specFloat[i] = spectrum.readFloat();
		}
		for (i in 0...256) {
			specFloat[i] += spectrum.readFloat();
		}
		var b : Float = 0;
		for (i in _low..._hi)
		{
			b += specFloat[i];
		}
		b = b / _div + _add;
		Reflect.setField(_obj, _prop, b);
	}
}