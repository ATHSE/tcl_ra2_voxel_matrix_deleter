# Voxel Transform Deleter v1.01 by G-E
#
# To be able to use this script, you need the following:
#  -->> Download ActiveTCL's tclsh runtimes: http://www.activestate.com/activetcl/downloads

set verbose 1

proc trannystripper {voxel} { 
	global verbose
	set novox 0
	catch {open $voxel r+} of
	if ![string match "file*" $of] {puts "voxel not readable ..." ; exit}
	fconfigure $of -translation binary
#load good matrix
	catch {open "matrix.bin" r} fuf
	if ![string match "file*" $fuf] {puts "matrix.bin not readable ... cannot clean voxel matrices" ; set novox 1}
	fconfigure $fuf -translation binary
	set maternity [read $fuf 48]
	close $fuf
#end load	
	set len [file size $voxel]
	binary scan [read $of 16] a* vxlname
	set vxlname [lindex [split $vxlname \x00] 0]
	puts "Voxel Descriptor: $vxlname"
	binary scan [read $of 18] {i i i i c c} pal sects1 sects2 voxeldatasize b1 b2
	puts "Palettes: $pal"
	puts "Header Sections: $sects1"
	puts "Tailer Sections: $sects2"
	puts "Body Data Size: $len file, $voxeldatasize allocated" 
	puts "Remap Index Range: $b1 to $b2" ;# palette indexes of remap start/end

	if {$sects1 != $sects2} {puts "Missing Header or Tailer" ; exit}
	# sort out offsets, skip palette
	seek $of 802

	# section headers
	set loopcnt 0
	while {$loopcnt < $sects1} {
		set secname ""
		binary scan [read $of 16] a* secname
		set secname [lindex [split $secname \x00] 0]
		binary scan [read $of 12] {i i i} secnum secsize dummy
		puts "Section Index: $secnum"
		puts "Section Name: $secname"
		set limbname($secnum) $secname
		set limbstat(siz,[set secnum]) $secsize
		incr loopcnt
	}	
	# (position should be 830 for a single section here)
	set databegin [tell $of]
	puts "Total Header Length: $databegin"
	# voxel data goes here
	# ...except it doesn't! 

	set datastart [expr 802 + (28 * $sects1)]
	set dataend [expr $len - (92 * $sects2)]
	if {$verbose} {
		puts "-> Computed Total Data Length: [expr $dataend - $datastart]"
		puts "-> Computed Total Data Offset: $datastart"
	}
	# section tailers
	seek $of $dataend
	set loopcnt 0
	while {$loopcnt < $sects2} {
		binary scan [read $of 16] {i i i f} lstarts lends loffset lscale
		puts ""
		puts "Voxel Section Name: $limbname($loopcnt)"	
		puts "Voxel Scale: $lscale"
		binary scan [read $of 48] {f f f f f f f f f f f f} t1 t2 t3 t4 t5 t6 t7 t8 t9 t10 t11 t12 ;# the transform float data
		if {$verbose} {
			puts "Old Section transform matrix:"
			puts "$t1 | $t2 | $t3 | $t4"
			puts "$t5 | $t6 | $t7 | $t8"
			puts "$t9 | $t10 | $t11 | $t12"
		}
		# do we need modified values?
		if {[expr $t1 + $t2 + $t3 + $t4] != 1 || [expr $t5 + $t6 + $t7 + $t8] != 1 || [expr $t9 + $t10 + $t11 + $t12] != 1} {
			#begin modify
			if {!$novox} {
				puts ">> found unclean transform values... BALEETED!"
				seek $of -48 current
				puts -nonewline $of $maternity
				#rewind and review values
				seek $of -48 current
				binary scan [read $of 48] {f f f f f f f f f f f f} t1 t2 t3 t4 t5 t6 t7 t8 t9 t10 t11 t12 ;# the transform float data
				if {$verbose} {
					puts "New Section transform matrix:"
					puts "$t1 | $t2 | $t3 | $t4"
					puts "$t5 | $t6 | $t7 | $t8"
					puts "$t9 | $t10 | $t11 | $t12"
				}
			}
			# end modify
		}
		binary scan [read $of 24] {f f f f f f} xmin ymin zmin xmax ymax zmax
		binary scan [read $of 4] {cu cu cu cu} xsize ysize zsize normals
		if {$normals == 2} {
			set limbstat(max,[set loopcnt]) 35
			set normals "TS"
		} elseif {$normals == 4} {
			set limbstat(max,[set loopcnt]) 243
			set normals "RA2"
		}	
		puts "Normals mode: $normals"
		puts "Section Dimensions:"
		puts "  Absolute Length: $xsize, Scaled: [expr $xmax - $xmin]"
		puts "  Absolute Width: $ysize, Scaled: [expr $ymax - $ymin]"
		puts "  Absolute Height: $zsize, Scaled: [expr $zmax - $zmin]"
		if {$verbose} {
			puts "Span Start lists: $lstarts"
			puts "Span End lists: $lends"
			puts "Span Data Offset: $loffset"
		}
		set limbstat(x,[set loopcnt]) $xsize
		set limbstat(y,[set loopcnt]) $ysize
		set limbstat(z,[set loopcnt]) $zsize
		# single section model
		set limbstat(d1,[set loopcnt]) $lstarts
		set limbstat(d2,[set loopcnt]) $lends
		set limbstat(d3,[set loopcnt]) $loffset
		#----	
		incr loopcnt
	}	
	close $of
}

if ![string equal {} $argv] {
	#encapsulation cleaner
	set cc [expr [string first \} $argv] - [string first \{ $argv]]
	if {$cc > 0} {set argv [lindex $argv 0]}
	set argv [file tail $argv]
	puts "\n>> voxel specified: $argv"
	trannystripper $argv
} else {
	puts "\n>> voxel not specified, exiting..."
}

