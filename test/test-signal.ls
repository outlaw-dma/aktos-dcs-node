
/*
EXAMPLE FOR USE GO!
do
    console.log "waiting mahmut..."
    reason, param <- timeout-wait-for 10000ms, \mahmut
    console.log "mahmut happened! reason: ", reason, "param: ", param

do
    console.log "firing mahmut in 2 seconds..."
    <- sleep 2000ms
    go \mahmut, 5
    console.log "fired mahmut event!"

*/

require! '../src/signal': {Timeout}
require! 'aea/debug-log': {logger}
require! 'aea': {sleep}

log = new logger \signal-test

tests =
    * ->
        my-timeout = new Timeout!
        log.log "signal will run because it will receive an event"
        do
            log.log "started coroutine 1"
            <- sleep 1000ms
            reason, arg1, arg2 <- my-timeout.wait 10_000ms
            log.log "coroutine 1 continuing! reason: ", reason, "arg1: ", arg1, "arg2: ", arg2
            log.log "This should happen at +2000ms"

        do
            log.log "firing my-timeout in 2 seconds..."
            <- sleep 2000ms
            my-timeout.go \hello, \world
            log.log "fired my-timeout! This should happen at +2000ms"

    * ->
        my-timeout = new Timeout!
        log.log "signal will run because it will timeout"

        do
            log.log "started coroutine 1"
            <- sleep 500ms
            reason, arg1, arg2 <- my-timeout.wait 500ms
            log.log "coroutine 1 continuing! reason: ", reason, "arg1: ", arg1, "arg2: ", arg2
            log.log "This should happen at +1000ms"

        do
            log.log "firing my-timeout in 2 seconds..."
            <- sleep 2000ms
            my-timeout.go \hello, \world
            log.log "fired my-timeout! This should happen at +2000ms"

    * ->
        log.log "started watchdog test"
        my-timeout = new Timeout!

        do
            reason <- my-timeout.wait 1000ms
            log.log "watchdog barked!"

        do
            i = 0
            <- :lo(op) ->
                log.log "resetting timeout timer, i: ", i
                my-timeout.reset!
                <- sleep 500ms + ((i++) * 100ms)
                return op! if i > 10
                lo(op)

tests.2!