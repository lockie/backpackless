(local globals (require "globals"))


(fn setup-messages [dungeon player items mobs]
    (var status-message "")
    (fn draw []
        (love.graphics.setFont globals.font)
        (love.graphics.print
         status-message
         0 (- (love.graphics.getHeight) (* 2 globals.font-size)))
        (love.graphics.print
         (player.describe)
         0 (- (love.graphics.getHeight) globals.font-size)))
    (fn init-status-message []
        (set status-message
             (let [[x y] (player.pos)
                   dungeon-description (dungeon.describe x y)
                   mobs-description (mobs.describe x y)
                   item-description (items.describe x y)]
               (..
                dungeon-description
                (if (= dungeon-description "") "" " ")
                mobs-description
                (if (= mobs-description "") "" " ")
                item-description))))
    (fn update-status-message [message prepend]
        (print message)
        (let [new-status-message
              (.. (if prepend message status-message)
                  (if (= status-message "") "" " ")
                  (if prepend status-message message))]
          (if (> (# new-status-message) 80)
              (set status-message message)
              (set status-message new-status-message))))
    {:draw draw
     :init-status-message init-status-message
     :update-status-message update-status-message
     })
