module ExpectationMaximizationPCA

using LinearAlgebra

"""
    EMPCA(μ, n_comp, data, weights; basis_vecs, scores, kwargs...)

Performs expectation-maximization principal component analysis (EMPCA) on `data` with `n_comp` basis vectors using `weights` as the weights. Pre-allocated arrays for `basis_vecs`, and `scores`, can be passed via keyword arguments.
"""
function EMPCA(
    μ::AbstractVector,
    n_comp::Int, 
    data::AbstractMatrix, 
    weights::AbstractMatrix; 
    basis_vecs::AbstractMatrix=Array{Float64}(undef, size(data, 1), n_comp), 
    scores::AbstractMatrix=Array{Float64}(undef, n_comp, size(data, 2)), 
    kwargs...)

    EMPCA!(basis_vecs, scores, μ, copy(data), weights; kwargs...)
    return basis_vecs, scores
end

"""
    EMPCA!(basis_vecs, scores, μ, data_tmp, weights; use_log, kwargs...)

Performs in-place (modifying `basis_vecs`, `scores`, and `data_tmp`) expectation-maximization principal component analysis (EMPCA) on `data_tmp` using `weights` as the weights.

# Keyword Arguments
- `use_log::false`: whether you want to perform EMPCA on the log of `data` instead
- `inds::AbstractUnitRange=axes(basis_vecs, 2)`: which indices of `basis_vecs` you want to use
- `vec_by_vec::Bool=true`: whether you want to perform EMPCA one vector at a time (generally preffered) or all at once
"""
function EMPCA!(basis_vecs::AbstractMatrix, scores::AbstractMatrix, μ::AbstractVector, data_tmp::AbstractMatrix, weights::AbstractMatrix; use_log::Bool=false, inds::AbstractUnitRange=axes(basis_vecs, 2), vec_by_vec::Bool=true, kwargs...)
	
    # if you want to perform EMPCA on the log of the data, modify `data_tmp` and `weights` appropriately
    if use_log
		weights .*= (data_tmp .^ 2)
		mask = weights.!=0
		data_tmp[mask] = log.(view(data_tmp ./ μ, mask))
		data_tmp[.!mask] .= 0
	else
		data_tmp .-= μ
	end
    if length(inds) > 0
		@assert inds[1] > 0
		vec_by_vec ?
			_empca_vec_by_vec!(basis_vecs, scores, data_tmp, weights; inds=inds, kwargs...) :
			_empca_all_at_once!(basis_vecs, scores, data_tmp, weights; inds=inds, kwargs...)
	end
end


"""
    _solve(dm, data, w)

Get optimal score(s) for modeling `data` with the basis vectors in the design matrix (`dm`) with weights (`w`) using generalized least squares (GLS)
"""
function _solve(
    dm::AbstractVecOrMat{T},
    data::AbstractVector,
    w::AbstractVector) where {T<:Real}
    return (dm' * (w .* dm)) \ (dm' * (w .* data))
end
"""
    _solve_scores!(basis_vec, scores, data, weights)

Fill `scores` with those that optimally model `data` with the `basis_vec` and weights (`w`) using generalized least squares (GLS)
"""
function _solve_scores!(basis_vec::AbstractVector, scores::AbstractVector, data::AbstractMatrix, weights::AbstractMatrix)
	for i in axes(data, 2)
		scores[i] = _solve(basis_vec, view(data, :, i), view(weights, :, i))
	end
end
"""
    _solve_scores!(basis_vecs, scores, data, weights)

Fill `scores` with those that optimally model `data` with the `basis_vecs` and weights (`w`) using generalized least squares (GLS)
"""
function _solve_scores!(basis_vecs::AbstractMatrix, scores::AbstractMatrix, data::AbstractMatrix, weights::AbstractMatrix; inds::AbstractUnitRange=axes(basis_vecs, 2))
	for i in axes(data, 2)
		scores[inds, i] .= _solve(view(basis_vecs, :, inds), view(data, :, i), view(weights, :, i))
	end
end


"""
    _solve_eigenvectors!(basis_vecs, scores, data, weights)

Fill `basis_vecs` with those that optimally model `data` with the `scores` and weights (`w`)
"""
function _solve_eigenvectors!(basis_vecs::AbstractMatrix, scores::AbstractMatrix, data::AbstractMatrix, weights::AbstractMatrix; inds::AbstractUnitRange=axes(basis_vecs, 2))
	nvar = size(basis_vecs, 1)
	cw = Array{Float64}(undef, size(data, 2))
	for i in inds
		c = view(scores, i, :)
		for j in 1:nvar
			cw[:] = c .* view(weights, j, :)
			cwc = dot(c, cw)
			iszero(cwc) ? basis_vecs[j, i] = 0 : basis_vecs[j, i] = dot(view(data, j, :), cw) / cwc
		end
		data .-= view(basis_vecs, :, i) * c'
	end
	basis_vecs[:, 1] ./= norm(view(basis_vecs, :, 1))
	_reorthogonalize(basis_vecs)
end
"""
    _solve_eigenvectors!(basis_vec, scores, data, weights)

Fill `basis_vec` with the one that optimally model `data` with the `scores` and weights (`w`)
"""
function _solve_eigenvectors!(basis_vec::AbstractVector, scores::AbstractVector, data::AbstractMatrix, weights::AbstractMatrix)
	nvar = length(basis_vec)
	cw = Array{Float64}(undef, size(data, 2))
	for j in 1:nvar
		cw[:] = scores .* view(weights, j, :)
		cwc = dot(scores, cw)
		iszero(cwc) ? basis_vec[j] = 0 : basis_vec[j] = dot(view(data, j, :), cw) / cwc
	end
	# Renormalize the answer
	basis_vec ./= norm(basis_vec)
end


"""
    _reorthogonalize!(basis_vec)

Modifies `basis_vec` to ensure all basis vectors are orthagonal and normalized
"""
function _reorthogonalize!(basis_vec::AbstractMatrix; inds=2:size(basis_vec, 2), kwargs...)
	nvec = size(basis_vec, 2)
	@assert inds[1] > 1
	if nvec > 1
		for i in inds
			_reorthogonalize_vec_i!(basis_vec, i; kwargs...)
		end
	end
end
"""
    _reorthogonalize!(basis_vec, i)

Modifies `basis_vec[:, i]` to ensure it orthagonal to `basis_vec[:, 1:i-1]` and normalized
"""
function _reorthogonalize_vec_i!(basis_vec::AbstractMatrix, i::Int; extra_vec::Union{Nothing, AbstractVector}=nothing)
	#- Renormalize and re-orthogonalize the answer
	if !isnothing(extra_vec)
		_reorthogonalize_no_renorm!(view(basis_vec, :, i), extra_vec)
	end
	for j in 1:(i-1)
		_reorthogonalize_no_renorm!(view(basis_vec, :, i), view(basis_vec, :, j))
	end
	basis_vec[:, i] ./= norm(view(basis_vec, :, i))
end
"""
    _reorthogonalize!(basis_vec1, basis_vec2)

Modifies `basis_vec1` to be orthagonal to `basis_vec2` without normalizing
"""
function _reorthogonalize_no_renorm!(basis_vec1::AbstractVector, basis_vec2::AbstractVector)
	basis_vec1 .-=  dot(basis_vec1, basis_vec2) .* basis_vec2 / sum(abs2, basis_vec2)
end


"""
    _random_orthonormal!(A)

Fill `A` with orthonormal basis vectors
"""
function _random_orthonormal!(A::AbstractMatrix; inds::AbstractUnitRange=axes(A, 2))
	keep_going = true
	i = 0
	while keep_going
		i += 1
		A[:, inds] .= randn(size(A, 1), length(inds))
		for i in inds
			for j in 1:(i-1)
				A[:, i] .-= dot(view(A, :, j), view(A, :, i)) .* view(A, :, j)
			end
			A[:, i] ./= norm(view(A, :, i))
		end
		keep_going = any(isnan.(A)) && (i < 100)
	end
	if i > 99; println("_random_orthonormal!() in empca failed for some reason") end
	return A
end


"""
    _empca_all_at_once!(basis_vec, scores, data, weights; niter, kwargs...)

Performs in-place EMPCA, improving all basis vectors and scores with each iteration

# Keyword Arguments
- `niter::Int=100`: the amount of iterations used
"""
function _empca_all_at_once!(basis_vec::AbstractMatrix, scores::AbstractMatrix, data::AbstractMatrix, weights::AbstractMatrix; niter::Int=100, inds::AbstractUnitRange=axes(basis_vec, 2), kwargs...)

    #- Basic dimensions
    @assert size(data) == size(weights)
	@assert size(scores, 1) == size(basis_vec, 2)
	@assert size(scores, 2) == size(data, 2)
	@assert size(basis_vec, 1) == size(data, 1)

    #- Starting random guess
    basis_vec .= _random_orthonormal!(basis_vec; inds=inds, kwargs...)

	_solve_scores!(basis_vec, scores, data, weights)
	_data = copy(data)
    for k in 1:niter
		_solve_eigenvectors!(basis_vec, scores, _data, weights; inds=inds)
		_data .= data
        _solve_scores!(basis_vec, scores, _data, weights; inds=inds)
	end

    return basis_vec, scores
end


"""
    _empca_vec_by_vec!(basis_vec, scores, data, weights; niter, kwargs...)

Performs in-place EMPCA, finishing one basis vector (and its scores) before moving onto the next

# Keyword Arguments
- `niter::Int=100`: the amount of iterations used
"""
function _empca_vec_by_vec!(basis_vec::AbstractMatrix, scores::AbstractMatrix, data::AbstractMatrix, weights::AbstractMatrix; niter::Int=100, inds::AbstractUnitRange=axes(basis_vec, 2), kwargs...)

    #- Basic dimensions
    nvar, nobs = size(data)
    @assert size(data) == size(weights)
	@assert size(scores, 1) == size(basis_vec, 2)
	@assert size(scores, 2) == nobs
	@assert size(basis_vec, 1) == nvar

	_data = copy(data)
	for i in 1:inds[end]
		if i in inds
			basis_vec[:, i] .= randn(nvar)
			# basis_vec[:, i] ./= norm(view(basis_vec, :, i))
			_reorthogonalize_vec_i!(basis_vec, i; kwargs...)  # actually useful
			_solve_scores!(view(basis_vec, :, i), view(scores, i, :), data, weights)
		    for k in 1:niter
				_solve_eigenvectors!(view(basis_vec, :, i), view(scores, i, :), _data, weights)
				_reorthogonalize_vec_i!(basis_vec, i; kwargs...)  # actually useful
		        _solve_scores!(view(basis_vec, :, i), view(scores, i, :), _data, weights)
			end
		end
		_data .-= view(basis_vec, :, i) * view(scores, i, :)'
	end

    return basis_vec, scores
end


end # module
