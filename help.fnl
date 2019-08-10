(local lume (require "lib.lume"))
(local globals (require "globals"))


(local help (lume.split (love.filesystem.read "assets/text/help.txt") "\n"))

(fn draw []
    (love.graphics.setFont globals.font)
    (for [i 1 (# help)]
         (love.graphics.print (. help i) 185 (+ (* 18 i) 80))))

(fn keypressed [key set-mode]
    (set-mode :play))

{:draw draw
 :update (fn [])
 :keypressed keypressed}
