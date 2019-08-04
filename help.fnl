(local font (love.graphics.newFont "assets/november.ttf" 18))

(local help (lume.split (love.filesystem.read "assets/text/help.txt") "\n"))

{:draw (fn draw []
           (love.graphics.setFont font)
           (for [i 1 (# help)]
                (love.graphics.print (. help i) 185 (+ (* 18 i) 110))))
 :update (fn [])
 :keypressed (fn keypressed [key set-mode]
                 (set-mode :play))}
