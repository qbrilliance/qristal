# Quantum Brilliance SDK

The QB SDK is the QB software development kit for quantum computing.

## Getting Started

For the private beta release, the QB SDK can be installed directly from source or via a pre-built Docker image. The Docker image is provided in the container GitLab container registry associated with SDK repository.

### Docker

Depending on how you have set up Docker on your system, you may or may not need to run the following commands as root.

1. Login to GitLab container registry

```
docker login registry.gitlab.com
```

Enter your GitLab login credential as prompted.

2. Start the QB SDK container

```
docker run --rm -it --name qbsdk -d -p 8889:8889 -p 8080:8080 registry.gitlab.com/qbau/software-and-apps/public/qbsdk
```

The above command will start the QB SDK container and map TCP ports 8080 and 8889 of the container to the same ports on the Docker host (your computer).

From your web browser, you can access the SDK documentation at http://localhost:8080 and a JupyterLab environment at http://localhost:8889 to view Python examples and start prototyping with the SDK.

3. Connect to the QB SDK container

After starting the container, besides the [JupyterLab environment](http://localhost:8889), you can connect (attach) directly to the container via a terminal or VSCode.

- For the terminal, run the following command to attach to a terminal session inside the container.

```
docker exec -it qbsdk bash
```

- If you prefer using VSCode, you can "attach" VS Code to the  running `qbsdk` Docker container.

To attach to the `qbsdk` Docker container, either select `Dev Containers: Attach to Running Container...` from the `Command Palette` (F1) or use the `Remote Explorer` in the `Activity Bar` and from the `Containers` view, select the `Attach to Container` inline action on the container. In both methods, a dropdown will appear, select the `qbsdk` container.

4. Stop and remove the container

```
docker stop qbsdk
```

### Install from source

**Prerequisites**

In this private beta release, only Linux (e.g., Ubuntu) is supported.

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

**Compilation**

<a name="compilation"></a>

After cloning the QB SDK repository, compile and install it with

```
export GITLAB_PRIVATE_TOKEN=<YOUR GITLAB API KEY>
mkdir build && cd build
cmake .. -DINSTALL_MISSING=ON
make -j$(nproc) install
```

If you wish to only install missing C++ or Python dependencies, instead of passing `-DINSTALL_MISSING=ON` you can pass `-DINSTALL_MISSING=CXX` or `-DINSTALL_MISSING=PYTHON`.

If you also wish to build the C++ noise-aware circuit placement based on the [TKET](https://github.com/CQCL/tket) library, you can pass `-DWITH_TKET=ON` to `cmake`.

Along with the `-DINSTALL_MISSING=ON` option as shown above, `cmake` will automatically pull in and build TKET for you.
Alternatively, if you have an existing TKET installation, you can pass `-DWITH_TKET=ON -DTKET_DIR=<YOUR TKET INSTALLATION DIR>` to `cmake` to let it use your installation rather than building TKET from source.  

If you also wish to build the html documentation, you can pass `-DQB_BUILD_DOCS=ON` to `cmake`.

When using the QB SDK, a user workflow normally consists of the following steps:

- Define a quantum circuit, for example, as an OpenQASM source string.

- Configure the QB SDK runtime, e.g., the accelerator backend, number of measurement shots, etc.

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

If using the pre-built Docker image, users will also have access to the beta version of the QB emulator allowing for emulating QB hardware devices. The emulation (noisy simulation) can be enabled with

```
# Import the core of the QB SDK
import qb.core

# Create a quantum computing session using the QB SDK
my_sim = qb.core.session()

# Set up meaningful defaults for session parameters
my_sim.qb12()

# Enable noisy simulation
my_sim.noise = True

# Choose the noise model
my_sim.noise_model = "qb-nm1"

# Choose a simulator backend
my_sim.acc = "qsim"

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

In particular, we set the `noise` option to `True` and choose a QB noise model (e.g., `qb-nm1`).

We can see the effect of quantum noises in the resulting measurement distribution.  If you run the noisy example, you will get an output similar to the following:

```
About to run quantum program...
Ran successfully!
Results:
 {
    "00": 43,
    "01": 2,
    "10": 1,
    "11": 54
}
```

Values for "00" and "11" will be around 50, whereas those for "01" and "10" will be around 0.


## Further examples ##

Following installation, you can find 

- A series of examples in the installed folder `examples`.  These are described [here](examples/README.md).
- A detailed set of introductory exercises in the `exercises` folder.  These can be launched using Jupyter Notebook.
- A standalone [Quantum Decoder application](docs/README_decoder.md).

## Documentation
If you have built and installed the documentation (see [compilation](#compilation)), you can find it [here](docs/html/index.html).
