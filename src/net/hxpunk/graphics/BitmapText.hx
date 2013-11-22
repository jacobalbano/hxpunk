package net.hxpunk.graphics;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.errors.Error;
import flash.geom.Matrix;
import flash.text.TextFormatAlign;
import haxe.ds.IntMap;
import net.hxpunk.graphics.BitmapFont;

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

		if (options != null)
		{
			for (property in Reflect.fields(options)) {
				try {	// if (Reflect.hasField(this, property)) seems to not work in this case
					Reflect.setProperty(this, property, Reflect.getProperty(options, property));
				} catch (e:Error) {
					throw new Error('"' + property + '" is not a property of BitmapText.');
				}
			}
		}

		updateGlyphs(true, _shadow, _outline);
		
		_fieldWidth = 2;
		_fieldHeight = _font.height;
		super(new BitmapData(_fieldWidth, _fieldHeight, true, 0));
		
		_pendingTextChange = true;
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
	private function set_text(text:String):String 
	{
		if (text != _text)
		{
			_text = text;
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return _text;
	}
	
	/** Updates the text buffer, which is the source for the image buffer. */
	public function updateTextBuffer(forceUpdate:Bool = false):Void 
	{
		if (_font == null || (!_pendingTextChange && !forceUpdate))
		{
			return;
		}
		
		var preparedText:String = (_autoUpperCase) ? _text.toUpperCase() : _text;
		var calcFieldWidth:Int = _fieldWidth;
		var rows:Array<String> = [];

		var fontHeight:Int = Math.floor(_font.height * _fontScale);
		
		// cut text into pices
		var lineComplete:Bool;
		
		// get words
		var lines:Array<String> = preparedText.split("\n");
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
				var words:Array<String> = [];
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
									rows.push(txt.substr(0, txt.length - 1));
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
											rows.push(txt.substr(0, txt.length - 1));
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
								rows.push(txt);
							}
							lineComplete = true;
						}
					}
				}
				else
				{
					rows.push("");
				}
			}
			else
			{
				var lineWithoutTabs:String = lines[i].split("\t").join(_tabSpaces);
				calcFieldWidth = Math.floor(Math.max(calcFieldWidth, _font.getTextWidth(lineWithoutTabs, _letterSpacing, _fontScale)));
				rows.push(lineWithoutTabs);
			}
		}
		
		var finalWidth:Int = calcFieldWidth + _padding * 2 + (_outline ? 2 : 0);
		var finalHeight:Int = Math.floor(_padding * 2 + Math.max(1, (rows.length * fontHeight + (_shadow ? 1 : 0)) + (_outline ? 2 : 0))) + ((rows.length >= 1) ? _lineSpacing * (rows.length - 1) : 0);
		
		if (_source != null) 
		{
			if (finalWidth != _sourceRect.width || finalHeight != _sourceRect.height) 
			{
				_source.dispose();
				_source = null;
			}
		}
		
		if (_source == null) 
		{
			_source = new BitmapData(finalWidth, finalHeight, !_background, _backgroundColor);
			_sourceRect = source.rect;
			createBuffer();
		} 
		else 
		{
			_source.fillRect(_sourceRect, _backgroundColor);
		}
		
		_fieldWidth = Std.int(_sourceRect.width);
		_fieldHeight = Std.int(_sourceRect.height);
		
		if (_fontScale > 0)
		{
			_source.lock();
			
			// render text
			var row:Int = 0;
			
			for (t in rows) 
			{
				var ox:Int = 0; // LEFT
				var oy:Int = 0;
				if (_align == TextFormatAlign.CENTER) 
				{
					if (_fixedWidth)
					{
						ox = Math.floor((_fieldWidth - _font.getTextWidth(t, _letterSpacing, _fontScale)) / 2);
					}
					else
					{
						ox = Math.floor((finalWidth - _font.getTextWidth(t, _letterSpacing, _fontScale)) / 2);
					}
				}
				if (align == TextFormatAlign.RIGHT) 
				{
					if (_fixedWidth)
					{
						ox = _fieldWidth - Math.floor(_font.getTextWidth(t, _letterSpacing, _fontScale));
					}
					else
					{
						ox = finalWidth - Math.floor(_font.getTextWidth(t, _letterSpacing, _fontScale)) - 2 * padding;
					}
				}
				if (_outline) 
				{
					for (py in 0...(2 + 1)) 
					{
						for (px in 0...(2 + 1)) 
						{
							_font.render(_source, _preparedOutlineGlyphs, t, _outlineColor, px + ox + _padding, py + row * (fontHeight + _lineSpacing) + _padding, _letterSpacing);
						}
					}
					ox += 1;
					oy += 1;
				}
				if (_shadow) 
				{
					_font.render(_source, _preparedShadowGlyphs, t, _shadowColor, 1 + ox + _padding, 1 + oy + row * (fontHeight + _lineSpacing) + _padding, _letterSpacing);
				}
				_font.render(_source, _preparedTextGlyphs, t, _textColor, ox + _padding, oy + row * (fontHeight + _lineSpacing) + _padding, _letterSpacing);
				row++;
			}
			
			_source.unlock();
		}
		
		super.updateBuffer();
		_pendingTextChange = false;
	}
	
	/**
	 * Specifies whether the text field should have a filled background.
	 */
	public var background(get, set):Bool;
	private inline function get_background():Bool
	{
		return _background;
	}
	private function set_background(value:Bool):Bool 
	{
		if (_background != value)
		{
			_background = value;
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return value;
	}
	
	/**
	 * Specifies the color of the text field background.
	 */
	public var backgroundColor(get, set):Int;
	private inline function get_backgroundColor():Int
	{
		return _backgroundColor;
	}
	private function set_backgroundColor(value:Int):Int
	{
		if (_backgroundColor != value)
		{
			_backgroundColor = value;
			if (_background)
			{
				_pendingTextChange = true;
				updateTextBuffer();
			}
		}
		return value;
	}
	
	/**
	 * Specifies whether the text should have a shadow.
	 */
	public var shadow(get, set):Bool;
	private inline function get_shadow():Bool
	{
		return _shadow;
	}
	private function set_shadow(value:Bool):Bool
	{
		if (_shadow != value)
		{
			_shadow = value;
			_outline = false;
			updateGlyphs(false, _shadow, false);
			_pendingTextChange = true;
			updateTextBuffer();
		}
		
		return value;
	}
	
	/**
	 * Specifies the color of the text field shadow.
	 */
	public var shadowColor(get, set):Int;
	private inline function get_shadowColor():Int
	{
		return _shadowColor;
	}
	private function set_shadowColor(value:Int):Int 
	{
		if (_shadowColor != value)
		{
			_shadowColor = value;
			updateGlyphs(false, _shadow, false);
			_pendingTextChange = true;
			updateTextBuffer();
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
	 * Sets the color of the text.
	 */
	public var textColor(get, set):Int;
	private inline function get_textColor():Int
	{
		return _textColor;
	}
	private function set_textColor(value:Int):Int 
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
	 * Specifies whether the text field should use text color.
	 */
	public var useTextColor(get, set):Bool;
	private inline function get_useTextColor():Bool 
	{
		return _useTextColor;
	}
	private function set_useTextColor(value:Bool):Bool 
	{
		if (_useTextColor != value)
		{
			_useTextColor = value;
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
			_source = new BitmapData(_fieldWidth, _fieldHeight, !_background, _backgroundColor);
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
	 * Specifies whether the text should have an outline.
	 */
	public var outline(get_outline, set_outline):Bool;
	private inline function get_outline():Bool
	{
		return _outline;
	}
	private function set_outline(value:Bool):Bool 
	{
		if (_outline != value)
		{
			_outline = value;
			_shadow = false;
			updateGlyphs(false, false, true);
			_pendingTextChange = true;
			updateTextBuffer();
		}
		return value;
	}
	
	/**
	 * Specifies the color to use for the text outline.
	 */
	public var outlineColor(get_outlineColor, set_outlineColor):Int;
	private inline function get_outlineColor():Int
	{
		return _outlineColor;
	}
	private function set_outlineColor(value:Int):Int 
	{
		if (_outlineColor != value)
		{
			_outlineColor = value;
			updateGlyphs(false, false, _outline);
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
			updateGlyphs(true, _shadow, _outline);
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
			_lineSpacing = Math.floor(Math.abs(value));
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
			updateGlyphs(true, _shadow, _outline);
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
	
	/** Update array of glyphs. */
	private function updateGlyphs(?textGlyphs:Bool = false, ?shadowGlyphs:Bool = false, ?outlineGlyphs:Bool = false):Void
	{
		if (textGlyphs)
		{
			clearPreparedGlyphs(_preparedTextGlyphs);
			_preparedTextGlyphs = _font.getPreparedGlyphs(_fontScale, _textColor, _useTextColor);
		}
		
		if (shadowGlyphs)
		{
			clearPreparedGlyphs(_preparedShadowGlyphs);
			_preparedShadowGlyphs = _font.getPreparedGlyphs(_fontScale, _shadowColor);
		}
		
		if (outlineGlyphs)
		{
			clearPreparedGlyphs(_preparedOutlineGlyphs);
			_preparedOutlineGlyphs = _font.getPreparedGlyphs(_fontScale, _outlineColor);
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
	private var _textColor:Int = 0xFFFFFF;
	private var _useTextColor:Bool = false;
	private var _outline:Bool = false;
	private var _outlineColor:Int = 0x0;
	private var _shadow:Bool = false;
	private var _shadowColor:Int = 0x0;
	private var _background:Bool = false;
	private var _backgroundColor:Int = 0x0;
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