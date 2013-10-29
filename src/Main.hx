package ;

import flash.system.System;
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
		
		//HP.world.addGraphic(new Text("ecciao", 100, 100));
    }
	
	override public function update():Void 
	{
		super.update();
		
		if (Input.pressed(Key.ESCAPE)) {
			System.exit(1);
		}
		
		if (Input.check(Key.ANY)) e.x += HP.sign(Math.random() * 4 - 2) * Math.random() * 3;
		
		var img:Image = cast e.graphic;
		if (img.scale > 3 || img.scale < 0.5) deltaScale *= -1;
		img.scale += deltaScale;
		img.angle += 1;
		img.angle %= 360;
	}
	
    public static function main() { 
		new Main(); 
	}
}
