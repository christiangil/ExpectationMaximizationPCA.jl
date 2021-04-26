"""
Julia interface to a local verison of the empca
(https://github.com/sbailey/empca) python package
"""
__precompile__()
module EMPCA
    using PyCall
    const empca = PyNULL()
    # joinpath(pathof(EMPCA),"src")
    function __init__()
        pushfirst!(PyVector(pyimport("sys")."path"), joinpath(pathof(EMPCA),".."))
        copy!(empca, pyimport("empca"))
    end
    export empca
end
