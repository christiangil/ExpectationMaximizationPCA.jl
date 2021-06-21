"""
Julia interface to a local verison of the empca
(https://github.com/sbailey/empca) python package
"""
__precompile__()
module EMPCA
    using PyCall
    const empca = PyNULL()
    function __init__()
        pushfirst!(PyVector(pyimport("sys")."path"), joinpath(pathof(EMPCA),".."))
        # pushfirst!(PyVector(pyimport("sys")."path"), @__DIR__)
        copy!(empca, pyimport("empca"))
    end
    export empca
end
