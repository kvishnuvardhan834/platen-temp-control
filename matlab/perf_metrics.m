function m = perf_metrics(p, T, U)
%PERF_METRICS  Overshoot, settling, disturbance dip/recovery, energy.
kd   = p.dist_start;                 % samples before the cold mold
t    = (0:p.N-1)' * p.Ts;
pre  = T(1:kd);
m.overshoot_C = max(pre) - p.SP;
out = find(abs(pre - p.SP) > 1, 1, 'last');            % +/- 1 degC band
if isempty(out), m.settle_s = 0; else, m.settle_s = t(out); end
post = T(kd+1:end);
m.dip_C = p.SP - min(post);
out = find(abs(post - p.SP) > 1, 1, 'last');
if isempty(out), m.recover_s = 0; else, m.recover_s = t(out); end
m.energy_kWh = sum(U) * p.Pmax * p.Ts / 3.6e6;
end
