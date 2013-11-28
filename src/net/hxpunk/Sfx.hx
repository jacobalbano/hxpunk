package net.hxpunk;

import flash.errors.Error;
import flash.events.Event;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.media.SoundTransform;
import net.hxpunk.HP.VoidCallback;


/**
 * Sound effect object used to play embedded sounds.
 * 
 * For differences between targets @see http://www.openfl.org/archive/developer/documentation/key-concepts/assets/
 */
class Sfx 
{
	private static var init:Bool = initStaticVars();
	
	/**
	 * Optional callback function for when the sound finishes playing.
	 */
	public var onComplete:VoidCallback;
	
	private static inline function initStaticVars():Bool 
	{
		_typePlaying = new Map<String, Map<String, Sfx>>();
		_typeTransforms = new Map<String, SoundTransform>();
		
		return true;
	}
		
	/**
	 * Creates a sound effect from an embedded source. Store a reference to
	 * this object so that you can play the sound using play() or loop().
	 * @param	source		The embedded sound class to use or a Sound object. An asset id/file, Sound object, or embedded Sound class.
	 * @param	onComplete	Optional callback function for when the sound finishes playing.
	 */
	public function new(source:Dynamic, onComplete:VoidCallback = null, type:String = null) 
	{
		_transform = new SoundTransform();
		_type = type != null ? type : "";
		_sound = HP.getSound(source); 
		if (Std.is(source, Class))
			_className = Type.getClassName(source);
		else if (Std.is(source, String)) 
			_className = source;
		else if (source == null) throw new Error("Sfx source must be of type Sound, String or Class.");
		this.onComplete = onComplete;
	}
	
	/**
	 * Plays the sound once.
	 * @param	vol		Volume factor, a value from 0 to 1.
	 * @param	pan		Panning factor, a value from -1 to 1.
	 */
	public function play(vol:Float = 1, pan:Float = 0):Void
	{
		if (_channel != null) stop();
		_pan = HP.clamp(pan, -1, 1);
		_vol = HP.clamp(vol, 0, 1);
	#if flash
		_filteredPan = HP.clamp(_pan + getPan(_type), -1, 1);
	#else
		_filteredPan = HP.clamp(_pan + getPan(_type) + HP.pan, -1, 1);
	#end
		_filteredVol = Math.max(0, _vol * getVolume(_type) #if !flash * HP.volume #end);
		_transform.pan = _filteredPan;
		_transform.volume = _filteredVol;
		_channel = _sound.play(0, 0, _transform);
		if (_channel != null)
		{
			addPlaying();
			_channel.addEventListener(Event.SOUND_COMPLETE, _onComplete);
		}
		_looping = false;
		_position = 0;
	}
	
	/**
	 * Plays the sound looping. Will loop continuously until you call stop(), play(), or loop() again.
	 * @param	vol		Volume factor, a value from 0 to 1.
	 * @param	pan		Panning factor, a value from -1 to 1.
	 */
	public function loop(vol:Float = 1, pan:Float = 0):Void
	{
		play(vol, pan);
		_looping = true;
	}
	
	/**
	 * Stops the sound if it is currently playing.
	 * @return
	 */
	public function stop():Bool
	{
		if (_channel == null) return false;
		removePlaying();
		_position = _channel.position;
		_channel.removeEventListener(Event.SOUND_COMPLETE, _onComplete);
		_channel.stop();
		_channel = null;
		return true;
	}
	
	/**
	 * Resumes the sound from the position stop() was called on it.
	 */
	public function resume():Void
	{
		_channel = _sound.play(_position, 0, _transform);
		if (_channel != null)
		{
			addPlaying();
			_channel.addEventListener(Event.SOUND_COMPLETE, _onComplete);
		}
	#if !flash
		// take global volume and pan into account for nonflash targets
		volume = _vol;
		pan = _pan;
	#end
		_position = 0;
	}
	
	/** @private Event handler for sound completion. */
	private function _onComplete(e:Event = null):Void
	{
		if (_looping) loop(_vol, _pan);
		else stop();
		_position = 0;
		if (onComplete != null) onComplete();
	}
	
	/** @private Add the sound to the global list. */
	private function addPlaying():Void
	{
		if (!_typePlaying.exists(_type)) _typePlaying.set(_type, new Map<String, Sfx>());
		_typePlaying[_type].set(_className, this);
	}
	
	/** @private Remove the sound from the global list. */
	private function removePlaying():Void
	{
		if (_typePlaying[_type] != null) _typePlaying[_type].remove(_className);
	}
	
	/**
	 * Alter the volume factor (a value from 0 to 1) of the sound during playback.
	 */
	public var volume(get, set):Float;
	private inline function get_volume():Float { return _vol; }
	private function set_volume(value:Float):Float
	{
		if (_channel == null) return value;
		value = HP.clamp(value, 0, 1);
		_vol = value;
	#if flash
		var filteredVol:Float = value * getVolume(_type);
	#else
		var filteredVol:Float = value * getVolume(_type) * HP.volume;
	#end
		if (_filteredVol == filteredVol) return value;
		_filteredVol = _transform.volume = filteredVol;
		_channel.soundTransform = _transform;
		return value;
	}
	
	/**
	 * Alter the panning factor (a value from -1 to 1) of the sound during playback.
	 */
	public var pan(get, set):Float;
	private inline function get_pan():Float { return _pan; }
	private function set_pan(value:Float):Float
	{
		if (_channel == null) return value;
		value = HP.clamp(value, -1, 1);
	#if flash
		var filteredPan:Float = HP.clamp(value + getPan(_type), -1, 1);
	#else
		var filteredPan:Float = HP.clamp(value + getPan(_type) + HP.pan, -1, 1);
	#end
		if (_filteredPan == filteredPan) return value;
		_pan = value;
		_filteredPan = _transform.pan = filteredPan;
		_channel.soundTransform = _transform;
		return value;
	}
	
	/**
	* Change the sound type. This an arbitrary string you can use to group
	* sounds to mute or pan en masse.
	*/
	public var type(get, set):String;
	private inline function get_type():String { return _type; }
	private function set_type(value:String):String
	{
		if (_type == value) return value;
		if (_channel != null)
		{
			removePlaying();
			_type = value;
			addPlaying();
			// reset, in case type has different global settings
			pan = pan;
			volume = volume;
		}
		else
		{
			_type = value;
		}
		return _type;
	}
	
	/**
	 * If the sound is currently playing.
	 */
	public var isPlaying(get, null):Bool;
	private inline function get_isPlaying():Bool { return _channel != null; }
	
	/**
	 * Position of the currently playing sound, in seconds.
	 */
	public var position(get, null):Float;
	private inline function get_position():Float { return (_channel != null ? _channel.position : _position) / 1000; }
	
	/**
	 * Length of the sound, in seconds.
	 */
	public var length(get, null):Float;
	private inline function get_length():Float { return _sound.length / 1000; }
	
	/**
	* Return the global pan for a type.
	*/
	static public function getPan(type:String):Float
	{
		var transform:SoundTransform = _typeTransforms[type];
		return transform != null ? transform.pan : 0;
	}
	
	/**
	* Return the global volume for a type.
	*/
	static public function getVolume(type:String):Float
	{
		var transform:SoundTransform = _typeTransforms[type];
		return transform != null ? transform.volume : 1;
	}
	
	/**
	* Set the global pan for a type. Sfx instances of this type will add
	* this pan to their own.
	*/
	static public function setPan(type:String, pan:Float):Void
	{
		var transform:SoundTransform = _typeTransforms[type];
		if (transform == null) transform = _typeTransforms[type] = new SoundTransform();
		transform.pan = HP.clamp(pan, -1, 1);
		for (sfx in _typePlaying[type])
		{
			sfx.pan = sfx.pan;
		}
	}
	
	/**
	* Set the global volume for a type. Sfx instances of this type will
	* multiply their volume by this value.
	*/
	static public function setVolume(type:String, volume:Float):Void
	{
		var transform:SoundTransform = _typeTransforms[type];
		if (transform == null) transform = _typeTransforms[type] = new SoundTransform();
		volume = HP.clamp(volume, 0, 1);
		transform.volume = volume;
		for (sfx in _typePlaying[type])
		{
			sfx.volume = sfx.volume;
		}
	}
	
	/**
	 * Updates all groups with this global settings. (used in HP for nonflash targets, which lack the SoundMixer class)
	 * 
	 * @param	globalVolume	all Sfx instances will multiply their volume by this value (defaults to HP.volume).
	 * @param	globalVolume	all Sfx instances will add this value to their pan (defaults to HP.pan).
	 */
	static public function updateAll(?globalVolume:Float, ?globalPan:Float):Void 
	{
		if (globalVolume == null) globalVolume = HP.volume;
		if (globalPan == null) globalPan = HP.pan;
		
		for (type in _typePlaying.keys()) {
			Sfx.setVolume(type, globalVolume);
			Sfx.setPan(type, globalPan);
		}
	}
	
	// Sound information.
	private var _type:String;
	private var _vol:Float = 1;
	private var _pan:Float = 0;
	private var _filteredVol:Float = 0;
	private var _filteredPan:Float = 0;
	private var _sound:Sound;
	private var _channel:SoundChannel;
	private var _transform:SoundTransform;
	private var _position:Float = 0;
	private var _looping:Bool = false;
	private var _className:String;
	
	// Stored Sound objects.
	private static var _typePlaying:Map<String, Map<String, Sfx>>;
	private static var _typeTransforms:Map<String, SoundTransform>;
}
