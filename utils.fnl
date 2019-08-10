(local direction-descriptions ["north" "east" "south" "west"])

(fn set-table [dst src]
    (each [k v (pairs src)]
          (tset dst k v)
          (tset src k nil)))

(fn empty? [tbl] (= (next tbl) nil))

(fn describe-hp [hp max-hp]
                  (if (> hp (* 0.80 max-hp))
                      ""
                      (> hp (* 0.60 max-hp))
                      "lightly wounded"
                      (> hp (* 0.40 max-hp))
                      "wounded"
                      "gravely wounded"))

(fn string-pad [str num char]
    (let [c (if char char " ")]
      (.. str (string.rep c (- num (# str))))))

(fn advance [pos-x pos-y direction delta]
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

(fn direction-description [direction]
     (. direction-descriptions direction))

{:set-table set-table
 :empty? empty?
 :describe-hp describe-hp
 :string-pad string-pad
 :advance advance
 :direction-description direction-description
}
