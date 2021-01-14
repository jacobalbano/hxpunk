Forked from https://github.com/azrafe7/hxpunk to make compatible with openfl 9.0.2

Add this line to project xml if you want the default font to work:
```xml

	<assets path="Source/net/hxpunk/assets" rename="hxpunk" />
```

Main class:
```haxe
package ;

import net.hxpunk.Engine;
import net.hxpunk.HP;

class Main extends Engine
{
    public function new() {
        super(320, 240, 60, false);
    }
	
    override public function init():Void {
        super.init();
		trace(HP.NAME + " is running!");
		//HP.world = new MyWorld();
	}
}
```