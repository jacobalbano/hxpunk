package net.hxpunk.tweens.sound;

import net.hxpunk.HP.VoidCallback;
import net.hxpunk.Tween.TweenType;
import net.hxpunk.utils.Ease.EasingFunction;
import net.hxpunk.Sfx;
import net.hxpunk.Tween;

/**
	 * Sound effect fader.
	 */
class SfxFader extends Tween
{
    public var sfx(get, never) : Sfx;

    /**
		 * Constructor.
		 * @param	sfx			The Sfx object to alter.
		 * @param	complete	Optional completion callback.
		 * @param	type		Tween type.
		 */
    public function new(sfx : Sfx, complete : VoidCallback = null, type : TweenType = TweenType.PERSIST)
    {
        super(0, type, finish);
        _complete = complete;
        _sfx = sfx;
    }
    
    /**
		 * Fades the Sfx to the target volume.
		 * @param	volume		The volume to fade to.
		 * @param	duration	Duration of the fade.
		 * @param	ease		Optional easer function.
		 */
    public function fadeTo(volume : Float, duration : Float, ease : EasingFunction = null) : Void
    {
        if (volume < 0)
        {
            volume = 0;
        }
        _start = _sfx.volume;
        _range = volume - _start;
        _target = duration;
        _ease = ease;
        start();
    }
    
    /**
		 * Fades out the Sfx, while also playing and fading in a replacement Sfx.
		 * @param	play		The Sfx to play and fade in.
		 * @param	loop		If the new Sfx should loop.
		 * @param	duration	Duration of the crossfade.
		 * @param	volume		The volume to fade in the new Sfx to.
		 * @param	ease		Optional easer function.
		 */
    public function crossFade(play : Sfx, loop : Bool, duration : Float, volume : Float = 1, ease : EasingFunction = null) : Void
    {
        _crossSfx = play;
        _crossRange = volume;
        _start = _sfx.volume;
        _range = -_start;
        _target = duration;
        _ease = ease;
        if (loop)
        {
            _crossSfx.loop(0);
        }
        else
        {
            _crossSfx.play(0);
        }
        start();
    }
    
    /** @private Updates the Tween. */
    override public function update() : Void
    {
        super.update();
        if (delay > 0)
        {
            return;
        }
        if (_sfx != null)
        {
            _sfx.volume = _start + _range * _t;
        }
        if (_crossSfx != null)
        {
            _crossSfx.volume = _crossRange * _t;
        }
    }
    
    /** @private When the tween completes. */
    override function finish() : Void
    {
        if (_crossSfx != null)
        {
            if (_sfx != null)
            {
                _sfx.stop();
            }
            _sfx = _crossSfx;
            _crossSfx = null;
        }
        if (_complete != null)
        {
            _complete();
        }
    }
    
    /**
		 * The current Sfx this object is effecting.
		 */
    private function get_sfx() : Sfx
    {
        return _sfx;
    }
    
    // Fader information.
    /** @private */private var _sfx : Sfx;
    /** @private */private var _start : Float;
    /** @private */private var _range : Float;
    /** @private */private var _crossSfx : Sfx;
    /** @private */private var _crossRange : Float;
    /** @private */private var _complete : VoidCallback;
}
