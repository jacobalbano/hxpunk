package net.hxpunk.graphics;
import flash.display.BitmapData;
import flash.errors.Error;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.geom.Rectangle;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.Utf8;
import net.hxpunk.HP;
import net.hxpunk.utils.Draw;


/**
 * Holds information and bitmap glyphs for a bitmap font.
 * 
 * Adapted from Beeblerox work (which built upon Pixelizer implementation).
 * 
 * @see https://github.com/Beeblerox/BitmapFont
 */
class BitmapFont 
{
	
	/**
	 * Creates a new bitmap font. Use one of the load_ methods to actually load the font.
	 */
	public function new() 
	{
		if (_storedFonts == null) _storedFonts = new Map<String, BitmapFont>();
		
		_colorTransform = new ColorTransform();
		_glyphs = new Array<BitmapData>();
	}
	
	/**
	 * Loads font data from Pixelizer's format
	 * @param	bitmapData	Font source image
	 * @param	letters		All letters contained in this font
	 * @return this BitmapFont
	 */
	public function loadFromPixelizer(bitmapData:BitmapData, letters:String):BitmapFont
	{
		reset();
		_glyphString = letters;
		
		if (bitmapData != null) 
		{
			var tileRects:Array<Rectangle> = [];
			var result:BitmapData = prepareBitmapData(bitmapData, tileRects);
			var currRect:Rectangle;
			
			for (letterID in 0...(tileRects.length))
			{
				currRect = tileRects[letterID];
				
				// create glyph
				var bd:BitmapData = new BitmapData(Math.floor(currRect.width), Math.floor(currRect.height), true, 0x0);
				bd.copyPixels(bitmapData, currRect, HP.zero, null, null, true);
				
				// store glyph
				setGlyph(_glyphString.charCodeAt(letterID), bd);
			}
		}
		
		return this;
	}
	
	/**
	 * Loads font data form XML (AngelCode's) format
	 * @param	bitmapData		Font image source
	 * @param	XMLData			Font data in XML format
	 * @return	this BitmapFont
	 */
	public function loadFromXML(bitmapData:BitmapData, XMLData:Xml):BitmapFont
	{
		reset();
		
		if (bitmapData != null) 
		{
			_glyphString = "";
			var rect:Rectangle = new Rectangle();
			var point:Point = new Point();
			var bd:BitmapData;
			var letterID:Int = 0;
			var charCode:Int;
			var charString:String;
			
			var chars:Xml = null;
			for (node in XMLData.elements())
			{
				if (node.nodeName == "font")
				{
					for (nodeChild in node.elements())
					{
						if (nodeChild.nodeName == "chars")
						{
							chars = nodeChild;
							break;
						}
					}
				}
			}
			
			if (chars != null)
			{
				for (node in chars.elements())
				{
					if (node.nodeName == "char")
					{
						rect.x = Std.parseInt(node.get("x"));
						rect.y = Std.parseInt(node.get("y"));
						rect.width = Std.parseInt(node.get("width"));
						rect.height = Std.parseInt(node.get("height"));
						
						point.x = Std.parseInt(node.get("xoffset"));
						point.y = Std.parseInt(node.get("yoffset"));
						
						charCode = Std.parseInt(node.get("id"));
						charString = String.fromCharCode(charCode);
						_glyphString += charString;
						
						var xadvance:Int = Std.parseInt(node.get("xadvance"));
						var charWidth:Int = xadvance;
						
						if (rect.width > xadvance)
						{
							charWidth = Std.int(rect.width);
							point.x = 0;
						}
						
						// create glyph
						bd = null;
						if (charString != " " && charString != "")
						{
							bd = new BitmapData(charWidth, Std.parseInt(node.get("height")) + Std.parseInt(node.get("yoffset")), true, 0x0);
						}
						else
						{
							bd = new BitmapData(charWidth, 1, true, 0x0);
						}
						bd.copyPixels(bitmapData, rect, point, null, null, true);
						
						// store glyph
						setGlyph(charCode, bd);
						
						letterID++;
					}
				}
			}
		}
		
		return this;
	}
	
	/**
	 * Deserializes a font encoded with serialize().
	 * 
	 * @return	The deserialized BitmapFont.
	 */
	public static function loadFromSerialized(encodedFont:String):BitmapFont 
	{
		var encodedFont:String = rleDecodeStr(Unserializer.run(encodedFont));
		var letters:String = "";
		var letterPos:Int = 0;
		var i:Int = 0;
		
		var n:Int = encodedFont.charCodeAt(i) - 32;		// number of glyphs
		var w:Int = encodedFont.charCodeAt(++i) - 32;	// max width of single glyph
		var h:Int = encodedFont.charCodeAt(++i) - 32;	// max height of single glyph
		var size:Int = Std.int(Math.ceil(Math.sqrt(n * (w + 1) * (h + 1))) + Math.max(w, h));
		var rows:Int = Std.int(size / (h + 1));
		var cols:Int = Std.int(size / (w + 1));
		var bd:BitmapData = new BitmapData(size, size, true, 0xFFFF0000);
		
		while (i < encodedFont.length - 1) 		// (length - 1) because last char is "\0" when using haxe.Serializer/Unserializer
		{
			letters += encodedFont.charAt(++i);
			
			var gw:Int = encodedFont.charCodeAt(++i) - 32;
			var gh:Int = encodedFont.charCodeAt(++i) - 32;
			for (py in 0...gh) 
			{
				for (px in 0...gw) 
				{
					i++;
					
					var pixelOn:Bool = encodedFont.charAt(i) == "1"; 
					bd.setPixel32(1 + (letterPos % cols) * (w + 1) + px, 1 + Std.int(letterPos / cols) * (h + 1) + py, pixelOn ? 0xFFFFFFFF : 0x0);
				}
			}
			
			letterPos++;
		}
		
		var font:BitmapFont = new BitmapFont().loadFromPixelizer(bd, letters);
		bd.dispose();
		bd = null;
		
		return font;
	}

	/**
	 * Serializes the font as a bit font by encoding it into a big string (max 224 extended ascii glyphs, no alpha is encoded, pixels are either on (if alpha == 1) or off (otherwise)).
	 * 
	 * Format:
	 * 	   [fromCharCode(numGlyphs + 32)][fromCharCode(maxWidth + 32)][fromCharCode(height + 32)] then for each glyph [char][fromCharCode(width + 32)][fromCharCode(height + 32)][series of 0 or 1 for each pixel of the glyph]...
	 * 
	 *     the resulting string is then passed to haxe.Serializer() for cross-platform compatibility and to rleEncodeStr() for compressing and then returned.
	 * 
	 * @return	Serialized font string.
	 */
	public function serialize():String 
	{
		var charCode:Int;
		var glyph:BitmapData;
		var nGlyphs:Int = _glyphString.length;
		var outputBuf:StringBuf = new StringBuf();
		
		outputBuf.addChar(nGlyphs + 32);
		outputBuf.addChar(maxWidth + 32);
		outputBuf.addChar(height + 32);

		for (i in 0...nGlyphs) 
		{
			charCode = _glyphString.charCodeAt(i);
			glyph = _glyphs[charCode];
			
			outputBuf.add(_glyphString.substr(i, 1));
			outputBuf.addChar(glyph.width + 32);
			outputBuf.addChar(glyph.height + 32);
			
			for (py in 0...(glyph.height)) 
			{
				for (px in 0...(glyph.width)) 
				{
					outputBuf.add(((glyph.getPixel32(px, py) & 0xFF000000) == 0xFF000000) ? "1" : "0");
				}
			}
		}
		
		return rleEncodeStr(Serializer.run(outputBuf.toString()));
	}

	/**
	 * Internal function. Resets current font
	 */
	private function reset():Void
	{
		dispose();
		_maxWidth = 0;
		_maxHeight = 0;
		_glyphs = [];
		_glyphString = "";
	}
	
	/**
	 * Adjusts the font BitmapData making background transparent and stores glyphs positions in the rects array.
	 * @return The modified BitmapData.
	 */
	public function prepareBitmapData(bitmapData:BitmapData, rects:Array<Rectangle>):BitmapData
	{
		var bgColor:Int = bitmapData.getPixel(0, 0);
		var cy:Int = 0;
		var cx:Int;
		
		while (cy < bitmapData.height)
		{
			var rowHeight:Int = 0;
			cx = 0;
			
			while (cx < bitmapData.width)
			{
				if (Std.int(bitmapData.getPixel(cx, cy)) != bgColor) 
				{
					// found non bg pixel
					var gx:Int = cx;
					var gy:Int = cy;
					// find width and height of glyph
					while (Std.int(bitmapData.getPixel(gx, cy)) != bgColor)
					{
						gx++;
					}
					while (Std.int(bitmapData.getPixel(cx, gy)) != bgColor)
					{
						gy++;
					}
					var gw:Int = gx - cx;
					var gh:Int = gy - cy;
					
					rects.push(new Rectangle(cx, cy, gw, gh));
					
					// store max size
					if (gh > rowHeight) 
					{
						rowHeight = gh;
					}
					if (gh > _maxHeight) 
					{
						_maxHeight = gh;
					}
					
					// go to next glyph
					cx += gw;
				}
				
				cx++;
			}
			// next row
			cy += (rowHeight + 1);
		}
		
		var resultBitmapData:BitmapData = bitmapData.clone();
		
		var pixelColor:UInt;
		var bgColor32:UInt = bitmapData.getPixel(0, 0);
		
		cy = 0;
		while (cy < bitmapData.height)
		{
			cx = 0;
			while (cx < bitmapData.width)
			{
				pixelColor = bitmapData.getPixel32(cx, cy);
				if (pixelColor == bgColor32)
				{
					resultBitmapData.setPixel32(cx, cy, 0x00000000);
				}
				cx++;
			}
			cy++;
		}
		
		return resultBitmapData;
	}
	
	/**
	 * Prepares and returns a set of glyphs using the specified parameters.
	 */
	public function getPreparedGlyphs(scale:Float, color:Int, ?useColorTransform:Bool = true):Array<BitmapData>
	{
		var result:Array<BitmapData> = [];
		
		HP.matrix.identity();
		HP.matrix.scale(scale, scale);
		
		var colorMultiplier:Float = 0.00392;
		_colorTransform.redOffset = 0;
		_colorTransform.greenOffset = 0;
		_colorTransform.blueOffset = 0;
		_colorTransform.redMultiplier = (color >> 16) * colorMultiplier;
		_colorTransform.greenMultiplier = (color >> 8 & 0xff) * colorMultiplier;
		_colorTransform.blueMultiplier = (color & 0xff) * colorMultiplier;
		
		var glyph:BitmapData;
		var preparedGlyph:BitmapData;
		for (i in 0...(_glyphs.length))
		{
			glyph = _glyphs[i];
			var bdWidth:Int;
			var bdHeight:Int;
			if (glyph != null)
			{
				if (scale > 0)
				{
					bdWidth = Math.ceil(glyph.width * scale);
					bdHeight = Math.ceil(glyph.height * scale);
				}
				else
				{
					bdWidth = 1;
					bdHeight = 1;
				}
				
				preparedGlyph = new BitmapData(bdWidth, bdHeight, true, 0x00000000);
				if (useColorTransform)
				{
					preparedGlyph.draw(glyph,  HP.matrix, _colorTransform);
				}
				else
				{
					preparedGlyph.draw(glyph,  HP.matrix);
				}
				result[i] = preparedGlyph;
			}
		}
		
		return result;
	}
	
	/** Returns a string with all the supported glyphs. */
	public var supportedGlyphs(get, null):String;
	private function get_supportedGlyphs():String {
		return _glyphString;
	}
	
	/**
	 * Clears all resources used by the font.
	 */
	public function dispose():Void 
	{
		var bd:BitmapData;
		for (i in 0...(_glyphs.length)) 
		{
			bd = _glyphs[i];
			if (bd != null) 
			{
				_glyphs[i].dispose();
			}
		}
		_glyphs = null;
	}

	/** Encodes an extended-ASCII string using a run-length algorithm. 
	 * 
	 *  Format:
	 *      if more than 2 characters are repeated in sequence this gets appended to output 
	 *
	 * 			[RLE_MARKER][number of repetitions + 32][char to repeat]
	 * 
	 * 		otherwise the character itself is appended (so the encoded string is never longer than the original one).
	 * 
	 *  @param str	The string to encode (must have characters with values in the range [32..254] - 255 is used as marker)
	 *  @return The encoded string.
	 */
	public static function rleEncodeStr(str:String):String 
	{
		var RLE_MARKER:Int = 255;
		var FIRST_VALID_CHAR:Int = 32;
		var outputBuf:StringBuf = new StringBuf();
		var runlength:Int = 0;
		var currChar:Int = -1;
		var lastChar:Int = -1;
		
		for (i in 0...str.length) {
			currChar = str.charCodeAt(i);
			
		#if debug
			if (currChar < FIRST_VALID_CHAR || currChar >= RLE_MARKER) 
				throw new Error("Encountered char outside valid range in string to encode [pos:" + i + " value:" + currChar + " char:'" + str.charAt(i) + "'].");
		#end
		
			if (lastChar == currChar || lastChar < 0) {
				runlength++;
			} else if (lastChar != currChar || runlength == RLE_MARKER - FIRST_VALID_CHAR - 1) {
				if (runlength > 1) {
					if (runlength == 2) {
						outputBuf.addChar(lastChar);
					} else {
						outputBuf.addChar(RLE_MARKER);
						outputBuf.addChar(runlength + FIRST_VALID_CHAR);
					}
				}
				outputBuf.addChar(lastChar);
				runlength = 1;
			}
			lastChar = currChar;
		}
		
		if (runlength > 0) {
			if (runlength > 1) {
				if (runlength == 2) {
					outputBuf.addChar(lastChar);
				} else {
					outputBuf.addChar(RLE_MARKER);
					outputBuf.addChar(runlength + FIRST_VALID_CHAR);
				}
			}
			outputBuf.addChar(lastChar);
		}
		
		return outputBuf.toString();
	}
	
	/** Decodes a string encoded with rleEncodeStr(). */
	public static function rleDecodeStr(str:String):String 
	{
		var RLE_MARKER:Int = 255;
		var FIRST_VALID_CHAR:Int = 32;
		var outputBuf:StringBuf = new StringBuf();
		var runlength:Int = 0;
		var encodedChar:Int;
		var currChar:Int;
		var i:Int = 0;
		var len:Int = str.length;
		
		while (i < len) {
			encodedChar = str.charCodeAt(i);
			if (encodedChar == RLE_MARKER) { 
				runlength = str.charCodeAt(++i) - FIRST_VALID_CHAR;
				currChar = str.charCodeAt(++i);
				for (r in 0...runlength) outputBuf.addChar(currChar);
			} else {
				outputBuf.addChar(encodedChar);
			}
			i++;
		}
		
		return outputBuf.toString();
	}
	
	/**
	 * Sets the BitmapData for a specific glyph.
	 */
	private function setGlyph(charID:Int, bitmapData:BitmapData):Void 
	{
		if (_glyphs[charID] != null) 
		{
			_glyphs[charID].dispose();
		}
		
		_glyphs[charID] = bitmapData;
		
		if (bitmapData.width > _maxWidth) 
		{
			_maxWidth = bitmapData.width;
		}
		if (bitmapData.height > _maxHeight) 
		{
			_maxHeight = bitmapData.height;
		}
	}
	
	/**
	 * Renders a string of text onto bitmap data using the font.
	 * @param	bitmapData	Where to render the text.
	 * @param	text		Test to render.
	 * @param	color		Color of text to render.
	 * @param	offsetX		X position of text output.
	 * @param	offsetY		Y position of text output.
	 */
	public function render(bitmapData:BitmapData, fontData:Array<BitmapData>, text:String, color:UInt, offsetX:Float, offsetY:Float, letterSpacing:Int):Void 
	{
		HP.point.x = offsetX;
		HP.point.y = offsetY;

		var glyph:BitmapData;
		
		for (i in 0...(text.length)) 
		{
			var charCode:Int = text.charCodeAt(i);

			glyph = fontData[charCode];
			if (glyph != null) 
			{
				bitmapData.copyPixels(glyph, glyph.rect, HP.point, null, null, true);
				HP.point.x += glyph.width + letterSpacing;
			}
		}
	}
		
	/**
	 * Returns the width of a certain test string.
	 * @param	text			String to measure.
	 * @param	letterSpacing	Distance between letters.
	 * @param	fontScale		"size" of the font.
	 * @return	Width in pixels.
	 */
	public function getTextWidth(text:String, ?letterSpacing:Int = 0, ?fontScale:Float = 1.0):Int 
	{
		var w:Int = 0;
		
		var textLength:Int = text.length;
		for (i in 0...(textLength)) 
		{
			var charCode:Int = text.charCodeAt(i);
			var glyph:BitmapData = _glyphs[charCode];
			if (glyph != null) 
			{
				
				w += glyph.width;
			}
		}
		
		w = Math.round(w * fontScale);
		
		if (textLength > 1)
		{
			w += (textLength - 1) * letterSpacing;
		}
		
		return w;
	}
	
	/**
	 * Returns the height of font in pixels.
	 */
	public var height(get, null):Int;
	private inline function get_height():Int 
	{
		return _maxHeight;
	}
	
	/**
	 * Returns the width of the largest glyph.
	 */
	public var maxWidth(get, null):Int;
	private inline function get_maxWidth():Int 
	{
		return _maxWidth;
	}
	
	/**
	 * Returns number of glyphs available in this font.
	 * @return Number of glyphs available in this font.
	 */
	public var numGlyphs(get, null):Int;
	private inline function get_numGlyphs():Int 
	{
		return _glyphs.length;
	}
	
	/**
	 * Stores a font for global use using an identifier.
	 * @param	fontName	String identifer for the font.
	 * @param	font		Font to store.
	 */
	public static function store(fontName:String, font:BitmapFont):Void 
	{
		_storedFonts.set(fontName, font);
	}
	
	/**
	 * Retrieves a font previously stored.
	 * @param	fontName	Identifier of font to fetch.
	 * @return	Stored font, or null if no font was found.
	 */
	public static function fetch(fontName:String):BitmapFont 
	{
		var f:BitmapFont = _storedFonts.get(fontName);
		return f;
	}

	/**
	 * Creates and stores the default font for later use.
	 */
	public static function createDefaultFont():Void
	{
		var defaultFont:BitmapFont = loadFromSerialized(_DEFAULT_FONT_DATA);
		BitmapFont.store("default", defaultFont);
	}

	/** Serialized default font data. (04B_03__.ttf @ 16px) */
	private static inline var _DEFAULT_FONT_DATA:String = "y10744:%7F%2C0%20%28%2100000000%21%24%2C000000000110011001100110011001100000000001100110%22%28%2700000000000000000110011001100110011001100110011000000000%23%2C%2C000000000000000000000000000110011000000110011000011111111110011111111110000110011000000110011000011111111110011111111110000110011000000110011000%24%2A.00000000000000000000000001100000000110000001111110000111111001111000000111100000000001111000000111100111111000011111100000000110000000011000%25%2C%2C000000000000000000000000011000011000011000011000000000011000000000011000000001100000000001100000000110000000000110000000000110000110000110000110%26%2C%2C000000000000000000000000000111100000000111100000011000000000011000000000000111100110000111100110011000011000011000011000000111100110000111100110%27%24%270000000001100110011001100000%28%26%2C000000000000000110000110011000011000011000011000011000011000000110000110%29%26%2C000000000000011000011000000110000110000110000110000110000110011000011000%2A%28%29000000000000000001100110011001100001100000011000011001100110011000000000%2B%28%2B0000000000000000000000000000000000011000000110000111111001111110000110000001100000000000%2C%26.000000000000000000000000000000000000000000000000000000000000000110000110011000011000-%28%29000000000000000000000000000000000000000000000000011111100111111000000000.%24%2C000000000000000000000000000000000000000001100110%2F%2C%2C0000000000000000000000000000000001100000000001100000000110000000000110000000011000000000011000000001100000000001100000000110000000000110000000000%2A%2C0000000000000000000000011110000001111000011000011001100001100110000110011000011001100001100110000110000111100000011110001%26%2C0000000000000111100111100001100001100001100001100001100001100001100001102%2A%2C0000000000000000000001111110000111111000000000011000000001100001111000000111100001100000000110000000011111111001111111103%2A%2C0000000000000000000001111110000111111000000000011000000001100001111000000111100000000001100000000110011111100001111110004%2A%2C0000000000000000000000000110000000011000000111100000011110000110011000011001100001111111100111111110000001100000000110005%2A%2C0000000000000000000001111111100111111110011000000001100000000111111000011111100000000001100000000110011111100001111110006%2A%2C0000000000000000000000011110000001111000011000000001100000000111111000011111100001100001100110000110000111100000011110007%2A%2C0000000000000000000001111111100111111110000000011000000001100000011000000001100000011000000001100000000110000000011000008%2A%2C0000000000000000000000011110000001111000011000011001100001100001111000000111100001100001100110000110000111100000011110009%2A%2C000000000000000000000001111000000111100001100001100110000110000111111000011111100000000110000000011000011110000001111000%3A%24%2B00000000000000000110011000000000011001100000%3B%24%2C000000000000000001100110000000000110011001100110%3C%28%2C000000000000000000000110000001100001100000011000011000000110000000011000000110000000011000000110%3D%28%2B0000000000000000000000000000000001111110011111100000000000000000011111100111111000000000%3E%28%2C000000000000000001100000011000000001100000011000000001100000011000011000000110000110000001100000%3F%2A%2C000000000000000000000111111000011111100000000001100000000110000111100000011110000000000000000000000000011000000001100000%40%2C%2C000000000000000000000000000111111000000111111000011000000110011000000110011001111110011001111110011001100110011001100110000111111000000111111000A%2A%2C000000000000000000000001111000000111100001100001100110000110011000011001100001100111111110011111111001100001100110000110B%2A%2C000000000000000000000111111000011111100001100001100110000110011111100001111110000110000110011000011001111110000111111000C%28%2C000000000000000000011110000111100110000001100000011000000110000001100000011000000001111000011110D%2A%2C000000000000000000000111111000011111100001100001100110000110011000011001100001100110000110011000011001111110000111111000E%28%2C000000000000000001111110011111100110000001100000011111100111111001100000011000000111111001111110F%28%2C000000000000000001111110011111100110000001100000011111100111111001100000011000000110000001100000G%2A%2C000000000000000000000001111110000111111001100000000110000000011001111001100111100110000110011000011000011111100001111110H%2A%2C000000000000000000000110000110011000011001100001100110000110011111111001111111100110000110011000011001100001100110000110I%28%2C000000000000000001111110011111100001100000011000000110000001100000011000000110000111111001111110J%2A%2C000000000000000000000000011110000001111000000001100000000110000000011000000001100110000110011000011000011110000001111000K%2A%2C000000000000000000000110000110011000011001100110000110011000011110000001111000000110011000011001100001100001100110000110L%28%2C000000000000000001100000011000000110000001100000011000000110000001100000011000000111111001111110M%2C%2C000000000000000000000000011000000110011000000110011110011110011110011110011001100110011001100110011000000110011000000110011000000110011000000110N%2A%2C000000000000000000000110000110011000011001111001100111100110011001111001100111100110000110011000011001100001100110000110O%2A%2C000000000000000000000001111000000111100001100001100110000110011000011001100001100110000110011000011000011110000001111000P%2A%2C000000000000000000000111111000011111100001100001100110000110011000011001100001100111111000011111100001100000000110000000Q%2A.00000000000000000000000111100000011110000110000110011000011001100001100110000110011000011001100001100001111000000111100000000001100000000110R%2A%2C000000000000000000000111111000011111100001100001100110000110011000011001100001100111111000011111100001100001100110000110S%2A%2C000000000000000000000001111110000111111001100000000110000000000111100000011110000000000110000000011001111110000111111000T%28%2C000000000000000001111110011111100001100000011000000110000001100000011000000110000001100000011000U%2A%2C000000000000000000000110000110011000011001100001100110000110011000011001100001100110000110011000011000011110000001111000V%2A%2C000000000000000000000110000110011000011001100001100110000110011001100001100110000110011000011001100000011000000001100000W%2C%2C000000000000000000000000011000000110011000000110011001100110011001100110011001100110011001100110011001100110011001100110000110011000000110011000X%2A%2C000000000000000000000110000110011000011001100001100110000110000111100000011110000110000110011000011001100001100110000110Y%2A%2C000000000000000000000110000110011000011001100001100110000110000111111000011111100000000110000000011000011110000001111000Z%28%2C000000000000000001111110011111100000011000000110000110000001100001100000011000000111111001111110%5B%26%2C000000000000011110011110011000011000011000011000011000011000011110011110%5C%2C%2C000000000000000000000000011000000000011000000000000110000000000110000000000001100000000001100000000000011000000000011000000000000110000000000110%5D%26%2C000000000000011110011110000110000110000110000110000110000110011110011110%5E%28%2700000000000000000001100000011000011001100110011000000000_%2A%2C000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111100111111110%60%26%27000000000000011000011000000110000110000000a%2A%2C000000000000000000000000000000000000000000011111100001111110011000011001100001100110000110011000011000011111100001111110b%2A%2C000000000000000000000110000000011000000001111110000111111000011000011001100001100110000110011000011001111110000111111000c%28%2C000000000000000000000000000000000001111000011110011000000110000001100000011000000001111000011110d%2A%2C000000000000000000000000000110000000011000011111100001111110011000011001100001100110000110011000011000011111100001111110e%2A%2C000000000000000000000000000000000000000000011110000001111000011001111001100111100111100000011110000000011110000001111000f%28%2C000000000000000000000110000001100001100000011000011111100111111000011000000110000001100000011000g%2A00000000000000000000000000000000000000000000111111000011111100110000110011000011001100001100110000110000111111000011111100000000110000000011000011110000001111000h%2A%2C000000000000000000000110000000011000000001111110000111111000011000011001100001100110000110011000011001100001100110000110i%24%2C000000000110011000000000011001100110011001100110j%260000000000000000110000110000000000000000110000110000110000110000110000110000110000110011000011000k%2A%2C000000000000000000000110000000011000000001100001100110000110011001100001100110000111111000011111100001100001100110000110l%24%2C000000000110011001100110011001100110011001100110m%2C%2C000000000000000000000000000000000000000000000000011111111000011111111000011001100110011001100110011001100110011001100110011001100110011001100110n%2A%2C000000000000000000000000000000000000000001111110000111111000011000011001100001100110000110011000011001100001100110000110o%2A%2C000000000000000000000000000000000000000000011110000001111000011000011001100001100110000110011000011000011110000001111000p%2A00000000000000000000000000000000000000000011111100001111110000110000110011000011001100001100110000110011111100001111110000110000000011000000001100000000110000000q%2A00000000000000000000000000000000000000000000111111000011111100110000110011000011001100001100110000110000111111000011111100000000110000000011000000001100000000110r%28%2C000000000000000000000000000000000110011001100110011110000111100001100000011000000110000001100000s%2A%2C000000000000000000000000000000000000000000011111100001111110011110000001111000000000011110000001111001111110000111111000t%28%2C000000000000000000011000000110000111111001111110000110000001100000011000000110000000011000000110u%2A%2C000000000000000000000000000000000000000001100001100110000110011000011001100001100110000110011000011000011111100001111110v%2A%2C000000000000000000000000000000000000000001100001100110000110011000011001100001100110011000011001100000011000000001100000w%2C%2C000000000000000000000000000000000000000000000000011001100110011001100110011001100110011001100110000110011000000110011000000110011000000110011000x%28%2C000000000000000000000000000000000110011001100110000110000001100000011000000110000110011001100110y%2A00000000000000000000000000000000000000000011000011001100001100110000110011000011001100001100110000110000111111000011111100000000110000000011000011110000001111000z%2A%2C000000000000000000000000000000000000000001111111100111111110000001100000000110000001100000000110000001111111100111111110%7B%28%2C000000000000000000011110000111100001100000011000011000000110000000011000000110000001111000011110%7C%24%2C000000000110011001100110011001100110011001100110%7D%28%2C000000000000000001111000011110000001100000011000000001100000011000011000000110000111100001111000%7E%2A%270000000000000000000000011001100001100110011001100001100110000000000000";

	// BitmapFont information
	private var _glyphs:Array<BitmapData>;

	private var _glyphString:String;
	private var _maxHeight:Int = 0;
	private var _maxWidth:Int = 0;
	
	private var _colorTransform:ColorTransform;
	
	
	// BitmapFonts cache
	private static var _storedFonts:Map<String, BitmapFont>;
	
}