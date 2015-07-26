if (! defined $output) {
	$output = "out";
}

if (! defined $endIndex) {
	$endIndex = 150;
}

if (! defined $step) {
	$step = 10;
}

if (! defined $timeStep) {
	$timeStep = 0.1;
}

for ($i=0;$i<=$endIndex;$i+=$step) {
	my $filename = "$output/Time_2_$i.part0.exnode";
	mt $time = $i * $timeStep;
    print "Reading $filename @ $time\n";
    gfx read node "$filename" time $time;
}

gfx read element "$output/MonodomainExample.part0.exelem"; 

gfx define faces egroup Region;
gfx create window 1;
gfx modify window 1 background colour 1.0 1.0 1.0;
gfx modify window 1 view interest_point 0.5,0.5,0.0 eye_point 0.5,0.5,3.0 up_vector 0.0,1.0,0.0;
gfx modify spectrum default clear overwrite_colour;
gfx modify spectrum default linear reverse range -95.0 50.0 extend_above extend_below rainbow colour_range 0 1 component 1;
gfx modify spectrum default linear reverse range -95.0 50.0 banded number_of_bands 10 band_ratio 0.05 component 1;
gfx modify g_element Region lines material black;
gfx modify g_element Region surfaces select_on coordinate Coordinate material default data Vm spectrum default selected_material default_selected render_shaded;
