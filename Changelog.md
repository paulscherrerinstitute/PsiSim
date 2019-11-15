## 2.3.0

* Added Features
  * Added *launch\_tb* command
  * Show message icons in Modelsim
* Bugfixes
  * Made GHDL more permissive to better match Modelsim behavior

## 2.2.0

* Added Features
  * Vivado simulator is now also supported

## 2.1.0

* Added Features
  * Added *tb\_run\_skip* - possibility to skip a simulation for one or all simulator tools (helps avoiding tool bugs)

## 2.0.2

* Bugfixes
  * Fixed Modelsim Version Readout (required for 2.0.1) to also work on linux and be more stable

## 2.0.1

* Bugfixes
  * Do only use -novopt flag for modelsim versions < 10.7 (does not exist anymore in newer versions)

## 2.0.0

* First open-source release (older history is not kept)

## 1.5.1

* Bugfixes
  * Version and Options (added in 1.5.0) did not always work due to TCL/Modelsim issues
  * Only print warning (and do not abort with an error) if the same file is added twice

## 1.5.0

* Added Features
  * Version and Options switch added to add\_sources command.
  * Check if the same file is added to the same library multiple times and throw error if this is the case

## 1.4.0

* Added Features
  * PsiSim now also supports GHDL (not only Modelsim). In the case of GHDL, the GHDL directory must be added to the system path and the TCL scripts must be evaluated by a standalone TCL interpreter (e.g. active TCL).

## 1.3.1

* Bugfixes
  * Prevented simulation from aborting if the transcript file cannot be deleted. This is the case for batch-mode execution where the option *-logfile transcript.transcript* must be passed to the *vsim* command and therefore this file is locked during execution of the simulation.

## 1.3.0

* Added features
  * Added -contains option to *run_tb* and *compile* commands to only handle files with a given string in their name (helps with development focused on some parts of bigger libraries)

## 1.2.0

* Added Features
  * Added the option to limit the simulation time for each tb\_run (to allow using testbenches that do not stop on their own)
* Bugfixes
  * None

## 1.1.1

* Added Features
  * None
* Bugfixes
  * Fix issue #1: run\_check_errors did not work when run\_tb was not run previously
  * Fix issue #2: compile\_files ignored arguments

## V1.01

* Added Features
  * Implemented propper namespace handling
* Bugfixes
  * None

## V1.00

* First release