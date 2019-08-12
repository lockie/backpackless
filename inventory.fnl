(local lume (require "lib.lume"))


(local base-defense "1d2")
(local base-attack  "1d2")

(fn setup-inventory [dungeon player items combat update-status-message]
    (fn item-class [item]
        (. item 1))
    (fn item-durability [item]
        (. item 2))
    (fn full-item-description [item]
        (if item
            (let [[item-class durability] item
                  title (. item-class :title)
                  dice (. item-class :dice)
                  max-dur (. item-class :durability)]
              (if (= durability 1)
                  title
                  (lume.format "{title} ({dur}/{max-dur})"
                               {:title title
                                :dur durability
                                :max-dur max-dur})))
            "-"))
    (fn set-item-durability [item durability]
        (tset item 2 durability))
    (fn item-durability-color [item]
        (if item
            (let [[item-class durability] item
                  max-durability (. item-class :durability)
                  ratio (/ durability max-durability)]
              [(lume.lerp 0.26 0.43 ratio)
               (lume.lerp 0.16 0.76 ratio)
               (lume.lerp 0.18 0.80 ratio)
               1])
            [1 1 1 1]))
    (var armor nil)
    (var weapon nil)
    (var item nil)
    (fn dual-wielding? []
        (and weapon (= (. (item-class weapon) :class) :double-handed-weapon)))
    (fn ranged-weapon? []
        (if weapon
            (string.find (. (item-class weapon) :title) "bow") ;; HACK
            false))
    (fn take [x y]
        (let [it (items.item-at x y)]
          (fn do-take []
              (items.remove-item x y)
              (set item it)
              true)
          (if item
              false
              (and (ranged-weapon?) (= (. (item-class it) :class) :arrow))
              (do-take)
              (dual-wielding?)
              false
              (do-take))))
    (fn throw [x y]
        (fn random-point-near []
            (local points
                   (lume.shuffle
                    [[-1 -1]
                     [-1  0]
                     [-1  1]
                     [0  -1]
                     [0   1]
                     [1  -1]
                     [1   0]
                     [1   1]]))
            (var new-item-x nil)
            (var new-item-y nil)
            (each [i point (ipairs points)]
                  (when (not new-item-x)
                    (let [[dx dy] point
                          new-x (+ x dx)
                          new-y (+ y dy)]
                      (when (and (dungeon.traversable? new-x new-y)
                                 (not (items.item-at new-x new-y)))
                        (set new-item-x new-x)
                        (set new-item-y new-y)))))
            [new-item-x new-item-y])
        (if item
            (let [[new-x new-y] (random-point-near)
                  item-instance item]
              (when new-x
                (items.set-item-at new-x new-y item true))
              (set item nil)
              item-instance)
            false))
    (fn equip []
        (if (not item)
            false
            (let [class (. (item-class item) :class)]
              (if (or (= class :single-handed-weapon)
                      (= class :double-handed-weapon))
                  (if weapon
                      false
                      (do
                       (set weapon item)
                       (set item nil)
                       weapon))
                  (= class :arrow)
                  false
                  (= class :armor)
                  (if armor
                      false
                      (do
                       (set armor item)
                       (set item nil)
                       armor))
                  (= class :light-source)
                  false
                  (= class :potion)
                  (let [old-item item]
                    (combat.heal-player
                     ;; HACK
                     (if (= (. (item-class item) :title) "small HP")
                         8
                         (= (. (item-class item) :title) "HP")
                         16
                         32))
                    (set item nil)
                    old-item)
                  (= class :scroll)
                  (let [old-item item]
                    (when armor
                      (let [armor-durability (item-durability armor)
                            max-armor-durability (. (item-class armor) :durability)]
                        (set-item-durability
                         armor
                         (math.floor
                          (math.max
                           (lume.random armor-durability max-armor-durability)
                           (lume.random armor-durability max-armor-durability))))))
                    (when weapon
                      (let [weapon-durability (item-durability weapon)
                            max-weapon-durability (. (item-class weapon) :durability)]
                        (set-item-durability
                         weapon
                         (math.floor
                          (math.max
                           (lume.random weapon-durability max-weapon-durability)
                           (lume.random weapon-durability max-weapon-durability))))))
                    (set item nil)
                    old-item)
                  (= class :shield)
                  false))))
    (fn unequip []
        (if item
            false
            (if weapon
                (do
                 (set item weapon)
                 (set weapon nil)
                 item)
                armor
                (do
                 (set item armor)
                 (set armor nil)
                 item)
                false)))
    (fn wear-armor [points]
        (if (and item (= (item-class item) :shield))
            (do
             (set-item-durability item (- (item-durability item) points))
             (when (<= (item-durability item) 0)
               (update-status-message "Your shield breaks.")
               (set item nil)))
            armor
            (do
             (set-item-durability armor (- (item-durability armor) points))
             (when (<= (item-durability armor) 0)
               (update-status-message "Your armor breaks.")
               (set armor nil)))))
    (fn wear-weapon [points]
        (when weapon
          (if (ranged-weapon?)
              (do
               (set-item-durability item (- (item-durability item) 1))
               (when (<= (item-durability item) 0)
                 (update-status-message "You are out of arrows.")
                 (set item nil)))
              (do
               (set-item-durability weapon (- (item-durability weapon) points))
               (when (<= (item-durability weapon) 0)
                 (update-status-message "Your weapon breaks.")
                 (set weapon nil))))))
    (fn describe []
        (let [it
              (if (dual-wielding?)
                  (if (and item (= (. (item-class item) :class) :arrow))
                      item
                      weapon)
                  item)]
          [[1 1 1 1]
           "BODY "
           (item-durability-color armor)
           (.. (full-item-description armor) " ")
           [1 1 1 1]
           "WEAP "
           (item-durability-color weapon)
           (..  (full-item-description weapon) " ")
           [1 1 1 1]
           "ITEM "
           (item-durability-color it)
           (..  (full-item-description it) " ")]))
    (fn defense []
        (if (and item (= (item-class item) :shield))
            (. (item-class item) :dice)
            armor
            (. (item-class armor) :dice)
            base-defense))
    (fn attack []
        (if weapon
            (. (item-class weapon) :dice)
            base-attack))
    (fn weapon-usable? []
        (if (ranged-weapon?)
            (and item (= (. (item-class item) :class) :arrow))
            true))
    (fn update-world []
        (player.set-extra-light-radius 0)
        (when item
          (let [it (item-class item)]
            (if (= it.class :light-source)
                (do
                 (set-item-durability item (- (item-durability item) 1))
                 (if (= (item-durability item) 0)
                     (set item nil)
                     (player.set-extra-light-radius 3)))))))
    {:describe describe
     :take take
     :throw throw
     :equip equip
     :unequip unequip
     :defense defense
     :attack attack
     :wear-armor wear-armor
     :wear-weapon wear-weapon
     :ranged-weapon? ranged-weapon?
     :weapon-usable? weapon-usable?
     :update-world update-world
     })
