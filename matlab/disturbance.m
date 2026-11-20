function w = disturbance(p, k)
%DISTURBANCE  Heat removed by a cold mold, in W, at sample k (1-based).
n = k - 1;
if n >= p.dist_start && n < p.dist_start + p.dist_len
    w = p.dist_W;
else
    w = 0;
end
end
