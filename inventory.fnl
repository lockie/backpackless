(local lume (require "lib.lume"))

(local base-defense "1d2")
(local base-attack  "1d2")

(fn full-item-description [item]
    (if item
        (let [[item-class durability] item
              title (. item-class :title)
              dice (. item-class :dice)
              max-dur (. item-class :durability)]
          (if (= durability 1)
              (lume.format "{title} {dice}" {:title title :dice dice})
              (lume.format "{title} {dice} ({dur}/{max-dur})"
                           {:title title
                            :dice dice
                            :dur durability
                            :max-dur max-dur})))
        "-"))

(fn item-class [item]
    (. item 1))

(fn item-durability [item]
    (. item 2))

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

(fn setup-inventory [dungeon items combat update-status-message]
    (var armor nil)
    (var weapon nil)
    (var item nil)
    (fn dual-wielding? []
        (and weapon (= (. (item-class weapon) :class) :double-handed-weapon)))
    (fn take [x y]
        (if (or item (dual-wielding?))
            false
            (let [it (items.item-at x y)]
              (items.remove-item x y)
              (set item it)
              true)))
    (fn throw [x y]
        (fn random-point-near []
            (let [dx (math.random -1 1)
                  dy (math.random -1 1)
                  new-x (+ x dx)
                  new-y (+ y dy)]
              (if (or (and (= dx 0) (= dy 0))
                      (or (not (dungeon.traversable? new-x new-y)))
                      (items.item-at new-x new-y))
                  (random-point-near)
                  [new-x new-y])))
        (if item
            (let [[new-x new-y] (random-point-near)
                  item-instance item]
              (items.set-item-at new-x new-y item true)
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
                    ((. (combat) :heal-player)
                     ;; HACK
                     (if (= (. (item-class item) :title) "small HP")
                         8
                         (= (. (item-class item) :title) "HP")
                         16
                         32))
                    (set item nil)
                    old-item)
                  (= class :scroll)
                  false  ;; TODO : use scroll
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
    (fn ranged-weapon? []
        (if weapon
            (string.find (. (item-class weapon) :title) "bow") ;; HACK
            false))
    (fn wear-weapon [points]
        (when weapon
          (if (ranged-weapon?)
              (set-item-durability item (- (item-durability item) 1))
              (do
               (set-item-durability weapon (- (item-durability weapon) points))
               (when (<= (item-durability weapon) 0)
                 (update-status-message "Your weapon breaks.")
                 (set weapon nil))))))
    {:describe (fn []
                   [[1 1 1 1]
                    "ARM: "
                    (item-durability-color armor)
                    (.. (full-item-description armor) " ")
                    [1 1 1 1]
                    "WEAP: "
                    (item-durability-color weapon)
                    (..  (full-item-description weapon) " ")
                    [1 1 1 1]
                    "IT: "
                    (item-durability-color item)
                    (..  (full-item-description item) " ")])
     :take take
     :throw throw
     :equip equip
     :unequip unequip
     :defense (fn []
                  (if (and item (= (item-class item) :shield))
                      (. (item-class item) :dice)
                      armor
                      (. (item-class armor) :dice)
                      base-defense))
     :attack (fn [] (if weapon (. (item-class weapon) :dice) base-attack))
     :wear-armor wear-armor
     :wear-weapon wear-weapon
     :ranged-weapon? ranged-weapon?
     :weapon-usable? (fn []
                         (if (ranged-weapon?)
                             (and item (= (. (item-class item) :class) :arrow))
                             true))
     })
