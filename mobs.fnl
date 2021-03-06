(local utils (require "utils"))
(local globals (require "globals"))


(local tile-set (love.graphics.newImage "assets/images/mobs.png"))
(local tile-set-width (: tile-set :getWidth))
(local tile-set-height (: tile-set :getHeight))
(local animations-count 2)

(fn setup-mob [sprite-index title max-hp attack defense]
    {:quads
     [(love.graphics.newQuad
       (* sprite-index globals.tile-size) 0
       globals.tile-size globals.tile-size
       tile-set-width tile-set-height)
      (love.graphics.newQuad
       (* sprite-index globals.tile-size) globals.tile-size
       globals.tile-size globals.tile-size
       tile-set-width tile-set-height)]
     :title title
     :max-hp max-hp
     :attack attack
     :defense defense})

(local demon  (setup-mob 0 "demon"        16 "1d4^+1" "1d4"))
(local spider (setup-mob 1 "giant spider" 8  "2d2^+2" "1d1"))
(local slime  (setup-mob 2 "vile slime"   6  "1d1"    "1d4^+1"))
(local zombie (setup-mob 3 "zombie"       10 "1d2"    "1d2"))

(local mob-classes [demon spider slime zombie])

(fn setup-mobs [dungeon player combat items update-status-message]
    (let [sprite-batch (love.graphics.newSpriteBatch tile-set)
          mobs []  ;; [int][int] -> mob class + HP
          ]
      (var current-time 0)
      (var current-stance 1)
      (var mob-count 0)
      (fn generate-mob [class-choices]
          (local class (lume.weightedchoice class-choices))
          (let [class (lume.weightedchoice class-choices)
                max-hp class.max-hp
                hp
                (math.max
                  (math.random max-hp)
                  (math.random max-hp)
                  (math.random max-hp))]
            [class hp]))
      (fn build-sprite-batch []
          (: sprite-batch :clear)
          (set mob-count 0)
          (for [x 0 (dungeon.width)]
               (let [col-pos (* x globals.tile-size)
                     col (. mobs x)]
                 (when col
                   (for [y 0 (dungeon.height)]
                        (let [mob (. col y)]
                          (when mob
                            (set mob-count (+ mob-count 1))
                            (let [mob-class (. mob 1)]
                              (: sprite-batch :add
                                 (. mob-class.quads current-stance)
                                 col-pos (* y globals.tile-size))))))))))
      (fn mob-at [x y]
          (let [col (. mobs x)]
            (if col (. col y) nil)))
      (fn set-mob-at [x y mob rebuild]
          (when (not (. mobs x))
            (tset mobs x []))
          (tset (. mobs x) y mob)
          (when rebuild
            (build-sprite-batch)))
      (let [[player-x player-y] (player.pos)]
        (lume.each
         (dungeon.dead-ends)
         (fn [dead-end]
             (let [[x y] dead-end]
               (when (and (not (= x player-x)) (not (= y player-y)) (not (mob-at x y)))
                 (set-mob-at
                  x y
                  (generate-mob {spider 0.95 slime 0.05}))))))
        (lume.each
         (dungeon.rooms)
         (fn [room]
             (let [[x y] room]
               (when (and (not (= x player-x)) (not (= y player-y)) (not (mob-at x y)))
                 (set-mob-at
                  x y
                  (generate-mob {demon 0.20 zombie 0.80})))))))
      (build-sprite-batch)
      (fn describe [x y]
          (var result "")
          (for [dir 1 4]
               (let [[cell-x cell-y] (utils.advance x y dir)]
                 (let [mob (mob-at cell-x cell-y)]
                   (when mob
                     (let [[mob-class hp] mob
                           hp-description (utils.describe-hp hp mob-class.max-hp)]
                       (set result
                            (..
                             result
                             (if (= result "") "" " ")
                             "There is "
                             hp-description
                             (if (= hp-description "") "" " ")
                             mob-class.title
                             " to the "
                             (utils.direction-description dir)
                             ".")))))))
          result)
      (fn remove-mob [x y rebuild]
          (tset (. mobs x) y nil)
          (when rebuild
            (build-sprite-batch)))
      (fn simulate []
          (let [[player-x player-y] (player.pos)]
            (fn move-mob [x y new-x new-y]
                (if (and (dungeon.traversable? new-x new-y)
                         (not (mob-at new-x new-y))
                         (not (and (= player-x new-x) (= player-y new-y))))
                    (let [mob (mob-at x y)]
                      (tset (. mobs x) y nil)
                      (set-mob-at new-x new-y mob)
                      true)
                    false))
            (for [x 0 (dungeon.width)]
                 (let [col (. mobs x)]
                   (when col
                     (for [y 0 (dungeon.height)]
                          (let [mob (. col y)]
                            (when mob
                              (if (> (lume.distance x y player-x player-y) 10)
                                  (let [dir (math.random 2)
                                        dx (if (= dir 1) (math.random -1 1) 0)
                                        dy (if (= dir 2) (math.random -1 1) 0)
                                        new-x (+ x dx)
                                        new-y (+ y dy)]
                                    (when (or (not (= dx 0)) (not (= dy 0)))
                                      (move-mob x y new-x new-y)))
                                  (do
                                   (combat.maybe-attack-player x y)
                                   (var moved false)
                                   (if (> player-x x)
                                       (set moved (move-mob x y (+ x 1) y))
                                       (< player-x x)
                                       (set moved (move-mob x y (- x 1) y)))
                                    (if (and (> player-y y)
                                             (not moved))
                                        (move-mob x y x (+ y 1))
                                        (and (< player-y y)
                                             (not moved))
                                        (move-mob x y x (- y 1)))))))))))))
      (fn update-state [set-mode]
          (var mob-count 0)
          (for [x 0 (dungeon.width)]
               (let [col (. mobs x)]
                 (when col
                   (for [y 0 (dungeon.height)]
                        (let [mob (. col y)]
                          (when mob
                            (let [mob-hp (. mob 2)]
                              (if (<= mob-hp 0)
                                  (do
                                   (update-status-message
                                    (.. "The " (. (. mob 1) :title) " dies."))
                                   (items.monster-drop x y)
                                   (remove-mob x y))
                                  (set mob-count (+ mob-count 1)))))))))))
      (fn update [dt]
          (set current-time (+ current-time dt))
          (when (>= current-time globals.animation-duration)
            (set current-time (- current-time globals.animation-duration)))
          (let [new-stance
                (+ 1 (math.floor (* (/ current-time globals.animation-duration)
                                    animations-count)))]
            (when (not (= new-stance current-stance))
              (set current-stance new-stance)
              (build-sprite-batch))))
      (fn update-world [set-mode]
          (update-state set-mode)
          (simulate)
          (build-sprite-batch)
          (when (= 0 mob-count)
            (update-status-message "You beat the dungeon.")
            (let [win-music
                  (love.audio.newSource "assets/sounds/riverside-ride.ogg" "stream")]
              (: globals.ambient-music :stop)
              (: win-music :setLooping true)
              (: win-music :play))
            (set-mode :credits)))
      (fn draw []
          (love.graphics.draw sprite-batch (utils.player-transform player)))
      {:draw draw
       :update update
       :update-world update-world
       :describe describe
       :mob-at mob-at
       :set-mob-at set-mob-at
       :remove-mob remove-mob
       }))
