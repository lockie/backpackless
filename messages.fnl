
(local status-font-size 18)
(local status-font (love.graphics.newFont "assets/8bitlimr.ttf" status-font-size))

(fn setup-messages [dungeon player]
    (var status-message "")
    {:draw (fn draw []
               (love.graphics.setFont status-font)
               (love.graphics.print
                status-message
                0 (- (love.graphics.getHeight) (* 2 status-font-size)))
               (love.graphics.print
                (player.describe)
                0 (- (love.graphics.getHeight) status-font-size)))
     :init-status-message (fn init-status-message []
                              (set status-message
                                   (let [[x y] (player.pos)]
                                     (dungeon.describe x y))))
     :update-status-message (fn update-status-message [message prepend]
                                (let [new-status-message
                                      (.. (if prepend message status-message)
                                          (if (= status-message "") "" " ")
                                          (if prepend status-message message))]
                                  (if (> (# new-status-message) 85)
                                      (set status-message message)
                                      (set status-message new-status-message))))
     })
