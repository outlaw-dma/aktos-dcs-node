require! '../../drivers'
require! 'prelude-ls': {keys, first, compact, join}
require! '../../lib/memory-map': {IoHandle}
require! './io-proxy-handler': {IoProxyHandler}
require! './io-proxy-client': {IoProxyClient}

export create-io-proxies = (opts) ->
    get-devices = (io-table, namespace='') ->
        device-list = []
        if typeof! io-table is \Object
            for key, sub-table of io-table
                curr-namespace = [namespace, key] |> compact |> join '.'
                #console.log "Key: ", key, "namespace is: ", curr-namespace
                if \driver of sub-table
                    # this is a device description
                    switch typeof! sub-table.driver
                    | \String =>
                        driver-name = sub-table.driver
                        driver-opts = null
                    | \Object =>
                        driver-name = sub-table.driver |> keys |> first
                        driver-opts = sub-table.driver[driver-name]

                    DeviceDriver = if driver-name of drivers
                        drivers[driver-name]
                    else if driver-name of opts.extra-drivers
                        opts.extra-drivers[driver-name]
                    else
                        #drivers['IoSimulatorDriver']
                        throw new CodingError "Driver is required."
                        null

                    #console.log "using driver: ", DeviceDriver.constructor.name
                    device =
                        driver: new DeviceDriver driver-opts
                        io-handles: [(new IoHandle params, "#{curr-namespace}.#{io}") for io, params of sub-table.handles]

                    device-list.push device
                else
                    device-list ++= get-devices sub-table, curr-namespace
        return device-list

    devices = get-devices opts.devices
    #console.log "devices: ", devices
    for let device in devices
        console.log "========================> Initializing #{device.driver.constructor.name}"
        for let handle in device.io-handles
            #console.log "handle is: ", handle
            new IoProxyHandler handle, device.driver

## Example Usage
->
    create-io-proxies do
        extra-drivers: {TankSimulatorDriver}
        devices:
            io:
                'tank-simulator':
                    driver: 'TankSimulatorDriver':
                        poll: 300ms
                    handles:
                        level1:
                            address: 'hey'
                            poll: 300ms
                'station-aaa':
                    driver: 'SiemensS7Driver':
                        host: '1.2.3.4'
                        port: 102
                        rack: 0
                        slot: 1
                    handles:
                        'test-level1':
                            address: \MD84
                            type: \hexf
                        'test-level2':
                            address: \MD85
                            type: \hexf
