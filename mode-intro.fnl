
(var counter 0)
(var time 0)

{:draw (fn draw [message]
           (love.graphics.print (: "This window should close in %0.2f seconds"
                                 :format (- 3 time)) 32 16))
 :update (fn update [dt set-mode]
             (if (< counter 65535)
                 (set counter (+ counter 1))
                 (set counter 0))
             (set time (+ time dt))
             (when (> time 3)
               (love.event.quit)))
 :keypressed (fn keypressed [key set-mode]
                 (love.event.quit))}
