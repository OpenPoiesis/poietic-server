# Poietic Server

Simple server to locally serve and simulate Stock-and-Flow models.

_Important: This is just an early prototyping playground. Not for serious use
at this stage._


## Installation

Pre-requisites:

1. Build and install [Poietic Flows](https://github.com/OpenPoiesis/PoieticFlows).
   See the instructions contained in the project.
2. Build the server: `swift build`

## Usage

The server requires a design library file. The file can be created using the
Poietic tool command `poietic create-library`, see
`poietic create-library --help` for more information about the command.

### Examples

Download Flows examples from [Poietic Examples](https://github.com/OpenPoiesis/PoieticExamples)
repository.

Run the included script `create-examples-library`, which will:

1. Search for `*.poieticframe` source files in `FRAMES_PATH` (default: `../PoieticExamples`)
2. Creates a design file for each frame.
3. Creates a library `poietic-library.json` in current directory.

Example run:

```
git clone https://github.com/OpenPoiesis/PoieticExamples
FRAMES_PATH=PoieticExamples ./create-examples-library
```

Start the server:

```bash
swift run poietic-server
```

Open the file [Demo/index.html](Demo/index.html) in your browser.


## Author

- [Stefan Urbanek](mailto:stefan.urbanek@gmail.com)
