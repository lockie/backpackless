(local shadows (require "shadows"))
(local light-world (require "shadows.LightWorld"))
(local utils (require "utils"))
(local globals (require "globals"))


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
         (generate-dungeon current-light-world player))))
    (when (utils.empty? items)
      (let [setup-items (require "items")]
        (utils.set-table
         items
         (setup-items dungeon player))))
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
         (setup-mobs dungeon player combat items update-status-message))))
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
    (let [[half-x half-y] (utils.half-screen)
          [player-x player-y] (player.pos)
          camera-x (- (* player-x globals.tile-size globals.scale-factor) half-x)
          camera-y (- (* player-y globals.tile-size globals.scale-factor) half-y)]
      (: current-light-world :SetPosition camera-x camera-y 1))
    (: current-light-world :Update))

(fn draw []
    (dungeon.draw)
    (items.draw)
    (mobs.draw)
    (player.draw)
    (: current-light-world :Draw)
    (love.graphics.setColor 0 0 0)
    (let [messages-height (* globals.font-size 2)]
      (love.graphics.rectangle
       "fill"
       0 (- (love.graphics.getHeight) messages-height)
       (love.graphics.getWidth) messages-height))
    (love.graphics.setColor 255 255 255)
    (messaging.draw))

(fn keypressed [key set-mode]
                 (if (or (= key "/") (= key "?"))
                     (set-mode :help)
                     (player.keypressed key)))

{:update update
 :draw draw
 :keypressed keypressed}
