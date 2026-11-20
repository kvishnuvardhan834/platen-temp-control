(* FB_PlatenModel
   Simulated heater + platen (same equations as matlab/platen_params.m).
   Lets the soft PLC run a full test with no hardware.
   Forward Euler integration; keep rDt <= 0.5 s (fast heater time constant ~8 s). *)
FUNCTION_BLOCK FB_PlatenModel
VAR_INPUT
    rU      : REAL;            (* heater command 0..1 *)
    rW      : REAL;            (* disturbance heat [W], negative = cold mold *)
    rDt     : REAL := 0.1;     (* integration step = task cycle [s] *)
    xReset  : BOOL;            (* TRUE = back to ambient *)
END_VAR
VAR_OUTPUT
    rTh     : REAL := 25.0;    (* heater temperature [degC] *)
    rTp     : REAL := 25.0;    (* platen temperature [degC] *)
END_VAR
VAR
    rCh     : REAL := 800.0;
    rCp     : REAL := 14000.0;
    rRhp    : REAL := 0.01;
    rRpa    : REAL := 0.155;
    rPmax   : REAL := 4000.0;
    rTa     : REAL := 25.0;
    rQhp    : REAL;            (* heat flow heater -> platen [W] *)
    rQloss  : REAL;            (* heat loss platen -> ambient [W] *)
END_VAR

IF xReset THEN
    rTh := rTa;
    rTp := rTa;
    RETURN;
END_IF

rQhp   := (rTh - rTp) / rRhp;
rQloss := (rTp - rTa) / rRpa;
rTh := rTh + rDt * (rPmax * LIMIT(0.0, rU, 1.0) - rQhp) / rCh;
rTp := rTp + rDt * (rQhp - rQloss + rW) / rCp;
END_FUNCTION_BLOCK
