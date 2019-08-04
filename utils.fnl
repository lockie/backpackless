
(local direction-descriptions ["north" "east" "south" "west"])

{:describe-hp (fn [hp max-hp]
                  (if (> hp (* 0.80 max-hp))
                      ""
                      (> hp (* 0.60 max-hp))
                      "lightly wounded"
                      (> hp (* 0.40 max-hp))
                      "wounded"
                      (> hp (* 0.20 max-hp))
                      "gravely wounded"))
 :string-pad (fn [str num char]
                 (let [c (if char char " ")]
                   (.. str (string.rep c (- num (# str))))))
 :advance
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
