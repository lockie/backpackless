(local shadows (require "shadows"))
(local light-world (require "shadows.LightWorld"))
(local current-light-world (: light-world :new))

(var dungeon nil)
(var player nil)
(var messaging nil)
(var items nil)
(var inventory nil)
(var mobs nil)

(fn update-world []
    (mobs.update-world)
    (messaging.init-status-message))

{:update (fn update [dt set-mode]
             (when (not dungeon)
               (let [generate-dungeon (require "dungeon")]
                 (set dungeon (generate-dungeon))))
             (when (not items)
               (let [setup-items (require "items")]
                 (set items (setup-items dungeon))))
             (when (not inventory)
               (let [setup-inventory (require "inventory")]
                 (set inventory (setup-inventory dungeon items))))
             (when (not player)
               (let [create-player (require "player")]
                 (set player
                      (create-player
                       current-light-world
                       dungeon
                       items
                       inventory
                       (fn [] mobs)
                       (fn [] messaging)
                       update-world))))
             (when (not mobs)
               (let [setup-mobs (require "mobs")]
                 (set mobs (setup-mobs dungeon (fn [] (player.pos))))))
             (when (not messaging)
               (let [setup-messages (require "messages")]
                 (set messaging (setup-messages dungeon player items mobs))
                 (messaging.update-status-message "You enter the dungeon. Press ? for help.")))
             (player.update dt)
             (mobs.update dt)
             (: current-light-world :Update))
 :draw (fn draw []
           (dungeon.draw)
           (items.draw)
           (mobs.draw)
           (player.draw)
           (: current-light-world :Draw)
           (messaging.draw))
 :keypressed (fn keypressed [key set-mode]
                 (if (or (= key "/") (= key "?"))
                     (set-mode :help)
                     (player.keypressed key)))}
