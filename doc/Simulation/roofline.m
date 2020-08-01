function max_perf = roofline( f, dsp, BW, hp, ctc)
comp_roof = 2*f*dsp/5;
bw_roof = (BW/8)*f*hp;
max_perf = min(comp_roof, bw_roof*ctc);
end

