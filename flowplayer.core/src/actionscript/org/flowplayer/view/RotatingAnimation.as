/*
 *    Copyright (c) 2008-2011 Flowplayer Oy *
 *    This file is part of Flowplayer.
 *
 *    Flowplayer is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    Flowplayer is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with Flowplayer.  If not, see <http://www.gnu.org/licenses/>.
 */
package org.flowplayer.view {
    import flash.display.Sprite;
    import flash.events.TimerEvent;
	import flash.utils.Timer;
	import org.flowplayer.model.Rotator;
	
    public class RotatingAnimation extends AbstractSprite {
        private var _rotator:Rotator;
        //private var _rotation:Sprite;
        //private var _rotationTimer:Timer;

        public function RotatingAnimation() {
            createRotation();
            //_rotationTimer = new Timer(50);
            //_rotationTimer.addEventListener(TimerEvent.TIMER, rotate);
            //_rotationTimer.start();
        }

        public function start():void {
            _rotator.start();
        }

        public function stop():void {
            _rotator.stop();
        }

        protected override function onResize():void {
            arrangeRotation(width, height);
        }

        //private function rotate(event:TimerEvent):void {
        //    _rotation.rotation += 10;
        //}

        private function createRotation():void {
            //_rotationImage = new BufferAnimation();
			_rotator = new Rotator(0xffffff, 0);
            //_rotation = new Sprite();
            //_rotation.addChild(_rotationImage);
            addChild(_rotator);
        }

        private function arrangeRotation(width:Number, height:Number):void {
            if (_rotator) {
                _rotator.height = height;
                _rotator.scaleX = _rotator.scaleY = 0.6;

                _rotator.x =  width/2;
                _rotator.y = height/2;
                //_rotation.x = _rotator.width / 2 + (width - _rotationImage.width)/2;
                //_rotation.y = _rotationImage.height / 2 + (height - _rotationImage.height)/2;
            }
        }
    }
}