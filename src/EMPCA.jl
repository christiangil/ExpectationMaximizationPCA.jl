"""
Julia interface to a local verison of the empca
(https://github.com/sbailey/empca) python package
"""
__precompile__()
module EMPCA
    using PyCall
    const empca = PyNULL()
    function __init__()
        pushfirst!(PyVector(pyimport("sys")."path"), dirname(pathof(EMPCA)))
        copy!(empca, pyimport("empca"))
        @assert empca != PyNULL()
    end
    export empca
end
