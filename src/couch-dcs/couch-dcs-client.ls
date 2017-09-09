require! '../actor': {Actor}
require! 'aea': {pack}


export class CouchDcsClient extends Actor
    (@doc-type) ->
        super \CouchDcsClient
        @topic = "db.#{@doc-type}"
        @subscribe "#{@topic}.**"

    get: (doc-id, opts, callback) ->
        # normalize parameters
        if typeof! opts is \Function
            callback = opts
            opts = {}
        # end of normalization

        err, msg <~ @send-request "#{@topic}.get", {get: doc-id, opts: opts}
        callback (err or msg?.payload.err), msg?.payload.res

    all: (opts, callback) ->
        # normalize parameters
        if typeof! opts is \Function
            callback = opts
            opts = {}
        # end of normalization

        err, msg <~ @send-request "#{@topic}.all", {all: opts}
        callback (err or msg?.payload.err), msg?.payload.res

    put: (doc, opts, callback) ->
        # normalize parameters
        if typeof! opts is \Function
            callback = opts
            opts = {}
        # end of normalization

        err, msg <~ @send-request "#{@topic}.put", {put: doc}
        callback (err or msg?.payload.err), msg?.payload.res

    view: (viewName, opts, callback) ->
        # normalize parameters
        if typeof! opts is \Function
            callback = opts
            opts = {}
        # end of normalization

        err, msg <~ @send-request "#{@topic}.view", {view: viewName, opts: opts}
        callback (err or msg?.payload.err), msg?.payload.res

    get-attachment: (doc-id, att-name, opts, callback) ->
        # normalize parameters
        if typeof! opts is \Function
            callback = opts
            opts = {}
        # end of normalization

        err, msg <~ @send-request {topic: "#{@topic}.getAtt", timeout: 5000ms}, do
            getAtt:
                doc-id: doc-id
                att-name: att-name
                opts: opts

        callback (err or msg?.payload.err), msg?.payload.res
