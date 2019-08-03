
(local tile-size 16)

(fn generate-dungeon []
    (let [astray (require "lib.astray.astray")
          generator (: astray :new
                       (math.floor (/ (love.graphics.getWidth) tile-size 2))
                       (math.floor (/ (love.graphics.getHeight) tile-size 2))
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
                      (: sprite-batch :add
                         (. col y) col-pos (* y tile-size))))))
      (build-sprite-batch)
      (for [x 0 (# tiles)]
           (let [col (. tiles x)]
             (for [y 0 (# col)]
                  (let [cell (. col y)]
                    (when (and (not (= cell wall-quad)) (not (= cell empty-quad)))
                      (when (not (. doors-state x))
                        (table.insert doors-state x []))
                      (table.insert (. doors-state x) y false))))))
      (fn traversable? [x y]
          (if (or (< x 0) (< y 0))
              false
              (> x width)
              false
              (> y height)
              false
              (= (. (. tiles x) y) wall-quad)
              false
              (not (= (. (. tiles x) y) empty-quad))
              (. (. doors-state x) y)
              true))
      {:draw (fn draw [] (love.graphics.draw sprite-batch))
       :traversable? traversable?
       :initial-pos (fn initial-pos []
                        (let [pos-x (math.random width)
                              pos-y (math.random height)]
                          (if (traversable? pos-x pos-y)
                              [pos-x pos-y]
                              (initial-pos))))
             }))
