# lindoapi-lua

**lindoapi-lua** is a Lua binding for the LINDO API. It allows you to interface with the LINDO API optimization library in the Lua programming language. This can be particularly useful if you want to perform complex mathematical optimization tasks in your Lua applications.

The use of scripting languages, such as Lua, can greatly facilitate the prototyping of ideas and the exploration of different parameter settings for optimization tasks. Scripting languages offer a flexible and dynamic environment for quickly implementing and testing algorithms, without the need for time-consuming compilations or complex build processes. In the context of mathematical programming tasks, the lindoapi-lua binding provides a powerful tool for interfacing with the LINDO API optimization library directly within the Lua programming language. This seamless integration allows for rapid experimentation with different parameter configurations and algorithmic approaches, enabling practitioners to efficiently explore and evaluate various optimization strategies. By leveraging scripting languages like Lua in conjunction with specialized optimization libraries, researchers and practitioners can streamline the process of testing and refining parameter adjustments, ultimately leading to more effective and efficient optimization solutions.

## Table of Contents

- [Installation](#installation)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

## Installation

To use **lindoapi-lua**, you need to have the LINDO API installed on your system. If you haven't already, follow the installation instructions for LINDO API user manual.

   ```bash
   git clone https://github.com/your-username/lindoapi-lua.git
   ```     

## Documentation

For more detailed information, please refer to the official LINDO API documentation and Lua documentation.

- [LINDO API Documentation](https://www.lindo.com/doc/online_help/9_0/)


## Examples

lindoapi-lua binding for the LINDO API has several illustrative examples that showcase the versatility and utility of using Lua for mathematical optimization tasks. 

- The "ex_mps" example mimics the functionality of the "runlindo" command, demonstrating how Lua can be used to interface with the LINDO API for solving optimization problems encoded in the MPS or other portable file formats.
- The "ex_sets" example highlights the ability to add arbitrary Special Ordered Sets (SOS) constraints to a model, showcasing Lua's flexibility in manipulating and customizing optimization models.
- The "ex_imbnd" example demonstrates how Lua can be utilized to compute the implied bounds of variables within an optimization model, showcasing the power of scripting languages for performing advanced mathematical computations.
- The "ex_debug" example exemplifies Lua's capability to aid in debugging infeasible linear, integer, or nonlinear models, showcasing its utility in troubleshooting and refining optimization models.
- The "ex_sort" example illustrates Lua's potential for sorting a vector using math programming techniques, showcasing its applicability beyond traditional optimization tasks.
- The "ex_cluster" example showcases Lua's ability to perform cluster analysis using LINDO API's extension libraries, highlighting its potential for advanced data analysis and optimization-related tasks. These examples collectively underscore the diverse applications and advantages of using Lua and the **lindoapi-lua** binding for mathematical optimization and related tasks.

## Testing Reproducibility - A Detailed Use Case

The "ex_mps" example not only mimics the functionality of the "runlindo" command, but also offers special command-line options such as --ktryenv=<NUMBER>, --ktrymod=<NUMBER>, and --ktrysolv=<NUMBER> which are suitable for testing the reproducibility of solutions (when available) with back-to-back runs under the same parameter configuration. These options allow the user to identify the number of times an environment, model, and solver-invocation will be tried, providing a robust mechanism for verifying the consistency and reliability of optimization solutions across multiple runs with the same parameter settings. 

In addition, the "--ktrylogf=<keyword>" option in the "ex_mps" example enables the export of the log of each run to a file, with <keyword> serving as the basename for the log files. This feature provides a convenient means of capturing and documenting the reproducible details of each optimization run, like i) branch-counts, ii) #LPs solved, iii) iteration-counts, iv) active nodes etc. Furthermore, to ensure the reproducibility of runs, the "--cbmip=1 --cblog=0" options should be enabled, where the former (--cbmip=1) activates progress logging at new-integer solution epochs, while the latter (--cblog=0) disables the standard MIP log containing non-reproducible components such as time-elapsed information. Subsequently, the log files are subjected to SHA1 or MD5 hashing to verify their identicalness, thereby establishing a robust framework for validating the consistency and reproducibility of optimization runs conducted under the same parameter configuration.

## Contributing

Contributions are welcome! If you find any issues with **lindoapi-lua** or have ideas for improvements, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.