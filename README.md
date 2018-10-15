# General Information

## Maintainer
Oliver Bründler [oliver.bruendler@psi.ch]

## Authors
Oliver Bründler [oliver.bruendler@psi.ch]

## License
This library is published under [PSI HDL Library License](License.txt), which is [LGPL](LGPL2_1.txt) plus some additional exceptions to clarify the LGPL terms in the context of firmware development.

## Changelog
See [Changelog](Changelog.md)

## Commands
See [Command Reference](CommandRef.md)

## Features
This TCL framework allows easily creating regression tests using modelsim. Files or groups of files can
be compiled by a single command, full regression tests can be run easily and results of testbenches can be 
parsed automatically.

In contrast to modelsim projects, simulation scripts written using this TCL package are version control friendly and
easily mergable.

The framework allows running the same simulations using either Modelsim or GHDL. See [Command Reference](CommandRef.md) for details.

## Usage
Usually two files are written to describe simulations for a set of VHDL files. 

One file is the configuration file (*config.tcl*)
and it describes what files, testbenches and runs (testbench with generics and possibly pre- or post-scripts) shall be simulated.

The other file is the fun file (*run.tcl*) that can be ran from modelsim console and automatically compile and execute
all required simulations.

The splitting into two files is very useful since it allows nesting. For example each library can have its *config.tcl* and
its *run.tcl*. If one only works on the library, the *run.tcl* of the library can be executed. If one uses the library in a 
project, the project *run.tcl* can call the *config.tcl* of the library to include all tests of the library into the project
regression test.

## Tagging Policy
Stable releases are tagged in the form *major*.*minor*.*bugfix*. 

* Whenever a change is not fully backward compatible, the *major* version number is incremented
* Whenever new features are added, the *minor* version number is incremented
* If only bugs are fixed (i.e. no functional changes are applied), the *bugfix* version is incremented

# Examples

## Example Configuration Script (config.tcl)
```
#Constants
set LibPath "../.."

#Import psi::sim library
namespace import psi::sim::*

#Set library
add_library psi_common

#suppress messages
compile_suppress 135,1236
run_suppress 8684,3479,3813,8009,3812

# psi_tb_v1_0	
add_sources "$LibPath/psi_tb/hdl" {
	psi_tb_txt_util.vhd \
} -tag lib

# Library
add_sources $LibPath {
	psi_tb/hdl/psi_tb_txt_util.vhd \
	psi_tb/hdl/psi_tb_compare_pkg.vhd \
} -tag lib

# project sources
add_sources "../hdl" {
	psi_common_array_pkg.vhd \
	psi_common_math_pkg.vhd \
	psi_common_logic_pkg.vhd \
	psi_common_numeric_std_extension_pkg.vhd \
	psi_common_pulse_cc.vhd \
	psi_common_simple_cc.vhd \
	psi_common_status_cc.vhd \
	psi_common_tdp_ram_rbw.vhd \
	psi_common_sync_fifo.vhd \
	psi_common_async_fifo.vhd \
} -tag src

# testbenches
add_sources "../testbench" {
	psi_common_simple_cc_tb/psi_common_simple_cc_tb.vhd \
	psi_common_status_cc_tb/psi_common_status_cc_tb.vhd \
	psi_common_sync_fifo_tb/psi_common_sync_fifo_tb.vhd \
	psi_common_async_fifo_tb/psi_common_async_fifo_tb.vhd \
	psi_common_logic_pkg_tb/psi_common_logic_pkg_tb.vhd \
} -tag tb
	
#TB Runs
create_tb_run "psi_common_simple_cc_tb"
tb_run_add_arguments \
	"-gClockRatio_g=3" \
	"-gClockRatio_g=1.01" \
	"-gClockRatio_g=0.99" \
	"-gClockRatio_g=0.3"
add_tb_run

create_tb_run "psi_common_status_cc_tb"
tb_run_add_arguments \
	"-gClockRatio_g=3" \
	"-gClockRatio_g=1.01" \
	"-gClockRatio_g=0.99" \
	"-gClockRatio_g=0.3"
add_tb_run

create_tb_run "psi_common_sync_fifo_tb"
tb_run_add_arguments \
	"-gAlmFullOn_g=true -gAlmEmptyOn_g=true -gDepth_g=32" \
	"-gAlmFullOn_g=false -gAlmEmptyOn_g=false -gDepth_g=128"
add_tb_run

create_tb_run "psi_common_async_fifo_tb"
tb_run_add_arguments \
	"-gAlmFullOn_g=true -gAlmEmptyOn_g=true -gDepth_g=32" \
	"-gAlmFullOn_g=false -gAlmEmptyOn_g=false -gDepth_g=128"
add_tb_run

create_tb_run "psi_common_logic_pkg_tb"
add_tb_run
```

## Example Execution Script (run.tcl)  
```
#Load dependencies
source ../../../TCL/PsiSim/PsiSim.tcl

#Import psi::sim library
namespace import psi::sim::*

#Initialize Simulation
init

#Configure
source ./config.tcl

#Run Simulation
puts "------------------------------"
puts "-- Compile"
puts "------------------------------"
compile_files -all -clean
puts "------------------------------"
puts "-- Run"
puts "------------------------------"
run_tb -all
puts "------------------------------"
puts "-- Check"
puts "------------------------------"

run_check_errors "###ERROR###"

``` 


