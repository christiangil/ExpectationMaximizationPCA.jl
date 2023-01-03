using Test
using LinearAlgebra
using MultivariateStats
using Statistics
using Random
import EMPCA

nx = 200
b1 = sin.(((1:nx) ./ nx) * 2π)
b2 = cos.(((1:nx) ./ nx) * 2π)
d = rand(Random.MersenneTwister(0), 50)' .* b1 + (0.2 .* rand(Random.MersenneTwister(1), 50)') .* b2

@testset "Replicating exact PCA" begin
    M = fit(PCA, d; maxoutdim=2)
    basis_vecs, scores = EMPCA.EMPCA!(vec(mean(d;dims=2)), 2, d, ones(size(d)))
    for i in 1:2
        s = sum(abs, M.proj[:, i] - basis_vecs[:, i]) < sum(abs, M.proj[:, i] + basis_vecs[:, i])
        basis_vecs[:, i] .*= 2*s-1
        scores[:, i] .*= 2*s-1
    end
    @test all(isapprox.(M.proj,basis_vecs; atol=1e-6, rtol=1e-6))
    println()
end

@testset "Better than PCA in a χ²-sense" begin
    σ = ((((((1:nx) .- nx/2).^2) ./ (nx/2)^2) .+ 1)* ones(50)') ./ 6  # edges are twice as noisy as the center
    dn = d + σ .* randn(Random.MersenneTwister(2), size(d))
    M = fit(PCA, dn; maxoutdim=2)
    basis_vecs, scores = EMPCA.EMPCA!(vec(mean(dn;dims=2)), 2, dn, 1 ./ σ.^2)
    @test sum(abs2, (dn - (basis_vecs * scores .+ vec(mean(dn;dims=2)))) ./ σ) < sum(abs2, (dn - reconstruct(M, predict(M, dn))) ./ σ)
    println()
end
