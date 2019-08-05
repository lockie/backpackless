(local shadows (require "shadows"))
(local light-world (require "shadows.LightWorld"))
(local current-light-world (: light-world :new))

(var dungeon nil)
(var player nil)
(var messaging nil)
(var items nil)
(var inventory nil)
(var mobs nil)
(var combat nil)

(fn update-status-message [...]
    (messaging.update-status-message ...))

{:update (fn update [dt set-mode]
             (fn update-world [keep-messages]
                 (when (not keep-messages)
                   (messaging.init-status-message))
                 (mobs.update-world set-mode))
             (when (not dungeon)
               (let [generate-dungeon (require "dungeon")]
                 (set dungeon (generate-dungeon))))
             (when (not items)
               (let [setup-items (require "items")]
                 (set items (setup-items dungeon))))
             (when (not inventory)
               (let [setup-inventory (require "inventory")]
                 (set inventory (setup-inventory dungeon items (fn [] combat) update-status-message))))
             (when (not player)
               (let [create-player (require "player")]
                 (set player
                      (create-player
                       current-light-world
                       dungeon
                       items
                       inventory
                       (fn [] mobs)
                       (fn [] combat)
                       update-status-message
                       update-world))))
             (when (not mobs)
               (let [setup-mobs (require "mobs")]
                 (set mobs (setup-mobs dungeon (fn [] (player.pos)) (fn [] combat) items update-status-message))))
             (when (not combat)
               (let [setup-combat (require "combat")]
                 (set combat (setup-combat inventory player mobs update-status-message))))
             (when (not messaging)
               (let [setup-messages (require "messages")]
                 (set messaging (setup-messages dungeon player items mobs))
                 (update-status-message "You enter the dungeon. Press ? for help.")))
             (player.update dt)
             (mobs.update dt)
             (combat.update dt set-mode)
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
