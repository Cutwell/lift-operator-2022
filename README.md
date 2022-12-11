# Lift Operator 2022

* Extreme lift-operating action.
* Play as a lift operating software, managing payloads of passengers.

​*​How to play*
1. Passengers congregate on different floors, and start pressing the call button.
2. The player chooses which floor to service using the lift panel.
3. The max. payload (4) of passengers load onto the lift.
4. The requested floors then light up on the panel.
5. When the player moves to a floor, passengers intended for that floor will disembark (and new ones will embark up the the max payload).
6. If a passenger is made to wait more than 30 seconds before embarking, the game ends (this is indicated by the passenger changing from green to red).
7. The player can queue multiple floors to travel to in advance, however these can't be unqueued.

*Controls*
* `left-click` to select a floor from the panel.
* `F1` to toggle fullscreen.
* `F3` toggle debug (FPS), and enable gamestate switching with `1-6` keys.
* `Escape` to quit.
* `m` to mute all in-game sound.
* `r` to reset the game.

*Attribution*
|Asset|Attribution|
|:---:|:---:|
|Passenger delivered sfx|[Inside Sounds](https://www.youtube.com/watch?v=AO7nOa50vOc)|
|Elevator bmg|[jhaeka](https://joshuuu.itch.io/short-loopable-background-music)|
|Powerdown sfx|[HALFTONE SFX](https://void1gaming.itch.io/halftone-sound-effects-pack-lite)|

*Dev*
* Build love.js: `npx love.js.cmd -c .\lift-operator-2022-js.love lift-operator-2022`
* Run love.js build locally (from inside build root): `py -m http.server 8000`
* Delete elements from love.js build (footer, background image, etc.)
* Change canvas HTML to fit 512x512
```html
<center>
    <div>
    <canvas id="loadingCanvas" oncontextmenu="event.preventDefault()" width="512" height="512"></canvas>
    <canvas id="canvas" oncontextmenu="event.preventDefault()"></canvas>
    </div>
</center>
```
* Add dynamic styling to love.css
```css
/* the canvas *must not* have any border or padding, or mouse coords will be wrong */
#canvas {
    height: 512px;
    width: 512px;
    padding-right: 0;
    display: block;
    border: 0px none;
    visibility: hidden;
}

#loadingCanvas {
    height: 512px;
    width: 512px;
}

/* if screen width is less than 512, scale canvas to fit */
@media screen and (max-width: 512px) {
    #canvas {
        width: 100%;
        height: auto;
    }
    #loadingCanvas {
        width: 100%;
        height: auto;
    }
}
```