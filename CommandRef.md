# Command Reference
**All commands are in the namespace psi::sim**, so either a fully qualified name (psi::sim::<my command>) must 
be used to access them or the namespace psi::sim must be imported (see example in [README](README.md)).

Beroe using the commands, type the following line in modelsim to import the commands into the golbal workspace:
```
namespace import psi::sim::*
```


# Command Links
* General Commands
  * [init](#init)  
* Configuration Commands
  * [add_library](#add_library)  
  * [add_sources](#add_sources)  
  * [create_tb_run](#create_tb_run)  
  * [add_tb_run](#add_tb_run)  
  * [tb_run_add_arguments](#tb_run_add_arguments)  
  * [tb_run_add_time_limit](#tb_run_add_time_limit)  
  * [tb_run_add_pre_script](#tb_run_add_pre_script)  
  * [tb_run_add_post_script](#tb_run_add_post_script)  
  * [tb_run_skip](#tb_run_skip)  
  * [compile_suppress](#compile_suppress)  
  * [run_suppress](#run_suppress)  
* Run Commands
  * [clean_libraries](#clean_libraries)
  * [compile_files](#compile_files)
  * [run_tb](#run_tb)
  * [run_check_errors](#run_check_errors)
  * [launch_tb](#launch_tb)

## General Commands

### init
**Usage**
```
init [-ghdl|-vivado]
```

**Description**  
This command clears the PSI simulation environment. This means all libraries,
testbenches and files added are removed. As a result this command should be called
once in every script before using any other commands.

**Parameters**  
<table>
    <tr>
      <th width="200"><b>Parameter</b></th>
      <th align="center" width="80"><b>Optional</b></th>
      <th align="right"><b>Description</b></th>
    </tr>
    <tr>
      <td> -ghdl </td>
      <td> Yes </td>
      <td> Use GHDL instead of Modelsim (if the parameter is not given, Modelsim is used). For Modelsim, all commands must be executed in the Modelsim TCL shell. For GHDL, a standalone TCL shell (e.g. Active TCL) must be used </td>
    </tr>
    <tr>
      <td> -vivado </td>
      <td> Yes </td>
      <td> Use Vivado Simulator instead of Modelsim (if the parameter is not given, Modelsim is used). All commands must be executed in the Vivado TCL shell. </td>
    </tr>
</table>

## Configuration Commands

### add_library
**Usage**
```
add_library <lib>
```

**Description**  
Adds a library to the simultion project. At least one library must be specified
since there is no library to compile files into otherwise.

**Parameters**  
<table>
    <tr>
      <th width="200"><b>Parameter</b></th>
      <th align="center" width="80"><b>Optional</b></th>
      <th align="right"><b>Description</b></th>
    </tr>
    <tr>
      <td> lib </td>
      <td> No </td>
      <td> Name of the library to create  </td>
    </tr>
</table>

### add_sources
**Usage**
```
add_sources <directory> <file> [-lib <lib>] [-tag <tag>] [-language <lang>] [-version <ver>] [-options <cmd>]
```

**Description**  
Adds one or more source files. All source files added are compiled outomatically 
in the order they are added (i.e. files must be added in compile order). Files
are not compiled when they are added but when the [psi::sim::compile](#psisimcompile) command is called.

Multiple files from the same directory can be added with one call of the command. This
is also shown in the example code in the main [README.md](README.md).

**Parameters**
<table>
    <tr>
      <th width="200"><b>Parameter</b></th>
      <th align="center" width="80"><b>Optional</b></th>
      <th align="right"><b>Description</b></th>
    </tr>
    <tr>
      <td> directory </td>
      <td> No </td>
      <td> Directory the file(s) to add is/are in </td>
    </tr>
    <tr>
      <td> file </td>
      <td> No </td>
      <td> Name of one or more files to add     </td>    
    </tr>
    <tr>
      <td> lib </td>
      <td> Yes </td>
      <td> Library to compile the file into. If no library is given, the file is 
           compiled into the last library added using the <i>add_library</i> command </td>    
    </tr>   
    <tr>
      <td> tag </td>
      <td> Yes </td>
      <td> Tags are optional and can be use to selectively only compile files with the same tag. </td>    
    </tr>  
    <tr>
      <td> lang </td>
      <td> Yes </td>
      <td> By default VHDL is assumed as language. By passing <i>-lang verilog</i>, verilog
           files can be integrated. However, the verilog support is only roughly tested. </td>    
    </tr>    
    <tr>
      <td> ver </td>
      <td> Yes </td>
      <td> By default VHDL files are compiled with version 2008. If any other version is desired pass it as argument. 2008|2002|93|87| </td>    
    </tr>    
    <tr>
      <td> cmd </td>
      <td> Yes </td>
      <td> Additional Modelsim commands can be passed as a string with the options switch. E.g. a macro for a Verilog manufacturer model <i>-options +define+MacroName</i> </td>    
    </tr>        
</table>

### create_tb_run
**Usage**
```
create_tb_run <tb> [<lib>] 
```

**Description**  
Create a testbench run. A testbench run consists of the testbench to execute (mandatory) and optionally
different arguments to pass to the simulation as well as scripts to execute before and after the run. If different
arguments are passed to the simulation, the scripts are ran only once befor/after all simulations with different arguments
and not before/after each simulation.

Note that the TB-run is only added to the project with the [add_tb_run](#add_tb_run) command.

**Parameters**
<table>
    <tr>
      <th width="200"><b>Parameter</b></th>
      <th align="center" width="80"><b>Optional</b></th>
      <th align="right"><b>Description</b></th>
    </tr>
    <tr>
      <td> tb </td>
      <td> No </td>
      <td> Name of the testbench to execute </td>
    </tr>
    <tr>
      <td> lib </td>
      <td> Yes </td>
      <td> Library the testbench is in. If no library is given, the last library added using the <i>add_library</i> 
           is used. </td>    
    </tr>         
</table>

### add_tb_run
**Usage**
```
add_tb_run
```

**Description**  
Add the last TB-run created using [create_tb_run](#create_tb_run) to the project. Optionally the TB run can be configured 
between these two commands (e.g. using [tb_run_add_arguments](#tb_run_add_arguments)).

Note that it is possible to add multiple runs for the same testbench (e.g. with different pre- and post-scripts).

**Parameters**  
Nonte

### tb_run_add_arguments
**Usage**
```
tb_run_add_arguments <arguments>
```

**Description**  
This command allows defining additional arguments to pass to the *vsim* command of modelsim. Details can be found
in the modelsim documentation but one useful argument is the *-gMyGeneric=MyValue* option to set generics. If a list 
of strings is passed, the simulation is executed once for each argument string. So this command is ideal to run a 
testbench with different sets of generics.

The command must be called between the [create_tb_run](#create_tb_run) and the [add_tb_run](#add_tb_run) commands.

**Parameters**
<table>
    <tr>
      <th width="200"><b>Parameter</b></th>
      <th align="center" width="80"><b>Optional</b></th>
      <th align="right"><b>Description</b></th>
    </tr>
    <tr>
      <td> arguments </td>
      <td> No </td>
      <td> String or list of strings to be passed to the simulation run(s) </td>
    </tr>
</table>

### tb_run_add_time_limit
**Usage**
```
tb_run_add_time_limit <limit>
```

**Description**  
Specify an end-time for a tb-run. Usually testbenches should stop on their own but in some cases (e.g. if Xilinx primitives do keep the simulation running and run -all is not workgin), it may be required to limit the runtime.

The command must be called between the [create_tb_run](#create_tb_run) and the [add_tb_run](#add_tb_run) commands.

**Parameters**
<table>
    <tr>
      <th width="200"><b>Parameter</b></th>
      <th align="center" width="80"><b>Optional</b></th>
      <th align="right"><b>Description</b></th>
    </tr>
    <tr>
      <td> limit </td>
      <td> No </td>
      <td> Timelimit in the form "100 us" (the double-quotes are important) </td>
    </tr>
</table>

### tb_run_add_pre_script
**Usage**
```
tb_run_add_pre_script <cmd> [<args>] [<path>]
```

**Description**  
This command allows defining a script to be executed at the beginning of the TB-run.

The command must be called between the [create_tb_run](#create_tb_run) and the [add_tb_run](#add_tb_run) commands.

**Parameters**
<table>
    <tr>
      <th width="200"><b>Parameter</b></th>
      <th align="center" width="80"><b>Optional</b></th>
      <th align="right"><b>Description</b></th>
    </tr>
    <tr>
      <td> cmd </td>
      <td> No </td>
      <td> Command to execute </td>
    </tr>
    <tr>
      <td> args </td>
      <td> Yes </td>
      <td> Arguments to pass to the command (by default no arguments are passed) </td>
    </tr>	
    <tr>
      <td> path </td>
      <td> Yes </td>
      <td> Working directory to call the command from (by default the simulation directory is used) </td>
    </tr>	
</table>

### tb_run_add_post_script  
This command is equal to [tb_run_add_pre_script](#tb_run_add_pre_script) but the script is executed
after the simulations.

### tb_run_skip
**Usage**
```
tb_run_skip [<simulator>]
```

**Description**  
This command allows skipping the testbench for all simulators or only for one simulator. This can be used if bugs in a simulator tool lead to crashes.

The command must be called between the [create_tb_run](#create_tb_run) and the [add_tb_run](#add_tb_run) commands.

For skipping a run for multiple simulators, use teh form *tb_run_skip "Vivado Ghdl"*.

**Parameters**
<table>
    <tr>
      <th width="200"><b>Parameter</b></th>
      <th align="center" width="80"><b>Optional</b></th>
      <th align="right"><b>Description</b></th>
    </tr>
    <tr>
      <td> simulator </td>
      <td> Yes </td>
      <td> Simulator to skip simulation for. Use **all**, **Modelsim** or **GHDL** </td>
    </tr>		
</table>

### compile_suppress
**Usage**
```
compile_suppress <msgNos> 
```

**Description**  
This command allows to suppress one or more warning messages during compilation. For suppression of warning messages
during simulations, use [run_suppress](#run_suppress).

**Parameters**
<table>
    <tr>
      <th width="200"><b>Parameter</b></th>
      <th align="center" width="80"><b>Optional</b></th>
      <th align="right"><b>Description</b></th>
    </tr>
    <tr>
      <td> msgNos </td>
      <td> No </td>
      <td> One or more message numbers to suppress. Multiple message numbers must be delimited using a comma. </td>
    </tr>
</table>

### run_suppress  
This command is equal to [compile_suppress](#compile_suppress) but the messages are suppressed
during simulations instead of compilation.


## Run Commands

### clean_libraries
**Usage**
```
clean_libraries [-all] [-lib <lib>] 
```

**Description**  
This command cleans either one specific libraries or all libraries. Cleaning means all contents are deleted,
so entities compiled earlier are no more visible.

**Parameters**
<table>
    <tr>
      <th width="200"><b>Parameter</b></th>
      <th align="center" width="80"><b>Optional</b></th>
      <th align="right"><b>Description</b></th>
    </tr>
    <tr>
      <td> -all </td>
      <td> Yes </td>
      <td> All libraries in the project are cleaned. </td>
    </tr>
    <tr>
      <td> lib </td>
      <td> Yes </td>
      <td> Name of one specific library to clean. Passing no library has the same effect as using -all (i.e.
		   all libraries are cleaned). </td>
    </tr>
</table>

### compile_files
**Usage**
```
compile_files [-all] [-lib <lib>] [-tag <tag>] [-contains <str>] [-clean]
```

**Description**  
This command compiles source files. Depending on the arguments, either all files or only a selection of 
themare compiled. Optionally the All libraries can be cleaned prior to compilation.

Note that the command is also available as *psi::sim::compile* but this name is not exported to prevent
name clashes with the compile command of modelsim. It is therefore recommended to only use compile_files.

**Parameters**
<table>
    <tr>
      <th width="200"><b>Parameter</b></th>
      <th align="center" width="80"><b>Optional</b></th>
      <th align="right"><b>Description</b></th>
    </tr>
    <tr>
      <td> -all </td>
      <td> Yes </td>
      <td> Compile all source files. </td>
    </tr>
    <tr>
      <td> -lib </td>
      <td> Yes </td>
      <td> Only compile files that belong to a given library. </td>
    </tr>
	<tr>
      <td> -tag </td>
      <td> Yes </td>
      <td> Only compile files that have a given tag. This option can for example be used to only re-compile            files that are related to a certain part of the project. </td>
    </tr>
    <tr>
      <td> -contains </td>
      <td> Yes </td>
      <td> Only compile files if their path contains a given string </td>
    </tr>
	<tr>
      <td> -clean </td>
      <td> Yes </td>
      <td> Clean all libraries before compiling. Note that this option should only be used together with the
           -all switch.  </td>
    </tr>	
</table>

### run_tb
**Usage**
```
run_tb [-all] [-lib <lib>] [-name <name>] [-contains <str>]
```

**Description**  
This command executes the specified testbench runs.

**Parameters**
<table>
    <tr>
      <th width="200"><b>Parameter</b></th>
      <th align="center" width="80"><b>Optional</b></th>
      <th align="right"><b>Description</b></th>
    </tr>
    <tr>
      <td> -all </td>
      <td> Yes </td>
      <td> Run all TB runs in the projet. </td>
    </tr>
    <tr>
      <td> -lib </td>
      <td> Yes </td>
      <td> Only run TB runs for testbenches in a given library. </td>
    </tr>
	<tr>
      <td> -name </td>
      <td> Yes </td>
      <td> Only execute TB runs for a testbench with a given name. </td>
    </tr>
    <tr>
      <td> -contains </td>
      <td> Yes </td>
      <td> Only execute testbenches that contain a given string in their name </td>
    </tr>
</table>


### run_check_errors
**Usage**
```
run_check_errors <string>
```

**Description**  
This command checks whether a given error string occurs in the transcript. If yes, simulations are regarded
as failed. If the string does not occur, simulations are regarded as successul.

It is recommended to use a very distinctive error pattern (e.g. "###ERROR###"). If a less distinctive pattern such as
"Error" is used, there is a probability that the pattern occurs in messages that are not errors (e.g. "Checking Correct Operation for zero Position Error").

Note that all libraries use the error pattern ###ERROR###.

**Parameters**
<table>
    <tr>
      <th width="200"><b>Parameter</b></th>
      <th align="center" width="80"><b>Optional</b></th>
      <th align="right"><b>Description</b></th>
    </tr>
    <tr>
      <td> str </td>
      <td> No </td>
      <td> Error string to search for </td>
    </tr>
</table>

### launch_tb
**Usage**
```
launch_tb -contains <str> [-argidx <index>] [-wave [<file>]] [-show]
```

**Description**
This command launches the specified TB run but it does not execute it (without the -wave and -show options used). Instead it stops after launching, so the user can execute the simulation interactively and view the waveform. So this command is intended for interactive debugging.

The user can optionally choose to use a specific set of testbench arguments (see [tb_run_add_arguments](#tb_run_add_arguments)) by using the *-argidx* option. If the option is not used, the testbench is started with the default generics from the source code.


**Parameters**
<table>
    <tr>
      <th width="200"><b>Parameter</b></th>
      <th align="center" width="80"><b>Optional</b></th>
      <th align="right"><b>Description</b></th>
    </tr>
    <tr>
      <td> -contains </td>
      <td> No </td>
      <td> Execute only the first testbench that contains the given string in its name </td>
    </tr>
    <tr>
      <td> -argidx </td>
      <td> Yes </td>
      <td> Index of the TB arguments to use (see [tb_run_add_arguments](#tb_run_add_arguments)). Index is zero based (i.e. passing 0 leads to the first argument set being used). If this option is omitted, the testbench is started with its default arguments as given in the source code. </td>
    </tr>  
    <tr>
      <td> -wave </td>
      <td> Yes </td>
      <td> Modelsim: Optionally a do-file can be passed for a desired waveform view. In case -wave is passed without argument, all signals are added to the waveform, the simulation is run and the zoom is set to the complete run. <br> GHDL: When executing this option in GHDL, a vcd file is generated with the naming pattern <tb_name><argidx|default>.vcd. The parameter <file> is not implemented in GHDL.</td>
    </tr>   
    <tr>
      <td> -show </td>
      <td> Yes </td>
      <td> GTKwave is opened (forked) with the generated vcd file. Only implemented in GHDL.</td>
    </tr>    
</table>