
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
                    :DoorE closed-door-quad :DoorW closed-door-quad})]
      (: dungeon :FlagAllCellsAsUnvisited)
      (tset dungeon :visitedCells {})
      (fn build-sprite-batch []
          (: sprite-batch :clear)
          (for [x 0 (# tiles)]
               (let [col-pos (* x tile-size)
                     col (. tiles x)]
                 (for [y 0 (# col)]
                      (: sprite-batch :add
                         (. col y) col-pos (* y tile-size))))))
      (build-sprite-batch)
      {:draw (fn draw []
                 (love.graphics.draw sprite-batch))
             }))
