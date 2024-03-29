# lindoapi-lua
                      Copyright (c) 2024

         LINDO Systems, Inc.           312.988.7422
         1415 North Dayton St.         info@lindo.com
         Chicago, IL 60622             http://www.lindo.com
         
**lindoapi-lua** is a Lua binding for the LINDO API. It allows you to interface with the LINDO API optimization library in the Lua programming language. This can be particularly useful if you want to perform complex mathematical optimization tasks in your Lua applications.

Using scripting languages like Lua simplifies the process of prototyping ideas and testing different parameter settings for optimization tasks. Lua offers a flexible and dynamic environment for implementing and testing algorithms without the need for complex build processes. This streamlined process helps researchers and practitioners efficiently explore and evaluate various optimization strategies, leading to more effective and efficient solutions.

## Installation

Clone this repository to install lindoapi-lua.

   ```bash
   git clone https://github.com/lindosystems/lindoapi-lua.git
   ```     

Make sure to have LINDO API installed on your system. If you haven't already, click [here](https://www.lindo.com/index.php/ls-downloads/try-lindo-api) to download and install the latest version.


For more detailed information on LINDO API, please refer to the official LINDO API user-manual and Appendix on Lua.


## Running lindoapi-lua

In order to utilize the lindoapi-lua and run the provided examples, you can initiate the process from the command-line interface. To begin, open a command-line (shell) and activate lindoapi-lua by executing the "activate_lindo_lua.bat" script for Windows or the "activate_lindo_lua.sh" script for Unix-like systems. 

On Windows

        > activate_lindo_lua.bat win64x86

On Unix-like systems

        $ source activate_lindo_lua.sh linux64x86

Subsequently, run the "lslua" command to execute the desired example. For instance, to run the "ex_solve.lua" example, execute the following command line:

On Windows

        > lslua ex_solve.lua -m c:/path/to/myfile.mps

On Unix-like systems

        $ lslua ex_solve.lua -m /path/to/myfile.mps
        
This interface is versionless and supports all recent LINDO API versions. The version to use will be deduced from the `LINDOAPI_LICENSE_FILE` and `LINDOAPI_HOME` environment variables.    

## Examples

lindoapi-lua binding for the LINDO API has several illustrative examples that showcase the versatility and utility of using Lua for various mathematical optimization tasks. 

- The `ex_solve` example mimics the functionality of the `runlindo` command, demonstrating how Lua can be used to interface with the LINDO API for solving optimization problems encoded in the MPS or other portable file formats. See the section on `runlindo` in the LINDO API's user manual.
- The `ex_sets` example highlights the ability to add arbitrary Special Ordered Sets (SOS) constraints to a model, showcasing Lua's flexibility in manipulating and customizing model data.
- The `ex_imbnd` example demonstrates how Lua can be utilized to compute the implied bounds of variables within an optimization model, showcasing the power of scripting languages for performing repetitive optimization tasks.
- The `ex_debug` example exemplifies Lua's capability to aid in debugging infeasible linear, integer, or nonlinear models, showcasing its utility in troubleshooting and refining optimization models.
- The `ex_sort` example illustrates Lua's potential for sorting a vector using math programming techniques, showcasing its applicability beyond traditional optimization tasks.
- The `ex_cluster` example showcases Lua's ability to perform cluster analysis using LINDO API's extension libraries, highlighting its potential for advanced data analysis and optimization-related tasks. These examples collectively underscore the diverse applications and advantages of using Lua and the **lindoapi-lua** binding for mathematical optimization and related tasks.


## Testing Reproducibility - A Detailed Use Case

The `ex_solve` example includes special command-line options `--ktryenv=<NUMBER>`, `--ktrymod=<NUMBER>`, and `--ktrysolv=<NUMBER>`. These options are designed to test the reproducibility of solutions on single-threaded runs for LP/QP/NLP models, with or without integer restrictions. Each option determines the count of times the software will create a fresh environment, instantiate a new model, and begin a new solving process to tackle a given model repeatedly while keeping the parameters constant. This method offers a simple and dependable way to collect and compare logs from multiple optimization trials, facilitating the verification of solution consistency.

In addition, the `--ktrylogf=<keyword>` option enables exporting logs of each run to a file, with `<keyword>` serving as the basename for the log files. This option is implied by `--ktryenv`, `--ktrymod` and `--ktrysolv` options and set to a random string unless specified by the user. This feature provides a convenient means of capturing and documenting the reproducible details of each optimization run, like (i) branch-counts, (ii) #LPs solved, (iii) iteration-counts, (iv) active nodes etc. Note, time-elapsed log entries are specifically ignored as these entries are not deterministic because elapsed time can vary from run to run depending on machine workload.

There are other options required to ensure the reproducibility of logs: first, all time-limits should be turned off (already the default). Also, to ensure reproducibility of MIP logs, `--cbmip=1 --cblog=0` options need to be set. The former (`--cbmip=1`) activates progress logging only at new-integer solution epochs, while the latter (`--cblog=0`) disables the standard MIP log, which contain non-reproducible components such as time-elapsed information. After completing the runs, the log strings are concatenated and subjected to SHA1 or MD5 hashing to compute a hash value of their content, thereby establishing a simple but robust framework for comparing logs or solution vectors.

A typical test run for reproducibility can be initiated as follows. Here, `X.Y` stands for LINDO API's version number, e.g. `12.0`. You should modify this line according to your installation path.

        $ lslua ex_solve.lua -m /usr/lindoapi/X.Y/samples/data/bm23.mps --ktrymod=10  --ktrylogf=bm23 --cblog=0 --cbmip=1

A report will be generated to display the hash of the log strings and primal solution vector. The `log.digests` table will showcase the hash values of the logs, with each entry indicating a unique hash value for a specific log file. For instance:

        log.digests:
        {
              ccb5a7c3d41c4d72 = 10,
        }
        
Similarly, the `solution.digests` table will provide the counts of different hash values of terminal primal solutions, with each entry representing a distinct hash value and its corresponding count in the solution vector. For example:

        solution.digests:
        {
              2b69668ddde265aa = 10,
        }

In the event that there are logs differ from one another, the log.digests table would contain multiple entries, each corresponding to a unique hash value for a log file. Likewise, the `solutions.digest` table would present counts of different hash values of terminal primal solutions, offering insights into the variability and consistency of the optimization runs.

## Contributing

Contributions are welcome! If you find any issues with **lindoapi-lua** or have ideas for improvements, please open an issue or submit a pull request.

