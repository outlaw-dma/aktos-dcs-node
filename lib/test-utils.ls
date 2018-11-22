'''
Example test:

make-tests 'foo-lib', tests =
    'hello world': ->
        orig = {hello: 'world'}
        _new = {hi: 'there'}

        expect foo orig, _new
        .to-equal {thats: 'nice'}

    'upps': ->
        docs = <[ some things here ]>

        expect (-> foo docs)
        .to-throw "Huston, we have a problem!"

    'skipped test': ->
        return false # Skipped tests will drop a warning into the console.

        # doing some serious tests here
        ...


# You can split tests into files and run them by referencing an object:
require! './some'
require! './thing'
require! './important'
make-tests 'my-lib', {some, thing, important}

'''

jsondiffpatch = require 'jsondiffpatch'
require! \expect
require! './packing': {clone}
require! './flatten-obj': {flattenObj}

run-test = (name, test) ->
    @expect = expect
    @clone = clone

    try
        res = test.call this
    catch
        console.error   "- FAILED on test: #{name}"
        if (typeof! e.matcherResult isnt \Object) or not e.matcherResult.actual
            throw e

        actual = JSON.stringify(e.matcherResult.actual)
        expected = JSON.stringify(e.matcherResult.expected)
        console.log     "- result  \t: ", actual
        console.log     "- expected\t: ", expected

        d = jsondiffpatch.diff e.matcherResult.actual, e.matcherResult.expected
        console.error "diff: "
        console.error (JSON.stringify d, null, 2)

        # Visual diff
        left = encodeURIComponent expected
        right = encodeURIComponent actual
        console.log "Visual Diff: http://benjamine.github.io/jsondiffpatch/demo/index.html?desc=Expected..Actual&left=#{left}&right=#{right}"

        throw  "- FAILED on test: #{name}"



    if typeof! res is \Undefined
        #console.log "...passed from external test: #{name}."
        null
    else if not res
        console.warn "Test [#{name}] is skipped..."
        null
    else
        expected = JSON.stringify(res.expect)
        result = JSON.stringify(res.result)
        if jsondiffpatch.diff res.result, res.expect
            console.error   "- FAILED on test: #{name}"
            console.log     "- diff    \t: ", that
            console.log     "- result  \t: ", result
            console.log     "- expected\t: ", expected
            console.warn "DEPRECATED: ----------- convert to 'expect' method --------------"
            throw   "- FAILED on test: #{name}"

        else
            #console.log "...passed from test: #{name}."


export make-tests = (lib-name, tests) ->
    if typeof! lib-name is \Object
        tests = lib-name
        lib-name = \Tests

    console.log "+++ Start of #{lib-name}"
    unless typeof! tests is \Object
        tests = {test: tests}
    for name, test of flattenObj tests
        run-test name, test
    console.log "... End of #{lib-name}"
