# Core
# ---------
require! './src/actor': {Actor}
require! './src/filters': {FpsExec}
require! './src/signal': {Signal}

# Connectors
# ----------
# CouchDCS
require! './services/couch-dcs/client': {CouchDcsClient}
require! './services/couch-dcs/server': {CouchDcsServer}

# Dcs Proxy
require! './services/dcs-proxy/tcp/client': {DcsTcpClient}
require! './services/dcs-proxy/tcp/server': {DcsTcpServer}
require! './services/dcs-proxy/protocol-actor/auth-db': {AuthDB, as-docs}

require! './lib': {
    EventEmitter, Logger, sleep, merge
    pack, unpack, clone, diff
}

require! './proxy-actors/io-proxy/io-proxy-client': {IoProxyClient}


module.exports = {
    Actor, FpsExec, Signal
    CouchDcsClient, CouchDcsServer,
    DcsTcpClient, DcsTcpServer, AuthDB, as-docs
    EventEmitter, Logger, sleep, merge
    pack, unpack, clone, diff
    IoProxyClient
}
