require! './actor': {Actor}
require! 'aea/debug-log': {debug-levels}
require! 'prelude-ls': {
    initial,
    drop,
    join,
    split,
}

/*

ProxyActor has two "network interfaces":

    1. ActorManager (as every Actor has)
    2. network

ProxyActor simply forwards all messages it receives to/from ActorManager
from/to network.

ProxyActor is also responsible from security.

*/

export class SocketIOBrowser extends Actor
    @instance = null
    (server-addr) ->
        # Make this class Singleton
        return @@instance if @@instance
        @@instance = this

        __ = @
        super \SocketIOBrowser
        #console.log "Proxy actor is created with id: ", @actor-id

        @token = null
        @connection-listener = (self, connect-str) ->

        # calculate socket.io path
        # -----------------------------------------------------------
        /* initialize socket.io connections */
        /*
        url = String window.location .split '#' .0
        arr = url.split "/"
        addr_port = arr.0 + "//" + arr.2
        socketio-path = [''] ++ (initial (drop 3, arr)) ++ ['socket.io']
        socketio-path = join '/' socketio-path
        @log.section \conn1, "socket-io path: #{socketio-path}, url: #{url}"
        # FIXME: HARDCODED SOCKET.IO PATH
        socketio-path = "/socket.io"
        */
        a = server-addr
        @socket = io.connect "#{a.host}:#{a.port}", resource: "#{a.path or "/socket.io"}"

        # send to server via socket.io
        @socket.on 'aktos-message', (msg) ~>
            @network-receive msg

        @socket.on "connect", !~>
            @log.section \v1, "Connected to server with id: ", __.socket.io.engine.id

        @socket.on "disconnect", !~>
            @log.section \v1, "proxy actor says: disconnected"

        @on-receive (msg) ~>
            @log.section \debug-local, "received msg: ", msg
            @network-send-raw msg



    update-io: ->
        @network-send UpdateIoMessage: {}

    network-receive: (msg) ->
        # receive from server via socket.io
        # forward message to inner actors
        @log.section \debug-network, "proxy actor got network message: ", msg
        @send_raw msg

    network-send: (msg) ->
        @log.section \debug-network, "network-send msg: ", msg
        @network-send-raw (envelp msg, @get-msg-id!)

    network-send-raw: (msg) ->
        # receive from inner actors, forward to server
        #
        # ---------------------------------------------------------
        # WARNING:
        # ---------------------------------------------------------
        # Do not modify msg as it's only a reference to original message,
        # so modifying this object will cause the original message to be
        # sent to it's original source (which is an error)
        # ---------------------------------------------------------

        msg.token = @token
        @socket.emit 'aktos-message', msg