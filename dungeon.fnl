(local utils (require "utils"))

(local tile-size 16)
(local message-area-height 36)

(fn generate-dungeon []
    (let [astray (require "lib.astray.astray")
          generator (: astray :new
                       (math.floor (/ (love.graphics.getWidth) tile-size 2))
                       (math.floor (/
                                    (- (love.graphics.getHeight) message-area-height)
                                    tile-size 2))
                       10  ;; changeDirectionModifier
                       30  ;; sparsenessModifier
                       )
          dungeon (: generator :Generate)
          width (* 2 (: dungeon :getWidth))
          height (* 2 (: dungeon :getHeight))
          tile-set (love.graphics.newImage "assets/images/dungeon-tiles.png")
          tile-set-width (: tile-set :getWidth)
          tile-set-height (: tile-set :getHeight)
          sprite-batch (love.graphics.newSpriteBatch tile-set)
          wall-quad (love.graphics.newQuad
                      0 0 tile-size tile-size tile-set-width tile-set-height)
          empty-quad (love.graphics.newQuad
                       tile-size 0 tile-size tile-size tile-set-width tile-set-height)
          closed-door-quad (love.graphics.newQuad
                             (* 2 tile-size) 0 tile-size tile-size tile-set-width tile-set-height)
          open-door-quad (love.graphics.newQuad
                           (* 3 tile-size) 0 tile-size tile-size tile-set-width tile-set-height)
          tiles (: generator :CellToTiles dungeon
                   {:Wall wall-quad :Empty empty-quad
                    :DoorN closed-door-quad :DoorS closed-door-quad
                    :DoorE closed-door-quad :DoorW closed-door-quad})
          ;; false means door's closed
          doors-state []]
      (fn build-sprite-batch []
          (: sprite-batch :clear)
          (for [x 0 (# tiles)]
               (let [col-pos (* x tile-size)
                     col (. tiles x)]
                 (for [y 0 (# col)]
                      (let [row-pos (* y tile-size)]
                        (var cell (. col y))
                        (when (= cell closed-door-quad)
                          (when (. (. doors-state x) y)
                            (set cell open-door-quad)
                            (: sprite-batch :add empty-quad col-pos row-pos)))
                        (: sprite-batch :add cell col-pos row-pos))))))
      (for [x 0 (# tiles)]
           (let [col (. tiles x)]
             (for [y 0 (# col)]
                  (let [cell (. col y)]
                    (when (and (not (= cell wall-quad)) (not (= cell empty-quad)))
                      (when (not (. doors-state x))
                        (table.insert doors-state x []))
                      (table.insert (. doors-state x) y false))))))
      (build-sprite-batch)
      (fn door? [x y]
          (let [cell (. (. tiles x) y)]
            (and (not (= cell wall-quad)) (not (= cell empty-quad)))))
      (fn toggle-door [x y open]
          (let [col (. doors-state x)
                current-state (. col y)
                new-state
                (if (= open nil)
                    (not current-state)
                    (= open true)
                    true
                    false)]
            (tset col y new-state)
            (build-sprite-batch)
            new-state))
      (fn traversable? [x y]
          (if (or (< x 0) (< y 0))
              false
              (> x width)
              false
              (> y height)
              false
              (= (. (. tiles x) y) wall-quad)
              false
              (door? x y)
              (. (. doors-state x) y)
              true))
      (fn describe [x y]
          (var result "")
          (for [dir 1 4]
               (let [[cell-x cell-y] (utils.advance x y dir)]
                 (when (door? cell-x cell-y)
                   (set result
                        (..
                         result
                         (if (= result "") "" " ")
                         "There is "
                         (if (. (. doors-state cell-x) cell-y) "an open" "a closed")
                         " door to the "
                         (utils.direction-description dir)
                         ".")))))
          result)
      {:draw (fn draw [] (love.graphics.draw sprite-batch))
       :door? door?
       :toggle-door toggle-door
       :traversable? traversable?
       :initial-pos (fn initial-pos []
                        (let [pos-x (math.random width)
                              pos-y (math.random height)]
                          (if (traversable? pos-x pos-y)
                              [pos-x pos-y]
                              (initial-pos))))
       :describe describe
             }))
