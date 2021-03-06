/*
  Copyright Facebook Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
 */
// Gives you tips about tools
package fbair.gui {
  import fb.util.FlexUtil;
  import fb.util.MathUtil;

  import flash.display.DisplayObject;
  import flash.display.GraphicsPathCommand;
  import flash.events.TimerEvent;
  import flash.geom.Point;
  import flash.utils.Timer;

  import mx.controls.Text;
  import mx.core.Application;
  import mx.managers.PopUpManager;

  public class FBTooltip extends Text {
    private static const ArrowSize:Number = 4;
    private static const FlashTime:int = 500;

    private static var instance:FBTooltip = new FBTooltip();
    private var arrowOffset:Number = 0;
    private var flashTimer:Timer = new Timer(FlashTime);

    public function FBTooltip() {
      if (instance) throw new Error("FBTooltip is a Singleton");
      flashTimer.addEventListener(TimerEvent.TIMER, _hide)
    }

    public static function hide():void {
      instance._hide();
    }
    private function _hide(event:TimerEvent = null):void {
      flashTimer.stop();
      visible = false;
      text = "";
    }

    // shows the tooltip for a brief period before hiding it
    public static function flash(txt:String, at:*, below:Boolean = true):void {
      instance._flash(txt, at, below);
    }
    private function _flash(txt:String, at:*, below:Boolean = true):void {
      _show(txt, at, below);
      flashTimer.start();
    }

    // shows a tooltip at a point or under a display object
    public static function show(txt:String, at:*, below:Boolean = true):void {
      instance._show(txt, at, below);
    }
    private function _show(txt:String, at:*, below:Boolean):void {
      if (text == txt) return;
      flashTimer.stop();
      
      // add to display tree
      if (!stage) {
        PopUpManager.addPopUp(this, Application.application as Application);
        maxWidth = stage.stageWidth * 0.75;
      } else {
        PopUpManager.bringToFront(this);
      }
      visible = true;

      // set text
      text = txt;
      validateNow();

      // determine point of interest
      var pt:Point;
      if (at is Point) {
        pt = at as Point;
      } else if (at is DisplayObject) {
        var dObj:DisplayObject = at as DisplayObject;
        pt = dObj.localToGlobal(new Point(dObj.width * 0.5, 0));
        if (below)
          pt.y += dObj.height;
      }

      // determine position of tip
      var targetX:Number = Math.round(pt.x - width * 0.5);
      y = Math.round(pt.y + (below ? ArrowSize : (-height - ArrowSize)));
      x = MathUtil.clamp(targetX, 1, stage.stageWidth - width - 1);
      arrowOffset = x - targetX;
      invalidateDisplayList();
    }

    override protected function updateDisplayList(unscaledWidth:Number,
                                                  unscaledHeight:Number):void {
      super.updateDisplayList(unscaledWidth, unscaledHeight);

      // use this opportunity to draw in the background
      var points:Vector.<Number> = new Vector.<Number>(18, true);
      var commands:Vector.<int> = new Vector.<int>(9, true);

      // draw rect
      commands[0] = GraphicsPathCommand.MOVE_TO;
        points[0] = 0; points[1] = 0;
      commands[1] = GraphicsPathCommand.LINE_TO;
        points[2] = unscaledWidth; points[3] = 0;
      commands[2] = GraphicsPathCommand.LINE_TO;
        points[4] = unscaledWidth; points[5] = unscaledHeight;
      commands[3] = GraphicsPathCommand.LINE_TO;
        points[6] = 0; points[7] = unscaledHeight;
      commands[4] = GraphicsPathCommand.LINE_TO;
        points[8] = 0; points[9] = 0;

      // draw arrow
      var midPoint:Number = Math.round(unscaledWidth * 0.5) - 0.5 - arrowOffset;
      commands[5] = GraphicsPathCommand.MOVE_TO;
        points[10] = midPoint; points[11] = -ArrowSize;
      commands[6] = GraphicsPathCommand.LINE_TO;
        points[12] = midPoint + ArrowSize; points[13] = 0;
      commands[7] = GraphicsPathCommand.LINE_TO;
        points[14] = midPoint - ArrowSize; points[15] = 0;
      commands[8] = GraphicsPathCommand.LINE_TO;
        points[16] = midPoint; points[17] = -ArrowSize;

      graphics.clear();
      graphics.beginFill(FlexUtil.getStyle(this, "backgroundColor", 0x111111));
      graphics.drawPath(commands, points);
      graphics.endFill();
    }
  }
}
