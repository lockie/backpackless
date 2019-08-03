
(local direction-descriptions ["north" "east" "south" "west"])

{:advance
 (fn [pos-x pos-y direction]
     (var new-pos-x pos-x)
     (var new-pos-y pos-y)
     (if (= direction 1)
         (set new-pos-y (- new-pos-y 1))
         (= direction 2)
         (set new-pos-x (+ new-pos-x 1))
         (= direction 3)
         (set new-pos-y (+ new-pos-y 1))
         (= direction 4)
         (set new-pos-x (- new-pos-x 1)))
     [new-pos-x new-pos-y])
 :direction-description
 (fn [direction]
     (. direction-descriptions direction))}
