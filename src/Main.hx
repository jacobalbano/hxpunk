package ;

import flash.system.System;
import net.hxpunk.debug.Console;
import net.hxpunk.Engine;
import net.hxpunk.Entity;
import net.hxpunk.graphics.Image;
import net.hxpunk.graphics.Text;
import net.hxpunk.HP;
import net.hxpunk.utils.Input;
import net.hxpunk.utils.Key;
import openfl.Assets;


/**
 * ...
 * @author azrafe7
 */

class Main extends Engine
{
	private var e:Entity;
	var deltaScale:Float = -.1;
	var text:Text;

	
    public function new() {
        super(640, 480, 60, false);
    }
	
    override public function init():Void {
        super.init();
        HP.console.enable();
		
		trace("HXPunk is running!");
		
		//var img:Image = Image.createRect(40, 40);
		var img:Image = new Image(Assets.getBitmapData("assets/ball.png"));
		img.centerOrigin();
		e = new Entity(0, 0, img);
		HP.world.add(e, HP.halfWidth, HP.halfHeight);
		e.setHitboxTo(img);
		e.centerOrigin();
		img.angle = 45;
		
		for (i in 0...35) HP.log(i, [1, 2, 3]);
		
		HP.world.addGraphic(text = new Text("Ecciao!", 5, 30));
    }
	
	override public function update():Void 
	{
		super.update();
		
		// ESC to exit
		if (Input.pressed(Key.ESCAPE)) {
			System.exit(1);
		}
		
		// move Entity with arrows
		var dx:Float = 0;
		var dy:Float = 0;
		if (Input.check(Console.ARROW_KEYS)) {
			dx += Input.check(Key.LEFT) ? -1 : Input.check(Key.RIGHT) ? 1 : 0;
			dy += Input.check(Key.UP) ? -1 : Input.check(Key.DOWN) ? 1 : 0;
		}
		e.x += dx * 2;
		e.y += dy * 2;
		
		// scale and rotate Entity
		var img:Image = cast e.graphic;
		if (img.scale > 2.5 || img.scale < 0.5) deltaScale *= -1;
		img.scale += deltaScale;
		img.angle += 1.5;
		img.angle %= 360;
		
		//text.text = Std.string(System.totalMemory / 1024 / 1024);
		//text.text = Std.string(HP.frameRate);
	}
	
    public static function main() { 
		new Main(); 
	}
}
