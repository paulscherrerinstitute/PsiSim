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
# An example on how to use the package can be found here:
# G\GPAC\Board\GPAC3_0\BPM_FPGA\SLS_DBPM3\IP_Repo\sls_dwc_1.0\sim

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
	variable TranscriptFile
	
	#################################################################
	# Tool abstraction functions (not exported)
	#################################################################
	proc print_log {text} {
		variable Simulator
		variable TranscriptFile
		if {$Simulator == "Modelsim"} {
			echo $text
		} elseif {$Simulator == "GHDL"} {
			#Console
			puts $text
			#Transcript
			set fo [open $TranscriptFile a]
			puts $fo $text
			close $fo
			
		}
	}
	
	proc transcript_off {} {
		variable Simulator
		if {$Simulator == "Modelsim"} {
			transcript off
		}
	}
	
	proc transcript_on {} {
		variable Simulator
		if {$Simulator == "Modelsim"} {
			transcript on
		}
	}
	
	proc transcript_file {filename} {
		variable Simulator
		if {$Simulator == "Modelsim"} {
			transcript file $filename
		} 
		variable TranscriptFile [file normalize $filename]
	}	

	#################################################################
	# Interface Functions (exported)
	#################################################################	
	# Initialize PSI Simulation Package. This must be called as first command to use the library.
	#
	# -ghdl		Use GHDL instead of modelsim (modelsim is default)
	proc init {args} {
		set argList [split $args]
		set simulatorType "Modelsim"
		set i 0		
		while {$i < [llength $argList]} {
			set thisArg [lindex $argList $i]
			if {$thisArg == "-ghdl"} {
				set simulatorType "GHDL"
			} else {
				print_log "WARNING: ignored argument $thisArg"
				print_log ""
			}
			set i [expr $i + 1]
		}
		variable Simulator $simulatorType
		variable Libraries [list]
		variable Sources [list]
		variable TbRuns [list]
		variable CompileSuppress ""
		variable RunSuppress ""
		variable CurrentLib "NoCurrentLibrary"
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
				print_log "WARNING: ignored argument $thisArg"
				print_log ""
			}
			set i [expr $i + 1]
		}
		#Add files
		variable Sources
		foreach file $files {
			set path [file normalize [concat $directory/$file]]
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
					print_log "WARNING: file $ePath already added to library $eLib" 
				}
			}
			lappend Sources $ThisSrc
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
				print_log "WARNING: ignored argument $thisArg"
				print_log ""
			}
			set i [expr $i + 1]
		}	
		#Clean
		variable Libraries
		variable Simulator
		foreach lib $Libraries {
			if {($Library == "All-Libraries") || ($Library == $lib)} {
				print_log "cleanup $lib"
				if {$Simulator == "Modelsim"} {
					vlib $lib
					vdel -all -lib $lib
					vlib $lib
				} elseif {$Simulator == "GHDL"} {
					file delete -force $lib
					file mkdir $lib
				}
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
				print_log "WARNING: ignored argument $thisArg"
				print_log ""
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
		variable Simulator
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
			print_log "$thisFileLib - Compile [file tail $thisFilePath]"
			if {$Simulator == "Modelsim"} {
				set args "-work $thisFileLib -novopt -suppress $CompileSuppress $thisFileOptions -quiet $thisFilePath"
				if {$thisFileLanguage == "vhdl"} {
					lappend args "-$thisFileVersion"
					vcom {*}$args
				} else {
					lappend args "-incr"
					vlog {*}$args
				}
			} elseif {$Simulator == "GHDL"} {
				if {$thisFileLanguage == "vhdl"} {
					exec ghdl -a --std=08 -frelaxed-rules -Wno-shared --work=$thisFileLib $thisFilePath
				} else {
					print_log "ERROR: Verilog currently not supported for GHDL"
					print_log ""
				}
			}
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
		variable Simulator
		transcript_off
		if {$Simulator == "GHDL"} {
			file delete ./Transcript.transcript
			transcript_file ./Transcript.transcript
			return
		} elseif {$Simulator == "Modelsim"} {
			transcript_file ./Dummy.transcript
			set bm [batch_mode]
			if {$bm == 0} {
				file delete ./Transcript.transcript
			}
			transcript_file ./Transcript.transcript
			file delete ./Dummy.transcript
		}
		transcript_on
	}
	
	# Check if the transcript file contains a specific error string. Note that the string "Fatal:" is also interpreted as error.
	#
	# @param errorString	Error string to search for (should be included in all error messages)
	proc run_check_errors {errorString} {
		#Read transcript
		transcript_off
		set transcriptFile [open "./Transcript.transcript" r]
		set transcriptContent [read "$transcriptFile"]; list
		close $transcriptFile
		#Suppress the command call from analysis
		regsub -all -linestop {.*run_check_errors.*} $transcriptContent "" transcriptContent		
		#Search for string
		set found [regexp -nocase $errorString $transcriptContent]
		set foundFatal [regexp -nocase {Fatal:} $transcriptContent]
		print_log $found
		print_log $foundFatal
		if {($found == 1) || ($foundFatal == 1)} {
			print_log "!!! ERRORS OCCURED IN SIMULATIONS !!!"		
		} else {
			print_log "SIMULATIONS COMPLETED SUCCESSFULLY"
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
				print_log "WARNING: ignored argument $thisArg"
				print_log ""
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
			if {($runLib != $Library) && ($Library != "All-Libraries")} {
				continue
			}
			if {($runName != $Name) && ($Name != "All-Names")} {
				continue
			}
			if {($contains != "All-regex") && ([string first $contains $runName] == -1)} {
				continue
			}
			print_log ""
			print_log "******************************************************"
			print_log "*** Run $runLib.$runName"
			print_log "******************************************************"
		
			#Execute pre-script if required
			set PsCmd [dict get $run PRESCRIPT_CMD]
			set PsPath [dict get $run PRESCRIPT_PATH]	
			set PsArgs [dict get $run PRESCRIPT_ARGS]				
			if {($PsCmd != "")} {
				set oldPath [pwd]
				cd $PsPath
				print_log "Running Pre Script"
				if {$Simulator == "Modelsim"} {
					print_log [exec $PsCmd $PsArgs]
				} elseif {$Simulator == "GHDL"} {
					set outp [exec $PsCmd $PsArgs]
					print_log $outp
				}
				cd $oldPath
			}
			#Execute TB for all arguments
			print_log "Running Simulation"
			set allArgLists [dict get $run TB_ARGS]
			set timeLimit [dict get $run TIME_LIMIT]
			foreach tbArgs $allArgLists {
				#The set/eval combination is a workaroudn for problems of modelsim with argument parsing...
				set supp ""
				if {$RunSuppress != ""} {
					set supp +nowarn$RunSuppress
				}
				if {$Simulator == "Modelsim"} {
					set cmd "vsim -quiet -t 1ps $supp $runLib.$runName $tbArgs"
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
						print_log "Stop $timeLimit"
						set stopTime " --stop-time=[string map {" " ""} $timeLimit]"
					} else {
						set stopTime ""
					}
					set cmd "ghdl --elab-run --std=08 -frelaxed-rules -Wno-shared --work=$runLib $runName$tbArgs$stopTime --ieee-asserts=disable "
					print_log $cmd
					set outp [eval "exec $cmd"]
					print_log $outp
				}				
			}
			#Execute pre-script if required
			set PsCmd [dict get $run POSTSCRIPT_CMD]
			set PsPath [dict get $run POSTSCRIPT_PATH]	
			set PsArgs [dict get $run POSTSCRIPT_ARGS]				
			if {($PsCmd != "")} {
				set oldPath [pwd]
				cd $PsPath
				print_log "Running Post Script"
				if {$Simulator == "Modelsim"} {
					print_log [exec $PsCmd $PsArgs]
				} elseif {$Simulator == "GHDL"} {
					set outp [exec $PsCmd $PsArgs]
					print_log $outp
				}
				cd $oldPath
			}		
			
		}
		transcript_off
	}
	namespace export run_tb	
}