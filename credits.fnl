(local lume (require "lib.lume"))

(local font (love.graphics.newFont "assets/november.ttf" 18))

(local help (lume.split (love.filesystem.read "assets/text/credits.txt") "\n"))

{:draw (fn draw []
           (love.graphics.setFont font)
           (for [i 1 (# help)]
                (love.graphics.print (. help i) 0 (* 18 (- i 1)))))
 :update (fn [])
 :keypressed (fn keypressed [key set-mode]
                 (when (= key "escape")
                   (love.event.quit)))}
