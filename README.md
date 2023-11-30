# lindoapi-lua

**lindoapi-lua** is a Lua binding for the LINDO API. It allows you to interface with the LINDO API optimization library in the Lua programming language. This can be particularly useful if you want to perform complex mathematical optimization tasks in your Lua applications.

Using scripting languages like Lua simplifies the process of prototyping ideas and testing different parameter settings for optimization tasks. Lua offers a flexible and dynamic environment for implementing and testing algorithms without the need for complex build processes. The lindoapi-lua binding provides a powerful tool for interfacing with the LINDO API optimization library directly within Lua, enabling rapid experimentation with parameter configurations and algorithmic approaches. This streamlined process helps researchers and practitioners efficiently explore and evaluate various optimization strategies, leading to more effective and efficient solutions.

## Installation

To use **lindoapi-lua**, you need to have the LINDO API installed on your system. If you haven't already, follow the installation instructions in LINDO API user manual.

   ```bash
   git clone https://github.com/your-username/lindoapi-lua.git
   ```     

## Documentation

For more detailed information on LINDO API, please refer to the official LINDO API user-manual and Appendix on Lua.


## Running lindoapi-lua

In order to utilize the lindoapi-lua and run the provided examples, the user can initiate the process from the command-line interface. To begin, the user should open a command-line (shell) and activate lindoapi-lua by executing the "activate_lindo_lua.bat" script for Windows or the "activate_lindo_lua.sh" script for Unix-like systems. 

On Windows

        > activate_lindo_lua.bat win64x86

On Unix-like systems

        $ source activate_lindo_lua.sh linux64

Subsequently, depending on the operating system bit size, the user can run the "lslua" command for 32-bit systems or "lslua64" for 64-bit systems to execute the desired examples. For instance, to run the "ex_mps.lua" example, the user can utilize the following command line:

On Windows

        > lslua64.exe ex_mps.lua -m c:/path/to/myfile.mps

On Unix-like systems

        $ lslua64.lnx64 ex_mps.lua -m /path/to/myfile.mps

**Note:** Currently only Windows versions are available. Open a request for other platforms.

## Examples

lindoapi-lua binding for the LINDO API has several illustrative examples that showcase the versatility and utility of using Lua for mathematical optimization tasks. 

- The "ex_mps" example mimics the functionality of the "runlindo" command, demonstrating how Lua can be used to interface with the LINDO API for solving optimization problems encoded in the MPS or other portable file formats.
- The "ex_sets" example highlights the ability to add arbitrary Special Ordered Sets (SOS) constraints to a model, showcasing Lua's flexibility in manipulating and customizing optimization models.
- The "ex_imbnd" example demonstrates how Lua can be utilized to compute the implied bounds of variables within an optimization model, showcasing the power of scripting languages for performing advanced mathematical computations.
- The "ex_debug" example exemplifies Lua's capability to aid in debugging infeasible linear, integer, or nonlinear models, showcasing its utility in troubleshooting and refining optimization models.
- The "ex_sort" example illustrates Lua's potential for sorting a vector using math programming techniques, showcasing its applicability beyond traditional optimization tasks.
- The "ex_cluster" example showcases Lua's ability to perform cluster analysis using LINDO API's extension libraries, highlighting its potential for advanced data analysis and optimization-related tasks. These examples collectively underscore the diverse applications and advantages of using Lua and the **lindoapi-lua** binding for mathematical optimization and related tasks.


## Testing Reproducibility - A Detailed Use Case

The "ex_mps" example not only mimics the functionality of the "runlindo" command, but also offers special command-line options such as `--ktryenv=<NUMBER>`, `--ktrymod=<NUMBER>`, and `--ktrysolv=<NUMBER>` which are suitable for testing the reproducibility of solutions (when available). This is done by performing back-to-back runs (under the same optimization parameter configuration) with these options specifying the number of times a new `environment`, `model`, and `optimization-call` would be initiated. This provides a simple but robust mechanism for verifying the reproducibility of optimization solutions across multiple runs with the same parameter settings. 

In addition, the `--ktrylogf=<keyword>` option in the "ex_mps" example enables the export of the log of each run to a file, with `<keyword>` serving as the basename for the log files. This feature provides a convenient means of capturing and documenting the reproducible details of each optimization run, like (i) branch-counts, (ii) #LPs solved, (iii) iteration-counts, (iv) active nodes etc. Note, time-elapsed log entries are specifically ignored as these entries are not deterministic (i.e. can vary from log to log)

Note, to ensure the reproducibility of runs, time-limits should *not* be turned. To ensure reproducibility of logs, `--cbmip=1 --cblog=0` options need to be used. The former (--cbmip=1) activates progress logging only at new-integer solution epochs, while the latter (--cblog=0) disables the standard MIP log containing non-reproducible components such as time-elapsed information. Subsequently, the log strings are concatenated and subjected to SHA1 or MD5 hashing to verify their identicalness, thereby establishing a robust framework for validating the consistency and reproducibility of optimization runs conducted under the same parameter configuration.

A typical test run for reproducibility can be initiated as follows

        $ lslua ex_mps.lua -m /usr/lindoapi/14.0/samples/data/bm23.mps --ktrymod=10  --ktrylogf=bm23 --cblog=0 --cbmip=1

A report will be generated to display the hash of the log strings and primal solution vector. The log.digests table will showcase the hash values of the logs, with each entry indicating a unique hash value for a specific log file. For instance:

        log.digests:
        {
              ccb5a7c3d41c4d72 = true,
        }
        
Similarly, the solution.digests table will provide the counts of different hash values of terminal primal solutions, with each entry representing a distinct hash value and its corresponding count in the solution vector. For example:

        solution.digests:
        {
              2b69668ddde265aa = 10,
        }

In the event that there are logs differ from one another, the log.digests table would contain multiple entries, each corresponding to a unique hash value for a log file. Likewise, the solutions.digest table would present counts of different hash values of terminal primal solutions, offering insights into the variability and consistency of the optimization runs.

## Contributing

Contributions are welcome! If you find any issues with **lindoapi-lua** or have ideas for improvements, please open an issue or submit a pull request.

