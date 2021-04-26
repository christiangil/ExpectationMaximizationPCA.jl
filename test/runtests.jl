using EMPCA
using Test

@testset "will EMPCA.jl work at all?" begin
    nobs = 100
    nvar = 200
    nvec = 3
    data = zeros(nobs, nvar)

    #- Generate data
    x = (0:(nvar - 1)) ./ (nvar - 1) .* (2 * π)
    for i in 1:nobs
        for k in 1:nvec
            data[i, :] += 5.0*nvec//(k)^2 * randn() * sin.(x*(k))
        end
    end

    #- Add noise
    sigma = ones(size(data))
    for i in Int.(1:(nobs//10))
        sigma[i, :] *= 5
        sigma[i, 1:(Int(floor(nvar/4)) + 1)] *= 5
    end

    weights = 1.0 ./ sigma.^2
    noisy_data = data + (randn(size(sigma)) .* sigma)
    m0 = empca.empca(noisy_data, weights, niter=20)
    @test isreal(m0.R2())
    m1 = empca.lower_rank(noisy_data, weights, niter=20)
    @test isreal(m1.R2())
    m2 = empca.classic_pca(noisy_data)
    @test isreal(m2.R2())
end
