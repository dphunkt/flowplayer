package org.flowplayer.deeptags {
	import flash.display.*;
	import flash.events.*;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Security;
	import flash.text.*;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
                
	import org.flowplayer.controls.Controlbar;
	import org.flowplayer.controls.Controls;
	import org.flowplayer.controls.scrubber.*;
	import org.flowplayer.layout.Position;
	import org.flowplayer.model.DisplayPluginModel;
	import org.flowplayer.model.DisplayProperties;
	import org.flowplayer.model.Plugin;
	import org.flowplayer.model.PluginModel;
	import org.flowplayer.util.Arrange;
	import org.flowplayer.util.Log;
	import org.flowplayer.view.Flowplayer;
	import org.flowplayer.view.StyleableSprite;
	import org.flowplayer.controls.scrubber.ScrubberController;

	public class DeepTags_admin extends StyleableSprite implements Plugin {

        private var _deepTags:Object;
        private var _duration:Number;
		private var _model:PluginModel;
		private var _text:TextField;
        private var _player:Flowplayer;		
        private var _format:TextFormat;
        private var _style:StyleSheet;
		private var _controls:Controls;
		private var _controlbar:Controlbar;
        private var _scrubberWidth:Number;
        private var _plugin:DisplayPluginModel;
		private var _slider:ScrubberSlider;
        //private var _videoId:Number;
        private var _dict:Dictionary;
        //private var _base:String = 'www.madthumbs.com';
      
        private var _distance:Number = 2;        
        private var _angle:Number = 45;
        private var _color:Number = 0xFF9900;
        private var _dsfColor:Number = 0x000000;
        private var _alpha:Number = 0.40;
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
        private var _spacing:int;
        private var _tickArray:Array = [];
        private var _linkArray:Array = [];
        private var _margin:int = 6;
        
        private var glow:GlowFilter = new GlowFilter(_color,
                                _alpha,
                                _blurX,
                                _blurY,
                                _strength,
                                _quality,
                                _inner,
                                _knockout);
        
        private var dsf:DropShadowFilter = new DropShadowFilter(
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
        
		public function DeepTags_admin():void {
            _dict = new Dictionary();
            _style = new StyleSheet();
            _style.setStyle('.plain', {color:'#cccccc', fontSize:11, fontFamily: 'Tahoma, Helvetica, Verdana, sans-serif', kerning:true, textAlign: 'center'});
            _style.setStyle('a', {color:'#FF6600', fontSize:11, fontFamily: 'Tahoma, Helvetica, Verdana, sans-serif', kerning:true});
            _style.setStyle('a:hover', {color:'#FFFFFF'});
            _timer = new Timer(800, 1);
            _timer.addEventListener("timer", function():void {
                _slider.hideTooltip();
            });
		}
		
		[External]
        public function addHashMark(tag:String, seconds:Number):void{
            var linkText:String = tag.toUpperCase();                               
            var perc:Number = Math.ceil((seconds / _duration) * _scrubberWidth);                
            var _tick:Sprite = new Sprite();
            _tick.buttonMode = true;
            _tick.graphics.lineStyle(2, 0xFF6600, 0, false, 'none', 'none', 'miter');
            with (_tick.graphics) {
    		    beginFill(0xFF6600, 1);
                drawRect(0, 0, 2, 6); 
			    endFill();
            }

            _tick.x = perc - _tick.width / 2;
			_tick.y = (_slider.height - _tick.height) / 2;
            _tick.addEventListener(MouseEvent.ROLL_OVER, tickOver);
            _tick.addEventListener(MouseEvent.ROLL_OUT, tickOut);     
            _tick.addEventListener(MouseEvent.CLICK, tickClick);            
            //_tick.filters = [dsf];
            _slider.addChild(_tick);
            
            _text = new TextField();
            
            //_text.embedFonts = true;
			_text.antiAliasType = AntiAliasType.ADVANCED;
			_text.autoSize = TextFieldAutoSize.LEFT;
			_text.styleSheet = _style;
			_text.selectable = true;
			//_text.multiline = true;
            _text.addEventListener(MouseEvent.ROLL_OVER, mouseOver);
            _text.addEventListener(MouseEvent.ROLL_OUT, mouseOut);
            _text.gridFitType = GridFitType.PIXEL;
            _text.sharpness = 400;

			//_text.background = true;
			_text.htmlText = '<a href="event:' + Number(seconds) + '">' + linkText + '</a>';
			_dict[_text] = {'seconds':seconds, 'tick':_tick};
			_dict[_tick] = {'seconds':seconds, 'txt':_text};
			
			_linkArray.push(_text);
			_tickArray.push(_tick);
			
			_text.x = _spacing;
			_text.y = -2;
			_text.filters = [dsf];
			_spacing += _text.width + _margin;
			_text.addEventListener(TextEvent.LINK, linkEvent);
			addChild(_text);
        }
        
        [External]
        public function removeHashMark(idx:int):void{
            var link:TextField = _linkArray[idx];
            var tick:Sprite = _tickArray[idx];
            try{
                removeChild(link);
                _slider.removeChild(tick);
            } catch(error:*) {
                trace(error);
            }
            _linkArray.splice(idx,1);
            _tickArray.splice(idx,1);
                 
            _spacing = 40;
                        
            for( var i:int = 0; i < _linkArray.length; i++){
                if(i >= idx){ 
                    _linkArray[i].x -= link.width + _margin;
                }
                _spacing += _linkArray[i].width + _margin;
            }
        }        
        
        private function initHashMarks():void{            
            if (_deepTags == null) return;
            var span:TextField = new TextField();
			
			if (_controls) {
				_controlbar = _controls.controlbar;
				_slider = _controlbar.widgetControllers['scrubber'].widget as ScrubberSlider;
				_scrubberWidth = _slider.width;
			}			
			
			span.antiAliasType = AntiAliasType.ADVANCED;
			span.autoSize = TextFieldAutoSize.LEFT;
			span.styleSheet = _style;
			span.selectable = false;
            span.gridFitType = GridFitType.PIXEL;
            span.sharpness = 400;
            span.x = 1;
            span.y = -2;
            span.htmlText = '<span class="plain">JUMP:</span>';
            span.filters = [dsf];
            addChild(span);
            _spacing = 40;    
            
			if (_slider){ 
       	        for (var i:int = 0; i < _deepTags.length; i++){ 
        			addHashMark(_deepTags[i].name, _deepTags[i].seconds);
                }
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
			link.textColor = 0xFFFFFF;
			link.filters = event.target.filters = [glow];
		}
		
		private function tickOut(event:MouseEvent):void{
			var link:TextField = _dict[event.target].txt;
			//link.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
			redraw(Sprite(event.target), event.type);
			link.textColor = 0xFF6600;
			link.filters = [dsf];
			event.target.filters = [];
		}          

		private function mouseOver(event:MouseEvent):void{
			var obj:Object = _dict[event.target];
			var seconds:Number = obj.seconds;
			var tick:Sprite = obj.tick;
			var xPos:Number = Math.ceil((seconds/_duration) * _scrubberWidth);
			var spritePos:Number = Math.ceil((seconds/_duration) * 50);
			if (_timer.running) _timer.stop();
			redraw(tick, event.type);
			_slider.triggerTooltip(xPos, spritePos);
			event.target.filters = tick.filters = [glow];
		}
        
		private function redraw(tick:Sprite, eventType:String):void {
			if (eventType == "rollOver"){
				tick.graphics.clear();
				tick.graphics.lineStyle(2, 0xFFFFFF, 0, false, 'none', 'none', 'miter');
				with (tick.graphics) {
					beginFill(0xFFFFFF, 1);
					drawRect(0, 0, 2, 15); 
					endFill();
				}
				tick.y = -4;
			} else {
				tick.graphics.clear();
				tick.graphics.lineStyle(2, 0xFF6600, 0, false, 'none', 'none', 'miter');
				with (tick.graphics) {
					beginFill(0xFF6600, 1);
					drawRect(0, 0, 2, _slider.height/2); 
					endFill();
				}
				tick.y = (_slider.height - tick.height) / 2;
			}
			_slider.addChild(tick);
		}
		
		private function mouseOut(event:MouseEvent):void{
			var obj:Object = _dict[event.target];
			var tick:Sprite = obj.tick;
			redraw(tick, event.type);            
			_slider.hideTooltip();
			event.target.filters = [dsf];
			tick.filters = [];
		}                
		
		/**
		 * Arranges the child display objects.
		 * Called by superclass when the size of this sprite changes.
		 */
		override protected function onResize():void {
			super.onResize();
			if (!_slider) return;
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
				"backgroundGradient": [0.1,0.125,0.15],
				"background": '#000000',
				"zIndex":3
			};
		}

		public function onConfig(plugin:PluginModel):void {
			/*
				setting rootStyle causes the superclass to draw our background
				rootStyle properties can be defined in our config object,
				so we'll use that as the rootStyle object
			*/
			rootStyle = plugin.config;
			// store a reference to the model, it's used below
			_model = plugin;
			if (plugin.config) {
			    //_base = plugin.config.urlBase;  
                _duration = plugin.config.duration;
                //_videoId = plugin.config.id;
                _deepTags = plugin.config.deeptags;
            }
		}
        
		public function onLoad(player:Flowplayer):void {
			// onLoad event must be dispatched once our plugin is completely initialized,
			// if initialization fails we need to call _model.dispatchError(PluginError.INIT_FAILED)
			_player = player;
			var plugin:DisplayPluginModel = _player.pluginRegistry.getPlugin("controls") as DisplayPluginModel;
            _controls = plugin.getDisplayObject() as Controls;
            //_controlProps = _player.pluginRegistry.getPlugin("controls") as DisplayProperties;
            initHashMarks();
			_model.dispatchOnLoad();
		}
	}
}