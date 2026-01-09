function [mat_out] = normLin(mat_in)
    if(any(mat_in))
        mat_out = mat_in / max(max(max(max(mat_in))));
    else
        mat_out = mat_in;
    end
end