(local lume (require "lib.lume"))
(local light (require "shadows.Light"))
(local star (require "shadows.Star"))
(local utils (require "utils"))
(local globals (require "globals"))


(fn create-player [light-world dungeon items inventory mobs combat update-status-message update-world]
    (local footstep-sounds [])
    (for [i 1 8]
         (tset
          footstep-sounds i
          (love.audio.newSource
           (lume.format "assets/sounds/stepdirt_{i}.ogg" {:i i}) "static")))
    (fn load-sprites [image y-offset]
        (let [image-width (: image :getWidth)
              image-height (: image :getHeight)
              result []]
          (for [x 0 (- image-width globals.tile-size) globals.tile-size]
               (table.insert result
                             (love.graphics.newQuad
                              x y-offset
                              globals.tile-size globals.tile-size
                              image-width image-height)))
          result))
    (let [sprite-sheet (love.graphics.newImage "assets/images/warrior.png")
          south-dir (load-sprites sprite-sheet 0)
          west-dir (load-sprites sprite-sheet globals.tile-size)
          east-dir (load-sprites sprite-sheet (* globals.tile-size 2))
          north-dir (load-sprites sprite-sheet (* globals.tile-size 3))
          directions [north-dir east-dir south-dir west-dir]
          [intial-pos-x initial-pos-y] (dungeon.initial-pos)
          [half-x half-y] (utils.half-screen)
          player-star (: star :new light-world 1)
          player-light (: light :new light-world 1)]
      (var current-pos-x intial-pos-x)
      (var current-pos-y initial-pos-y)
      (fn set-extra-light-radius [r]
          (print
           (* (+ r 4) globals.tile-size globals.scale-factor)
           (* (+ r 5) globals.tile-size globals.scale-factor))
          (: player-light :SetRadius
             (* (+ (/ r 4) 4) globals.tile-size globals.scale-factor))
          (: player-star :SetRadius
             (* (+ r 5) globals.tile-size globals.scale-factor))
          (: light-world :ForceUpdate))
      (set-extra-light-radius 0)
      (fn sync-light []
          (let [pos-x (+ (* current-pos-x globals.tile-size globals.scale-factor)
                         (* 0.5 globals.tile-size globals.scale-factor))
                pos-y (+ (* current-pos-y globals.tile-size globals.scale-factor)
                         (* 0.5 globals.tile-size globals.scale-factor))]
            (: player-light :SetPosition pos-x pos-y)
            (: player-star :SetPosition pos-x pos-y)))
      (sync-light)
      (var current-time 0)
      (var current-direction 3)
      (fn attack [x y]
          (if (not (inventory.weapon-usable?))
              (update-status-message "You cannot attack.")
              (do
               (var mob-x x)
               (var mob-y y)
                (when (not mob-x)
                  (let [range (if (inventory.ranged-weapon?) 10 1)]
                    (for [dir 1 4]
                         (var visible true)
                         (var found false)
                         (for [distance 1 range]
                              (when (and visible (not found))
                                (let [[pos-x pos-y]
                                      (utils.advance current-pos-x current-pos-y dir distance)]
                                  (set visible (dungeon.traversable? pos-x pos-y))
                                  (when (and visible (not found))
                                    (when (mobs.mob-at pos-x pos-y)
                                      (do
                                       (set current-direction dir)
                                       (set mob-x pos-x)
                                       (set mob-y pos-y)
                                       (set found true))))))))))
                (if (not mob-x)
                    (update-status-message "There is nothing to attack.")
                    (do
                     (when (mobs.mob-at mob-x mob-y)
                       (combat.maybe-attack-mob mob-x mob-y))
                     (update-world true))))))
      (fn move [direction]
          (set current-direction direction)
          (let [[new-pos-x new-pos-y]
                (utils.advance current-pos-x current-pos-y direction)]
            (if (mobs.mob-at new-pos-x new-pos-y)
                (attack new-pos-x new-pos-y)
                (dungeon.traversable? new-pos-x new-pos-y)
                (do
                  (: (. footstep-sounds (math.random 1 8)) :play)
                  (set current-pos-x new-pos-x)
                  (set current-pos-y new-pos-y)
                  (sync-light)
                  (update-world))
                (update-status-message "You cannot go there."))))
      (fn toggle-door [open]
          (let [[door-pos-x door-pos-y]
                (utils.advance current-pos-x current-pos-y current-direction)]
            (if (not (dungeon.door? door-pos-x door-pos-y))
                (update-status-message "You are not facing any door.")
                (do
                 (let [new-door-status (dungeon.toggle-door door-pos-x door-pos-y open)]
                   (update-world)
                   (update-status-message
                    (.. "You " (if new-door-status "open" "close") " the door.") true))))))
      (fn item-title [item]
          (. (. item 1) :title))
      (fn item-class [item]
          (. (. item 1) :class))
      (fn take-item []
          (let [item (items.item-at current-pos-x current-pos-y)]
            (if (not item)
                (update-status-message "There is nothing here.")
                (if (not (inventory.take current-pos-x current-pos-y))
                    (update-status-message "You are overburdened.")
                    (do
                     (update-status-message (.. "You take the " (item-title item) "."))
                     (update-world true))))))
      (fn throw-item []
          (let [item (inventory.throw current-pos-x current-pos-y)]
            (if (not item)
                (update-status-message "You got nothing to throw.")
                (do
                 (update-status-message (.. "You throw the " (item-title item) " away."))
                 (update-world true)))))
      (fn equip-item []
          (let [item (inventory.equip)]
            (if (not item)
                (update-status-message "You cannot equip that.")
                (let [verb
                      (if (or (= (item-class item) :potion) (= (item-class item) :scroll))
                          "use" "equip")]
                  (update-status-message (.. "You " verb " the " (item-title item) "."))
                  (update-world true)))))
      (fn unequip-item []
          (let [item (inventory.unequip)]
            (if (not item)
                (update-status-message "You got nothing to unequip.")
                (do
                 (update-status-message (.. "You unequip the " (item-title item) "."))
                 (update-world true)))))
      (fn update [dt]
          (set current-time (+ current-time dt))
          (when (>= current-time globals.animation-duration)
            (set current-time (- current-time globals.animation-duration))))
      (fn draw []
          (let [dir (. directions current-direction)
                sprite-num 1]
            (love.graphics.draw sprite-sheet (. dir sprite-num)
                                half-x half-y 0
                                globals.scale-factor globals.scale-factor)))
      (fn keypressed [key]
          (if (or (= key "up") (= key "w") (= key "k"))
              (move 1)
              (or (= key "right") (= key "d") (= key "l"))
              (move 2)
              (or (= key "down") (= key "s") (= key "j"))
              (move 3)
              (or (= key "left") (= key "a") (= key "h"))
              (move 4)
              (= key "o")
              (toggle-door true)
              (= key "c")
              (toggle-door false)
              (= key "g")
              (take-item)
              (or (= key "backspace") (= key "t"))
              (throw-item)
              (= key "e")
              (equip-item)
              (= key "u")
              (unequip-item)
              (= key ".")
              (update-world)
              (= key "f")
              (attack)
              (update-status-message "Unknown key. Press ? for help.")))
      (fn pos []
          [current-pos-x current-pos-y])
      (fn describe [key]
          (let [hp (combat.player-hp)
                max-hp (combat.player-max-hp)
                hp-ratio (/ hp max-hp)]
            (lume.concat
             [[0.26 0.16 0.18 1]
              (..
               "facing "
               (utils.string-pad (utils.direction-description current-direction) 5)
               " ")]
             [[1 1 1 1]
              "HP "]
             [[(- 1 hp-ratio) hp-ratio 0 1]
              (.. (tostring hp) " ")]
             (inventory.describe))))
      {:update update
       :draw draw
       :keypressed keypressed
       :pos pos
       :describe describe
       :set-extra-light-radius set-extra-light-radius
       }))
