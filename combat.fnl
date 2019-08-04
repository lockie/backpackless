(local dice (require "lib.dice"))

(local starting-player-hp 64)


(fn setup-combat [inventory player mobs update-status-message]
    (var player-hp starting-player-hp)

    (fn do-attack [attack-dice defense-dice]
        (let [attack  (: (: dice :new attack-dice)  :roll)
              defense (: (: dice :new defense-dice) :roll)]
          (if (> attack defense)
              (- attack defense)
              nil)))

    (fn do-attack-player [x y]
        (let [mob (mobs.mob-at x y)
              mob-class (. mob 1)
              damage-dealt (do-attack mob-class.attack (inventory.defense))]
          (if (not damage-dealt)
              (update-status-message
               (.. "The " mob-class.title " attacks but misses you."))
              (do
               (update-status-message
                (.. "The " mob-class.title " attacks dealing "
                    damage-dealt " damage to you."))
               (inventory.wear-armor (math.random damage-dealt))
               (set player-hp (- player-hp damage-dealt))))))

    (fn maybe-attack-player [x y]
        (let [[player-x player-y] (player.pos)
              dx (math.abs (- x player-x))
              dy (math.abs (- y player-y))]
          (when (and (< dx 2) (< dy 2) (< (+ dx dy) 2))
            (do-attack-player x y))))

    (fn do-attack-mob [x y]
        (let [mob (mobs.mob-at x y)
              mob-class (. mob 1)
              damage-dealt (do-attack (inventory.attack) mob-class.defense)
              ranged-attack (inventory.ranged-weapon?)
              attack-text (if ranged-attack "shoot" "hit")]
          (if (not damage-dealt)
              (update-status-message
               (.. "You " attack-text " " mob-class.title " but miss."))
              (do
               (update-status-message
                (.. "You " attack-text " " mob-class.title " dealing "
                    damage-dealt " damage."))
               (inventory.wear-weapon (math.random damage-dealt))
               (tset mob 2 (- (. mob 2) damage-dealt))))))

    (fn maybe-attack-mob [x y]
        (do-attack-mob x y))

    (fn update [dt set-mode]
        (when (<= player-hp 0)
          (update-status-message "You die.")
          (set-mode :credits)))

    {:player-hp (fn [] player-hp)
     :player-max-hp (fn [] starting-player-hp)
     :maybe-attack-player maybe-attack-player
     :maybe-attack-mob maybe-attack-mob
     :update update
     })
