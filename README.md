# Quantum Brilliance Qristal SDK

Qristal is the QB software development kit for quantum computing.

## Getting Started

QB Qristal can be installed directly from source or via a pre-built Docker image.

### Docker

A Docker image is provided in the GitLab container registry associated with the SDK repository.

Depending on how you have set up Docker on your system, you may or may not need to run the following commands as root.

1. Start the QB Qristal container
```
docker run --rm -it --name qbsdk -d -p 8889:8889 registry.gitlab.com/qbau/software-and-apps/public/qbsdk
```
If your system has one or more NVIDIA GPUs, install the [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker) and add the switch `--gpus all` to the `docker run` command in order to use them.

This command will start a container and map its TCP port 8889 to the same port on the Docker host (your computer).

From your web browser, you can access a JupyterLab environment at http://localhost:8889 to view Python examples and start prototyping with QB Qristal.

2. Connect to the QB Qristal container

After starting the container, besides the [JupyterLab environment](http://localhost:8889), you can connect (attach) directly to the container via a terminal or VSCode.

- For the terminal, run the following command to attach to a terminal session inside the container.

```
docker exec -it qbsdk bash
```

- If you prefer to use VSCode, you can "attach" it to the  running `qbsdk` Docker container.

To attach to the `qbsdk` Docker container, either select `Dev Containers: Attach to Running Container...` from the `Command Palette` (F1) or use the `Remote Explorer` in the `Activity Bar` and from the `Containers` view, select the `Attach to Container` inline action on the container. In both methods, a dropdown will appear; select the `qbsdk` container.

3. Stop and remove the container

```
docker stop qbsdk
```

### Install from source

**Prerequisites**

As of this beta release, only Linux (e.g., Ubuntu) is supported.

At a minimum, the following packages are required:

- Python3.8+

- gcc, g++, and gfortran (version 7+).  Usage of clang is supported, but gcc/g++ is still required for building exatn and tnqvm.

- cmake (version 3.20+)

- Eigen 3.4+

- Boost 1.71+

- OpenBLAS

- Curl


For example, on Debian-based distributions (e.g., Ubuntu), we can use `apt` to install all above prerequisites:

```
sudo apt install build-essential cmake gfortran libboost-all-dev libcurl4-openssl-dev  libeigen3-dev libopenblas-dev libpython3-dev python3 python3-pip
```

Qristal will be built with support for CUDA Quantum if and only if cmake detects that your system has a compatible CUDA Quantum installation.

**Compilation**

<a name="compilation"></a>

After cloning the QB Qristal SDK repository, compile and install it with

```
mkdir build && cd build
cmake .. -DINSTALL_MISSING=ON
make -j$(nproc) install
```

If you wish to only install missing C++ or Python dependencies, instead of passing `-DINSTALL_MISSING=ON` you can pass `-DINSTALL_MISSING=CXX` or `-DINSTALL_MISSING=PYTHON`.

If you also wish to build the C++ noise-aware circuit placement based on the [TKET](https://github.com/CQCL/tket) library, you can pass `-DWITH_TKET=ON` to `cmake`.

Along with the `-DINSTALL_MISSING=ON` option as shown above, `cmake` will automatically pull in and build TKET for you.
Alternatively, if you have an existing TKET installation, you can pass `-DWITH_TKET=ON -DTKET_DIR=<YOUR TKET INSTALLATION DIR>` to `cmake` to let it use your installation rather than building TKET from source.  

If you also wish to build the html documentation, you can pass `-DBUILD_DOCS=ON` to `cmake`.

When using QB Qristal, a user workflow normally consists of the following steps:

- Define a quantum circuit, for example, as an OpenQASM source string.

- Configure the QB Qristal runtime, e.g., the accelerator backend, number of measurement shots, etc.

- Run the circuit with the specified configurations.

- Retrieve and analyze the results of the experiments.

Here is an example of the entire workflow:

```
# Import the core of the QB SDK
import qb.core

# Create a quantum computing session using the QB SDK
my_sim = qb.core.session()

# Set up meaningful defaults for session parameters
my_sim.qb12()

# Choose a simulator backend
my_sim.acc = "qpp"

# Choose how many qubits to simulate
my_sim.qn = 2

# Choose how many 'shots' to run through the circuit
my_sim.sn = 100

# Define the quantum program to run (aka 'quantum kernel' aka 'quantum circuit')
my_sim.instring = '''
__qpu__ void MY_QUANTUM_CIRCUIT(qreg q)
{
  OPENQASM 2.0;
  include "qelib1.inc";
  creg c[2];
  h q[0];
  cx q[0], q[1];
  measure q[1] -> c[1];
  measure q[0] -> c[0];
}
'''

# Run the circuit 100 times and count up the results in each of the classical registers
print("About to run quantum program...")
my_sim.run()
print("Ran successfully!")

# Print the cumulative results in each of the classical registers
print("Results:\n", my_sim.out_raw[0][0])
```

If you run the example, you will get an output similar to the following (right-hand values will both be around 50):

```
About to run quantum program...
Ran successfully!
Results:
 {
    "00": 45,
    "11": 55
}
```

## Further examples ##

Following installation, you can find 

- A series of examples in the installed folder `examples`.  These are described [here](examples/README.md).
- A detailed set of introductory exercises in the `exercises` folder.  These can be launched using Jupyter Notebook.
- A standalone [Quantum Decoder application](docs/README_decoder.md).

## Documentation
You can find Qristal documentation [here](https://qristal.readthedocs.io/en/latest/).
