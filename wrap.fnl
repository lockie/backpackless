(local repl (require "lib.stdio"))
(local canvas (let [(w h) (love.window.getMode)]
                (love.graphics.newCanvas w h)))

(var scale 1)

;; set the first mode
(var mode (require "intro"))

(fn set-mode [mode-name ...]
    (set mode (require mode-name))
    (when mode.activate
      (mode.activate ...)))

(fn love.load []
    (love.window.setTitle "Backpackless")
    (: canvas :setFilter "nearest" "nearest")
    (repl.start))

(fn love.draw []
    ;; the canvas allows you to get sharp pixel-art style scaling; if you
    ;; don't want that, just skip that and call mode.draw directly.
    (love.graphics.setCanvas canvas)
    (love.graphics.clear)
    (love.graphics.setColor 1 1 1)
    (mode.draw)
    (love.graphics.setCanvas)
    (love.graphics.setColor 1 1 1)
    (love.graphics.draw canvas 0 0 0 scale scale))

(fn love.update [dt]
    (mode.update dt set-mode))

(fn love.keypressed [key]
    (if
     (and (love.keyboard.isDown "lctrl" "rctrl" "capslock") (= key "q"))
     (love.event.quit)
     ;; add what each keypress should do in each mode
     (mode.keypressed key set-mode)))
