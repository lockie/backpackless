(local lume (require "lib.lume"))

(local tile-size 16)
(local tile-set (love.graphics.newImage "assets/images/items.png"))
(local tile-set-width (: tile-set :getWidth))
(local tile-set-height (: tile-set :getHeight))

(fn setup-item [sprite-index title dice durability class-probability class]
    {:quad (love.graphics.newQuad
            (* sprite-index tile-size) 0
            tile-size tile-size
            tile-set-width tile-set-height)
     :title title
     :dice dice
     :durability durability
     :class-probability class-probability
     :class class})

(local short-bow      (setup-item 0  "short bow"           "1d6"    1  0.20 :single-handed-weapon))
(local long-bow       (setup-item 1  "long bow"            "3d6"    1  0.20 :double-handed-weapon))
(local arrow          (setup-item 2  "arrow pack"          ""       10 0.80 :arrow))
(local enhanced-arrow (setup-item 3  "enhanced arrow pack" ""       10 0.20 :arrow))
(local armor          (setup-item 4  "armor"               "1d4"    30 0.80 :armor))
(local enhanced-armor (setup-item 5  "enhanced armor"      "3d4"    50 0.20 :armor))
(local candle         (setup-item 6  "candle"              ""       20 0.80 :light-source))
(local lamp           (setup-item 7  "lamp"                ""       50 0.20 :light-source))
(local long-sword     (setup-item 8  "long sword"          "3d4^+3" 50 0.40 :double-handed-weapon))
(local halberd        (setup-item 9  "halberd"             "1d8"    50 0.25 :double-handed-weapon))
(local hammer         (setup-item 10 "hammer"              "2d8"    50 0.15 :double-handed-weapon))
(local short-sword    (setup-item 11 "short sword"         "1d4^+3" 30 0.30 :single-handed-weapon))
(local axe            (setup-item 12 "axe"                 "1d4^+1" 30 0.25 :single-handed-weapon))
(local small-potion   (setup-item 13 "small health potion" ""       1  0.50 :potion))
(local potion         (setup-item 14 "health potion"       ""       1  0.30 :potion))
(local large-potion   (setup-item 15 "large health potion" ""       1  0.20 :potion))
(local scroll         (setup-item 16 "repair scroll"       ""       1  1.00 :scroll))
(local small-shield   (setup-item 17 "small shield"        "1d6^+1" 30 0.80 :shield))
(local large-shield   (setup-item 18 "large shield"        "3d6^+3" 50 0.20 :shield))
(local dagger         (setup-item 19 "dagger"              "1d2^+1" 20 0.25 :single-handed-weapon))

(local item-classes
       [short-bow long-bow arrow enhanced-arrow armor enhanced-armor candle lamp
                  long-sword halberd hammer short-sword axe
                  small-potion potion large-potion scroll small-shield large-shield dagger])

(fn setup-items [dungeon]
    (let [sprite-batch (love.graphics.newSpriteBatch tile-set)
          items []  ;; [int][int] -> item instance + durability(count)
          ]
      (fn generate-item [class-choices]
          (let [class (lume.weightedchoice class-choices)
                class-items (lume.filter
                              item-classes
                              (fn [it] (= class (. it :class))))
                item-choices {}]
            (for [i 1 (# class-items)]
                 (let [item (. class-items i)]
                   (tset item-choices item (. item :class-probability))))
            (let [item (lume.weightedchoice item-choices)
                  max-durability (. item :durability)
                  durability
                  (math.max
                    (math.random max-durability)
                    (math.random max-durability))]
              [item durability])))
      (fn build-sprite-batch []
          (: sprite-batch :clear)
          (for [x 0 (dungeon.width)]
               (let [col-pos (* x tile-size)
                     col (. items x)]
                 (when col
                   (for [y 0 (dungeon.height)]
                        (let [item (. col y)]
                          (when item
                            (: sprite-batch :add
                               (. (. item 1) :quad) col-pos (* y tile-size)))))))))
      (fn set-item-at [x y item rebuild]
          (when (not (. items x))
            (table.insert items x []))
          (table.insert (. items x) y item)
          (when rebuild
            (build-sprite-batch)))
      (lume.each
       (dungeon.dead-ends)
       (fn [dead-end]
           (let [[x y] dead-end]
             (set-item-at
              x y
              (generate-item
               {:single-handed-weapon 0.30
                :double-handed-weapon 0.20
                :armor 0.30
                :shield 0.20})))))
      (build-sprite-batch)
      (fn item-at [x y]
          (let [col (. items x)]
            (if col
                (. col y)
                nil)))
      (fn describe [x y]
          (fn with-article [title]
              (if (: "eyuioa" :find (: title :sub 1 1))
                  (.. "an " title)
                  (.. "a " title)))
          (let [item (item-at x y)]
            (if item
                (lume.format "There is {it} lying here."
                             {:it (with-article (. (. item 1) :title))})
                "")))
      (fn remove-item [x y]
          (tset (. items x) y nil)
          (build-sprite-batch))
      {:draw (fn [] (love.graphics.draw sprite-batch))
       :describe describe
       :item-at item-at
       :set-item-at set-item-at
       :remove-item remove-item
       }))
