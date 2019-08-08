
(local direction-descriptions ["north" "east" "south" "west"])

{:set-table (fn [dst src]
                (each [k v (pairs src)]
                      (tset dst k v)
                      (tset src k nil)))
 :empty? (fn [tbl] (= (next tbl) nil))
 :describe-hp (fn [hp max-hp]
                  (if (> hp (* 0.80 max-hp))
                      ""
                      (> hp (* 0.60 max-hp))
                      "lightly wounded"
                      (> hp (* 0.40 max-hp))
                      "wounded"
                      "gravely wounded"))
 :string-pad (fn [str num char]
                 (let [c (if char char " ")]
                   (.. str (string.rep c (- num (# str))))))
 :advance
 (fn [pos-x pos-y direction delta]
     (var new-pos-x pos-x)
     (var new-pos-y pos-y)
     (local d (if delta delta 1))
     (if (= direction 1)
         (set new-pos-y (- new-pos-y d))
         (= direction 2)
         (set new-pos-x (+ new-pos-x d))
         (= direction 3)
         (set new-pos-y (+ new-pos-y d))
         (= direction 4)
         (set new-pos-x (- new-pos-x d)))
     [new-pos-x new-pos-y])
 :direction-description
 (fn [direction]
     (. direction-descriptions direction))}
