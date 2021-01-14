package net.hxpunk.graphics;

import flash.display.BitmapData;
import flash.errors.Error;
import flash.geom.Matrix;
import flash.text.TextFormatAlign;
import haxe.ds.IntMap;
import net.hxpunk.graphics.BitmapFont;
import net.hxpunk.HP;

/**
 * Used for drawing text using a BitmapFont.
 *
 * Adapted from Beeblerox work (which built upon Pixelizer implementation).
 * 
 * @see https://github.com/Beeblerox/BitmapFont
 */
class BitmapText extends Image
{
	/**
	 * Constructor.
	 * @param	text		Text to display.
	 * @param	x			X offset.
	 * @param	y			Y offset.
	 * @param 	font		The BitmapFont to use (pass null to use the default one).
	 * @param	options		An object containing key/value pairs of property/value to set on the BitmapText object.
	 */ 
	public function new(text:String, x:Float = 0, y:Float = 0, ?font:BitmapFont = null, options:Dynamic = null) 
	{
		_text = text;
		_align = TextFormatAlign.LEFT;
		
		if (font == null)
		{
			if (BitmapFont.fetch("default") == null)
			{
				BitmapFont.createDefaultFont();
			}
			_font = BitmapFont.fetch("default");
		}
		else
		{
			_font = font;
		}
		
		this.x = x;
		this.y = y;

		_fieldWidth = 2;
		_fieldHeight = _font.height;
		
		super(new BitmapData(_fieldWidth, _fieldHeight, true, 0));
		
		lock();

		updateGlyphs(true, _shadowColor != null, _outlineColor != null);
		
		if (options != null)
		{
			for (property in Reflect.fields(options)) {
				try {
					Reflect.setProperty(this, property, Reflect.getProperty(options, property));
				} catch (e:Error) {
					throw new Error('"' + property + '" is not a property of BitmapText.');
				}
			}
		}

		_pendingTextChange = true;
		unlock();
		
		updateTextBuffer();
	}
	
	/**
	 * Clears all resources used.
	 */
	public function destroy():Void 
	{
		_font = null;

		clearPreparedGlyphs(_preparedTextGlyphs);
		clearPreparedGlyphs(_preparedShadowGlyphs);
		clearPreparedGlyphs(_preparedOutlineGlyphs);
	}
	
	/** Sets the number of spaces with which tab ("\t") will be replaced. */
	public var numSpacesInTab(get, set):Int;
	private inline function get_numSpacesInTab():Int 
	{
		return _numSpacesInTab;
	}
	private function set_numSpacesInTab(value:Int):Int 
	{
		if (_numSpacesInTab != value && value > 0)
		{
			_numSpacesInTab = value;
			_tabSpaces = "";
			for (i in 0...value)
			{
				_tabSpaces += " ";
			}
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return value;
	}
	
	/**
	 * Text to display.
	 */
	public var text(get, set):String;
	private inline function get_text():String
	{
		return _text;
	}
	private function set_text(value:String):String 
	{
		if (_text != value)
		{
			_text = value;
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return value;
	}
	
	/** Updates the text buffer, which is the source for the image buffer. */
	public function updateTextBuffer(forceUpdate:Bool = false):Void 
	{
		if (_font == null || locked || (!_pendingTextChange && !forceUpdate))
		{
			return;
		}
		
		var preparedText:String = (_autoUpperCase) ? _text.toUpperCase() : _text;
		var rows:Array<String> = new Array<String>();

		var fontHeight:Int = Math.floor(_font.height * _fontScale);
		
		// split text into lines and calc min text field width (based on multiLine, fixedWidth, wordWrap, etc.)
		var calcFieldWidth = splitIntoLines(preparedText, rows);
		
		var background:Bool = _backgroundColor != null;
		var shadow:Bool = _shadowColor != null;
		var outline:Bool = _outlineColor != null;
		
		var finalWidth:Int = Std.int(calcFieldWidth + _padding * 2 + (shadow ? Math.abs(_shadowOffsetX) : 0) + (outline ? 2 : 0));
		var finalHeight:Int = Std.int(Math.floor(_padding * 2 + Math.max(1, (rows.length * fontHeight + (shadow ? Math.abs(_shadowOffsetY) : 0) + (outline ? 2 : 0))) + ((rows.length >= 1) ? _lineSpacing * (rows.length - 1) : 0)));
		
		if (_source != null) 
		{
			if (finalWidth > _sourceRect.width || finalHeight > _sourceRect.height) 
			{
				_source.dispose();
				_source = null;
			}
		}
		
		if (_source == null) 
		{
			_source = new BitmapData(finalWidth, finalHeight, true, (background ? _backgroundColor | 0xFF000000 : 0));
			_sourceRect = source.rect;
			createBuffer();
		} 
		else 
		{
			_source.fillRect(_sourceRect, (background ? _backgroundColor | 0xFF000000 : 0));
		}
		
		_fieldWidth = Std.int(_sourceRect.width);
		_fieldHeight = Std.int(_sourceRect.height);
		
		if (_fontScale > 0)
		{
			_source.lock();
			
			// render text
			for (i in 0...rows.length) 
			{
				// if shadowOffsetY is negative, draw in reverse order (last row first), so that shadow text is drawn below
				var row:Int = (shadow && _shadowOffsetY < 0 ? rows.length - 1 - i : i);
				var t:String = rows[row];
				
				// default offset (align LEFT)
				var ox:Int = (shadow && _shadowOffsetX < 0 ? -_shadowOffsetX : 0) + (outline ? 1 : 0);
				var oy:Int = (shadow && _shadowOffsetY < 0 ? -_shadowOffsetY : 0) + (outline ? 1 : 0);
		
				if (_align == TextFormatAlign.CENTER) 
				{
					if (_fixedWidth)
					{
						ox += Math.floor((_fieldWidth - _font.getTextWidth(t, _letterSpacing, _fontScale)) / 2);
					}
					else
					{
						ox += Math.floor((finalWidth - _font.getTextWidth(t, _letterSpacing, _fontScale)) / 2);
					}
					if (shadow) ox -= Std.int(Math.abs(_shadowOffsetX / 2));
				}
				if (align == TextFormatAlign.RIGHT) 
				{
					if (_fixedWidth)
					{
						ox += _fieldWidth - Math.floor(_font.getTextWidth(t, _letterSpacing, _fontScale));
					}
					else
					{
						ox += finalWidth - Math.floor(_font.getTextWidth(t, _letterSpacing, _fontScale)) - 2 * padding;
					}
					if (shadow) ox -= Std.int(Math.abs(_shadowOffsetX));
					if (outline) ox -= 1;
				}
				if (shadow) 
				{
					var addOffX:Int = (outline ? HP.sign(shadowOffsetX) : 0);
					var addOffY:Int = (outline ? HP.sign(shadowOffsetY) : 0);
					
					_font.render(_source, t, _preparedShadowGlyphs, _shadowOffsetX + addOffX + ox + _padding, _shadowOffsetY + addOffY + oy + row * (fontHeight + _lineSpacing) + _padding, _letterSpacing);
				}
				if (outline) 
				{
					var py:Int = -1;
					var px:Int = -1;
					while (py <= 1) 
					{
						while (px <= 1)
						{
							// Note: seems unnecessary to also draw when (px == py == 0), but it gives better results
							_font.render(_source, t, _preparedOutlineGlyphs, px + ox + _padding, py + oy + row * (fontHeight + _lineSpacing) + _padding, _letterSpacing);
							px++;
						}
						py++;
						px = -1;
					}
				}
				_font.render(_source, t, _preparedTextGlyphs, ox + _padding, oy + row * (fontHeight + _lineSpacing) + _padding, _letterSpacing);
			}
			
			_source.unlock();
		}
		
		super.updateBuffer();
		_pendingTextChange = false;
	}
	
	/**
	 * Analyzes text and splits it into separate lines (appended to intoLines), giving back the calculated minimum 
	 * width of the text field (without accounting for outline and shadow).
	 * @param	text		The text string to analyze.
	 * @param	intoRows	An Array of strings with each item representing a single line.
	 * @return	The calculated width for the text field.
	 */
	private function splitIntoLines(text:String, intoLines:Array<String>):Int 
	{
		var calcFieldWidth:Int = 0;
		var lineComplete:Bool;
		
		// get words
		var lines:Array<String> = text.split("\n");
		var i:Int = -1;
		var j:Int = -1;
		
		if (!_multiLine)
		{
			lines = [lines[0]];
		}
		
		var wordLength:Int;
		var word:String;
		var tempStr:String;
		
		while (++i < lines.length) 
		{
			if (_fixedWidth)
			{
				lineComplete = false;
				var words:Array<String> = new Array<String>();
				if (!wordWrap)
				{
					words = lines[i].split("\t").join(_tabSpaces).split(" ");
				}
				else
				{
					words = lines[i].split("\t").join(" \t ").split(" ");
				}
				
				if (words.length > 0) 
				{
					var wordPos:Int = 0;
					var txt:String = "";
					
					while (!lineComplete) 
					{
						word = words[wordPos];
						var changed:Bool = false;
						var currentRow:String = txt + word;
						
						if (_wordWrap)
						{
							var prevWord:String = (wordPos > 0) ? words[wordPos - 1] : "";
							var nextWord:String = (wordPos < words.length) ? words[wordPos + 1] : "";
							if (prevWord != "\t") currentRow += " ";
							
							if (_font.getTextWidth(currentRow, _letterSpacing, _fontScale) > _fieldWidth) 
							{
								if (txt == "")
								{
									words.splice(0, 1);
								}
								else
								{
									intoLines.push(txt.substr(0, txt.length - 1));
								}
								
								txt = "";
								if (_multiLine)
								{
									if (word == "\t" && (wordPos < words.length))
									{
										words.splice(0, wordPos + 1);
									}
									else
									{
										words.splice(0, wordPos);
									}
								}
								else
								{
									words.splice(0, words.length);
								}
								wordPos = 0;
								changed = true;
							}
							else
							{
								if (word == "\t")
								{
									txt += _tabSpaces;
								}
								if (nextWord == "\t" || prevWord == "\t")
								{
									txt += word;
								}
								else
								{
									txt += word + " ";
								}
								wordPos++;
							}
						}
						else
						{
							if (_font.getTextWidth(currentRow, _letterSpacing, _fontScale) > _fieldWidth) 
							{
								if (word != "")
								{
									j = 0;
									tempStr = "";
									wordLength = word.length;
									while (j < wordLength)
									{
										currentRow = txt + word.charAt(j);
										if (_font.getTextWidth(currentRow, _letterSpacing, _fontScale) > _fieldWidth) 
										{
											intoLines.push(txt.substr(0, txt.length - 1));
											txt = "";
											word = "";
											wordPos = words.length;
											j = wordLength;
											changed = true;
										}
										else
										{
											txt += word.charAt(j);
										}
										j++;
									}
								}
								else
								{
									changed = false;
									wordPos = words.length;
								}
							}
							else
							{
								txt += word + " ";
								wordPos++;
							}
						}
						
						if (wordPos >= words.length) 
						{
							if (!changed) 
							{
								calcFieldWidth = Math.floor(Math.max(calcFieldWidth, _font.getTextWidth(txt, _letterSpacing, _fontScale)));
								intoLines.push(txt);
							}
							lineComplete = true;
						}
					}
				}
				else
				{
					intoLines.push("");
				}
			}
			else
			{
				var lineWithoutTabs:String = lines[i].split("\t").join(_tabSpaces);
				calcFieldWidth = Math.floor(Math.max(calcFieldWidth, _font.getTextWidth(lineWithoutTabs, _letterSpacing, _fontScale)));
				intoLines.push(lineWithoutTabs);
			}
		}
		
		return calcFieldWidth;
	}
	
	/**
	 * The color of the text field background (set to null to disable the background).
	 */
	public var backgroundColor(get, set):Null<Int>;
	private inline function get_backgroundColor():Null<Int>
	{
		return _backgroundColor;
	}
	private function set_backgroundColor(value:Null<Int>):Null<Int>
	{
		if (_backgroundColor != value)
		{
			_backgroundColor = value;
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return value;
	}
		
	/**
	 * The color of the text field shadow (set to null to disable the shadow).
	 */
	public var shadowColor(get, set):Null<Int>;
	private inline function get_shadowColor():Null<Int>
	{
		return _shadowColor;
	}
	private function set_shadowColor(value:Null<Int>):Null<Int> 
	{
		if (_shadowColor != value)
		{
			_shadowColor = value;
			updateGlyphs(false, true, false);
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return value;
	}
	
	/**
	 * The X offset of the text field shadow.
	 */
	public var shadowOffsetX(get, set):Int;
	private function get_shadowOffsetX():Int
	{
		return _shadowOffsetX;
	}
	private function set_shadowOffsetX(value:Int):Int		
	{
		if (_shadowOffsetX != value)
		{
			_shadowOffsetX = value;
			
			if (_shadowColor != null) {
				_pendingTextChange = true;
				updateTextBuffer();
			}
		}
		return value;
	}
	
	/**
	 * The Y offset of the text field shadow.
	 */
	public var shadowOffsetY(get, set):Int;
	private function get_shadowOffsetY():Int
	{
		return _shadowOffsetY;
	}
	private function set_shadowOffsetY(value:Int):Int		
	{
		if (_shadowOffsetY != value)
		{
			_shadowOffsetY = value;
			
			if (_shadowColor != null) {
				_pendingTextChange = true;
				updateTextBuffer();
			}
		}
		return value;
	}

	/**
	 * Sets the padding of the text field. This is the distance between the text and the border of the background (if any).
	 */
	public var padding(get, set):Int;
	private inline function get_padding():Int
	{
		return _padding;
	}
	private function set_padding(value:Int):Int 
	{
		if (_padding != value)
		{
			_padding = value;
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return value;
	}
	
	/**
	 * Sets the color of the text (set to null to use the original color).
	 */
	public var textColor(get, set):Null<Int>;
	private inline function get_textColor():Null<Int>
	{
		return _textColor;
	}
	private function set_textColor(value:Null<Int>):Null<Int> 
	{
		if (_textColor != value)
		{
			_textColor = value;
			updateGlyphs(true, false, false);
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return value;
	}
	
	/**
	 * Sets the width of the text field. If the text does not fit, it will spread on multiple lines.
	 */
	public function setWidth(value:Int):Int 
	{
		if (value < 1) 
		{
			value = 1;
		}
		if (value != _fieldWidth)
		{
			_fieldWidth = value;
			
			_source.dispose();
			_source = null;
			_source = new BitmapData(_fieldWidth, _fieldHeight, true, (_backgroundColor != null ? _backgroundColor | 0xFF000000 : 0));
			_sourceRect = source.rect;
			createBuffer();

			_pendingTextChange = true;
			updateTextBuffer();
		}
		
		return value;
	}
	
	/**
	 * Alignment ("left", "center" or "right").
	 */
#if (flash || html5)
	public var align(get, set):TextFormatAlign;
	private inline function get_align() { return _align; }
	private function set_align(value:TextFormatAlign):TextFormatAlign
#else
	public var align(get, set):String;
	private inline function get_align() { return _align; }
	private function set_align(value:String):String
#end
	{
		if (_align != value)
		{
			_align = value;
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return value;
	}
	
	/**
	 * Specifies whether the text field will break into multiple lines or not on overflow.
	 */
	public var multiLine(get_multiLine, set_multiLine):Bool;
	private inline function get_multiLine():Bool
	{
		return _multiLine;
	}
	private function set_multiLine(value:Bool):Bool 
	{
		if (_multiLine != value)
		{
			_multiLine = value;
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return value;
	}
	
	/**
	 * The color to use for the text outline (set to null to disable the outline).
	 */
	public var outlineColor(get_outlineColor, set_outlineColor):Null<Int>;
	private inline function get_outlineColor():Null<Int>
	{
		return _outlineColor;
	}
	private function set_outlineColor(value:Null<Int>):Null<Int> 
	{
		if (_outlineColor != value)
		{
			_outlineColor = value;
			updateGlyphs(false, false, true);
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return value;
	}
	
	/**
	 * Sets which BitmapFont to use for rendering.
	 */
	public var font(get, set):BitmapFont;
	private inline function get_font():BitmapFont
	{
		return _font;
	}
	private function set_font(font:BitmapFont):BitmapFont 
	{
		if (_font != font)
		{
			_font = font;
			updateGlyphs(true, _shadowColor != null, _outlineColor != null);
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return font;
	}
	
	/**
	 * Sets the distance between lines.
	 */
	public var lineSpacing(get, set):Int;
	private inline function get_lineSpacing():Int
	{
		return _lineSpacing;
	}
	private function set_lineSpacing(value:Int):Int
	{
		if (_lineSpacing != value)
		{
			_lineSpacing = Math.floor(value);
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return value;
	}
	
	/**
	 * Sets the "font size" of the text.
	 */
	public var fontScale(get, set):Float;
	private inline function get_fontScale():Float
	{
		return _fontScale;
	}
	private function set_fontScale(value:Float):Float
	{
		var tmp:Float = Math.abs(value);
		if (tmp != _fontScale)
		{
			_fontScale = tmp;
			updateGlyphs(true, _shadowColor != null, _outlineColor != null);
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return value;
	}
	
	/** Sets the space between each character. */
	public var letterSpacing(get, set):Int;
	private inline function get_letterSpacing():Int
	{
		return _letterSpacing;
	}
	private function set_letterSpacing(value:Int):Int
	{
		var tmp:Int = Math.floor(Math.abs(value));
		if (tmp != _letterSpacing)
		{
			_letterSpacing = tmp;
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return _letterSpacing;
	}
	
	/** Automatically uppercase the text. */
	public var autoUpperCase(get, set):Bool;
	private inline function get_autoUpperCase():Bool 
	{
		return _autoUpperCase;
	}
	private function set_autoUpperCase(value:Bool):Bool 
	{
		if (_autoUpperCase != value)
		{
			_autoUpperCase = value;
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return _autoUpperCase;
	}
	
	/** Whether the text should use word wrapping (use it in combination with fixedSize and setWidth()). */
	public var wordWrap(get, set):Bool;
	private inline function get_wordWrap():Bool 
	{
		return _wordWrap;
	}
	private function set_wordWrap(value:Bool):Bool 
	{
		if (_wordWrap != value)
		{
			_wordWrap = value;
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return _wordWrap;
	}
	
	/** Whether the text field should have a fixed width (use setWidth() afterwards). */
	public var fixedWidth(get, set):Bool;
	private inline function get_fixedWidth():Bool 
	{
		return _fixedWidth;
	}
	private function set_fixedWidth(value:Bool):Bool 
	{
		if (_fixedWidth != value)
		{
			_fixedWidth = value;
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return _fixedWidth;
	}
	
	/**
	 * Sets properties specified by the props object.
	 * 
	 * Ex.:
	 *     bitmapText.setProperties({shadowColor:0xFF0000, outlineColor:0x0, lineSpacing:5});
	 * 
	 * @param	props	An Object containing key/value pairs of properties to set.
	 */
	public function setProperties(props:Dynamic):Void 
	{
		if (props != null)
		{
			lock();
			for (property in Reflect.fields(props)) {
				try {
					Reflect.setProperty(this, property, Reflect.getProperty(props, property));
				} catch (e:Error) {
					throw new Error('"' + property + '" is not a property of BitmapText.');
				}
			}
			unlock();
			
			_pendingTextChange = true;
			updateTextBuffer();
		}
	}
	
	/** Update array of glyphs. */
	private function updateGlyphs(?textGlyphs:Bool = false, ?shadowGlyphs:Bool = false, ?outlineGlyphs:Bool = false):Void
	{
		if (textGlyphs)
		{
			clearPreparedGlyphs(_preparedTextGlyphs);
			_preparedTextGlyphs = _font.getPreparedGlyphs(_fontScale, (_textColor != null ? _textColor : 0), _textColor != null);
		}
		
		if (shadowGlyphs)
		{
			clearPreparedGlyphs(_preparedShadowGlyphs);
			_preparedShadowGlyphs = _font.getPreparedGlyphs(_fontScale, (_shadowColor != null ? _shadowColor : 0), _shadowColor != null);
		}
		
		if (outlineGlyphs)
		{
			clearPreparedGlyphs(_preparedOutlineGlyphs);
			_preparedOutlineGlyphs = _font.getPreparedGlyphs(_fontScale, (_outlineColor != null ? _outlineColor : 0), _outlineColor != null);
		}
	}
	
	/** Dispose of the prepared glyphs BitmapDatas. */
	private function clearPreparedGlyphs(glyphs:IntMap<BitmapData>):Void
	{
		if (glyphs != null)
		{
			var bmd:BitmapData;
			for (i in glyphs.keys())
			{
				bmd = glyphs.get(i);
				if (bmd != null)
				{
					bmd.dispose();
				}
				glyphs.remove(i);
			}
			glyphs = null;
		}
	}

	// BitmapText information
	private var _font:BitmapFont;
	private var _text:String = "";
	private var _fieldWidth:Int = 0;
	private var _fieldHeight:Int = 0;
	private var _textColor:Null<Int> = null;
	private var _outlineColor:Null<Int> = null;
	private var _shadowColor:Null<Int> = null;
	private var _shadowOffsetX:Int = 1;
	private var _shadowOffsetY:Int = 1;
	private var _backgroundColor:Null<Int> = null;
#if (flash || html5)
	private var _align:TextFormatAlign;
#else
	private var _align:String;
#end
	private var _padding:Int = 0;
	
	private var _lineSpacing:Int = 0;
	private var _letterSpacing:Int = 0;
	private var _fontScale:Float = 1;
	private var _autoUpperCase:Bool = false;
	private var _wordWrap:Bool = true;
	private var _fixedWidth:Bool = false;
	
	private var _numSpacesInTab:Int = 4;
	private var _tabSpaces:String = "    ";
	
	private var _pendingTextChange:Bool = false;
	private var _multiLine:Bool = true;

	private var _preparedTextGlyphs:IntMap<BitmapData>;
	private var _preparedShadowGlyphs:IntMap<BitmapData>;
	private var _preparedOutlineGlyphs:IntMap<BitmapData>;
}