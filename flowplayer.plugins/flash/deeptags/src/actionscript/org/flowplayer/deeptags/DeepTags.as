package org.flowplayer.deeptags {
    import com.adobe.serialization.json.JSON;
    import com.hurlant.crypto.Crypto;
    import com.hurlant.crypto.symmetric.ICipher;
    import com.hurlant.crypto.symmetric.IPad;
    import com.hurlant.crypto.symmetric.IVMode;
    import com.hurlant.crypto.symmetric.NullPad;
    import com.hurlant.util.Hex;
    
    import flash.display.*;
    import flash.events.*;
    import flash.filters.DropShadowFilter;
    import flash.filters.GlowFilter;
    import flash.system.Security;
    import flash.text.*;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.Timer;
    
    import org.flowplayer.controller.ResourceLoader;
    import org.flowplayer.controls.Controlbar;
    import org.flowplayer.controls.Controls;
    import org.flowplayer.controls.scrubber.*;
    import org.flowplayer.controls.scrubber.ScrubberController;
    import org.flowplayer.layout.Position;
    import org.flowplayer.model.DisplayPluginModel;
    import org.flowplayer.model.DisplayProperties;
    import org.flowplayer.model.Plugin;
    import org.flowplayer.model.PluginModel;
    import org.flowplayer.util.Arrange;
    import org.flowplayer.util.Log;
    import org.flowplayer.util.StyleSheetUtil;
    import org.flowplayer.view.Animation;
    import org.flowplayer.view.AnimationEngine;
    import org.flowplayer.view.Flowplayer;
    import org.flowplayer.view.StyleableSprite;

	public class DeepTags extends StyleableSprite implements Plugin {

        private static const KEY:String = "dbf8a9efe09130e02d8628d5019db882";
        private var _deepTags:Object;
        private var _duration:Number;
		private var _model:PluginModel;
		private var _text:TextField;
        private var _player:Flowplayer;		
        private var _format:TextFormat;
        private var _style:StyleSheet;
        private var _controls:Controls;
        private var _scrubberWidth:Number;
        private var _plugin:DisplayPluginModel;
        private var _controlbar:Controlbar;
        private var _videoID:Number;
        private var _slider:ScrubberSlider;
        private var _currentInput:ByteArray;
        private var _dict:Dictionary;
		private var _animationEngine:AnimationEngine;
        private var _base:String = 'www.madthumbs.com';
		
        private var _distance:Number = 2;        
        private var _angle:Number = 45;
        private var _glowColor:Number = 0xFF9900;
		private var _textColor:Number = 0xFFFFFF;
		private var _linkColor:Number = 0xFF6600;
		private var _hoverColor:Number = 0xFFFFFF;
		private var _fontFamily:String = 'Tahoma, Helvetica, Verdana, sans-serif';
        private var _dsfColor:Number = 0x000000;
        private var _alpha:Number = 0.40;
		private var _logo:Bitmap;
		
        private var _blurX:Number = 5;
        private var _blurY:Number = 5;
        private var _dsfBlurX:Number = 2;
        private var _dsfBlurY:Number = 2;
        private var _strength:Number = 4;
        private var _inner:Boolean = false;
        private var _knockout:Boolean = false;
        private var _hideObject:Boolean = false;        
        private var _quality:Number = 2;
        private var _timer:Timer;
		private var _scubberController:ScrubberController;

        private var glow:GlowFilter;
        
        private var dsf:DropShadowFilter;                                  
        
		public function DeepTags() {
		    Security.loadPolicyFile("http://www.madthumbs.com/crossdomain.xml");
			Security.loadPolicyFile("http://cache.tgpsitecentral.com/crossdomain.xml");
            _dict = new Dictionary();
            _style = new StyleSheet();
            _timer = new Timer(800, 1);
            _timer.addEventListener("timer", function():void {
                _slider.hideTooltip();
            });
		}
		
		public function get timer():Timer{
			return _timer;
		}
		
        private function makeHashMarks():void{            
			log.debug('adding hashmarks');
			if (_deepTags == null) return;
			_player.playlist.current.tags = _deepTags;
			log.debug('setting clip tags', _deepTags);
			
			if (_controls) {
       			_controlbar = _controls.controlbar as Controlbar;
				_slider = _controlbar.widgetControllers['scrubber'].widget as ScrubberSlider;
       			_scrubberWidth = _slider.width;
			}

            var spacing:int = 40;    
            for (var i:int = 0; i < _deepTags.length; i++){ 
                var linkText:String = _deepTags[i].name.toUpperCase();                               
                var perc:Number = Math.ceil((_deepTags[i].seconds / _duration) * _scrubberWidth);
                var _tick:Sprite = new Sprite();
                _tick.buttonMode = true;
                _tick.graphics.lineStyle(2, _linkColor, 0, false, 'none', 'none', 'miter');
                with (_tick.graphics) {
        		    beginFill(_linkColor, 1);
                    drawRect(0, 0, 2, _slider.height/2); 
    			    endFill();
                }
                _tick.name = "tick";       
                _tick.x = perc - _tick.width / 2;
                _tick.y = (_slider.height - _tick.height) / 2;
                _tick.addEventListener(MouseEvent.ROLL_OVER, tickOver);
                _tick.addEventListener(MouseEvent.ROLL_OUT, tickOut);     
                _tick.addEventListener(MouseEvent.CLICK, tickClick);          
                //_tick.filters = [dsf];
                _tick.cacheAsBitmap = true;
				_tick.alpha = 0;
				_slider.addChild(_tick);
				_animationEngine.fadeIn(_tick, 1000);
                
				_text = new TextField();
                
                //_text.embedFonts = true;
    			_text.antiAliasType = AntiAliasType.ADVANCED;
    			_text.autoSize = TextFieldAutoSize.LEFT;
    			_text.styleSheet = _style;
    			_text.selectable = false;
				_text.border = false;
    			//_text.multiline = true;
                _text.addEventListener(MouseEvent.ROLL_OVER, mouseOver);
                _text.addEventListener(MouseEvent.ROLL_OUT, mouseOut);
                _text.gridFitType = GridFitType.PIXEL;
                _text.sharpness = 400;

    			//_text.background = true;
    			_text.htmlText = '<a href="event:' + Number(_deepTags[i].seconds) + '">' + linkText + '</a>';
    			_dict[_text] = {'seconds':_deepTags[i].seconds, 'tick':_tick};
    			_dict[_tick] = {'seconds':_deepTags[i].seconds, 'txt':_text};
    			_text.x = spacing;
				_text.y = (getDefaultConfig().height - _text.textHeight)/2 - 1;
    			_text.filters = [dsf];
    			_text.alpha = 0;
				spacing += _text.width + 6;
    			_text.addEventListener(TextEvent.LINK, linkEvent);
    			addChild(_text);
				_animationEngine.fadeIn(_text, 1000);
            }
			
        }
		
		private function destroyTags():void {
			for(var obj:Object in _dict){
				//log.debug('dictionary object', _dict[obj]);
				if (_dict[obj].hasOwnProperty('tick')) {
					_dict[obj].tick.removeEventListener(MouseEvent.ROLL_OVER, tickOver);
					_dict[obj].tick.removeEventListener(MouseEvent.ROLL_OUT, tickOut);
					_dict[obj].tick.removeEventListener(MouseEvent.CLICK, tickClick);
					_slider.removeChild(_dict[obj].tick);
				} else {
					_dict[obj].txt.removeEventListener(MouseEvent.ROLL_OVER, mouseOver);
					_dict[obj].txt.removeEventListener(MouseEvent.ROLL_OUT, mouseOut);
					_dict[obj].txt.removeEventListener(TextEvent.LINK, linkEvent);
					removeChild(_dict[obj].txt);
				}
				delete _dict[obj];
			}
		}

        private function linkEvent(event:TextEvent):void {
        	_player.seek(Number(event.text));
        	_timer.start();
        }

		private function tickClick(event:MouseEvent):void{
			var seconds:Number = _dict[event.target].seconds;
			_player.seek(Number(seconds));
			_timer.start();
		}
		
        private function tickOver(event:MouseEvent):void{
            var link:TextField = _dict[event.target].txt;
            //link.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
			redraw(Sprite(event.target), event.type);
            link.textColor = _hoverColor;
			link.filters = event.target.filters = [glow];
        }
                
        private function tickOut(event:MouseEvent):void{
            var link:TextField = _dict[event.target].txt;
            //link.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
			redraw(Sprite(event.target), event.type);
            link.textColor = _linkColor;
			link.filters = [dsf];
			event.target.filters = [];
        }         

        private function mouseOver(event:MouseEvent):void{
            var obj:Object = _dict[event.target];
            var seconds:Number = obj.seconds;
            var tick:Sprite = obj.tick;
        	var xPos:Number = Math.ceil((seconds/_duration) * _scrubberWidth);
        	var spritePos:Number = Math.floor((seconds/_duration) * 50);
			if (_timer.running) _timer.stop();
			redraw(tick, event.type);
            _slider.triggerTooltip(xPos, spritePos);
            event.target.filters = tick.filters = [glow];
        }

		private function mouseOut(event:MouseEvent):void{
			var obj:Object = _dict[event.target];
			var tick:Sprite = obj.tick;
			redraw(tick, event.type);            
			_slider.hideTooltip();
			event.target.filters = [dsf];
			tick.filters = [];
		}    
		
		private function redraw(tick:Sprite, eventType:String):void {
			if (eventType == "rollOver"){
				tick.graphics.clear();
				tick.graphics.lineStyle(2, _hoverColor, 0, false, 'none', 'none', 'miter');
				with (tick.graphics) {
					beginFill(_hoverColor, 1);
					drawRect(0, 0, 2, 15); 
					endFill();
				}
				tick.y = -4;
			} else {
				tick.graphics.clear();
				tick.graphics.lineStyle(2, _linkColor, 0, false, 'none', 'none', 'miter');
				with (tick.graphics) {
					beginFill(_linkColor, 1);
					drawRect(0, 0, 2, _slider.height/2); 
					endFill();
				}
				tick.y = (_slider.height - tick.height) / 2;
			}
			_slider.addChild(tick);
		}
		
        private function decrypt(cipher:Object):void {
			log.debug('decrypting data', cipher);
			var arr:Array = com.adobe.serialization.json.JSON.decode(String(cipher)) as Array;
            log.debug('got array', arr);
			// get a key
            var kdata:ByteArray;
            kdata = Hex.toArray(KEY);
			log.debug('got kdata', kdata);
            // get an output
            var txt:String = String(arr[1]);
			log.debug('got txt', txt);
            var data:ByteArray = Hex.toArray(txt);
			log.debug('got data', data);
			// get an algorithm..
            var name:String = "aes-cbc";
            
            var pad:IPad = new NullPad();
            var mode:ICipher = Crypto.getCipher(name, kdata, pad);
			//pad.setBlockSize(mode.getBlockSize());
			// set IV
            var ivmode:IVMode = mode as IVMode;
            ivmode.IV = Hex.toArray(String(arr[0]));
			log.debug('got iv', ivmode.IV);
			try{
				mode.decrypt(data);
				_currentInput = data;
				log.debug('decrypted data: ', data);
				displayInput();
			} catch (e:Error){
				log.debug('something fucked up', e);
				trace(e);
			}
            
        }            

         private function displayInput():void {
			log.debug('displaying input', _currentInput);
			if (_currentInput == null) return;
            var txt:String = Hex.toString(Hex.fromArray(_currentInput));
            _deepTags = com.adobe.serialization.json.JSON.decode(txt) as Object;
			makeHashMarks();
         }       
		
		/**
		 * Arranges the child display objects.
		 * Called by superclass when the size of this sprite changes.
		 */
		override protected function onResize():void {
			super.onResize();
			if (!_slider) return;
			_logo.x = width - _logo.width;
			_scrubberWidth = _slider.width;
			for (var obj:Object in _dict){
				var perc:Number = Math.ceil((_dict[obj].seconds / _duration) * _scrubberWidth);
			     if (_dict[obj].hasOwnProperty('txt')){
					 obj.x = perc - obj.width / 2;
					 _slider.addChild(obj as DisplayObject);
			     }
			}		
			
		}
		
		/**
		 * Gets the default configuration for this plugin.
		 */
		public function getDefaultConfig():Object {
			return {
				"bottom": 0,  
				"left": 0, 
				"width": '100pct', 
				"height": 16, 
				"opacity": 1,
				"borderRadius": 0,
				"border": 'none',
				"backgroundGradient": [0.1, 0.125, 0.15],
				"backgroundColor": '#000000',
				"textColor": '#FFFFFF',
				"backgroundImage": 'none',
				"linkColor": '#FF6600',
				"hoverColor": '#FFFFFF',
				"glowColor": '#FF9900',
				"zIndex":3
			};
		}

		public function onConfig(plugin:PluginModel):void {
			log.debug('got config', plugin.config);
			/*
				setting rootStyle causes the superclass to draw our background
				rootStyle properties can be defined in our config object,
				so we'll use that as the rootStyle object
			*/
			// store a reference to the model, it's used below
			_model = plugin;
			if (plugin.config) {
			    _base = plugin.config.urlBase;  
                _duration = plugin.config.duration;
                _videoID = plugin.config.id;
				_textColor = StyleSheetUtil.colorValue(plugin.config.textColor, _textColor);
				_linkColor = StyleSheetUtil.colorValue(plugin.config.linkColor, _linkColor);
				_glowColor = StyleSheetUtil.colorValue(plugin.config.glowColor, _glowColor);
				_hoverColor = StyleSheetUtil.colorValue(plugin.config.hoverColor, _hoverColor);
				_dsfColor = StyleSheetUtil.colorValue(plugin.config.shadowColor, _dsfColor);
				_fontFamily = plugin.config.fontFamily ? plugin.config.fontFamily : _fontFamily;
				rootStyle = plugin.config;
			}
			_style.setStyle('.plain', {color:plugin.config.textColor, fontSize:11, fontFamily: _fontFamily, kerning:true, textAlign: 'center'});
			_style.setStyle('a', {color:plugin.config.linkColor, fontSize:11, fontFamily: _fontFamily, kerning:true});
			_style.setStyle('a:hover', {color:plugin.config.hoverColor});
			glow = new GlowFilter(
				_glowColor,
				_alpha,
				_blurX,
				_blurY,
				_strength,
				_quality,
				_inner,
				_knockout);
			dsf = new DropShadowFilter(
				_distance,
				_angle,
				_dsfColor,
				_alpha,
				_dsfBlurX,
				_dsfBlurY,
				_strength,
				_quality,
				_inner,
				_knockout,
				_hideObject);
		}
		
		private function loadDeepTags():void {
			if (!_videoID || typeof _videoID !== "number") return;
			log.debug('loading tags', typeof _videoID);
			var url:String = _base + "/videos/deep_tag_data/" + _videoID;
			var loader:ResourceLoader = _player.createLoader();

			loader.addTextResourceUrl(url);
            
			//loader.addEventListener(ProgressEvent.PROGRESS, loadProgress);
            loader.load(null, loadHandler);
		}
        
        private function loadHandler(loader:ResourceLoader):void {
			log.debug('data loaded');
			var url:String = _base + "/videos/deep_tag_data/" + _videoID;
			//trace(loader.data);
            decrypt(loader.getContent(url));
        }
        
		public function onLoad(player:Flowplayer):void {
			// onLoad event must be dispatched once our plugin is completely initialized,
			// if initialization fails we need to call _model.dispatchError(PluginError.INIT_FAILED)
			log.debug('dispatching onLoad');
			_player = player;
			_animationEngine = _player.animationEngine;
			var plugin:DisplayPluginModel = _player.pluginRegistry.getPlugin("controls") as DisplayPluginModel;
            _controls = plugin.getDisplayObject() as Controls;
            //_controlProps = _player.pluginRegistry.getPlugin("controls") as DisplayProperties;
			
			var span:TextField = new TextField();
			span.antiAliasType = AntiAliasType.ADVANCED;
			span.autoSize = TextFieldAutoSize.LEFT;
			span.styleSheet = _style;
			span.selectable = false;
			span.border = false;
			span.gridFitType = GridFitType.PIXEL;
			span.sharpness = 400;
			span.htmlText = '<span class="plain">JUMP:</span>';
			span.filters = [dsf];
			span.x = 1;
			span.y = (getDefaultConfig().height - span.textHeight)/2 - 1;
			addChild(span);
			
			//load DeepTags logo
			_player.createLoader().load('http://cache.tgpsitecentral.com/madthumbs/images/deep_tags.png', function(loader:ResourceLoader):void{
				_logo = loader.getContent('http://cache.tgpsitecentral.com/madthumbs/images/deep_tags.png').content as Bitmap;
				_logo.smoothing = true;
				_logo.pixelSnapping = PixelSnapping.AUTO;
				_logo.x = width - _logo.width - 2;
				addChild(_logo);
			});
			
			loadDeepTags();
			_model.dispatchOnLoad();
		}
		
		/**
		 * Sets the video ID and calls deep_tag_data.
		 * @param ID
		 */
		[External]
		public function setID(id:Number):void {
			log.debug('setting new ID:' + id);
			_videoID = id;
			_duration = _player.currentClip.duration;
			destroyTags();
			loadDeepTags();
		}
		
		[Value]
		public function get id():Number {
			return _videoID;
		}
		
		/**
		 * Sets the video ID and calls deep_tag_data.
		 * @param ID
		 */
		[External]
		public function highlight(seconds:int):void {
			var tick:Sprite;
			for(var obj:Object in _dict) {
				if (_dict[obj].hasOwnProperty('tick')) continue;
				//log.debug('dict obj', _dict[obj].seconds);
				if (parseInt(_dict[obj].seconds, 10) == seconds) {
					//log.debug('found tick', obj);
					tick = obj as Sprite;
					break;
				}
			}
			try {
				tick.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER, false));
				_timer.addEventListener("timer", function():void {
					tick.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT, false));
				});
				_timer.start();
			} catch(e:Error) {
				log.debug('error', e)
			}
		}
				
	}
}