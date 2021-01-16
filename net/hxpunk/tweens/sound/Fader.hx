package net.hxpunk.tweens.sound;

import net.hxpunk.utils.Ease.EasingFunction;
import net.hxpunk.HP;
import net.hxpunk.Tween;

/**
	 * Global volume fader.
	 */
class Fader extends Tween
{
    /**
		 * Constructor.
		 * @param	complete	Optional completion callback.
		 * @param	type		Tween type.
		 */
    public function new(complete : VoidCallback = null, type : TweenType = TweenType.PERSIST)
    {
        super(0, type, complete);
    }
    
    /**
		 * Fades HP.volume to the target volume.
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
        _start = HP.volume;
        _range = volume - _start;
        _target = duration;
        _ease = ease;
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
        HP.volume = _start + _range * _t;
    }
    
    // Fader information.
    /** @private */private var _start : Float;
    /** @private */private var _range : Float;
}
