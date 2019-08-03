(var dungeon nil)
(var player nil)
(var messaging nil)

(fn update-world []
    (messaging.init-status-message))

{:update (fn update [dt set-mode]
             (when (not dungeon)
               (let [generate-dungeon (require "dungeon")]
                 (set dungeon (generate-dungeon))))
             (when (not player)
               (let [create-player (require "player")]
                 (set player (create-player dungeon (fn [] messaging) update-world))))
             (when (not messaging)
               (let [setup-messages (require "messages")]
                 (set messaging (setup-messages dungeon player))))
             (player.update dt))
 :draw (fn draw []
           (dungeon.draw)
           (player.draw)
           (messaging.draw))
 :keypressed (fn keypressed [key set-mode]
                 (player.keypressed key))}
