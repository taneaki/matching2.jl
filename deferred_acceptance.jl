function deferred_acceptance(prop_prefs, resp_prefs, caps)
    prop_size = size(prop_prefs, 2)
    resp_size = size(resp_prefs, 2)
    prop_matched = zeros(Int64, prop_size)
    resp_matched_base = Int[]
    next_prop = zeros(Int64, prop_size)
    max_prop = Int64[]
    
    for m in 1:prop_size
        push!(max_prop, find(prop_prefs[:, m] .== 0)[1]-1)
    end

    for i in 1:length(caps)
        resp_matched_base = vcat(resp_matched_base, {zeros(Int, caps[i])})
    end
    
    indptr = Array(Int, resp_size+1)
    indptr[1] = 1
    for i in 1:resp_size
    indptr[i+1] = indptr[i] + caps[i]
    end
    
    while any(prop_matched .== 0) == true
        prop_single = find(prop_matched .== 0)
        if all(next_prop[prop_single] .>= max_prop[prop_single]) == true
            break
        else
            for each_prop_single in prop_single
                proposing = prop_prefs[next_prop[each_prop_single]+1, each_prop_single]
                if proposing != 0
                   next_prop[each_prop_single] = next_prop[each_prop_single]+1
                    if any((resp_matched_base[proposing]) .== 0) == true && (find(resp_prefs[:, proposing] .==each_prop_single) .<  find(resp_prefs[:, proposing] .==0)) == [true]
                        prop_matched[each_prop_single] = proposing
                        resp_matched_base[proposing][findfirst(resp_matched_base[proposing].==0)] = each_prop_single
                        elseif resp_matched_base[proposing] != 0 
                        k = Int[]
                        for j in 1:length(resp_matched_base[proposing])
                            k = vcat(k, find(resp_prefs[:, proposing] .== resp_matched_base[proposing][j]))
                        end
                        if ((find(resp_prefs[:, proposing] .==each_prop_single)) .< findmax(k)[1]) == [true]
                            prop_matched[each_prop_single] = proposing
                            prop_matched[resp_matched_base[proposing][findmax(k)[2]]] = 0
                            resp_matched_base[proposing][resp_matched_base[proposing][findmax(k)[2]]] = each_prop_single
                        end
                    end
                end
            end
        end
    end
    resp_matched = Int[]
    for l in 1:resp_size
        resp_matched = append!(resp_matched, resp_matched_base[l])
    end
    return prop_matched, resp_matched,indptr
end