(var dungeon nil)

{:update (fn update [dt set-mode]
             (when (not dungeon)
               (let [generate-dungeon (require "dungeon")]
                 (set dungeon (generate-dungeon)))))
 :draw (fn draw []
           (dungeon.draw))
 :keypressed (fn keypressed [key set-mode])}
