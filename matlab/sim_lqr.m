function [T, U, K] = sim_lqr(p, Q, R)
%SIM_LQR  Discrete LQR with integral action (servo LQR) for the platen.
%   Augmented state: [x - xss; z],  z(k+1) = z(k) + Ts*(y - SP)
%   Assumes both temperatures are measured. Extension: add an observer
%   to estimate the heater temperature from the platen sensor only.
Aa = [p.Ad, zeros(2,1); 0, p.Ts, 1];
Ba = [p.Bd(:,1); 0];

% Solve the discrete Riccati equation by iteration (no dlqr needed)
S = Q;
for i = 1:20000
    Snew = Aa'*S*Aa - Aa'*S*Ba/(R + Ba'*S*Ba)*Ba'*S*Aa + Q;
    if max(abs(Snew(:) - S(:))) < 1e-10*max(1, max(abs(S(:)))), S = Snew; break; end
    S = Snew;
end
K = (R + Ba'*S*Ba) \ (Ba'*S*Aa);

% Steady state for the setpoint (feedforward)
xs  = (eye(2) - p.Ad) \ p.Bd(:,1);   % state rise per unit u
uss = (p.SP - p.Ta) / xs(2);
xss = xs * uss;

x = [0; 0];  z = 0;
T = zeros(p.N,1);  U = zeros(p.N,1);
for k = 1:p.N
    y = x(2) + p.Ta;
    u_raw = uss - K(1:2)*(x - xss) - K(3)*z;
    u = min(max(u_raw, 0), 1);
    e = y - p.SP;
    if ~((u_raw >= 1 && e < 0) || (u_raw <= 0 && e > 0))
        z = z + p.Ts*e;                 % anti-windup on the integral state
    end
    x = p.Ad*x + p.Bd*[u; disturbance(p,k)];
    T(k) = y;  U(k) = u;
end
end
