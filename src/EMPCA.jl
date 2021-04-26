__precompile__()
module EMPCA
    using PyCall
    const empca = PyNULL()
    # joinpath(pathof(EMPCA),"src")
    function __init__()
        pushfirst!(PyVector(pyimport("sys")."path"), "")
        copy!(empca, pyimport("empca"))
    end
end
