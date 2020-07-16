##############################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
##############################################################################

########################################################################
# PSI Modelsim Simulation Package
########################################################################
# This package helps to quickly and easily create regression test simulations
# including multiple test-runs and pre- resp. post-scripts.
#

namespace eval psi::sim {

	# Namespace Variables
	variable Libraries
	variable CurrentLib
	variable Sources
	variable ThisTbRun
	variable TbRuns
	variable CompileSuppress
	variable RunSuppress
	variable Simulator
	variable SimulatorVersion
	variable TranscriptFile
	
	#################################################################
	# Simulator Abstraction Layer (SAL)
	#################################################################
	proc sal_print_log {text} {
		variable Simulator
		variable TranscriptFile
		if {$Simulator == "Modelsim"} {
			echo $text
		} elseif {($Simulator == "GHDL") || ($Simulator == "Vivado")} {
			#Console
			puts $text
			#Transcript
			set fo [open $TranscriptFile a]
			puts $fo $text
			close $fo			
		} else {
			puts "ERROR: Unsupported Simulator - sal_print_log(): $Simulator"
		}
	}
	
	proc sal_transcript_off {} {
		variable Simulator
		if {$Simulator == "Modelsim"} {
			transcript off
		} elseif {($Simulator == "GHDL") || ($Simulator == "Vivado")} {
			#Nothing to do
		} else {
			puts "ERROR: Unsupported Simulator - sal_transcript_off(): $Simulator"
		}
	}
	
	proc sal_transcript_on {} {
		variable Simulator
		if {$Simulator == "Modelsim"} {
			transcript on
		} elseif {($Simulator == "GHDL") || ($Simulator == "Vivado")} {
			#Nothing to do
		} else {
			puts "ERROR: Unsupported Simulator - sal_transcript_on(): $Simulator"
		}
	}
	
	proc sal_set_transcript_file {filename} {
		variable Simulator
		if {$Simulator == "Modelsim"} {
			transcript file $filename
		} elseif {($Simulator == "GHDL") || ($Simulator == "Vivado")} {
			#Nothing to do
		} else {
			puts "ERROR: Unsupported Simulator - sal_set_transcript_file(): $Simulator"
		}		
		variable TranscriptFile [file normalize $filename]
	}	
	
	proc sal_clean_transcript {} {
		variable Simulator
		sal_transcript_off
		if {$Simulator == "Modelsim"} {
			sal_set_transcript_file ./Dummy.transcript
			set bm [batch_mode]
			if {$bm == 0} {
				file delete ./Transcript.transcript
			}
			sal_set_transcript_file ./Transcript.transcript
			file delete ./Dummy.transcript
		} elseif {($Simulator == "GHDL") || ($Simulator == "Vivado")} {
			file delete ./Transcript.transcript
			sal_set_transcript_file ./Transcript.transcript
			return
		} else {
			puts "ERROR: Unsupported Simulator - sal_clean_transcript(): $Simulator"
		}
		sal_transcript_on
	}
		
	
	proc sal_version_specific_flags {} {
		variable Simulator
		variable SimulatorVersion
		set args ""
		if {$Simulator == "Modelsim"} {
			if {[expr $SimulatorVersion < 10.7]} {
				set args "$args -novopt"
			}			
		} elseif {($Simulator == "GHDL") || ($Simulator == "Vivado")} {
			#Nothing to do
		} else {
			puts "ERROR: Unsupported Simulator - sal_version_specific_flags(): $Simulator"
		}
		
		return $args
	}
	
	proc sal_init_simulator {} {
		variable Simulator
		if {$Simulator == "Modelsim"} {
			#The vsim -version command does not return the version but write it to stdout. Therefore this is
			#.. forwareded to a file and read back from there. A sleep is required because writing the
			#.. file takes some time. 
			#.. Modelsim prints a warning because the stdout is forwarded to a file. Unfortunately I could not
			#.. find any way to suppress this warning (the forwarding is fully okay and expected).
			puts ">>> Error expected ..."
			vcom -version >tempVersion.txt
			puts ">>> ... until here."
			after 500			
			set txtFile [open tempVersion.txt]; list
			set versionStr [read $txtFile]; list
			close $txtFile
			file delete tempVersion.txt
			regexp {\s([0-9\.]+)\s} $versionStr dummy versionNr
			variable SimulatorVersion $versionNr
			puts "ModelsimVersion: $versionNr"
		} elseif {$Simulator == "GHDL"} {
			variable SimulatorVersion "NotImplementedForGhdl"
		} elseif {$Simulator == "Vivado"} {
			variable SimulatorVersion "NotImplementedForvivado"			
		} else {
			puts "ERROR: Unsupported Simulator - sal_init_simulator(): $Simulator"
		}
	}
	
	proc sal_clean_lib {lib} {
		variable Simulator
		if {$Simulator == "Modelsim"} {
			vlib $lib
			vdel -all -lib $lib
			vlib $lib
		} elseif {($Simulator == "GHDL") || ($Simulator == "Vivado")} {
			file delete -force $lib
			file mkdir $lib
		} else {
			puts "ERROR: Unsupported Simulator - sal_clean_lib(): $Simulator"
		}
	}
	
	proc sal_compile_file {lib path language langVersion fileOptions} {
		variable Simulator
		variable CompileSuppress 
		set vFlags [sal_version_specific_flags]
		if {$Simulator == "Modelsim"} {			
			set args "-work $lib $vFlags -suppress $CompileSuppress $fileOptions -quiet $path"
			if {$language == "vhdl"} {
				lappend args "-$langVersion"
				vcom {*}$args
			} else {
				lappend args "-incr"
				vlog {*}$args
			}
		} elseif {$Simulator == "GHDL"} {
			if {$language == "vhdl"} {
				if {$langVersion == "2002"} {
					# compile for 2002 (to make sure no 2008 features are used) but compile again for 2008
					# since we assume most testbenches will use that and ghdl does not support mixing versions
					exec ghdl -a --ieee=synopsys --std=02 -fexplicit -frelaxed-rules -Wno-shared -Wno-hide --work=$lib -P. $path
				} elseif {$langVersion != "2008"} {
					sal_print_log "ERROR: VHDL Version $langVersion not supported for GHDL"
				}
				exec ghdl -a --ieee=synopsys --std=08 -frelaxed-rules -Wno-shared -Wno-hide --work=$lib -P. $path
			} else {
				sal_print_log "ERROR: Verilog currently not supported for GHDL"
				sal_print_log ""
			}
		} elseif {$Simulator == "Vivado"} {		
			if {$language == "vhdl"} {
				set langArg ""
				if {$langVersion == "2008"} {
					set langArg "--2008"
				}
			} else {
				sal_print_log "ERROR: Verilog currently not supported for Vivado, request this feature from the developers"
				sal_print_log ""
			}
			exec xvhdl --lib=$lib --work $lib=$lib $langArg $path
		} else {
			puts "ERROR: Unsupported Simulator - sal_compile_file(): $Simulator"
		}
	}
	
	proc sal_exec_script {path cmd args} {
		variable Simulator
		set oldPath [pwd]
		cd $path
		sal_print_log "Running Pre Script"
		if {$Simulator == "Modelsim"} {
			sal_print_log [exec $cmd $args]
		} elseif {($Simulator == "GHDL") || ($Simulator == "Vivado")} {
			set outp [exec $cmd $args]
			sal_print_log $outp
		} else {
			puts "ERROR: Unsupported Simulator - sal_exec_script(): $Simulator"
		}
		cd $oldPath
	}
	
	proc sal_run_tb {lib tbName tbArgs timeLimit suppressMsgNo {wave ""}} {
		variable Simulator
		if {$Simulator == "Modelsim"} {
			set supp ""
			if {$suppressMsgNo != ""} {
				set supp +nowarn$suppressMsgNo
			}
			set cmd "vsim -quiet -t 1ps -msgmode both $supp $lib.$tbName $tbArgs"
			eval $cmd
			set StdArithNoWarnings 1
			set NumericStdNoWarnings 1
			if {$timeLimit != "None"} {
				run $timeLimit
			} else {
				run -all
			}
			quit -sim
		} elseif {$Simulator == "GHDL"} {
			if {$tbArgs != ""} {
				set tbArgs " $tbArgs"
			}
			if {$timeLimit != "None"} {
				sal_print_log "Stop $timeLimit"
				set stopTime " --stop-time=[string map {" " ""} $timeLimit]"
			} else {
				set stopTime ""
			}
			if {$wave != ""} {
				set wave " --wave=$wave"
			} 
			set cmd "ghdl --elab-run --ieee=synopsys --std=08 -frelaxed-rules -Wno-shared --work=$lib $tbName$tbArgs$stopTime$wave --ieee-asserts=disable"
			sal_print_log $cmd
			set outp [eval "exec $cmd"]
			sal_print_log $outp
		} elseif {$Simulator == "Vivado"} {
			#Write propper initfile (workaround because --lib switch of xelab does not work)
			variable Libraries
			set initFile psi_vivado_init.ini
			file delete $initFile
			set fo [open $initFile w+]
			foreach lib $Libraries {
				puts $fo "$lib=$lib\n"
			}
			close $fo	
			#Find generic overrides
			set genericOverrides ""
			foreach param $tbArgs {
				if {[string match "-g*" $param]} {
					lappend genericOverrides "-generic_top [string range $param 2 end]"
				}
			}
			set genericOverrides [join $genericOverrides " "]
			#Elaborate
			set cmd "xelab --initfile $initFile -s psi_sim_snapshot -debug typical"
			if {$genericOverrides != ""} {
				set cmd "$cmd $genericOverrides"
			}
			set cmd "$cmd $lib.$tbName"
			sal_print_log "$cmd"
			eval "exec $cmd"
			#Create simulation tcl file
			set outputFile psi_sim_output.txt
			file delete -force $outputFile
			set simTclName "psi_sim_run.tcl"
			set fo [open $simTclName w+]
			if {$timeLimit != "None"} {
				puts $fo "run $timeLimit > $outputFile;"
			} else {
				puts $fo "run -all > $outputFile;"
			}
			puts $fo "exit" 
			close $fo
			set cmd "xsim psi_sim_snapshot -tclbatch $simTclName"
			sal_print_log "$cmd"
			eval "exec $cmd"	
			#Add aoutput to log
			set fo [open $outputFile r]
			sal_print_log [read $fo]
			close $fo
					
		} else {
			puts "ERROR: Unsupported Simulator - sal_run_tb(): $Simulator"
		}
	}

	proc sal_launch_tb {lib tbName tbArgs suppressMsgNo wave} {
		variable Simulator
		if {$Simulator == "Modelsim"} {
			set supp ""
			if {$suppressMsgNo != ""} {
				set supp +nowarn$suppressMsgNo
			}
			set cmd "vsim -quiet -t 1ps -msgmode both $supp $lib.$tbName $tbArgs"
			eval $cmd
			set StdArithNoWarnings 1
			set NumericStdNoWarnings 1
			if {$wave != ""} {
				if {$wave != "all"} {
					sal_print_log "Restoring Waveform View $wave"
					set cmd "do $wave"
				} else {
					sal_print_log "Adding all Signals to the Waveform View"
					set cmd "add wave -r /*; run -all; wave zoom full"
				}
				eval $cmd
			}
		} else {
			puts "ERROR: Unsupported Simulator - sal_launch_tb(): $Simulator"
		}
	}

	proc sal_open_wave {wave} {
		variable Simulator
		if {$Simulator == "GHDL"} {
			exec gtkwave -f $wave &
		} else {
			puts "ERROR: Unsupported Simulator - sal_open_wave(): $Simulator"
		}
	}

	#################################################################
	# Interface Functions (exported)
	#################################################################	
	# Initialize PSI Simulation Package. This must be called as first command to use the library.
	#
	# -ghdl		Use GHDL instead of modelsim (modelsim is default)
	# -vivado	Use Vivado Simulator instead of modelsim (modelsim is default)
	proc init {args} {
		puts "Initialize PsiSim"
		set argList [split $args]
		variable Simulator "Modelsim"
		set i 0		
		while {$i < [llength $argList]} {
			set thisArg [lindex $argList $i]
			if {$thisArg == "-ghdl"} {
				variable Simulator "GHDL"
			} elseif {$thisArg == "-vivado"} {
				variable Simulator "Vivado"
			} else {
				sal_print_log "WARNING: ignored argument $thisArg"
				sal_print_log ""
			}
			set i [expr $i + 1]
		}
		variable Libraries [list]
		variable Sources [list]
		variable TbRuns [list]
		variable CompileSuppress ""
		variable RunSuppress ""
		variable CurrentLib "NoCurrentLibrary"
		#Simulator specific initialization
		sal_init_simulator
		#Clean transcript
		clean_transcript
	}
	namespace export init
	
	# Create a new VHDL library to compile files into
	#
	# @param lib	Library to create
	proc add_library {lib} {
		variable Libraries
		lappend Libraries $lib
		variable CurrentLib $lib
	}
	namespace export add_library
	
	# Add one or more message numbers to the list of messages to ignore during compilation
	#
	# @param msgNos		One or more message numbers to suppress, speparated by comma
	proc compile_suppress {msgNos} {
		variable CompileSuppress 
		set msgList [split $msgNos]
		foreach msg $msgList {
			#Only add to the list if it is not yet in the list
			set exists [regexp -nocase $msg $CompileSuppress]
			if {$exists == 0} {
				variable CompileSuppress $CompileSuppress$msg,
			}
		}		
	}
	namespace export compile_suppress	
	
	# Add one or more message numbers to the list of messages to ignore during simulation runs
	#
	# @param msgNos		One or more message numbers to suppress, speparated by comma
	proc run_suppress {msgNos} {
		variable RunSuppress 
		set msgList [split $msgNos]
		foreach msg $msgList {
			#Only add to the list if it is not yet in the list
			set exists [regexp -nocase $msg $RunSuppress]
			if {$exists == 0} {
				variable RunSuppress $RunSuppress$msg,
			}
		}
	}
	namespace export run_suppress	
	
	# Add HDL source files (including testbenches)
	#
	# Variable Arguments:
	#
	# @param directory	Directory the source files are including
	# @param files		List of file namespace
	# -lib <name>		Name of the library to compile the files into. This parameter is optional, if it
	#					is omitted, all files are compiled to the last library created with add_library
	# -tag <name>		Optional tag that can be used to compile/run user selected groups of files
	# -language <name>	Language (either "vhdl" or "verilog"). VHDL is default
	# -version <year>	VHDL Version year to compile. Only used with VHDL. 2008 is default
	# -options <string>	Modelsim Options to add as a string. No options is default
	proc add_sources {directory files {args}} {
		#parse arguments
		variable CurrentLib
		set tgtLib $CurrentLib
		set tag ""
		set language "vhdl"
		set version "2008"
		set options ""
		set argList [split $args]
		set i 0		
		while {$i < [llength $argList]} {
			set thisArg [lindex $argList $i]
			if {$thisArg == "-lib"} {
				set i [expr $i + 1]
				set thisArg [lindex $argList $i]
				set tgtLib $thisArg
			} elseif {$thisArg == "-tag"} {
				set i [expr $i + 1]
				set thisArg [lindex $argList $i]
				set tag $thisArg	
			} elseif {$thisArg == "-language"} {
				set i [expr $i + 1]
				set thisArg [lindex $argList $i]
				set language $thisArg
			} elseif {$thisArg == "-version"} {
				set i [expr $i + 1]
				set thisArg [lindex $argList $i]
				set version $thisArg
			} elseif {$thisArg == "-options"} {
				set i [expr $i + 1]
				set thisArg [lindex $argList $i]
				set options $thisArg
			} else {
				sal_print_log "WARNING: ignored argument $thisArg"
				sal_print_log ""
			}
			set i [expr $i + 1]
		}
		#Add files
		variable Sources
		foreach patt $files {
			set normalizedPatt [file normalize [concat $directory/$patt]]
			if { ! [ catch {set found [glob $normalizedPatt]} ] } {
				foreach path $found {
					set ThisSrc [dict create]
					dict set ThisSrc PATH $path
					dict set ThisSrc LIBRARY $tgtLib
					dict set ThisSrc TAG $tag
					dict set ThisSrc LANGUAGE $language
					dict set ThisSrc VERSION $version
					dict set ThisSrc OPTIONS $options
#check if the file already exists for this library
					foreach entry $Sources {
						set ePath [dict get $entry PATH]
							set eLib [dict get $entry LIBRARY]
							if {($path == $ePath) && ($tgtLib == $eLib)} {
								sal_print_log "WARNING: file $ePath already added to library $eLib"
							}
					}
					# FIXME: should we omit appending existing source again?
					#        keep existing behaviour for now...
					lappend Sources $ThisSrc
				}
			} else {
				sal_print_log "WARNING: file/pattern $normalizedPatt not found - skipping"
			}
		}
	}
	namespace export add_sources
	
	# Cleanup one or more libraries
	#
	# Variable Arguments:
	# -all			Clean all libraries (if no argument is passed, -all is executed)
	# -lib <name>	Name of one specific library to clean
	proc clean_libraries {args} {
		#Parse Arguments
		set Library "All-Libraries"
		set argList [split $args]
		set i 0		
		while {$i < [llength $argList]} {
			set thisArg [lindex $argList $i]
			if {$thisArg == "-all"} {
				set Library "All-Libraries"
			} elseif {$thisArg == "-lib"} {
				set i [expr $i + 1]
				set thisArg [lindex $argList $i]
				set Library $thisArg
			} else {
				sal_print_log "WARNING: ignored argument $thisArg"
				sal_print_log ""
			}
			set i [expr $i + 1]
		}	
		#Clean
		variable Libraries
		foreach lib $Libraries {
			if {($Library == "All-Libraries") || ($Library == $lib)} {
				sal_print_log "cleanup $lib"
				sal_clean_lib $lib
			}
		}
	}
	namespace export clean_libraries
	
	# Compile source files
	#
	# Variable Arguments:
	# -all				Compile all source files
	# -lib <name>		Only compile this library
	# -tag <name>		Only compile files with this tag
	# -clean			Clean libraries before compiling
	# -contains <str>	Compile only if path to the file contains a given string
	proc compile {args} {
		#Parse Arguments
		set Library "All-Libraries"
		set Tag "All-Tags"
		set argList [split $args]
		set clean false
		set contains "All-regex"
		set i 0		
		while {$i < [llength $argList]} {
			set thisArg [lindex $argList $i]
			if {$thisArg == "-all"} {
				set Library "All-Libraries"
			} elseif {$thisArg == "-lib"} {
				set i [expr $i + 1]
				set thisArg [lindex $argList $i]
				set Library $thisArg
			} elseif {$thisArg == "-clean"} {
				set clean true
			} elseif {$thisArg == "-tag"} {
				set i [expr $i + 1]
				set thisArg [lindex $argList $i]
				set Tag $thisArg
			} elseif {$thisArg == "-contains"} {
				set i [expr $i + 1]
				set thisArg [lindex $argList $i]
				set contains $thisArg			
			} else {
				sal_print_log "WARNING: ignored argument $thisArg"
				sal_print_log ""
			}
			set i [expr $i + 1]
		}
		#Clean if required
		if {$clean} {
			clean_libraries -lib $Library
		}
		#Compile
		variable CompileSuppress 
		variable Sources
		foreach file $Sources {
			set thisFileLib [dict get $file LIBRARY]
			set thisFileTag [dict get $file TAG]
			set thisFilePath [dict get $file PATH]
			set thisFileLanguage [dict get $file LANGUAGE]
			set thisFileVersion [dict get $file VERSION]
			set thisFileOptions [dict get $file OPTIONS]
			if {($Library != "All-Libraries") && ($Library != $thisFileLib)} {
				continue
			}
			if {($Tag != "All-Tags") && ($Tag != $thisFileTag)} {
				continue
			}
			if {($contains != "All-regex") && ([string first $contains $thisFilePath] == -1)} {
				continue
			}
			#Execute compilation
			sal_print_log "$thisFileLib - Compile [file tail $thisFilePath]"
			sal_compile_file $thisFileLib $thisFilePath $thisFileLanguage $thisFileVersion $thisFileOptions
		}
	}
	#Wrapper to prevent name clash with modelsim "compile"
	proc compile_files {args} {
		set jonedArgs [join $args]
		eval "compile $jonedArgs"
	}
	namespace export compile_files
	
	# Creat a testbench run. A testbench run consists of a pre-script (run before TB), a post script (ran after TB) and optionally
	# different arguments to pass to the TB for multiple simulations. 
	# Note that the TB run is only added with the separate command add_tb_run
	#
	# @param tb			Name of the testbench to run
	# @param library	Name of the library the testbench is in. This parameter is optional, if it
	#					is omitted, it is assumed the TB is in the last library created with add_library 
	proc create_tb_run {tb {library "None"}} {
	
		#Select tb library
		variable CurrentLib
		set tbLib $library
		if {$tbLib == "None"} {
			set tbLib $CurrentLib
		}	
		#Implementation
		variable ThisTbRun [dict create]
		dict set ThisTbRun TB_NAME $tb
		dict set ThisTbRun TB_LIB $tbLib
		dict set ThisTbRun TB_ARGS [list ""]
		dict set ThisTbRun PRESCRIPT_CMD ""
		dict set ThisTbRun PRESCRIPT_PATH "."
		dict set ThisTbRun PRESCRIPT_ARGS ""
		dict set ThisTbRun POSTSCRIPT_CMD ""
		dict set ThisTbRun POSTSCRIPT_PATH "."
		dict set ThisTbRun POSTSCRIPT_ARGS ""	
		dict set ThisTbRun TIME_LIMIT "None"
        dict set ThisTbRun SKIP "None"
	}
	namespace export create_tb_run
	
	# Add a pre-script to the last TB run created with create_tb_run. It must be called between create_tb_run and add_tb_run.
	#
	# @param cmd		Command for the pre-script
	# @param args		Arguments to pass to the command
	# @param path		Working directory to execute the command in
	proc tb_run_add_pre_script {{cmd ""} {args ""} {path ""}} {
		variable ThisTbRun
		dict set ThisTbRun PRESCRIPT_CMD $cmd
		dict set ThisTbRun PRESCRIPT_ARGS $args
		if {$path != ""} {
			dict set ThisTbRun PRESCRIPT_PATH [file normalize $path]
		}
	}
	namespace export tb_run_add_pre_script
	
	# Add a post-script to the last TB run created with create_tb_run. It must be called between create_tb_run and add_tb_run.
	#
	# @param cmd		Command for the post-script
	# @param args		Arguments to pass to the command
	# @param path		Working directory to execute the command in	
	proc tb_run_add_post_script {{cmd ""} {args ""} {path ""}} {
		variable ThisTbRun
		dict set ThisTbRun POSTSCRIPT_CMD $cmd
		dict set ThisTbRun POSTSCRIPT_ARGS $args
		if {$path != ""} {
			dict set ThisTbRun POSTSCRIPT_PATH [file normalize $path]
		}
	}	
	namespace export tb_run_add_post_script
	
	# Specify different arguments set (e.g. generic values) to execute the TB for. It must be called between create_tb_run and add_tb_run.
	#
	# @param args		List of argument strings in the form "stringa" "stringB"
	proc tb_run_add_arguments {args} {
		variable ThisTbRun
		dict set ThisTbRun TB_ARGS $args
	}
	namespace export tb_run_add_arguments
	
	# Specify an end-time for a tb-run. Usually testbenches should stop on their own but in some cases (e.g. if Xilinx primitives do keep the simulation running and run -all is not workgin),
	# it may be required to limit the runtime.
	#
	# @param limit		Time limit in the form "100 us"
	proc tb_run_add_time_limit {limit} {
		variable ThisTbRun
		dict set ThisTbRun TIME_LIMIT $limit
	}
	namespace export tb_run_add_time_limit
    
    # Skip this testbench for one or all simulators
    #
    # @param simulator  Simulator to skip the TB for (use "GHDL", "Modelsim" or "all")
    proc tb_run_skip {{simulator "all"}} {
        variable ThisTbRun
        dict set ThisTbRun SKIP $simulator
    }
    namespace export tb_run_skip
	
	# This command must be called when a TB run created with create_tb_run is fully specified and can be added. The TB run cannot be modified after
	# this command is called
	proc add_tb_run {} {
		variable TbRuns
		variable ThisTbRun
		lappend TbRuns $ThisTbRun; list
	}
	namespace export add_tb_run
	
	# Internal Function
	proc clean_transcript {} {
		sal_clean_transcript
	}
	
	# Check if the transcript file contains a specific error string. Note that the string "Fatal:" is also interpreted as error.
	#
	# @param errorString	Error string to search for (should be included in all error messages)
	proc run_check_errors {errorString} {
		#Read transcript
		sal_transcript_off
		set transcriptFile [open "./Transcript.transcript" r]
		set transcriptContent [read "$transcriptFile"]; list
		close $transcriptFile
		#Suppress the command call from analysis
		regsub -all -linestop {.*run_check_errors.*} $transcriptContent "" transcriptContent		
		#Search for string
		set found [regexp -nocase $errorString $transcriptContent]
		set foundFatal [regexp -nocase {Fatal:} $transcriptContent]
		sal_print_log $found
		sal_print_log $foundFatal
		if {($found == 1) || ($foundFatal == 1)} {
			sal_print_log "!!! ERRORS OCCURED IN SIMULATIONS !!!"		
		} else {
			sal_print_log "SIMULATIONS COMPLETED SUCCESSFULLY"
		}
	}
	namespace export run_check_errors
	
	# Run one or more testbenches. The transcript is cleaned automatically before running the tesbenches. Pre- and Post-Scripts 
	# executed automatically if they were specified.
	#
	# Variable Arguments:
	# -all				Run all testbenches
	# -lib <name>		Only run testbenches in this library
	# -name <name>		Only run testbench with this name
	# -contains <str>	Run only if testbench name contains a given string
	#
	# Note that -lib and -name can be combined to choose one specific testbench	
	proc run_tb {args} {
		
		#Parse Arguments
		set Library "All-Libraries"
		set Name "All-Names"
		set contains "All-regex"
		set argList [split $args]
		set i 0		
		while {$i < [llength $argList]} {
			set thisArg [lindex $argList $i]
			if {$thisArg == "-all"} {
				set Library "All-Libraries"
				set Name "All-Names"
			} elseif {$thisArg == "-lib"} {
				set i [expr $i + 1]
				set thisArg [lindex $argList $i]
				set Library $thisArg
			} elseif {$thisArg == "-name"} {
				set i [expr $i + 1]
				set thisArg [lindex $argList $i]
				set Name $thisArg
			} elseif {$thisArg == "-contains"} {
				set i [expr $i + 1]
				set thisArg [lindex $argList $i]
				set contains $thisArg
			} else {
				sal_print_log "WARNING: ignored argument $thisArg"
				sal_print_log ""
			}
			set i [expr $i + 1]
		}
		#Clean Transcript
		clean_transcript
		#Run
		variable TbRuns
		variable RunSuppress
		variable Simulator
		foreach run $TbRuns {
			#Check if TB should be run
			set runLib [dict get $run TB_LIB]
			set runName [dict get $run TB_NAME]
			set skip [dict get $run SKIP]
			if {($runLib != $Library) && ($Library != "All-Libraries")} {
				continue
			}
			if {($runName != $Name) && ($Name != "All-Names")} {
				continue
			}
			if {($contains != "All-regex") && ([string first $contains $runName] == -1)} {
				continue
			}
			sal_print_log ""
			sal_print_log "******************************************************"
			sal_print_log "*** Run $runLib.$runName"
			sal_print_log "******************************************************"
            if {([lsearch $skip $Simulator] != -1) || ($skip == "all")} {
                sal_print_log "!!! Skipped for '$skip' !!!"
                continue
            }
		
			#Execute pre-script if required
			set PsCmd [dict get $run PRESCRIPT_CMD]
			set PsPath [dict get $run PRESCRIPT_PATH]
			set PsArgs [dict get $run PRESCRIPT_ARGS]
			if {($PsCmd != "")} {
				sal_exec_script $PsPath $PsCmd $PsArgs
			}
			
			#Execute TB for all arguments
			sal_print_log "Running Simulation"
			set allArgLists [dict get $run TB_ARGS]
			set timeLimit [dict get $run TIME_LIMIT]
			foreach tbArgs $allArgLists {
				#Tun TB
				sal_run_tb $runLib $runName $tbArgs $timeLimit $RunSuppress
			}
			#Execute pre-script if required
			set PsCmd [dict get $run POSTSCRIPT_CMD]
			set PsPath [dict get $run POSTSCRIPT_PATH]
			set PsArgs [dict get $run POSTSCRIPT_ARGS]
			if {($PsCmd != "")} {
				sal_exec_script $PsPath $PsCmd $PsArgs
			}		
			
		}
		sal_transcript_off
	}
	namespace export run_tb	
	
	# Launch a testbench and keep the simulator window open for interactive debugging. Because this is meant for
	# interactive debugging and not for regression test, neither pre- nor post-scripts are ran.
	# By default, the TB is run with the default generic values from the sources. Alternatively the user can choose
	# the generics combination to used (if specified with tb_run_add_arguments).
	# The test-run is only launched but not executed. Execution is controlled interactively.
	#
	# Variable Arguments:
	# -contains <str>	Run only if testbench name contains a given string (required!)
	# -argidx   <int>	Index of the arguments from tb_run_add_arguments (0 = use first argument-list)
	#
	# Note that currently this command is only supported for Modelsim
	proc launch_tb {args} {
	
		#Only Modelsim is supported currently for this debug command
		variable Simulator
		if {($Simulator != "Modelsim") && ($Simulator != "GHDL")} {
			sal_print_log "ERROR: launch_tb: this command is only implemented for Modelsim and GHDL"
			return
		}	

		#Parse Arguments
		set contains "All-regex"
		set argidx "default"
		set wave ""
		set show ""
		set argList [split $args]
		set i 0		
		while {$i < [llength $argList]} {
			set thisArg [lindex $argList $i]
			if {$thisArg == "-contains"} {
				set i [expr $i + 1]
				set thisArg [lindex $argList $i]
				set contains $thisArg
			} elseif {$thisArg == "-argidx"} {
				set i [expr $i + 1]
				set thisArg [lindex $argList $i]
				set argidx $thisArg
			} elseif {$thisArg == "-wave"} {
				set i [expr $i + 1]
				set thisArg [lindex $argList $i]
				if {$thisArg == ""} {
					set wave "all"
				} elseif {$thisArg == "-show"} {  
					set wave "all"
					set show "enable"
				} else {  
					set wave $thisArg
				}
			} elseif {$thisArg == "-show"} {
				set show "enable"
			} else {
				sal_print_log "WARNING: ignored argument $thisArg"
				sal_print_log ""
			}
			set i [expr $i + 1]
		}

		#Check Arguments
		if {$contains == "All-regex"} {
			sal_print_log "ERROR: launch_tb: -contains argument is required"
			return
		}
		
		#Launch
		variable TbRuns
		variable RunSuppress
		foreach run $TbRuns {
			#Check if TB should be run
			set runLib [dict get $run TB_LIB]
			set runName [dict get $run TB_NAME]
			set skip [dict get $run SKIP]
			set allArgLists [dict get $run TB_ARGS]
			if {[string first $contains $runName] == -1} {
				continue
			}
			sal_print_log ""
			sal_print_log "******************************************************"
			sal_print_log "*** Launch $runLib.$runName"
			sal_print_log "******************************************************"

			#Check if this TB run is not skipped
			if {([lsearch $skip $Simulator] != -1) || ($skip == "all")} {
				sal_print_log "!!! Skipped for '$skip' !!!"
				continue
			}

			#Get argument set
			set argListLength [llength $allArgLists]
			if {$argidx == "default"} {
				set argsToUse ""
			} elseif {$argidx >= $argListLength} {
				set maxIdx [expr $argListLength-1]
				sal_print_log "ERROR: launch_tb: -argidx out of range 0 ... $maxIdx"
				return
			} else {
				set argsToUse [lindex $allArgLists $argidx]
			}
					
			#Execute TB for arguments chosen
			sal_print_log "Launching Simulation"
			if {"Modelsim" == $Simulator} {
				#Modelsim -> launch TB
				sal_launch_tb $runLib $runName $argsToUse $RunSuppress $wave
			}	
			if {"GHDL" == $Simulator} {
				set timeLimit [dict get $run TIME_LIMIT]
				if {$wave != ""} {
					set wave "$runName\_$argidx\.ghw"
					sal_print_log "Writing Waveform: $wave"
				} 
				#GHDL -> run TB
				sal_run_tb $runLib $runName $argsToUse $timeLimit $RunSuppress $wave
				if {$show == "enable"} {
					sal_open_wave $wave
				}
			}

			#Only do one TB, return after it was quit
			return			
		}
		
		#If we arrive here, no TB matched to -contains string
		sal_print_log "ERROR: launch_tb: -contains <str> did not match any tb_runs!"
	}
	namespace export launch_tb	
}
