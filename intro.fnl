(local title-font (love.graphics.newFont "assets/november.ttf" 36))
(local font (love.graphics.newFont "assets/november.ttf" 18))


(local messages (lume.split (love.filesystem.read "assets/text/splash.txt") "\n"))

(var counter 0)

{:draw (fn draw []
           (love.graphics.setFont title-font)
           (love.graphics.print "Backpackless" 32 16)
           (love.graphics.setFont font)
           (for [i 1 (# messages)]
                (when (> counter (* i 2))
                  (love.graphics.print (. messages i) 8 (+ (* 18 i) 110))))
           (when (> counter 4)
             (love.graphics.print "PRESS SPACE TO CONTINUE" 32 500)))
 :update (fn update [dt set-mode]
             (set counter (+ counter dt)))
 :keypressed (fn keypressed [key set-mode]
                 (when (= key "space")
                   (set counter (if (> counter (* 2 (# messages)))
                                    (set-mode :play)
                                    (* 2 (math.ceil (/ counter 2)))))))}
