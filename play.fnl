(var dungeon nil)
(var player nil)

{:update (fn update [dt set-mode]
             (when (not dungeon)
               (let [generate-dungeon (require "dungeon")]
                 (set dungeon (generate-dungeon))))
             (when (not player)
               (let [create-player (require "player")]
                 (set player (create-player dungeon))))
             (player.update dt))
 :draw (fn draw []
           (dungeon.draw)
           (player.draw))
 :keypressed (fn keypressed [key set-mode]
                 (player.keypressed key))}
