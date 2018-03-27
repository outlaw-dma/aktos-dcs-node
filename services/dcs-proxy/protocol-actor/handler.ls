require! '../deps': {AuthHandler, pack, unpack, Actor}
require! 'colors': {bg-red, red, bg-yellow, green, bg-cyan}
require! 'prelude-ls': {split, flatten, split-at, empty}
require! './helpers': {MessageBinder}


export class ProxyHandler extends Actor
    (@transport, opts) ->
        """
        opts:
            name: name
            db: auth-db instance
        """
        super opts.name
        @subscribe "public.**"
        @log.log ">>=== New connection from the client is accepted. name: #{@name}"
        # ------------------------------------------------------
        # ------------------------------------------------------
        # ------------------------------------------------------
        @this-actor-is-a-proxy = yes # THIS IS VERY IMPORTANT
        # responses to the requests will be silently dropped otherwise
        # ------------------------------------------------------
        # ------------------------------------------------------
        # ------------------------------------------------------

        @auth = new AuthHandler opts.db, opts.name
            ..on \to-client, (msg) ~>
                @transport.write pack @msg-template msg

            ..on \login, (ctx) ~>
                @log.prefix = ctx.user
                @subscriptions = []  # clear all subscriptions, especially public.**
                unless empty (ctx.permissions.ro or [])
                    @log.info "subscribing readonly: "
                    for flatten [ctx.permissions.ro] => @log.info "->  #{..}"
                    @subscribe ctx.permissions.ro

                unless empty (ctx.permissions.rw or [])
                    @log.info "subscribing read/write: "
                    for flatten [ctx.permissions.rw] => @log.info "->  #{..}"
                    @subscribe ctx.permissions.rw

                # debug the subscriptions
                #@log.info "TOTAL Subscriptions", @subscriptions.length
                #for @subscriptions => @log.info "___  #{..}"

            ..on \logout, ~>
                # logout is specific to browser like environments, where user
                # might want to log out and log in with a different user.

                # IMPORTANT: SECURITY: Clear subscriptions
                @subscriptions = []

        # DCS interface
        @on do
            receive: (msg) ~>
                # debug
                #@log.log "DCS > Transport (topic : #{msg.topic}) msg id: #{msg.sender}.#{msg.msg_id}"
                #@log.log "... #{pack msg.payload}"
                @transport.write pack msg

            kill: (reason, e) ~>
                @log.log "Killing actor. Reason: #{reason}"

        # transport interface
        @m = new MessageBinder!
        @transport
            ..on "data", (data) ~>
                #@log.log "________data:", data.to-string!
                for msg in @m.append data
                    # in "client mode", authorization checks are disabled
                    # message is only forwarded to manager
                    if \auth of msg
                        #@log.log green "received auth message: ", msg
                        @auth.trigger \check-auth, msg
                    else
                        try
                            msg
                            |> @auth.check-permissions
                            # permission check ok, send to DCS network
                            #|> (x) -> console.log "permissions okay for #{x.sender}.#{x.msg_id}"; return x
                            |> @send-enveloped

                            # debug
                            #@log.log "  Transport > DCS (topic: #{msg.topic}) msg id: #{msg.sender}.#{msg.msg_id}"
                            #@log.log "... #{pack msg.payload}"
                        catch
                            if e.type is \AuthError
                                @log.warn "Authorization failed, dropping message."
                            else
                                throw e

            ..on \disconnect, ~>
                @log.log "proxy handler is exiting."
                @kill \disconnected