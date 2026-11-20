function [T, U] = sim_pi(p, Kp, Ti, use_aw)
%SIM_PI  Discrete PI control of the platen, written exactly like PLC code.
%   use_aw = true  -> conditional-integration (clamping) anti-windup
%   use_aw = false -> plain PI, the integrator keeps growing when saturated
x = [0; 0];  I = 0;
T = zeros(p.N,1);  U = zeros(p.N,1);
for k = 1:p.N
    y = x(2) + p.Ta;               % measured platen temperature [degC]
    e = p.SP - y;                  % error
    u_raw = Kp*e + I;              % unsaturated PI output
    u = min(max(u_raw, 0), 1);     % SSR duty limited to 0..100 %

    pushing_high = (u_raw > 1) && (e > 0);
    pushing_low  = (u_raw < 0) && (e < 0);
    if ~use_aw || ~(pushing_high || pushing_low)
        I = I + Kp*p.Ts/Ti*e;      % integrate only when it helps
    end

    x = p.Ad*x + p.Bd*[u; disturbance(p,k)];
    T(k) = y;  U(k) = u;
end
end
