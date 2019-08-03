
(local utils (require "utils"))

(local tile-size 16)
(local animation-duration 1)

(fn create-player [dungeon messaging update-world]
    (fn load-sprites [image y-offset]
        (let [image-width (: image :getWidth)
              image-height (: image :getHeight)
              result []]
          (for [x 0 (- image-width tile-size) tile-size]
               (table.insert result
                             (love.graphics.newQuad
                              x y-offset tile-size tile-size image-width image-height)))
          result))
    (let [sprite-sheet (love.graphics.newImage "assets/images/warrior.png")
          south-dir (load-sprites sprite-sheet 0)
          west-dir (load-sprites sprite-sheet tile-size)
          east-dir (load-sprites sprite-sheet (* tile-size 2))
          north-dir (load-sprites sprite-sheet (* tile-size 3))
          directions [north-dir east-dir south-dir west-dir]
          [intial-pos-x initial-pos-y] (dungeon.initial-pos)]
      (var current-pos-x intial-pos-x)
      (var current-pos-y initial-pos-y)
      (var current-time 0)
      (var current-direction 3)
      (fn update-status-message [message prepend]
          ((. (messaging) :update-status-message) message prepend))
      (fn move [direction]
          (set current-direction direction)
          (let [[new-pos-x new-pos-y]
                (utils.advance current-pos-x current-pos-y direction)]
            (if (dungeon.traversable? new-pos-x new-pos-y)
                (do
                 (set current-pos-x new-pos-x)
                 (set current-pos-y new-pos-y)
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
      {:update (fn update [dt]
                   (set current-time (+ current-time dt))
                   (when (>= current-time animation-duration)
                     (set current-time (- current-time animation-duration))))
       :draw (fn draw []
                 (let [dir (. directions current-direction)
                       sprite-num 1]
                       ;; (+ 1
                       ;;    (math.floor
                       ;;     (/ (* (# dir) current-time) animation-duration)))]
                   (love.graphics.draw sprite-sheet (. dir sprite-num)
                                       (* current-pos-x tile-size)
                                       (* current-pos-y tile-size))))
       :keypressed (fn keypressed [key]
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
                           (toggle-door false)))
       :pos (fn pos [] [current-pos-x current-pos-y])
       :describe (fn describe [key]
                     [[0.26 0.16 0.18 1]
                      (.. "facing " (utils.direction-description current-direction))])
       }))

