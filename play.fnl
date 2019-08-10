(local shadows (require "shadows"))
(local utils (require "utils"))
(local light-world (require "shadows.LightWorld"))


(local current-light-world (: light-world :new))

(var dungeon {})
(var player {})
(var messaging {})
(var items {})
(var inventory {})
(var mobs {})
(var combat {})

(fn update-status-message [...]
    (messaging.update-status-message ...))

(fn update [dt set-mode]
             (fn update-world [keep-messages]
                 (when (not keep-messages)
                   (messaging.init-status-message))
                 (mobs.update-world set-mode))
             (when (utils.empty? dungeon)
               (let [generate-dungeon (require "dungeon")]
                 (utils.set-table
                  dungeon
                  (generate-dungeon))))
             (when (utils.empty? items)
               (let [setup-items (require "items")]
                 (utils.set-table
                  items
                  (setup-items dungeon))))
             (when (utils.empty? inventory)
               (let [setup-inventory (require "inventory")]
                 (utils.set-table
                  inventory
                  (setup-inventory dungeon items combat update-status-message))))
             (when (utils.empty? player)
               (let [create-player (require "player")]
                 (utils.set-table
                  player
                  (create-player
                   current-light-world
                   dungeon
                   items
                   inventory
                   mobs
                   combat
                   update-status-message
                   update-world))))
             (when (utils.empty? mobs)
               (let [setup-mobs (require "mobs")]
                 (utils.set-table
                  mobs
                  (setup-mobs dungeon player.pos combat items update-status-message))))
             (when (utils.empty? combat)
               (let [setup-combat (require "combat")]
                 (utils.set-table
                  combat
                  (setup-combat inventory player mobs update-status-message))))
             (when (utils.empty? messaging)
               (let [setup-messages (require "messages")]
                 (utils.set-table
                  messaging
                  (setup-messages dungeon player items mobs))
                 (update-status-message "You enter the dungeon. Press ? for help.")))
             (player.update dt)
             (mobs.update dt)
             (combat.update dt set-mode)
    (: current-light-world :Update))

(fn draw []
           (dungeon.draw)
           (items.draw)
           (mobs.draw)
           (player.draw)
           (: current-light-world :Draw)
    (messaging.draw))

(fn keypressed [key set-mode]
                 (if (or (= key "/") (= key "?"))
                     (set-mode :help)
                     (player.keypressed key)))

{:update update
 :draw draw
 :keypressed keypressed}
