(* FB_TimeProportional
   Turns a 0..1 duty into an ON/OFF output for a solid-state relay (SSR).
   Example: rDuty = 0.3, cycle 2 s -> ON 0.6 s, OFF 1.4 s. *)
FUNCTION_BLOCK FB_TimeProportional
VAR_INPUT
    rDuty   : REAL;            (* 0..1 *)
    tCycle  : TIME := T#2S;    (* SSR cycle time *)
END_VAR
VAR_OUTPUT
    xOut    : BOOL;            (* wire to the SSR output card *)
END_VAR
VAR
    fbCycle : TON;
    tOn     : TIME;
END_VAR

fbCycle(IN := NOT fbCycle.Q, PT := tCycle);
tOn := REAL_TO_TIME(LIMIT(0.0, rDuty, 1.0) * TIME_TO_REAL(tCycle));
xOut := fbCycle.ET < tOn;
END_FUNCTION_BLOCK
